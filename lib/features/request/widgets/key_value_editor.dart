import 'package:flutter/material.dart';
import '../models/key_value_item.dart';
import '../../../../core/ui/components/app_kv_row.dart';
import '../../../../core/ui/components/app_button.dart';

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
               AppKVRow(
                 key: ValueKey(items[i].id),
                 keyText: items[i].key,
                 valueText: items[i].value,
                 isEnabled: items[i].isEnabled,
                 onKeyChanged: (val) => onUpdate(i, items[i].copyWith(key: val)),
                 onValueChanged: (val) => onUpdate(i, items[i].copyWith(value: val)),
                 onEnabledChanged: (val) => onUpdate(i, items[i].copyWith(isEnabled: val)),
                 onDelete: () => onRemove(i),
                 keyHint: keyLabel,
                 valueHint: valueLabel,
               ),
          ],
        ),
        
        // Add Button
        Container(
          width: double.infinity,
          height: 36,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: AppButton(
            label: 'Add Item',
            icon: const Icon(Icons.add, size: 14),
            variant: AppButtonVariant.ghost,
            onPressed: onAdd,
            width: double.infinity,
          ),
        ),
      ],
    );
  }
}
