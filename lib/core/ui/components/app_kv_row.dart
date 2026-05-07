import 'package:flutter/material.dart';
import '../tokens/app_tokens.dart';
import 'app_input.dart';
import 'app_button.dart';

class AppKVRow extends StatefulWidget {
  final String keyText;
  final String valueText;
  final bool isEnabled;
  final ValueChanged<String> onKeyChanged;
  final ValueChanged<String> onValueChanged;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onDelete;
  final String keyHint;
  final String valueHint;
  final String descriptionText;
  final ValueChanged<String>? onDescriptionChanged;
  final String descriptionHint;

  const AppKVRow({
    super.key,
    required this.keyText,
    required this.valueText,
    required this.isEnabled,
    required this.onKeyChanged,
    required this.onValueChanged,
    required this.onEnabledChanged,
    required this.onDelete,
    this.keyHint = 'Key',
    this.valueHint = 'Value',
    this.descriptionText = '',
    this.onDescriptionChanged,
    this.descriptionHint = 'Description',
  });

  @override
  State<AppKVRow> createState() => _AppKVRowState();
}

class _AppKVRowState extends State<AppKVRow> {
  late TextEditingController _keyController;
  late TextEditingController _valueController;
  late TextEditingController _descriptionController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.keyText);
    _valueController = TextEditingController(text: widget.valueText);
    _descriptionController =
        TextEditingController(text: widget.descriptionText);
  }

  @override
  void didUpdateWidget(AppKVRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.keyText != _keyController.text) {
      _keyController.text = widget.keyText;
    }
    if (widget.valueText != _valueController.text) {
      _valueController.text = widget.valueText;
    }
    if (widget.descriptionText != _descriptionController.text) {
      _descriptionController.text = widget.descriptionText;
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 32,
        decoration: BoxDecoration(
          color: _isHovering
              ? theme.colorScheme.primary.withValues(alpha: 0.055)
              : Colors.transparent,
          border: Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 32,
              child: Center(
                child: Checkbox(
                  value: widget.isEnabled,
                  onChanged: (v) => widget.onEnabledChanged(v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                ),
              ),
            ),
            VerticalDivider(width: 1, color: theme.dividerColor),
            Expanded(
              flex: 1,
              child: AppInput(
                controller: _keyController,
                onChanged: widget.onKeyChanged,
                hintText: widget.keyHint,
                mono: true,
                borderless: true,
              ),
            ),
            VerticalDivider(width: 1, color: theme.dividerColor),
            Expanded(
              flex: 2,
              child: AppInput(
                controller: _valueController,
                onChanged: widget.onValueChanged,
                hintText: widget.valueHint,
                mono: true,
                borderless: true,
              ),
            ),
            VerticalDivider(width: 1, color: theme.dividerColor),
            Expanded(
              flex: 2,
              child: AppInput(
                controller: _descriptionController,
                onChanged: widget.onDescriptionChanged ?? (_) {},
                hintText: widget.descriptionHint,
                mono: true,
                borderless: true,
              ),
            ),
            if (_isHovering ||
                _keyController.text.isNotEmpty ||
                _valueController.text.isNotEmpty ||
                _descriptionController.text.isNotEmpty)
              SizedBox(
                width: 36,
                child: AppButton(
                  label: '',
                  icon: const Icon(Icons.close, size: 14),
                  variant: AppButtonVariant.ghost,
                  onPressed: widget.onDelete,
                  width: 36,
                  padding: EdgeInsets.zero,
                ),
              )
            else
              const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }
}
