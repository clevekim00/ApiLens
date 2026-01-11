
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
  });

  @override
  State<AppKVRow> createState() => _AppKVRowState();
}

class _AppKVRowState extends State<AppKVRow> {
  late TextEditingController _keyController;
  late TextEditingController _valueController;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.keyText);
    _valueController = TextEditingController(text: widget.valueText);
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
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use AppTokens.s1 (4.0) or similar? 
    // Spec says "row height 36", "hover background = accent", "divider bottom = border"
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: _isHovering ? theme.colorScheme.secondary.withOpacity(0.5) : null, // using secondary as accent alias or explicit accent
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
                  // Custom shape for shadcn look?
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
            // Vertical Divider
            VerticalDivider(width: 1, color: theme.dividerColor),
            
            // Key Input (Flex 1)
            Expanded(
              flex: 1,
              child: AppInput(
                controller: _keyController,
                onChanged: widget.onKeyChanged,
                hintText: widget.keyHint,
                mono: true,
                // Remove borders for seamless table look? 
                // "key/value input(mono)" - usually in VSCode tables they are seamless until focused.
                // AppInput uses standard decoration which has borders.
                // To look like a table row, maybe we want borderless input?
                // But Prompt says "focus ring 느낌을 border로 표현".
                // Let's rely on AppInput's styling. Usually detailed table rows have inputs.
                // If it looks too cluttered with full borders in every cell, we might need a "ghost" input variant.
                // For now, let's just use AppInput. If it has full borders, it might look like a grid.
                // Wait, "AppKVRow... row height 36". AppInput height defaults to TextField height which might be > 36 strict if padding.
                // AppInput has isDense=true.
              ),
            ),
            
            // Vertical Divider
            VerticalDivider(width: 1, color: theme.dividerColor),

            // Value Input (Flex 2)
            Expanded(
              flex: 2,
              child: AppInput(
                controller: _valueController,
                onChanged: widget.onValueChanged,
                hintText: widget.valueHint,
                mono: true,
              ),
            ),
            
            // Delete Icon
            if (_isHovering || _keyController.text.isNotEmpty || _valueController.text.isNotEmpty)
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
