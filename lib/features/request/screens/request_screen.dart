import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../providers/request_provider.dart';
import '../../response/providers/response_provider.dart';
import '../../response/widgets/response_viewer.dart';
import 'package:apilens/features/request/widgets/url_bar.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import '../models/request_model.dart';
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
import '../application/saved_request_controller.dart';
import '../../../../core/widgets/info_button.dart';

import '../../../../features/websocket/presentation/widgets/websocket_client_panel.dart';
import '../../../../features/graphql/presentation/screens/graphql_client_tab.dart';
import '../../workflow_editor/presentation/workflow_editor_screen.dart';
import '../../workgroup/presentation/widgets/workgroup_selector.dart';
import '../../workgroup/presentation/widgets/workgroup_explorer.dart';

class RequestScreen extends ConsumerStatefulWidget {
  final bool isStandalone;

  const RequestScreen({super.key, this.isStandalone = true});

  @override
  ConsumerState<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends ConsumerState<RequestScreen> {
  static const double _sidebarWidth = 320;
  static const double _persistentSidebarBreakpoint = 900;
  static const double _responseAsideBreakpoint = 940;
  static const double _compactToolbarBreakpoint = 620;
  static const double _compactEditorHeaderBreakpoint = 720;

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(requestNotifierProvider);
    final responseState = ref.watch(responseNotifierProvider);
    final isLoading = responseState.isLoading;

    void onSend() {
      FocusManager.instance.primaryFocus?.unfocus();
      ref.read(responseNotifierProvider.notifier).sendRequest();
    }

    Widget body = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): onSend,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): onSend,
      },
      child: Focus(
        autofocus: true,
        child: _buildHttpWorkspace(
          context: context,
          request: request,
          isLoading: isLoading,
          onSend: onSend,
        ),
      ),
    );

    if (!widget.isStandalone) {
      return KeyedSubtree(
        key: const Key('screen_request_builder'),
        child: body,
      );
    }

    return DefaultTabController(
      length: 3, // HTTP, WebSocket, GraphQL
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showPersistentSidebar =
              constraints.maxWidth >= _persistentSidebarBreakpoint;

          return Scaffold(
            key: const Key('screen_request_builder'),
            drawer: showPersistentSidebar
                ? null
                : Drawer(
                    width: _sidebarWidth,
                    child: _RequestSidebarDrawer(
                      onClose: () => Navigator.of(context).pop(),
                    ),
                  ),
            appBar: AppBar(
              leading: showPersistentSidebar
                  ? null
                  : Builder(
                      builder: (context) {
                        return IconButton(
                          key: const Key('btn_open_sidebar'),
                          icon: const Icon(Icons.view_sidebar_outlined),
                          tooltip: 'Open Workspace Sidebar',
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        );
                      },
                    ),
              title: const Text('ApiLens'),
              centerTitle: false,
              elevation: 0,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'HTTP / REST'),
                  Tab(key: Key('tab_websocket'), text: 'WebSocket'),
                  Tab(text: 'GraphQL'),
                ],
              ),
              actions: [
                IconButton(
                  key: const Key('menu_workflow'),
                  icon: const Icon(Icons.account_tree_outlined),
                  tooltip: 'Workflow Editor',
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WorkflowEditorScreen()));
                  },
                ),
                PopupMenuButton<String>(
                  key: const Key('btn_more_actions'),
                  onSelected: (val) {
                    if (val == 'workflow') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WorkflowEditorScreen(),
                        ),
                      );
                    }
                    if (val == 'import') {
                      _showImportDialog(context, ref);
                    }
                    if (val == 'export') {
                      _showExportDialog(context, ref);
                    }
                    if (val == 'settings') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                        value: 'workflow', child: Text('Workflow Editor')),
                    const PopupMenuItem(
                        value: 'import', child: Text('Import cURL')),
                    const PopupMenuItem(
                        value: 'export', child: Text('Copy as cURL')),
                    const PopupMenuItem(
                        value: 'settings',
                        key: Key('menu_settings'),
                        child: Text('Settings')),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: _buildScreenBody(
              context: context,
              request: request,
              isLoading: isLoading,
              onSend: onSend,
              showPersistentSidebar: showPersistentSidebar,
            ),
          );
        },
      ),
    );
  }

  Widget _buildScreenBody({
    required BuildContext context,
    required RequestModel request,
    required bool isLoading,
    required VoidCallback onSend,
    required bool showPersistentSidebar,
  }) {
    final tabContent = TabBarView(
      children: [
        _buildHttpWorkspace(
          context: context,
          request: request,
          isLoading: isLoading,
          onSend: onSend,
        ),
        const WebSocketClientPanel(key: Key('screen_websocket_client')),
        const GraphQLClientTab(key: Key('screen_graphql_client')),
      ],
    );

    if (!showPersistentSidebar) {
      return tabContent;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(
          width: _sidebarWidth,
          child: HistoryPanel(showCloseButton: false),
        ),
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        Expanded(child: tabContent),
      ],
    );
  }

  Widget _buildHttpWorkspace({
    required BuildContext context,
    required RequestModel request,
    required bool isLoading,
    required VoidCallback onSend,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSideBySide = constraints.maxWidth >= _responseAsideBreakpoint;
        final requestPane = _buildRequestPane(
          context: context,
          request: request,
          isLoading: isLoading,
          onSend: onSend,
        );
        final responsePane = _buildResponsePane(context);

        if (useSideBySide) {
          return ColoredBox(
            color: _workspaceBackground(context),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: requestPane),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(flex: 5, child: responsePane),
              ],
            ),
          );
        }

        return ColoredBox(
          color: _workspaceBackground(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: requestPane),
              Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(flex: 4, child: responsePane),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestPane({
    required BuildContext context,
    required RequestModel request,
    required bool isLoading,
    required VoidCallback onSend,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRequestToolbar(context, isLoading: isLoading, onSend: onSend),
          const SizedBox(height: AppTokens.s3),
          Expanded(child: _buildEditorTabs(request)),
        ],
      ),
    );
  }

  Widget _buildRequestToolbar(
    BuildContext context, {
    required bool isLoading,
    required VoidCallback onSend,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < _compactToolbarBreakpoint;

          final sendButton = FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s4, vertical: AppTokens.s3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
              ),
            ),
            onPressed: isLoading ? null : onSend,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  )
                : const Icon(Icons.send, size: 16),
            label: Text(isLoading ? 'Sending...' : 'Send'),
          );

          final requestActions = PopupMenuButton<String>(
            tooltip: 'Request actions',
            icon: const Icon(Icons.more_horiz),
            onSelected: (val) {
              if (val == 'save') {
                final currentRequest = ref.read(requestNotifierProvider);
                ref
                    .read(savedRequestControllerProvider.notifier)
                    .saveRequest(currentRequest);
              }
              if (val == 'import') {
                _showImportDialog(context, ref);
              }
              if (val == 'export') {
                _showExportDialog(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'save', child: Text('Save Request')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'import', child: Text('Import cURL')),
              PopupMenuItem(value: 'export', child: Text('Copy as cURL')),
            ],
          );

          Widget buildLabeled(String label, Widget child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                child,
              ],
            );
          }

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    buildLabeled('Environment', const EnvironmentSelector()),
                    const SizedBox(width: AppTokens.s2),
                    buildLabeled('Method',
                        const MethodSelector(key: Key('selector_method'))),
                  ],
                ),
                const SizedBox(height: AppTokens.s2),
                const Row(
                  children: [
                    Expanded(child: UrlInput(key: Key('input_url_bar'))),
                  ],
                ),
                const SizedBox(height: AppTokens.s2),
                Row(
                  children: [
                    const Spacer(),
                    Expanded(child: sendButton),
                    const SizedBox(width: AppTokens.s1),
                    requestActions,
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              buildLabeled('Environment', const EnvironmentSelector()),
              const SizedBox(width: AppTokens.s3),
              buildLabeled(
                  'Method', const MethodSelector(key: Key('selector_method'))),
              const SizedBox(width: AppTokens.s3),
              const Expanded(child: UrlInput(key: Key('input_url_bar'))),
              const SizedBox(width: AppTokens.s3),
              sendButton,
              const SizedBox(width: AppTokens.s1),
              requestActions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildEditorTabs(RequestModel request) {
    return DefaultTabController(
      length: 5,
      child: DecoratedBox(
        decoration: _panelDecoration(context),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useStackedHeader =
                constraints.maxWidth < _compactEditorHeaderBreakpoint;

            return Column(
              children: [
                _buildEditorHeader(useStackedHeader: useStackedHeader),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTokens.s4),
                        child: KeyValueEditor(
                          items: request.params,
                          onUpdate: (idx, item) => ref
                              .read(requestNotifierProvider.notifier)
                              .updateParam(idx, item),
                          onRemove: (idx) => ref
                              .read(requestNotifierProvider.notifier)
                              .removeParam(idx),
                          onAdd: () => ref
                              .read(requestNotifierProvider.notifier)
                              .addParam(),
                          keyLabel: 'Parameter',
                        ),
                      ),
                      const AuthEditor(),
                      SingleChildScrollView(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AutoHeaderList(
                              autoHeaders:
                                  RequestHeaderBuilder.buildAutoHeaders(
                                      request),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(AppTokens.s4),
                              child: KeyValueEditor(
                                items: request.headers,
                                onUpdate: (idx, item) => ref
                                    .read(requestNotifierProvider.notifier)
                                    .updateHeader(idx, item),
                                onRemove: (idx) => ref
                                    .read(requestNotifierProvider.notifier)
                                    .removeHeader(idx),
                                onAdd: () => ref
                                    .read(requestNotifierProvider.notifier)
                                    .addHeader(),
                                keyLabel: 'Header',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const BodyEditor(),
                      const Center(
                          child: Text('Scripts (Pre-request / Tests)')),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditorHeader({required bool useStackedHeader}) {
    final l10n = AppLocalizations.of(context);
    final tabBar = TabBar(
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      tabs: [
        Tab(text: l10n.translate('params')),
        Tab(text: l10n.translate('auth')),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.translate('headers')),
              const SizedBox(width: 4),
              const InfoButton(
                title: 'Headers',
                message:
                    'HTTP headers allow the client and the server to pass additional information with an HTTP request or response.\n\nCommon headers:\n- Content-Type: application/json\n- Authorization: Bearer <token>',
              ),
            ],
          ),
        ),
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.translate('body')),
              const SizedBox(width: 4),
              const InfoButton(
                title: 'Request Body',
                message:
                    'The request body is used to send data to the server (e.g., in POST/PUT requests).\n\nSupported types:\n- JSON\n- Form Data\n- Raw Text\n- Binary',
              ),
            ],
          ),
        ),
        Tab(text: l10n.translate('scripts')),
      ],
    );

    const contextControls = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          WorkgroupSelector(),
        ],
      ),
    );

    if (useStackedHeader) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s3),
            child: tabBar,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppTokens.s3,
              0,
              AppTokens.s3,
              AppTokens.s2,
            ),
            child: contextControls,
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s3),
      child: Row(
        children: [
          Expanded(child: tabBar),
          const SizedBox(width: AppTokens.s3),
          const Flexible(
              child: Align(
                  alignment: Alignment.centerRight, child: contextControls)),
        ],
      ),
    );
  }

  Widget _buildResponsePane(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTokens.s3),
      child: DecoratedBox(
        decoration: _panelDecoration(context),
        child: const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusLg)),
          child: ResponseViewer(),
        ),
      ),
    );
  }

  BoxDecoration _panelDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: 0.10),
      theme.dividerColor,
    );

    return BoxDecoration(
      color: theme.colorScheme.surface,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      boxShadow: theme.brightness == Brightness.light
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : const [],
    );
  }

  Color _workspaceBackground(BuildContext context) {
    final theme = Theme.of(context);
    return Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: 0.025),
      theme.scaffoldBackgroundColor,
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.translate('import_curl')),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration:
              const InputDecoration(hintText: 'Paste curl command here...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel'))),
          ElevatedButton(
            onPressed: () {
              final model = CurlParser.parse(controller.text);
              if (model != null) {
                ref
                    .read(requestNotifierProvider.notifier)
                    .restoreRequest(model);
                Navigator.pop(context);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Imported!')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid cURL')));
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

    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.translate('export_curl')),
        content: TextField(
          controller: controller,
          maxLines: 5,
          readOnly: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('close'))),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: curl));
              Navigator.pop(context);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Copied!')));
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }
}

class _RequestSidebarDrawer extends StatelessWidget {
  final VoidCallback onClose;

  const _RequestSidebarDrawer({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      const SizedBox(width: AppTokens.s2),
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Close',
                        onPressed: onClose,
                      ),
                      const SizedBox(width: AppTokens.s1),
                      Text(
                        'Sidebar',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ],
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Workspace'),
                      Tab(text: 'Explorer'),
                      Tab(text: 'History'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _WorkspaceSidebarOverview(onClose: onClose),
                const WorkgroupExplorer(),
                HistoryPanel(onClose: onClose),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceSidebarOverview extends StatelessWidget {
  final VoidCallback onClose;

  const _WorkspaceSidebarOverview({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppTokens.s3),
      children: [
        Text(
          'Explorer Preview',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppTokens.s2),
        SizedBox(
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            child: const WorkgroupExplorer(),
          ),
        ),
        const SizedBox(height: AppTokens.s4),
        Text(
          'Recent History',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppTokens.s2),
        SizedBox(
          height: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
            child: HistoryPanel(onClose: onClose, showCloseButton: false),
          ),
        ),
      ],
    );
  }
}
