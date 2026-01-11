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

import '../../../../features/websocket/presentation/widgets/websocket_client_panel.dart';
import '../../../../features/graphql/presentation/screens/graphql_client_tab.dart';
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
        child: DefaultTabController(
          length: 3, // HTTP, WebSocket, GraphQL
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
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'HTTP / REST'),
                  Tab(text: 'WebSocket'),
                  Tab(text: 'GraphQL'),
                ],
              ),
              actions: [
                 IconButton(
                  icon: const Icon(Icons.account_tree_outlined),
                  tooltip: 'Workflow Editor',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkflowEditorScreen()));
                  },
                ),
                const EnvironmentSelector(),
                const SizedBox(width: 16),
                 // Send Button - Visible mainly for HTTP but kept shared for now
                 Padding(
                   padding: const EdgeInsets.only(right: 16.0),
                   child: FilledButton.icon(
                    onPressed: isLoading ? null : onSend,
                    icon: isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
                        : const Icon(Icons.send),
                    label: Text(isLoading ? 'Sending...' : 'HTTP Send'),
                   ),
                 ),
                 PopupMenuButton<String>(
                   onSelected: (val) {
                     if (val == 'workflow') Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkflowEditorScreen()));
                     if (val == 'import') _showImportDialog(context, ref);
                     if (val == 'export') _showExportDialog(context, ref);
                     if (val == 'settings') Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
            body: TabBarView(
              children: [
                // Tab 1: HTTP / REST
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Top Split: Request Builder ---
                    Expanded(
                      flex: 5, 
                      child: Column(
                        children: [
                          Card(
                            margin: const EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  const MethodSelector(),
                                  const SizedBox(width: 16),
                                  Expanded(child: UrlInput()),
                                ],
                              ),
                            ),
                          ),
                          
                          Expanded(
                            child: DefaultTabController(
                              length: 4,
                              child: Column(
                                children: [
                                  const TabBar(
                                    isScrollable: true,
                                    tabAlignment: TabAlignment.start,
                                    tabs: [
                                      Tab(text: 'Params'),
                                      Tab(text: 'Headers'),
                                      Tab(text: 'Body'),
                                      Tab(text: 'Auth'),
                                    ],
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      children: [
                                        // Params Tab
                                        SingleChildScrollView(
                                          padding: const EdgeInsets.all(16),
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
                                          padding: const EdgeInsets.all(0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                            children: [
                                              AutoHeaderList(
                                                autoHeaders: RequestHeaderBuilder.buildAutoHeaders(request),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(16.0),
                                                child: KeyValueEditor(
                                                  items: request.headers,
                                                  onUpdate: (idx, item) => ref.read(requestNotifierProvider.notifier).updateHeader(idx, item),
                                                  onRemove: (idx) => ref.read(requestNotifierProvider.notifier).removeHeader(idx),
                                                  onAdd: () => ref.read(requestNotifierProvider.notifier).addHeader(),
                                                  keyLabel: 'Header',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Body Tab
                                        BodyEditor(),
                                        // Auth Tab
                                        AuthEditor(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(thickness: 4, height: 4), 
                    // --- Bottom Split: Response Viewer ---
                    const Expanded(
                      flex: 5,
                      child: ResponseViewer(),
                    ),
                  ],
                ),

                // Tab 2: WebSocket
                const WebSocketClientPanel(),

                // Tab 3: GraphQL
                const GraphQLClientTab(),
              ],
            ),
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
      final controller = TextEditingController(text: curl);
      
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Export cURL'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            readOnly: true,
          ),
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
