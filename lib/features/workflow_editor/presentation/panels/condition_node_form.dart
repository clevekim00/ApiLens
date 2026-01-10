import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/node_config.dart';
import '../../application/workflow_editor_controller.dart';

class ConditionNodeForm extends ConsumerStatefulWidget {
  final String nodeId;
  final String nodeName;
  final ConditionNodeConfig config;

  const ConditionNodeForm({
    super.key,
    required this.nodeId,
    required this.nodeName,
    required this.config,
  });

  @override
  ConsumerState<ConditionNodeForm> createState() => _ConditionNodeFormState();
}

class _ConditionNodeFormState extends ConsumerState<ConditionNodeForm> {
  late TextEditingController _expressionController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.nodeName);
    _expressionController = TextEditingController(text: widget.config.expression);
  }

  @override
  void dispose() {
    _expressionController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final newConfig = ConditionNodeConfig(
      expression: _expressionController.text,
    );

    final data = newConfig.toJson();
    data['name'] = _nameController.text;

    ref.read(workflowEditorProvider.notifier).updateNodeConfig(widget.nodeId, data);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Node Name', border: OutlineInputBorder()),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _expressionController,
          decoration: const InputDecoration(
            labelText: 'Expression', 
            hintText: '{{result}} == 200',
            border: OutlineInputBorder(),
            helperText: 'Supported: ==, !=, >, <, contains',
            helperMaxLines: 2,
          ),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Example:\n{{node.api_1.response.statusCode}} == 200\n{{node.api_1.response.body.success}} == true',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
