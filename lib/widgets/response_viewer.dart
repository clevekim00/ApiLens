import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'dart:convert';
import 'package:flutter_json_view/flutter_json_view.dart';
import '../providers/request_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';

class ResponseViewer extends StatelessWidget {
  const ResponseViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        // Show loading or placeholder if no response and no error
        if (provider.isLoading) {
          return const Card(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Sending request...'),
                  ],
                ),
              ),
            ),
          );
        }

        final response = provider.currentResponse;
        final error = provider.error;

        if (response == null && error == null) {
          return Card(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(48.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.http,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No response yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Send a request to see the response',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Response header with status
                Row(
                  children: [
                    Text(
                      'Response',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: error != null 
                          ? AppTheme.errorRed 
                          : AppTheme.getStatusColor(response?.statusCode ?? 0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        error != null 
                          ? 'ERROR' 
                          : '${response!.statusCode} ${response.statusMessage}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // AI Explain Button
                    IconButton(
                      icon: const Icon(Icons.psychology_alt, color: AppTheme.cyanTeal, size: 20),
                      onPressed: () => _showAIExplanation(context, response?.body ?? '', response?.statusCode),
                      tooltip: 'AI Explain',
                    ),
                    const SizedBox(width: 4),
                    // Response time
                    if (response != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              response.formattedResponseTime,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: 8),
                    // Content length
                    if (response != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.data_usage, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              response.formattedContentLength,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tabs for Body, Headers
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          tabs: const [
                            Tab(text: 'Body'),
                            Tab(text: 'Headers'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildBodyTab(context, response?.body ?? '', error),
                              _buildHeadersTab(context, response?.headers ?? {}),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBodyTab(BuildContext context, String body, String? error) {
    if (error != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, size: 20, color: AppTheme.errorRed),
                const SizedBox(width: 8),
                const Text(
                  'Request Failed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              error,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }

    // Try to format as JSON
    dynamic decodedJson;
    bool isJson = false;

    try {
      if (body.trim().startsWith('{') || body.trim().startsWith('[')) {
        decodedJson = jsonDecode(body);
        isJson = true;
      }
    } catch (e) {
      // Not JSON, use as is
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: isJson
                  ? JsonView.map(
                      decodedJson is Map<String, dynamic> 
                        ? decodedJson 
                        : (decodedJson is List ? {'root': decodedJson} : {'data': body}),
                      theme: JsonViewTheme(
                        keyStyle: const TextStyle(
                          color: AppTheme.cyanTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        doubleStyle: const TextStyle(color: Colors.orange, fontSize: 13),
                        intStyle: const TextStyle(color: Colors.orange, fontSize: 13),
                        stringStyle: const TextStyle(color: Colors.green, fontSize: 13),
                        boolStyle: const TextStyle(color: Colors.purple, fontSize: 13),
                        closeIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 18),
                        openIcon: const Icon(Icons.arrow_right, color: Colors.grey, size: 18),
                      ),
                    )
                  : SelectableText(
                      body,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          // Copy button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: body));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Copy to clipboard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadersTab(BuildContext context, Map<String, dynamic> headers) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        itemCount: headers.length,
        itemBuilder: (context, index) {
          final key = headers.keys.elementAt(index);
          final value = headers[key].toString();

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.cyanTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: SelectableText(
                    value,
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAIExplanation(BuildContext context, String body, int? statusCode) async {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppTheme.darkCard.withOpacity(0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.cyanTeal.withOpacity(0.3)),
          ),
          title: Row(
            children: [
              Icon(Icons.auto_awesome, color: AppTheme.cyanTeal),
              const SizedBox(width: 8),
              const Text('AI Insight'),
            ],
          ),
          content: FutureBuilder<String>(
            future: AIService.explainResponse(body, statusCode: statusCode),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              return Text(
                snapshot.data ?? 'No insight available.',
                style: const TextStyle(height: 1.5),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
