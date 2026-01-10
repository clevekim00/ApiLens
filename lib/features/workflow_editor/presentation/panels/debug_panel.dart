import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apilens/features/execution/application/workflow_runner_controller.dart';
import 'dart:convert';

class DebugPanel extends ConsumerWidget {
  const DebugPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            height: 36,
            color: Colors.grey.shade200,
            child: const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: 'Logs'),
                Tab(text: 'Context Data'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _LogView(),
                _ContextView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogView extends ConsumerWidget {
  const _LogView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(workflowRunnerProvider).logs;
    final scrollController = ScrollController();

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        return Text(logs[index], style: const TextStyle(fontFamily: 'Courier', fontSize: 12));
      },
    );
  }
}

class _ContextView extends ConsumerWidget {
  const _ContextView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(workflowRunnerProvider).results;

    if (results.isEmpty) {
      return const Center(child: Text('No execution data yet.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final nodeId = results.keys.elementAt(index);
        final result = results[nodeId]!;
        
        // Format generic data nicely
        String dataPreview = '';
        if (result.responseBody != null) {
           try {
             const encoder = JsonEncoder.withIndent('  ');
             dataPreview = encoder.convert(result.responseBody);
           } catch (_) {
             dataPreview = result.responseBody.toString();
           }
        }

        return ExpansionTile(
          title: Text('$nodeId (${result.status.name})', 
             style: TextStyle(
               fontWeight: FontWeight.bold,
               color: result.status.name == 'success' ? Colors.green : (result.status.name == 'failure' ? Colors.red : Colors.black)
             )
          ),
          subtitle: Text('Time: ${(result.finishedAt ?? DateTime.now()).toIso8601String().substring(11, 19)} | Duration: ${(result.finishedAt?.difference(result.startedAt ?? result.finishedAt ?? DateTime.now()).inMilliseconds ?? 0)}ms'),
          children: [
            if (result.errorMessage != null)
              ListTile(
                title: const Text('Error', style: TextStyle(color: Colors.red)),
                subtitle: Text(result.errorMessage!),
              ),
            if (dataPreview.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade100,
                child: SelectableText(dataPreview, style: const TextStyle(fontFamily: 'Courier', fontSize: 11)),
              ),
          ],
        );
      },
    );
  }
}
