import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart'; // for Id
import '../providers/environment_provider.dart';
import '../models/environment_item.dart';
import '../../request/widgets/key_value_editor.dart';
import '../../request/models/key_value_item.dart';
import 'package:uuid/uuid.dart';

class EnvironmentManagerScreen extends ConsumerWidget {
  const EnvironmentManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envListAsync = ref.watch(environmentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Environments'),
      ),
      body: envListAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No Environments defined.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddDialog(context, ref),
                    child: const Text('Create New'),
                  ),
                ],
              ),
            );
          }
          return Row(
            children: [
              // Left: List
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final isSelected = ref.watch(activeEnvironmentIdProvider) == item.id;
                          return ListTile(
                            title: Text(item.name),
                            selected: isSelected,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                ref.read(environmentListProvider.notifier).deleteEnvironment(item.id);
                              },
                            ),
                            onTap: () {
                               // Open edit view for this env (Right pane)
                               // For MVP simplicity, we can just push a detail screen or use a provider to select "editing" item
                               ref.read(_editingEnvIdProvider.notifier).state = item.id;
                            },
                            leading: Radio<Id?>(
                              value: item.id,
                              groupValue: ref.watch(activeEnvironmentIdProvider),
                              onChanged: (val) {
                                ref.read(environmentListProvider.notifier).activateEnvironment(val);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () => _showAddDialog(context, ref),
                        child: const Text('Add Environment'),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              // Right: Editor details
              Expanded(
                flex: 7,
                child: const _EnvironmentDetailEditor(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Environment'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(environmentListProvider.notifier).addEnvironment(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// Local provider to track which env is being edited in the split view
final _editingEnvIdProvider = StateProvider<Id?>((ref) => null);

class _EnvironmentDetailEditor extends ConsumerStatefulWidget {
  const _EnvironmentDetailEditor();

  @override
  ConsumerState<_EnvironmentDetailEditor> createState() => _EnvironmentDetailEditorState();
}

class _EnvironmentDetailEditorState extends ConsumerState<_EnvironmentDetailEditor> {
  // We need to maintain local state of variables being edited
  late List<KeyValueItem> _vars;
  Id? _currentId;
  String _currentName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  // Reload when the selected editing ID changes
  void _load() {
    final id = ref.read(_editingEnvIdProvider);
    if (id == null) {
      _vars = [];
      return;
    }
    
    // Find the item from the list provider
    final list = ref.read(environmentListProvider).valueOrNull ?? [];
    final item = list.where((e) => e.id == id).firstOrNull;
    
    if (item != null && item.id != _currentId) {
      _currentId = item.id;
      _currentName = item.name;
      try {
        final Map<String, dynamic> json = jsonDecode(item.variablesJson);
        _vars = json.entries.map((e) => KeyValueItem(
          id: const Uuid().v4(),
          key: e.key,
          value: e.value.toString(),
          isEnabled: true,
        )).toList();
      } catch (_) {
        _vars = [];
      }
    }
    // Note: If we just built, setState isn't needed, but this is simplified sync
  }

  void _save() {
    if (_currentId == null) return;
    
    final Map<String, String> varMap = {};
    for (var item in _vars) {
      if (item.isEnabled && item.key.isNotEmpty) {
        varMap[item.key] = item.value;
      }
    }
    
    ref.read(environmentListProvider.notifier).updateEnvironment(_currentId!, _currentName, varMap);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
  }

  @override
  Widget build(BuildContext context) {
    final id = ref.watch(_editingEnvIdProvider);
    if (id == null) {
      return const Center(child: Text('Select an environment to edit'));
    }
    
    // We also need to watch list to react to name changes or if item deleted
    final list = ref.watch(environmentListProvider).valueOrNull ?? [];
    final item = list.where((e) => e.id == id).firstOrNull;
    
    if (item == null) {
      return const Center(child: Text('Environment not found'));
    }
    
    // If we switched IDs, reload local state
    if (_currentId != id) {
       _currentId = id;
       _currentName = item.name;
       try {
        final Map<String, dynamic> json = jsonDecode(item.variablesJson);
        _vars = json.entries.map((e) => KeyValueItem(
          id: const Uuid().v4(),
          key: e.key,
          value: e.value.toString(),
          isEnabled: true,
        )).toList();
      } catch (_) {
        _vars = [];
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: _currentName,
            decoration: const InputDecoration(labelText: 'Environment Name'),
            onChanged: (v) => _currentName = v, // Only save to local var until Save clicked
          ),
          const SizedBox(height: 16),
          const Text('Variables', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: KeyValueEditor(
                items: _vars,
                keyLabel: 'Variable Name',
                valueLabel: 'Value',
                onAdd: () {
                   setState(() {
                     _vars.add(KeyValueItem.initial());
                   });
                },
                onRemove: (idx) {
                   setState(() {
                     _vars.removeAt(idx);
                   });
                },
                onUpdate: (idx, update) {
                   setState(() {
                     _vars[idx] = update;
                   });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
