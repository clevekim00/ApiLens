import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/request_provider.dart';
import '../../response/providers/response_provider.dart';
import '../../response/widgets/response_viewer.dart';
import 'package:apilens/features/request/widgets/url_bar.dart';
import '../widgets/key_value_editor.dart';
import '../widgets/body_editor.dart';
import '../widgets/auth_editor.dart';
import '../widgets/auto_header_list.dart';
import '../../../../core/network/request_header_builder.dart';
import '../../history/widgets/history_panel.dart';
import '../../environments/widgets/environment_selector.dart';
import '../../../../core/utils/curl_parser.dart';
import '../../../../core/utils/curl_exporter.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import '../../../../core/ui/components/app_card.dart';
import '../../../../core/ui/components/app_button.dart';
import '../../../../core/ui/components/app_tabs.dart';

import '../../workflow_editor/presentation/workflow_editor_screen.dart';

class RequestScreen extends ConsumerStatefulWidget {
  const RequestScreen({super.key});

  @override
  ConsumerState<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends ConsumerState<RequestScreen> {
  @override
  Widget build(BuildContext context) {
    final request = ref.watch(requestNotifierProvider);
    final responseState = ref.watch(responseNotifierProvider);
    final isLoading = responseState.isLoading;

    void onSend() {
      FocusManager.instance.primaryFocus?.unfocus();
      ref.read(responseNotifierProvider.notifier).sendRequest();
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): onSend,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): onSend,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          drawer: Drawer(
            width: 300,
            child: HistoryPanel(
              onClose: () {
                Navigator.of(context).pop();
              },
            ),
          ),
          appBar: AppBar(
            title: const Text('Request Builder'),
            centerTitle: false,
            elevation: 0,
            actions: [
               IconButton(
                icon: const Icon(Icons.account_tree_outlined),
                tooltip: 'Workflow Editor',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkflowEditorScreen()));
                },
              ),
              const EnvironmentSelector(),
              const SizedBox(width: 8),
               // Removed duplicate AppBar Send button
               PopupMenuButton<String>(
                 tooltip: 'Settings & More',
                 icon: const Icon(Icons.settings_outlined),
                 onSelected: (val) {
                   if (val == 'workflow') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkflowEditorScreen()));
                   }
                   if (val == 'import') _showImportDialog(context, ref);
                   if (val == 'export') _showExportDialog(context, ref);
                   if (val == 'settings') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                   }
                 },
                 itemBuilder: (context) => [
                   const PopupMenuItem(value: 'workflow', child: Text('Workflow Editor')), 
                   const PopupMenuItem(value: 'import', child: Text('Import cURL')),
                   const PopupMenuItem(value: 'export', child: Text('Copy as cURL')),
                   const PopupMenuItem(value: 'settings', child: Text('Settings')),
                 ],
               ),
               const SizedBox(width: 8),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Top Split: Request Builder ---
              Expanded(
                flex: 5, 
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 1. URL Bar Section (AppCard)
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const MethodSelector(),
                            const SizedBox(width: 8),
                            Expanded(child: UrlInput(onSubmitted: onSend)),
                            // Send button is in AppBar as per existing, but Prompt said: "Send 버튼(primary) (가능하면 우측)"
                            // Let's duplicate it here for the "Request Builder" feel?
                            // Or move it from AppBar to here?
                            // Prompt: "Method dropdown... URL input... Send 버튼(primary) (가능하면 우측)"
                            // I should add it here.
                            const SizedBox(width: 8),
                            AppButton(
                               label: 'Send',
                               icon: const Icon(Icons.send, size: 14),
                               onPressed: isLoading ? null : onSend,
                               variant: AppButtonVariant.primary,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 2. Tabs
                      Expanded(
                        child: AppTabs(
                          tabs: const ['Params', 'Headers', 'Body', 'Auth'],
                          children: [
                            // Params Tab
                            SingleChildScrollView(
                              padding: const EdgeInsets.only(top: 16),
                              child: KeyValueEditor(
                                items: request.params,
                                onUpdate: (idx, item) => ref.read(requestNotifierProvider.notifier).updateParam(idx, item),
                                onRemove: (idx) => ref.read(requestNotifierProvider.notifier).removeParam(idx),
                                onAdd: () => ref.read(requestNotifierProvider.notifier).addParam(),
                                keyLabel: 'Parameter',
                              ),
                            ),
                            
                            // Headers Tab
                            SingleChildScrollView(
                              padding: const EdgeInsets.only(top: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AutoHeaderList(
                                    autoHeaders: RequestHeaderBuilder.buildAutoHeaders(request),
                                  ),
                                  const SizedBox(height: 16),
                                  KeyValueEditor(
                                    items: request.headers,
                                    onUpdate: (idx, item) => ref.read(requestNotifierProvider.notifier).updateHeader(idx, item),
                                    onRemove: (idx) => ref.read(requestNotifierProvider.notifier).removeHeader(idx),
                                    onAdd: () => ref.read(requestNotifierProvider.notifier).addHeader(),
                                    keyLabel: 'Header',
                                  ),
                                ],
                              ),
                            ),
                            
                            // Body Tab
                            const BodyEditor(),
                            
                            // Auth Tab
                            const AuthEditor(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(thickness: 1, height: 1), 

              // --- Bottom Split: Response Viewer ---
              const Expanded(
                flex: 5,
                child: ResponseViewer(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import cURL'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Paste curl command here...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final model = CurlParser.parse(controller.text);
              if (model != null) {
                ref.read(requestNotifierProvider.notifier).restoreRequest(model);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imported!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid cURL')));
              }
            },
            child: const Text('Import'),
           ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    final request = ref.read(requestNotifierProvider);
    final curl = CurlExporter.export(request);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Copy as cURL'),
        content: SelectableText(curl, style: const TextStyle(fontFamily: 'Fira Code', fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: curl));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}
