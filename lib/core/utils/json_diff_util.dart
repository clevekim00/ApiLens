import 'dart:convert';

enum DiffType { added, removed, changed, unchanged }

class DiffNode {
  final String key;
  final dynamic oldValue;
  final dynamic newValue;
  final DiffType type;
  final List<DiffNode> children;

  DiffNode({
    required this.key,
    this.oldValue,
    this.newValue,
    required this.type,
    this.children = const [],
  });
}

class JsonDiffUtil {
  static List<DiffNode> compare(dynamic oldJson, dynamic newJson) {
    return _compareNodes('', oldJson, newJson);
  }

  static List<DiffNode> _compareNodes(String key, dynamic oldVal, dynamic newVal) {
    // 1. If types are different, it's a change (unless both null?)
    if (oldVal.runtimeType != newVal.runtimeType && oldVal != null && newVal != null) {
      // Allow int/double mismatch if values are same numbers? For strict JSON, they are numbers.
      // But Dart differentiates. Let's simplfy: strictly changed.
      return [DiffNode(key: key, oldValue: oldVal, newValue: newVal, type: DiffType.changed)];
    }

    // 2. Maps
    if (oldVal is Map && newVal is Map) {
      final List<DiffNode> nodes = [];
      final oldMap = Map<String, dynamic>.from(oldVal);
      final newMap = Map<String, dynamic>.from(newVal);

      final allKeys = {...oldMap.keys, ...newMap.keys}.toList()..sort();

      for (var k in allKeys) {
        if (!oldMap.containsKey(k)) {
          // Added
          nodes.add(DiffNode(key: k, newValue: newMap[k], type: DiffType.added));
        } else if (!newMap.containsKey(k)) {
          // Removed
          nodes.add(DiffNode(key: k, oldValue: oldMap[k], type: DiffType.removed));
        } else {
          // Both verify
          final subDiffs = _compareNodes(k, oldMap[k], newMap[k]);
          if (subDiffs.isNotEmpty) {
             // If subDiffs represent the node itself or its children
             // We wrap them in a container node if it's a complex object that wasn't fully replaced?
             // Actually _compareNodes returns a list of diffs. 
             // If the value was a primitive and changed, it returns one Changed node.
             // If it was a map and had children changes, it returns children nodes.
             // We want to group them under 'k' if they are children.
             
             final isPrimitiveChange = subDiffs.length == 1 && subDiffs.first.key == k && subDiffs.first.type == DiffType.changed;
             
             if (isPrimitiveChange) {
               nodes.add(subDiffs.first);
             } else {
               // Children changed. We only add if there are actual changes
               // We need a parent node to show structure? 
               // For simple diff view: Flatten or Tree?
               // Let's create a "Unchanged" node with children diffs for structure?
               // Or just "Changed" node with children.
               final hasChanges = subDiffs.any((n) => n.type != DiffType.unchanged);
               if (hasChanges) {
                  nodes.add(DiffNode(key: k, type: DiffType.unchanged, children: subDiffs)); // Parent is unchanged container, children changed
               }
             }
          }
        }
      }
      return nodes;
    }

    // 3. Lists (Simple index based comparison for MVP)
    if (oldVal is List && newVal is List) {
       final List<DiffNode> nodes = [];
       final maxLen = oldVal.length > newVal.length ? oldVal.length : newVal.length;
       
       bool listChanged = false;
       for (int i = 0; i < maxLen; i++) {
         final k = '[$i]';
         if (i >= oldVal.length) {
           nodes.add(DiffNode(key: k, newValue: newVal[i], type: DiffType.added));
           listChanged = true;
         } else if (i >= newVal.length) {
           nodes.add(DiffNode(key: k, oldValue: oldVal[i], type: DiffType.removed));
           listChanged = true;
         } else {
           final subDiffs = _compareNodes(k, oldVal[i], newVal[i]);
            if (subDiffs.isNotEmpty) {
               nodes.addAll(subDiffs); // Flatten list items or wrap? Wrap is better really.
               listChanged = true;
            }
         }
       }
       // If list items changed, we usually wrap them if we want tree structure.
       // Creating a wrapper node for the list key if provided.
       if (listChanged && key.isNotEmpty) {
         return [DiffNode(key: key, type: DiffType.unchanged, children: nodes)];
       }
       return nodes;
    }

    // 4. Primitives
    if (oldVal != newVal) {
      return [DiffNode(key: key, oldValue: oldVal, newValue: newVal, type: DiffType.changed)];
    }

    return []; // Equal
  }
}
