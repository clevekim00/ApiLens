import 'package:flutter/material.dart';
import '../models/workflow_graph_model.dart';
import '../models/http_request_model.dart';
import '../theme/app_theme.dart';

class DataMappingDialog extends StatefulWidget {
  final WorkflowEdge edge;
  final WorkflowNode fromNode;
  final WorkflowNode toNode;
  final HttpRequestModel? fromRequest;
  final HttpRequestModel? toRequest;

  const DataMappingDialog({
    super.key,
    required this.edge,
    required this.fromNode,
    required this.toNode,
    this.fromRequest,
    this.toRequest,
  });

  @override
  State<DataMappingDialog> createState() => _DataMappingDialogState();
}

class _DataMappingDialogState extends State<DataMappingDialog> {
  late Map<String, dynamic> _mappings;
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  String _targetType = 'header'; // 'header', 'body', 'query'

  @override
  void initState() {
    super.initState();
    _mappings = Map<String, dynamic>.from(widget.edge.dataMapping);
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: Row(
        children: [
          const Icon(Icons.compare_arrows, color: Color(0xFF06B6D4)),
          const SizedBox(width: 12),
          const Text('Data Mapping', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Map data from "${widget.fromNode.label}" to "${widget.toNode.label}"',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            const SizedBox(height: 20),
            
            // Add mapping form
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sourceController,
                    decoration: InputDecoration(
                      labelText: 'Source (JSONPath)',
                      hintText: r'e.g. $.data.token',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _targetController,
                    decoration: InputDecoration(
                      labelText: 'Target (Key)',
                      hintText: 'e.g. Authorization',
                      labelStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Target Type:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(width: 16),
                _buildTypeChip('header'),
                const SizedBox(width: 8),
                _buildTypeChip('query'),
                const SizedBox(width: 8),
                _buildTypeChip('body'),
                const Spacer(),
                ElevatedButton(
                  onPressed: _addMapping,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cyanTeal),
                  child: const Text('Add Mapping'),
                ),
              ],
            ),
            
            const Divider(height: 32, color: Colors.white10),
            
            // Current mappings list
            const Text('Active Mappings:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_mappings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No mappings defined', style: TextStyle(color: Colors.grey))),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _mappings.length,
                  itemBuilder: (context, index) {
                    final key = _mappings.keys.elementAt(index);
                    final value = _mappings[key];
                    return ListTile(
                      dense: true,
                      title: Text('$key → $value', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 16, color: AppTheme.errorRed),
                        onPressed: () => setState(() => _mappings.remove(key)),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _mappings),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cyanTeal),
          child: const Text('Save Mappings'),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type) {
    final isSelected = _targetType == type;
    return ChoiceChip(
      label: Text(type, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.grey)),
      selected: isSelected,
      onSelected: (val) => setState(() => _targetType = type),
      selectedColor: AppTheme.cyanTeal.withOpacity(0.5),
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
    );
  }

  void _addMapping() {
    if (_sourceController.text.isNotEmpty && _targetController.text.isNotEmpty) {
      setState(() {
        _mappings['${_targetType}:${_targetController.text}'] = _sourceController.text;
        _sourceController.clear();
        _targetController.clear();
      });
    }
  }
}
