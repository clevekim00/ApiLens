import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/workflow_runner_controller.dart';

class ExecutionControlBar extends ConsumerWidget {
  final VoidCallback onRun;

  const ExecutionControlBar({super.key, required this.onRun});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runnerState = ref.watch(workflowRunnerProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: runnerState.isRunning ? null : onRun,
            icon: runnerState.isRunning 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.play_arrow),
            label: Text(runnerState.isRunning ? 'Running...' : 'Run Workflow'),
          ),
          const Spacer(),
          // Status indicator or summary could go here
        ],
      ),
    );
  }
}

class ExecutionLogPanel extends ConsumerWidget {
  const ExecutionLogPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runnerState = ref.watch(workflowRunnerProvider);
    
    return Container(
      color: Colors.black87,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Execution Logs', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: runnerState.logs.length,
              itemBuilder: (context, index) {
                return Text(
                  runnerState.logs[index],
                  style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 11),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
