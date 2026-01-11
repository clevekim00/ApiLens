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
        Column(
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
        Container(
          width: double.infinity,
          height: 32,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: InkWell(
            onTap: onAdd,
            child: Row(
              children: [
                const SizedBox(width: 8),
                const Icon(Icons.add, size: 14),
                const SizedBox(width: 4),
                Text('Add Item', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
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
    final borderColor = Theme.of(context).dividerColor;
    
    return Container(
      height: 32,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Enable/Disable Checkbox
          SizedBox(
            width: 32,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: Checkbox(
                  value: item.isEnabled,
                  onChanged: (val) {
                    onUpdate(item.copyWith(isEnabled: val));
                  },
                  activeColor: Theme.of(context).primaryColor,
                  checkColor: Colors.white,
                  side: BorderSide(color: Theme.of(context).disabledColor, width: 1),
                ),
              ),
            ),
          ),
         
          // Vertical Divider
          VerticalDivider(width: 1, thickness: 1, color: borderColor),
          
          // Key Input
          Expanded(
            flex: 1,
            child: TextFormField(
              initialValue: item.key,
              style: const TextStyle(fontFamily: 'Fira Code', fontSize: 13),
              decoration: InputDecoration(
                hintText: keyLabel,
                hintStyle: TextStyle(fontFamily: 'Fira Code', fontSize: 13, color: Theme.of(context).hintColor.withOpacity(0.5)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onChanged: (val) {
                onUpdate(item.copyWith(key: val)); 
              },
            ),
          ),
          
          // Vertical Divider
          VerticalDivider(width: 1, thickness: 1, color: borderColor),

          // Value Input
          Expanded(
            flex: 2, // More space for value
            child: TextFormField(
              initialValue: item.value,
              style: const TextStyle(fontFamily: 'Fira Code', fontSize: 13),
              decoration: InputDecoration(
                hintText: valueLabel,
                hintStyle: TextStyle(fontFamily: 'Fira Code', fontSize: 13, color: Theme.of(context).hintColor.withOpacity(0.5)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
              onChanged: (val) {
                onUpdate(item.copyWith(value: val));
              },
            ),
          ),
          
          // Remove Button
          SizedBox(
            width: 32,
            child: IconButton(
              icon: const Icon(Icons.close, size: 14),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              splashRadius: 16,
              tooltip: 'Remove',
            ),
          ),
        ],
      ),
    );
  }
}
