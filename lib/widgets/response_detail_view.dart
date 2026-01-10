import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_json_view/flutter_json_view.dart';
import '../models/http_response_model.dart';
import '../theme/app_theme.dart';

class ResponseDetailView extends StatelessWidget {
  final HttpResponseModel? response;
  final String? error;
  final bool showBadges;

  const ResponseDetailView({
    super.key,
    this.response,
    this.error,
    this.showBadges = true,
  });

  @override
  Widget build(BuildContext context) {
    if (response == null && error == null) {
      return const Center(
        child: Text(
          'No response data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBadges) _buildBadges(context),
        if (showBadges) const SizedBox(height: 16),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  labelColor: AppTheme.cyanTeal,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppTheme.cyanTeal,
                  tabs: [
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
    );
  }

  Widget _buildBadges(BuildContext context) {
    return Row(
      children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: error != null 
              ? AppTheme.errorRed 
              : AppTheme.getStatusColor(response?.statusCode ?? 0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            error != null 
              ? 'ERROR' 
              : '${response!.statusCode} ${response!.statusMessage}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Response time
        if (response != null)
          _buildInfoBadge(Icons.timer, response!.formattedResponseTime),
        if (response != null) const SizedBox(width: 8),
        // Content length
        if (response != null)
          _buildInfoBadge(Icons.data_usage, response!.formattedContentLength),
      ],
    );
  }

  Widget _buildInfoBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyTab(BuildContext context, String body, String? error) {
    if (error != null) {
      return _buildErrorView(error);
    }

    // JSON Detection
    dynamic decodedJson;
    bool isJson = false;
    final contentType = response?.headers['content-type']?.toString().toLowerCase() ?? '';
    
    if (contentType.contains('application/json') || contentType.contains('text/json')) {
      try {
        decodedJson = jsonDecode(body);
        isJson = true;
      } catch (_) {}
    } else {
      // Fallback detection
      try {
        if (body.trim().startsWith('{') || body.trim().startsWith('[')) {
          decodedJson = jsonDecode(body);
          isJson = true;
        }
      } catch (_) {}
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
                          color: Color(0xFF06B6D4), // Cyan/Teal
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
                        color: Colors.white70,
                      ),
                    ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: body));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                );
              },
              tooltip: 'Copy to clipboard',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
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
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.errorRed),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              error,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadersTab(BuildContext context, Map<String, dynamic> headers) {
    if (headers.isEmpty) {
      return const Center(child: Text('No headers available', style: TextStyle(color: Colors.grey)));
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(3),
            },
            border: TableBorder.symmetric(
              inside: BorderSide(color: Colors.grey[800]!, width: 0.5),
            ),
            children: headers.entries.map((e) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cyanTeal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      e.value.toString(),
                      style: TextStyle(color: Colors.grey[300], fontSize: 13),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
