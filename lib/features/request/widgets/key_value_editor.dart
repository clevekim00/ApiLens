import 'package:flutter/material.dart';
import '../models/key_value_item.dart';

class KeyValueEditor extends StatelessWidget {
  final List<KeyValueItem> items;
  final Function(int index, KeyValueItem item) onUpdate;
  final Function(int index) onRemove;
  final VoidCallback onAdd;
  final String keyLabel;
  final String valueLabel;

  const KeyValueEditor({
    super.key,
    required this.items,
    required this.onUpdate,
    required this.onRemove,
    required this.onAdd,
    this.keyLabel = 'Key',
    this.valueLabel = 'Value',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // List of existing items
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            // Reorder logic (optional for MVP, but good to have API)
          },
          children: [
             for (int i = 0; i < items.length; i++)
               _KeyValueRow(
                 key: ValueKey(items[i].id),
                 item: items[i],
                 onUpdate: (item) => onUpdate(i, item),
                 onRemove: () => onRemove(i),
                 keyLabel: keyLabel,
                 valueLabel: valueLabel,
               ),
          ],
        ),
        
        // Add Button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Row'),
          ),
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final KeyValueItem item;
  final ValueChanged<KeyValueItem> onUpdate;
  final VoidCallback onRemove;
  final String keyLabel;
  final String valueLabel;

  const _KeyValueRow({
    super.key,
    required this.item,
    required this.onUpdate,
    required this.onRemove,
    required this.keyLabel,
    required this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Enable/Disable Checkbox
          Checkbox(
            value: item.isEnabled,
            onChanged: (val) {
              onUpdate(item.copyWith(isEnabled: val));
            },
          ),
          
          // Key Input
          Expanded(
            child: TextFormField(
              initialValue: item.key,
              decoration: InputDecoration(
                hintText: keyLabel,
                isDense: true,
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (val) {
                // Debounce could be added here, but for MVP direct update is fine
                onUpdate(item.copyWith(key: val)); 
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // Value Input
          Expanded(
            child: TextFormField(
              initialValue: item.value,
              decoration: InputDecoration(
                hintText: valueLabel,
                isDense: true,
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: (val) {
                onUpdate(item.copyWith(value: val));
              },
            ),
          ),
          
          // Remove Button
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onRemove,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}
