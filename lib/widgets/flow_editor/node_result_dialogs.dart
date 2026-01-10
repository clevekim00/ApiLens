import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_json_view/flutter_json_view.dart';
import 'dart:convert';
import '../../services/batch_execution_service.dart';
import '../../theme/app_theme.dart';
import '../response_detail_view.dart';

class NodeHeaderDialog extends StatelessWidget {
  final BatchExecutionResult result;

  const NodeHeaderDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final headers = result.response?.headers ?? {};
    final metaInfo = <String, String>{
      'Node Label': result.nodeLabel ?? 'N/A',
      'Execution Type': result.type.toUpperCase(),
      if (result.response != null) ...{
        'Status Code': result.response!.statusCode.toString(),
        'Status Message': result.response!.statusMessage,
        'Response Time': result.response!.formattedResponseTime,
      },
      if (result.error != null) 'Error': result.error!,
    };

    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      title: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.cyanTeal),
          const SizedBox(width: 12),
          const Text('Execution Headers', style: TextStyle(color: Colors.white)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: ResponseDetailView(
          response: result.response,
          error: result.error,
          showBadges: true,
        ),
      ),
    );
  }
}

class NodeBodyDialog extends StatelessWidget {
  final BatchExecutionResult result;

  const NodeBodyDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      title: Row(
        children: [
          Icon(
            result.type == 'log' ? Icons.terminal : Icons.data_object,
            color: AppTheme.cyanTeal,
          ),
          const SizedBox(width: 12),
          Text(
            result.type == 'log' ? 'Log Content' : 'Response Body',
            style: const TextStyle(color: Colors.white),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        height: 500,
        child: result.type == 'log'
            ? Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    result.logMessage ?? '',
                    style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              )
            : ResponseDetailView(
                response: result.response,
                error: result.error,
                showBadges: true,
              ),
      ),
    );
  }
}
