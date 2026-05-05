import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_localizations.dart';
import '../ui/tokens/app_tokens.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/request/screens/request_screen.dart';

import '../../features/workflow_editor/presentation/workflow_editor_screen.dart';
import '../../features/import/presentation/screens/openapi_import_screen.dart';
import '../../features/environments/widgets/environment_selector.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/workgroup/presentation/widgets/workgroup_explorer.dart';
import '../../features/history/widgets/history_panel.dart';
import '../../features/help/screens/help_screen.dart';
import '../services/tutorial_service.dart';
import '../services/data_initialization_service.dart';
import '../services/command_service.dart';
import '../../core/settings/settings_repository.dart';
import '../widgets/command_palette.dart';
import 'package:flutter/services.dart';
import '../services/navigation_provider.dart';

class MainWorkspaceScreen extends ConsumerStatefulWidget {
  const MainWorkspaceScreen({super.key});

  @override
  ConsumerState<MainWorkspaceScreen> createState() => _MainWorkspaceScreenState();
}

class _MainWorkspaceScreenState extends ConsumerState<MainWorkspaceScreen> {
  
  final GlobalKey _keyRequests = GlobalKey();
  final GlobalKey _keyWorkflows = GlobalKey();
  final GlobalKey _keyImport = GlobalKey();
  final GlobalKey _keyExplorerAdd = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCommands();
      _initOnboarding();
    });
  }

  void _initCommands() {
    final commandService = ref.read(commandServiceProvider.notifier);
    final nav = ref.read(navigationProvider.notifier);
    
    commandService.registerCommand(AppCommand(
      id: 'new_request',
      title: 'New HTTP Request',
      description: 'Create a new standalone REST request',
      icon: Icons.add_link_rounded,
      shortcut: '⌘ N',
      action: () => nav.setIndex(1),

      tags: ['rest', 'api', 'http'],
    ));

    commandService.registerCommand(AppCommand(
      id: 'new_workflow',
      title: 'New Workflow',
      description: 'Create a new visual automation workflow',
      icon: Icons.account_tree_outlined,
      shortcut: '⌘ W',
      action: () => nav.setIndex(2),

      tags: ['automation', 'flow', 'visual'],
    ));

    commandService.registerCommand(AppCommand(
      id: 'import_openapi',
      title: 'Import OpenAPI / Swagger',
      description: 'Import API definitions from a file or URL',
      icon: Icons.import_export_rounded,
      shortcut: '⌘ I',
      action: () => nav.setIndex(3),

      tags: ['swagger', 'postman', 'import'],
    ));
    commandService.registerCommand(AppCommand(
      id: 'open_settings',
      title: 'Settings',
      description: 'Configure appearance, language, and proxy',
      icon: Icons.settings_outlined,
      shortcut: '⌘ ,',
      action: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
      tags: ['config', 'theme', 'ui'],
    ));
    
    commandService.registerCommand(AppCommand(
      id: 'help_center',
      title: 'Help & Documentation',
      description: 'View guides and documentation',
      icon: Icons.help_outline,
      action: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
      tags: ['guide', 'docs', 'support'],
    ));
  }

  void _initOnboarding() async {
    await ref.read(dataInitializationServiceProvider).initializeSampleData();

    final settings = ref.read(settingsProvider);
    if (!settings.hasSeenTutorial) {
      AppTutorialService().showTutorial(
        context,
        keyRequests: _keyRequests,
        keyWorkflows: _keyWorkflows,
        keyImport: _keyImport,
        keyExplorerAdd: _keyExplorerAdd,
      );
      
      ref.read(settingsProvider.notifier).setHasSeenTutorial(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = ref.watch(navigationProvider);

    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          CommandPalette.show(context);
        },
        SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          CommandPalette.show(context);
        },
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildTopNavigationBar(context, theme, isDark, currentIndex),
          Divider(height: 1, thickness: 1, color: theme.dividerColor),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSidebar(theme),
                VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
                Expanded(
                  child: IndexedStack(
                    index: currentIndex,
                    children: [
                      const DashboardScreen(),
                      const RequestScreen(isStandalone: false),
                      const WorkflowEditorScreen(),
                      const OpenApiImportScreen(targetGroupId: 'root'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTopNavigationBar(BuildContext context, ThemeData theme, bool isDark, int currentIndex) {
    final l10n = AppLocalizations.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.s4),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Icon(Icons.lens, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: AppTokens.s2),
              Text(
                'ApiLens',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppTokens.s6),
          // Navigation Tabs
          Row(
            children: [
              _buildNavTab(l10n.translate('dashboard'), 0, theme, null, currentIndex),
              const SizedBox(width: AppTokens.s2),
              _buildNavTab(l10n.translate('requests'), 1, theme, _keyRequests, currentIndex),
              const SizedBox(width: AppTokens.s2),
              _buildNavTab(l10n.translate('workflows'), 2, theme, _keyWorkflows, currentIndex),
              const SizedBox(width: AppTokens.s2),
              _buildNavTab(l10n.translate('import'), 3, theme, _keyImport, currentIndex),
            ],
          ),

          const Spacer(),
          // Right Actions
          Row(
            children: [
              const SizedBox(
                width: 160,
                child: EnvironmentSelector(),
              ),
              const SizedBox(width: AppTokens.s3),
              IconButton(
                icon: const Icon(Icons.help_outline, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab(String label, int index, ThemeData theme, Key? key, int currentIndex) {
    final isSelected = currentIndex == index;
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    
    return InkWell(
      key: key,
      onTap: () => ref.read(navigationProvider.notifier).setIndex(index),
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.s3, vertical: AppTokens.s2),
        decoration: isSelected
            ? BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              )
            : null,
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 280,
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTokens.s3),
              child: Row(
                children: [
                  Icon(Icons.folder_open, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppTokens.s2),
                  Text(
                    l10n.translate('explorer'),
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  const Spacer(),
                  IconButton(
                    key: _keyExplorerAdd,
                    icon: const Icon(Icons.add_box_outlined, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.s3),
              child: SizedBox(
                height: 32,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l10n.translate('filter_requests'),
                    prefixIcon: const Icon(Icons.filter_list, size: 16),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s2),
            const Expanded(
              flex: 3,
              child: WorkgroupExplorer(),
            ),
            Divider(height: 1, thickness: 1, color: theme.dividerColor),
            Padding(
              padding: const EdgeInsets.all(AppTokens.s3),
              child: Text(
                l10n.translate('history'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Expanded(
              flex: 2,
              child: HistoryPanel(showCloseButton: false),
            ),
          ],
        ),
      ),
    );
  }
}
