import 'package:flutter/material.dart';

import '../../../../core/ui/components/app_button.dart';
import '../../../../core/ui/components/app_kv_row.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
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
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TableHeader(keyLabel: keyLabel, valueLabel: valueLabel),
            if (items.isEmpty)
              _EmptyRows(keyLabel: keyLabel)
            else
              for (int i = 0; i < items.length; i++)
                AppKVRow(
                  key: ValueKey(items[i].id),
                  keyText: items[i].key,
                  valueText: items[i].value,
                  isEnabled: items[i].isEnabled,
                  onKeyChanged: (val) =>
                      onUpdate(i, items[i].copyWith(key: val)),
                  onValueChanged: (val) =>
                      onUpdate(i, items[i].copyWith(value: val)),
                  onEnabledChanged: (val) =>
                      onUpdate(i, items[i].copyWith(isEnabled: val)),
                  onDelete: () => onRemove(i),
                  keyHint: keyLabel,
                  valueHint: valueLabel,
                ),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: AppButton(
                label: 'Add ${keyLabel == 'Key' ? 'Item' : keyLabel}',
                icon: const Icon(Icons.add, size: 14),
                variant: AppButtonVariant.ghost,
                onPressed: onAdd,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String keyLabel;
  final String valueLabel;

  const _TableHeader({
    required this.keyLabel,
    required this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
      fontWeight: FontWeight.w800,
      letterSpacing: 0.3,
    );

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.035),
          theme.colorScheme.surface,
        ),
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32),
          VerticalDivider(width: 1, color: theme.dividerColor),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
              child: Text(keyLabel.toUpperCase(), style: labelStyle),
            ),
          ),
          VerticalDivider(width: 1, color: theme.dividerColor),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
              child: Text(valueLabel.toUpperCase(), style: labelStyle),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _EmptyRows extends StatelessWidget {
  final String keyLabel;

  const _EmptyRows({required this.keyLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 84,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Text(
        'No ${keyLabel.toLowerCase()} rows yet.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.58),
        ),
      ),
    );
  }
}
