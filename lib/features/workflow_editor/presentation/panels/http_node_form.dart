import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/node_config.dart';
import '../../application/workflow_editor_controller.dart';
import '../../../request/widgets/key_value_editor.dart';
import '../../../request/models/key_value_item.dart';
import 'package:uuid/uuid.dart';

class HttpNodeForm extends ConsumerStatefulWidget {
  final String nodeId;
  final String nodeName;
  final HttpNodeConfig config;

  const HttpNodeForm({
    super.key,
    required this.nodeId,
    required this.nodeName,
    required this.config,
  });

  @override
  ConsumerState<HttpNodeForm> createState() => _HttpNodeFormState();
}

class _HttpNodeFormState extends ConsumerState<HttpNodeForm> {
  late TextEditingController _urlController;
  late TextEditingController _nameController;
  late TextEditingController _bodyController;
  String _method = 'GET';
  
  // Headers state
  List<KeyValueItem> _headers = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.nodeName);
    _urlController = TextEditingController(text: widget.config.url);
    _bodyController = TextEditingController(text: widget.config.body);
    _method = widget.config.method;
    
    // Map existing headers Map<String,String> to List<KeyValueItem>
    if (widget.config.headers != null) {
      _headers = widget.config.headers!.entries.map((e) => 
        KeyValueItem(id: const Uuid().v4(), key: e.key, value: e.value, isEnabled: true)
      ).toList();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _save() {
    // Convert headers back to Map
    final headerMap = <String, String>{};
    for (final item in _headers) {
      if (item.isEnabled && item.key.isNotEmpty) {
        headerMap[item.key] = item.value;
      }
    }

    final newConfig = HttpNodeConfig(
      url: _urlController.text,
      method: _method,
      headers: headerMap,
      body: _bodyController.text,
    );

    // Update Node Data
    // We mix 'name' (top level data) and config json
    final data = newConfig.toJson();
    data['name'] = _nameController.text;

    ref.read(workflowEditorProvider.notifier).updateNodeConfig(widget.nodeId, data);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Name
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Node Name', border: OutlineInputBorder()),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: 16),
        
        // Method & URL
        Row(
          children: [
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<String>(
                value: _method,
                items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].map((m) => 
                   DropdownMenuItem(value: m, child: Text(m))
                ).toList(),
                onChanged: (val) {
                   if (val != null) {
                     setState(() => _method = val);
                     _save();
                   }
                },
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL (supports {{template}})', border: OutlineInputBorder()),
                onChanged: (_) => _save(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Tabs for Headers / Body
        DefaultTabController(
          length: 2,
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const TabBar(
                 labelColor: Colors.blue,
                 tabs: [Tab(text: 'Headers'), Tab(text: 'Body')],
               ),
               SizedBox(
                 height: 300, // Fixed height for scrolling content
                 child: TabBarView(
                   children: [
                     // Headers Editor
                     SingleChildScrollView(
                       child: KeyValueEditor(
                         items: _headers,
                         onAdd: () {
                           setState(() {
                             _headers.add(KeyValueItem(id: const Uuid().v4(), key: '', value: '', isEnabled: true));
                           });
                           _save(); // Save immediately? Or wait? 
                           // For seamless UX, maybe save on edit.
                         },
                         onRemove: (index) {
                           setState(() => _headers.removeAt(index));
                           _save();
                         },
                         onUpdate: (index, item) {
                           setState(() => _headers[index] = item);
                           _save();
                         },
                       ),
                     ),
                     
                     // Body Editor
                     Padding(
                       padding: const EdgeInsets.all(8.0),
                       child: TextFormField(
                         controller: _bodyController,
                         maxLines: 10,
                         decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'JSON Body (supports {{template}})'
                         ),
                         onChanged: (_) => _save(),
                       ),
                     ),
                   ],
                 ),
               )
             ],
          ),
        ),
      ],
    );
  }
}
