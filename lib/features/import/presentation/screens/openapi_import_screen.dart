import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';

import '../../application/openapi_import_controller.dart';
import '../../domain/models/openapi_operation_model.dart';

class OpenApiImportScreen extends ConsumerStatefulWidget {
  final String targetGroupId;
  const OpenApiImportScreen({super.key, required this.targetGroupId});

  @override
  ConsumerState<OpenApiImportScreen> createState() => _OpenApiImportScreenState();
}

class _OpenApiImportScreenState extends ConsumerState<OpenApiImportScreen> {
  final _urlController = TextEditingController();

  Future<void> _handleFilePick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'yaml', 'yml'],
        withData: true,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;
        String content;
        if (file.bytes != null) {
           content = utf8.decode(file.bytes!);
        } else if (file.path != null) {
           content = await File(file.path!).readAsString();
        } else {
           return;
        }
        ref.read(openApiImportControllerProvider.notifier).loadContent(content);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File Error: $e')));
    }
  }

  Future<void> _handleUrlLoad() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    
    // Simple fetch for now, assuming public or reachable
    try {
       // Using Dio simply here, but ideally via a service
       final response = await Dio().get(url);
       final content = response.data is String ? response.data : jsonEncode(response.data);
       ref.read(openApiImportControllerProvider.notifier).loadContent(content, baseUrlOverride: url);
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('URL Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(openApiImportControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Import from OpenAPI')),
      body: Column(
        children: [
          // 1. Load Section (always visible or collapsible?)
          // If parseResult is null, show big centered load area.
          // If loaded, show compact bar or just the preview.
          if (state.parseResult == null)
            Expanded(
              child: Center(
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.download, size: 48, color: Colors.blue),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: 'OpenAPI Spec URL',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: _handleUrlLoad,
                          ),
                        ),
                        onSubmitted: (_) => _handleUrlLoad(),
                      ),
                      const SizedBox(height: 16),
                      const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("OR")), Expanded(child: Divider())]),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _handleFilePick,
                        icon: const Icon(Icons.file_open),
                        label: const Text('Upload JSON/YAML File'),
                        style: ElevatedButton.styleFrom(
                           minimumSize: const Size(double.infinity, 48)
                        ),
                      ),
                      if (state.isLoading) const Padding(
                         padding: EdgeInsets.only(top: 16),
                         child: CircularProgressIndicator(),
                      ),
                      if (state.error != null) Padding(
                         padding: const EdgeInsets.only(top: 16),
                         child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else 
            Expanded(
              child: Row(
                children: [
                   // Left: Tags
                   SizedBox(
                     width: 250,
                     child: _TagFilterList(
                       activeTags: state.activeTags,
                       allTags: _extractAllTags(state.parseResult!.operations),
                       onToggle: ref.read(openApiImportControllerProvider.notifier).toggleTag,
                     ),
                   ),
                   const VerticalDivider(width: 1),
                   // Center: Endpoints
                   Expanded(
                     flex: 3,
                     child: _EndpointListPanel(state: state),
                   ),
                   const VerticalDivider(width: 1),
                   // Right: Options
                   SizedBox(
                     width: 300,
                     child: _ImportOptionsPanel(
                       options: state.options,
                       onUpdate: ref.read(openApiImportControllerProvider.notifier).updateOptions,
                     ),
                   ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: state.parseResult != null ? _buildBottomBar(context, ref, state) : null,
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, OpenApiImportState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
           Text('${state.selectedOperationIds.length} operations selected'),
           const Spacer(),
           TextButton(
             onPressed: () => ref.read(openApiImportControllerProvider.notifier).loadContent(''), // Reset
             child: const Text('Cancel / Reset'),
           ),
           const SizedBox(width: 16),
           FilledButton(
             onPressed: state.selectedOperationIds.isEmpty || state.isLoading 
               ? null
               : () async {
                  final result = await ref.read(openApiImportControllerProvider.notifier).importSelected(widget.targetGroupId);
                  if (context.mounted) {
                     // Show summary dialog
                     showDialog(context: context, builder: (_) => AlertDialog(
                       title: const Text('Import Complete'),
                       content: Text('Success: ${result['success']}\nErrors: ${result['error']}'),
                       actions: [
                         TextButton(
                           onPressed: () { 
                             Navigator.pop(context); // Close dialog
                             Navigator.pop(context); // Close screen
                           }, 
                           child: const Text('Close'),
                         )
                       ],
                     ));
                  }
               },
             child: state.isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : const Text('Import'),
           ),
        ],
      ),
    );
  }

  Set<String> _extractAllTags(List<OpenApiOperation> ops) {
    final tags = <String>{};
    for (var op in ops) {
      if (op.tags.isEmpty) {
        tags.add('(Untagged)');
      } else {
        tags.addAll(op.tags);
      }
    }
    return tags;
  }
}

class _TagFilterList extends StatelessWidget {
  final Set<String> activeTags;
  final Set<String> allTags;
  final Function(String) onToggle;

  const _TagFilterList({required this.activeTags, required this.allTags, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final sortedTags = allTags.toList()..sort();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.all(8), child: Text("Tags", style: TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: ListView(
            children: [
              CheckboxListTile(
                title: const Text('All'),
                value: activeTags.isEmpty,
                onChanged: (_) => onToggle('ALL'),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              const Divider(height: 1,),
              ...sortedTags.map((tag) => CheckboxListTile(
                title: Text(tag),
                value: activeTags.contains(tag),
                onChanged: (_) => onToggle(tag),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _EndpointListPanel extends ConsumerWidget {
  final OpenApiImportState state;
  const _EndpointListPanel({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search path, method, summary...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) => ref.read(openApiImportControllerProvider.notifier).setSearchQuery(val),
          ),
        ),
        Row(
           children: [
             Padding(
               padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
               child: TextButton.icon(
                 onPressed: () => ref.read(openApiImportControllerProvider.notifier).toggleSelectAllFiltered(),
                 icon: const Icon(Icons.select_all, size: 16),
                 label: const Text('Select All Filtered'),
               ),
             ),
           ],
        ),
        Expanded(
          child: ListView.separated(
            itemCount: state.visibleOperations.length,
            separatorBuilder: (_,__) => const Divider(height: 1),
            itemBuilder: (context, index) {
               final op = state.visibleOperations[index];
               final isSelected = state.selectedOperationIds.contains(op.id);
               return ListTile(
                 leading: Checkbox(
                    value: isSelected,
                    onChanged: (_) => ref.read(openApiImportControllerProvider.notifier).toggleOperation(op.id),
                 ),
                 title: Row(
                   children: [
                     _MethodBadge(method: op.method),
                     const SizedBox(width: 8),
                     Expanded(child: Text(op.path, style: const TextStyle(fontWeight: FontWeight.w500))),
                   ],
                 ),
                 subtitle: Text(op.summary ?? op.operationId ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                 trailing: op.tags.isNotEmpty 
                    ? Chip(label: Text(op.tags.first, style: const TextStyle(fontSize: 10)), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact) 
                    : null,
                 onTap: () => ref.read(openApiImportControllerProvider.notifier).toggleOperation(op.id),
                 dense: true,
               );
            },
          ),
        ),
      ],
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final String method;
  const _MethodBadge({required this.method});
  
  @override
  Widget build(BuildContext context) {
    Color color;
    switch (method.toUpperCase()) {
      case 'GET': color = Colors.green; break;
      case 'POST': color = Colors.orange; break;
      case 'PUT': color = Colors.blue; break;
      case 'DELETE': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
      child: Text(method, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

class _ImportOptionsPanel extends StatelessWidget {
  final ImportOptions options;
  final Function(ImportOptions) onUpdate;
  
  const _ImportOptionsPanel({required this.options, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Options", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        
        const Text("Base URL", style: TextStyle(fontWeight: FontWeight.bold)),
        RadioListTile<BaseUrlBehavior>(
          title: const Text('Use {{env.baseUrl}}'),
          value: BaseUrlBehavior.env,
          groupValue: options.baseUrlBehavior,
          onChanged: (v) => onUpdate(options.copyWith(baseUrlBehavior: v)),
          dense: true,
        ),
        RadioListTile<BaseUrlBehavior>(
          title: const Text('Use Fixed URL from Spec'),
          value: BaseUrlBehavior.fixed,
          groupValue: options.baseUrlBehavior,
          onChanged: (v) => onUpdate(options.copyWith(baseUrlBehavior: v)),
          dense: true,
        ),
        const Divider(),
        
        const Text("Request Body", style: TextStyle(fontWeight: FontWeight.bold)),
        // BodySampleStrategy
        RadioListTile<BodySampleStrategy>(
          title: const Text('Prefer Examples'),
          value: BodySampleStrategy.example,
          groupValue: options.bodySampleStrategy,
          onChanged: (v) => onUpdate(options.copyWith(bodySampleStrategy: v)),
          dense: true,
        ),
        RadioListTile<BodySampleStrategy>(
          title: const Text('Schema Based'),
          value: BodySampleStrategy.schema,
          groupValue: options.bodySampleStrategy,
          onChanged: (v) => onUpdate(options.copyWith(bodySampleStrategy: v)),
          dense: true,
        ),
        RadioListTile<BodySampleStrategy>(
          title: const Text('Minimal {}'),
          value: BodySampleStrategy.minimal,
          groupValue: options.bodySampleStrategy,
          onChanged: (v) => onUpdate(options.copyWith(bodySampleStrategy: v)),
          dense: true,
        ),

        const Divider(),
        const Text("Authentication", style: TextStyle(fontWeight: FontWeight.bold)),
         RadioListTile<AuthBehavior>(
          title: const Text('Auto Detect'),
          value: AuthBehavior.detect,
          groupValue: options.authBehavior,
          onChanged: (v) => onUpdate(options.copyWith(authBehavior: v)),
          dense: true,
        ),
        RadioListTile<AuthBehavior>(
          title: const Text('Ignore'),
          value: AuthBehavior.ignore,
          groupValue: options.authBehavior,
          onChanged: (v) => onUpdate(options.copyWith(authBehavior: v)),
          dense: true,
        ),
      ],
    );
  }
}
