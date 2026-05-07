import 'package:flutter/material.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  int _selectedTopic = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final List<String> topics = [
      l10n.translate('getting_started'),
      l10n.translate('rest_builder'),
      l10n.translate('workflow_editor'),
      l10n.translate('shortcuts'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('help')),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar
          SizedBox(
            width: 250,
            child: ColoredBox(
              color: theme.colorScheme.surface,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.s4),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedTopic;
                  return ListTile(
                    title: Text(
                      topics[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    selected: isSelected,
                    selectedTileColor:
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                    onTap: () => setState(() => _selectedTopic = index),
                  );
                },
              ),
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
          // Main Content
          Expanded(
            child: ColoredBox(
              color: _workspaceBackground(context),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.s6),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: _buildContent(theme, l10n),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... _workspaceBackground is unchanged ...

  Widget _buildContent(ThemeData theme, AppLocalizations l10n) {
    final content = l10n.helpContent;
    switch (_selectedTopic) {
      case 0:
        return _buildGettingStarted(theme, content['getting_started']);
      case 1:
        return _buildRestBuilder(theme, l10n);
      case 2:
        return _buildWorkflowEditor(theme, content['workflow_editor']);
      case 3:
        return _buildKeyboardShortcuts(theme, l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGettingStarted(ThemeData theme, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _h1(data['title'], theme),
        _p(data['p1'], theme),
        _h2(data['h2'], theme),
        _p(data['p2'], theme),
        _bullet(data['b1']),
        _bullet(data['b2']),
        _bullet(data['b3']),
      ],
    );
  }

  Widget _buildRestBuilder(ThemeData theme, AppLocalizations l10n) {
    // English content for now as it's common, but could be localized further
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _h1(l10n.translate('rest_builder'), theme),
        _p('Construct and test HTTP requests with a keyboard-first design.',
            theme),
        _h2('Key Features', theme),
        _bullet('Params: Key-Value editor for URL query parameters.'),
        _bullet('Headers: Auto-complete headers and manage custom tokens.'),
        _bullet('Body: Syntax highlighted JSON/XML editor.'),
        _bullet('Scripts: Run Pre-request and Test scripts.'),
      ],
    );
  }

  Widget _buildWorkflowEditor(ThemeData theme, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _h1(data['title'], theme),
        _p(data['p1'], theme),
        const SizedBox(height: AppTokens.s4),
        _h2(data['h2_1'], theme),
        _bullet(data['n1']),
        _bullet(data['n2']),
        _bullet(data['n3']),
        _bullet(data['n4']),
        const SizedBox(height: AppTokens.s4),
        _h2(data['h2_2'], theme),
        _p(data['p2'], theme),
        const SizedBox(height: AppTokens.s4),
        _h2(data['h2_3'], theme),
        _p(data['p3'], theme),
      ],
    );
  }

  Widget _buildKeyboardShortcuts(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _h1(l10n.translate('shortcuts'), theme),
        _h2('Global', theme),
        _bullet('Cmd/Ctrl + Enter: Send active request'),
        _bullet('Cmd/Ctrl + S: Save current request/workflow'),
        _h2('Workflow Editor', theme),
        _bullet('Space + Drag: Pan Canvas'),
        _bullet('Mouse Wheel: Zoom in/out'),
      ],
    );
  }

  // --- Helper Widgets for Markdown-like Formatting ---

  Widget _h1(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s4),
      child: Text(
        text,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _h2(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTokens.s4, bottom: AppTokens.s2),
      child: Text(
        text,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _p(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s3),
      child: Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTokens.s4, bottom: AppTokens.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•', style: TextStyle(fontSize: 18, height: 1.2)),
          const SizedBox(width: AppTokens.s2),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 15, height: 1.5))),
        ],
      ),
    );
  }

  Color _workspaceBackground(BuildContext context) {
    final theme = Theme.of(context);
    return Color.alphaBlend(
      theme.colorScheme.primary.withValues(alpha: 0.025),
      theme.scaffoldBackgroundColor,
    );
  }
}
