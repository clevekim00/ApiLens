import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apilens/core/settings/settings_repository.dart';
import '../../application/workflow_editor_controller.dart';
import 'workflow_actions.dart';
import '../../../../features/websocket/presentation/screens/websocket_client_screen.dart';

class AppMenuBar extends ConsumerWidget {
  const AppMenuBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider);
    // ignore: unused_local_variable
    final workflowState = ref.watch(workflowEditorProvider);

    return MenuBar(
      children: [
        // 1. Workflow Menu
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: () => WorkflowActions.handleNew(context, ref),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyN, meta: true),
              child: const MenuAcceleratorLabel('&New Workflow'),
            ),
             MenuItemButton(
              onPressed: () => WorkflowActions.handleOpen(context, ref),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
              child: const MenuAcceleratorLabel('&Open...'),
            ),
            const PopupMenuDivider(),
            MenuItemButton(
              onPressed: () => WorkflowActions.handleSave(context, ref, saveAs: false),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true),
              child: const MenuAcceleratorLabel('&Save'),
            ),
            MenuItemButton(
              onPressed: () => WorkflowActions.handleSave(context, ref, saveAs: true),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true, shift: true),
              child: const MenuAcceleratorLabel('Save &As...'),
            ),
            const PopupMenuDivider(),
            MenuItemButton(
              onPressed: () => WorkflowActions.handleExport(context, ref),
              child: const MenuAcceleratorLabel('Export &JSON'),
            ),
            MenuItemButton(
              onPressed: () => WorkflowActions.handleImport(context, ref),
              child: const MenuAcceleratorLabel('&Import JSON'),
            ),
            const PopupMenuDivider(),
            MenuItemButton(
              onPressed: () => WorkflowActions.handleRun(context, ref),
              shortcut: const SingleActivator(LogicalKeyboardKey.enter, meta: true),
              child: const MenuAcceleratorLabel('&Run Workflow'),
            ),
          ],
          child: const MenuAcceleratorLabel('&Workflow'),
        ),

        // 2. WebSocket Menu
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WebSocketClientScreen())
                );
              },
              child: const MenuAcceleratorLabel('&Open Client'),
            ),
          ],
          child: const MenuAcceleratorLabel('Web&Socket'),
        ),

        // 3. Settings Menu
        SubmenuButton(
          menuChildren: [
            SubmenuButton(
              menuChildren: [
                RadioMenuButton<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (val) => ref.read(settingsProvider.notifier).setThemeMode(val!),
                  child: const Text('Light'),
                ),
                RadioMenuButton<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (val) => ref.read(settingsProvider.notifier).setThemeMode(val!),
                  child: const Text('Dark'),
                ),
                RadioMenuButton<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (val) => ref.read(settingsProvider.notifier).setThemeMode(val!),
                  child: const Text('System'),
                ),
              ],
              child: const Text('Theme'),
            ),
          ],
          child: const MenuAcceleratorLabel('&Settings'),
        ),
      ],
    );
  }
}
