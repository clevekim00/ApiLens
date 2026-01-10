import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/batch_execution_service.dart';
import '../../theme/app_theme.dart';

class ConsoleViewer extends StatelessWidget {
  final List<BatchExecutionResult> results;
  final VoidCallback onClear;

  const ConsoleViewer({
    super.key,
    required this.results,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 32, color: Colors.grey[800]),
            const SizedBox(height: 8),
            Text(
              'No execution logs yet',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Console Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            border: Border(
              bottom: BorderSide(color: Colors.grey[800]!),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.terminal, size: 14, color: AppTheme.cyanTeal),
              const SizedBox(width: 8),
              const Text(
                'CONSOLE OUTPUT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_sweep, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onClear,
                tooltip: 'Clear Console',
              ),
            ],
          ),
        ),
        // Log entries
        Expanded(
          child: Container(
            color: const Color(0xFF0F172A),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                return _buildLogEntry(result);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogEntry(BatchExecutionResult result) {
    final time = DateFormat('HH:mm:ss.SSS').format(DateTime.now());
    
    if (result.type == 'log') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '[$time] ',
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'monospace'),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.cyanTeal.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                'LOG',
                style: const TextStyle(color: AppTheme.cyanTeal, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                result.logMessage ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      );
    } else {
      // API Result
      final isError = result.response == null;
      final statusColor = isError ? AppTheme.errorRed : AppTheme.getStatusColor(result.response!.statusCode);
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '[$time] ',
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'monospace'),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                isError ? 'ERR' : 'HTTP ${result.response!.statusCode}',
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      children: [
                        TextSpan(
                          text: '${result.request.method} ',
                          style: const TextStyle(color: AppTheme.cyanTeal, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: result.request.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (result.error != null)
                    Text(
                      'Error: ${result.error}',
                      style: TextStyle(color: AppTheme.errorRed.withOpacity(0.8), fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
