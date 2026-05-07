import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../l10n/app_localizations.dart';
import '../ui/tokens/app_tokens.dart';

class AppTutorialService {
  late TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> targets = [];

  void showTutorial(
    BuildContext context, {
    required GlobalKey keyRequests,
    required GlobalKey keyWorkflows,
    required GlobalKey keyImport,
    required GlobalKey keyExplorerAdd,
  }) {
    targets.clear();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // 1. Requests Tab
    targets.add(
      TargetFocus(
        identify: "keyRequests",
        keyTarget: keyRequests,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: l10n.translate('requests'),
                description:
                    "Test individual REST, WebSocket, or GraphQL endpoints here.",
                theme: theme,
              );
            },
          ),
        ],
      ),
    );

    // 2. Workflows Tab
    targets.add(
      TargetFocus(
        identify: "keyWorkflows",
        keyTarget: keyWorkflows,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: l10n.translate('workflows'),
                description:
                    "Design complex API logic by connecting nodes in the Workflow Editor.",
                theme: theme,
              );
            },
          ),
        ],
      ),
    );

    // 3. Import Tab
    targets.add(
      TargetFocus(
        identify: "keyImport",
        keyTarget: keyImport,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: l10n.translate('import'),
                description:
                    "Import Swagger/OpenAPI specifications to quickly populate your workspace.",
                theme: theme,
              );
            },
          ),
        ],
      ),
    );

    // 4. Explorer Add Button
    targets.add(
      TargetFocus(
        identify: "keyExplorerAdd",
        keyTarget: keyExplorerAdd,
        contents: [
          TargetContent(
            align: ContentAlign.right,
            builder: (context, controller) {
              return _buildTutorialContent(
                title: l10n.translate('explorer'),
                description:
                    "Create folders and workgroups to organize your API assets.",
                theme: theme,
              );
            },
          ),
        ],
      ),
    );

    tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: theme.colorScheme.primary.withValues(alpha: 0.8),
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        debugPrint("Tutorial finished");
      },
      onClickTarget: (target) {
        debugPrint("Target clicked: ${target.identify}");
      },
      onSkip: () {
        debugPrint("Tutorial skipped");
        return true;
      },
    )..show(context: context);
  }

  Widget _buildTutorialContent({
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.s4),
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTokens.s2),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
            // Extra spacing to ensure content is not too close to the edge
            const SizedBox(height: AppTokens.s6),
          ],
        ),
      ),
    );
  }
}
