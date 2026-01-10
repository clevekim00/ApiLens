import 'package:flutter/material.dart';
import '../models/workflow_graph_model.dart';
import '../theme/app_theme.dart';

class LogicNodeDialog extends StatefulWidget {
  final WorkflowNode node;

  const LogicNodeDialog({super.key, required this.node});

  @override
  State<LogicNodeDialog> createState() => _LogicNodeDialogState();
}

class _LogicNodeDialogState extends State<LogicNodeDialog> {
  late TextEditingController _conditionController;
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _conditionController = TextEditingController(text: widget.node.config['condition'] ?? '');
    _labelController = TextEditingController(text: widget.node.label);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure ${widget.node.type.toUpperCase()} Node',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: 'Node Label',
                labelStyle: TextStyle(color: Colors.grey[400]),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            if (widget.node.type == 'if') ...[
              TextField(
                controller: _conditionController,
                decoration: InputDecoration(
                  labelText: 'Condition',
                  hintText: 'e.g. response.status == 200',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 12),
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Available variables: response.status, response.body.field, etc.',
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final newConfig = Map<String, dynamic>.from(widget.node.config);
                    newConfig['condition'] = _conditionController.text;
                    
                    Navigator.pop(context, {
                      'label': _labelController.text,
                      'config': newConfig,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cyanTeal,
                  ),
                  child: const Text('Save Configuration'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
