import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';

import '../../application/openapi_import_controller.dart';
import '../../domain/models/openapi_operation_model.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import '../../../../core/ui/components/app_card.dart';

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
    
    await ref.read(openApiImportControllerProvider.notifier).loadFromUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(openApiImportControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('OpenAPI Specification Import'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Design Element
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                if (state.parseResult == null)
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: AppCard(
                          width: 500,
                          padding: const EdgeInsets.all(32),
                          backgroundColor: Theme.of(context).cardColor.withOpacity(0.8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.auto_awesome_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(height: 24),
                              Text("Start Your Integration", style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text("Paste a Swagger URL or upload a spec file to begin", 
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColorsLight.mutedForeground)),
                              const SizedBox(height: 32),
                              TextField(
                                controller: _urlController,
                                decoration: InputDecoration(
                                  labelText: 'Swagger UI or JSON/YAML URL',
                                  hintText: 'http://localhost:8080/swagger-ui/index.html',
                                  prefixIcon: const Icon(Icons.link),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.arrow_forward_rounded),
                                    onPressed: _handleUrlLoad,
                                  ),
                                ),
                                onSubmitted: (_) => _handleUrlLoad(),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text("OR", style: Theme.of(context).textTheme.labelSmall),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                onPressed: _handleFilePick,
                                icon: const Icon(Icons.upload_file_rounded),
                                label: const Text('Choose Spec File'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
                                ),
                              ),
                              if (state.isLoading) const Padding(
                                 padding: EdgeInsets.only(top: 24),
                                 child: CircularProgressIndicator(),
                              ),
                              if (state.error != null) Padding(
                                 padding: const EdgeInsets.only(top: 24),
                                 child: Container(
                                   padding: const EdgeInsets.all(12),
                                   decoration: BoxDecoration(
                                     color: Colors.red.withOpacity(0.1),
                                     borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                                   ),
                                   child: Row(
                                     children: [
                                       const Icon(Icons.error_outline, color: Colors.red, size: 20),
                                       const SizedBox(width: 8),
                                       Expanded(child: Text(state.error!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                                     ],
                                   ),
                                 ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else 
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                         // Left: Tags (Modernized)
                         Container(
                           width: 280,
                           decoration: BoxDecoration(
                             border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                           ),
                           child: _TagFilterList(
                             activeTags: state.activeTags,
                             allTags: _extractAllTags(state.parseResult!.operations),
                             onToggle: ref.read(openApiImportControllerProvider.notifier).toggleTag,
                           ),
                         ),
                         
                         // Center: Endpoints
                         Expanded(
                           child: _EndpointListPanel(state: state),
                         ),
                         
                         // Right: Options
                         Container(
                           width: 320,
                           decoration: BoxDecoration(
                             border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
                           ),
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
          ),
        ],
      ),
      bottomNavigationBar: state.parseResult != null ? _buildBottomBar(context, ref, state) : null,
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, OpenApiImportState state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        child: Row(
          children: [
             Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text('${state.selectedOperationIds.length} operations selected', 
                   style: theme.textTheme.titleMedium),
                 Text('Targeting folder: ${widget.targetGroupId}', 
                   style: theme.textTheme.labelSmall?.copyWith(color: AppColorsLight.mutedForeground)),
               ],
             ),
             const Spacer(),
             TextButton(
               onPressed: () => ref.read(openApiImportControllerProvider.notifier).loadContent(''), // Reset
               child: const Text('Reset Spec'),
             ),
             const SizedBox(width: 16),
             FilledButton.tonalIcon(
               onPressed: state.selectedOperationIds.isEmpty || state.isLoading 
                 ? null
                 : () async {
                    final name = 'Workflow ${DateTime.now().toLocal().toString().split('.')[0]}';
                    final workflowId = await ref.read(openApiImportControllerProvider.notifier).generateWorkflowFromSelected(name, widget.targetGroupId);
                    if (context.mounted) {
                       if (workflowId != null) {
                         showDialog(context: context, builder: (_) => AlertDialog(
                           title: const Text('Workflow Generated'),
                           content: const Text('Successfully generated workflow from selected endpoints.'),
                           actions: [
                             TextButton(
                               onPressed: () { 
                                 Navigator.pop(context); // Close dialog
                                 Navigator.pop(context); // Close screen
                               }, 
                               child: const Text('Done'),
                             )
                           ],
                         ));
                       } else {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate workflow.')));
                       }
                    }
                 },
               icon: const Icon(Icons.account_tree_outlined, size: 18),
               label: const Text('Create Workflow'),
             ),
             const SizedBox(width: 12),
             FilledButton.icon(
               onPressed: state.selectedOperationIds.isEmpty || state.isLoading 
                 ? null
                 : () async {
                    final result = await ref.read(openApiImportControllerProvider.notifier).importSelected(widget.targetGroupId);
                    if (context.mounted) {
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
               icon: const Icon(Icons.download_rounded, size: 18),
               label: const Text('Import Requests'),
             ),
          ],
        ),
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
        Padding(
          padding: EdgeInsets.all(AppTokens.s4), 
          child: Text("Filter by Tags", style: Theme.of(context).textTheme.titleSmall)
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
            children: [
              CheckboxListTile(
                title: const Text('All Endpoints'),
                value: activeTags.isEmpty,
                onChanged: (_) => onToggle('ALL'),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1),
              ),
              ...sortedTags.map((tag) => CheckboxListTile(
                title: Text(tag, style: const TextStyle(fontSize: 13)),
                value: activeTags.contains(tag),
                onChanged: (_) => onToggle(tag),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
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
          padding: EdgeInsets.all(AppTokens.s4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search path, method, summary...',
              hintStyle: const TextStyle(fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMd)),
              filled: true,
              fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            onChanged: (val) => ref.read(openApiImportControllerProvider.notifier).setSearchQuery(val),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
          child: Row(
             children: [
               TextButton.icon(
                 onPressed: () => ref.read(openApiImportControllerProvider.notifier).toggleSelectAllFiltered(),
                 icon: const Icon(Icons.checklist_rounded, size: 18),
                 label: const Text('Select/Deselect All'),
                 style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
               ),
               const Spacer(),
               Text('${state.visibleOperations.length} shown', style: Theme.of(context).textTheme.labelSmall),
             ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.visibleOperations.length,
            separatorBuilder: (_,__) => const Divider(height: 1, indent: 54),
            itemBuilder: (context, index) {
               final op = state.visibleOperations[index];
               final isSelected = state.selectedOperationIds.contains(op.id);
               return ListTile(
                 leading: Checkbox(
                    value: isSelected,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (_) => ref.read(openApiImportControllerProvider.notifier).toggleOperation(op.id),
                 ),
                 title: Row(
                   children: [
                     _MethodBadge(method: op.method),
                     const SizedBox(width: AppTokens.s3),
                     Expanded(child: Text(op.path, 
                       style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                   ],
                 ),
                 subtitle: Padding(
                   padding: const EdgeInsets.only(top: 4),
                   child: Text(op.summary ?? op.operationId ?? '', 
                     maxLines: 1, 
                     overflow: TextOverflow.ellipsis,
                     style: TextStyle(color: AppColorsLight.mutedForeground, fontSize: 12)),
                 ),
                 onTap: () => ref.read(openApiImportControllerProvider.notifier).toggleOperation(op.id),
                 dense: true,
                 hoverColor: Theme.of(context).hoverColor,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), 
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(method.toUpperCase(), 
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
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
      padding: EdgeInsets.all(AppTokens.s5),
      children: [
        Row(
          children: [
            Icon(Icons.settings_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text("Import Options", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 24),
        
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
