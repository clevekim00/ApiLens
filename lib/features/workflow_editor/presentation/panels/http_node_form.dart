import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/node_config.dart';
import '../../application/workflow_editor_controller.dart';
import '../../../request/widgets/key_value_editor.dart';
import '../../../request/models/key_value_item.dart';
import '../../../request/models/request_model.dart'; // NEW
import '../../../request/widgets/auto_header_list.dart'; // NEW
import '../../../../core/network/request_header_builder.dart'; // NEW
import '../../../../core/ui/tokens/app_tokens.dart';
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
    final theme = Theme.of(context);
    final inputDecoration = InputDecoration(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s3, vertical: AppTokens.s2),
      isDense: true,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Name
        Text(
          'Node Name',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _nameController,
          decoration: inputDecoration.copyWith(hintText: 'e.g., Fetch Users'),
          style: const TextStyle(fontSize: 13),
          onChanged: (_) => _save(),
        ),
        const SizedBox(height: AppTokens.s3),

        // Method & URL
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 86,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Method',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _method,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, size: 16),
                    items: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH']
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _method = val);
                        _save();
                      }
                    },
                    decoration: inputDecoration,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'URL',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _urlController,
                    decoration: inputDecoration.copyWith(
                      hintText: 'https://api.example.com',
                    ),
                    style: AppTokens.monoStyle.copyWith(fontSize: 12),
                    onChanged: (_) => _save(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s4),

        // Tabs for Headers / Body
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      theme.colorScheme.primary.withValues(alpha: 0.025),
                      theme.colorScheme.surface,
                    ),
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: const [
                      Tab(text: 'Headers'),
                      Tab(text: 'Body'),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.s2),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Headers Editor
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Builder(builder: (context) {
                              final bodyText = _bodyController.text.trim();
                              final bodyType = bodyText.startsWith('{')
                                  ? RequestBodyType.json
                                  : RequestBodyType.text;

                              final tempRequest = RequestModel(
                                id: 'temp',
                                method: _method,
                                url: _urlController.text,
                                bodyType: bodyType,
                              );
                              return AutoHeaderList(
                                autoHeaders: RequestHeaderBuilder.buildAutoHeaders(
                                    tempRequest),
                              );
                            }),
                            KeyValueEditor(
                              items: _headers,
                              keyLabel: 'Header',
                              onAdd: () {
                                setState(() {
                                  _headers.add(KeyValueItem(
                                      id: const Uuid().v4(),
                                      key: '',
                                      value: '',
                                      isEnabled: true));
                                });
                                _save();
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
                          ],
                        ),
                      ),

                      // Body Editor
                      TextFormField(
                        controller: _bodyController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: AppTokens.monoStyle.copyWith(fontSize: 12),
                        decoration: inputDecoration.copyWith(
                          hintText: '{"key": "value"}',
                        ),
                        onChanged: (_) => _save(),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
