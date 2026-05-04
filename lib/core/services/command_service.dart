import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppCommand {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String? shortcut;
  final VoidCallback action;
  final List<String> tags;

  const AppCommand({
    required this.id,
    required this.title,
    this.description = '',
    required this.icon,
    this.shortcut,
    required this.action,
    this.tags = const [],
  });
}

class CommandService extends StateNotifier<List<AppCommand>> {
  CommandService() : super([]);

  void registerCommand(AppCommand command) {
    state = [...state, command];
  }

  void unregisterCommand(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  List<AppCommand> search(String query) {
    if (query.isEmpty) return state;
    final lowercaseQuery = query.toLowerCase();
    return state.where((c) {
      return c.title.toLowerCase().contains(lowercaseQuery) ||
             c.description.toLowerCase().contains(lowercaseQuery) ||
             c.tags.any((t) => t.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }
}

final commandServiceProvider = StateNotifierProvider<CommandService, List<AppCommand>>((ref) {
  return CommandService();
});
