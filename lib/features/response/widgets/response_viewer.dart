import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_json_view/flutter_json_view.dart';

import '../../response/providers/response_provider.dart';
import '../../../core/network/models/response_model.dart';
import 'response_compare_dialog.dart';

class ResponseViewer extends ConsumerWidget {
  final ResponseModel? response;
  
  const ResponseViewer({super.key, this.response});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responseState = response != null 
        ? AsyncValue.data(response) 
        : ref.watch(responseNotifierProvider);

    return responseState.when(
      data: (response) {
        if (response == null) {
          return const Center(
            child: Text(
              'No Response Yet',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return _buildResponseContent(context, response);
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Sending Request...'),
          ],
        ),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error: $err',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildResponseContent(BuildContext context, ResponseModel response) {
    return Column(
      children: [
        // 1. Status Summary Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: response.isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          child: Row(
            children: [
              Text(
                '${response.statusCode} ${response.statusMessage}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: response.isSuccess ? Colors.green[700] : Colors.red[700],
                ),
              ),
              const SizedBox(width: 24),
              Text(
                '${response.durationMs} ms',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 24),
              Text(
                '${(response.sizeBytes / 1024).toStringAsFixed(2)} KB',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (response.jsonBody != null)
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ResponseCompareDialog(currentJson: response.jsonBody),
                    );
                  },
                  icon: const Icon(Icons.difference),
                  label: const Text('Compare'),
                ),
            ],
          ),
        ),
        
        // 2. Tabs (Body / Headers)
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'Body'),
                    Tab(text: 'Headers'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Body Tab
                      _buildBodyTab(response),
                      // Headers Tab
                      _buildHeadersTab(response),
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

  Widget _buildBodyTab(ResponseModel response) {
    if (response.jsonBody != null) {
      // JSON View
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: JsonView.map(
              response.jsonBody is Map ? response.jsonBody as Map<String, dynamic> : {'data': response.jsonBody},
              theme: const JsonViewTheme(
                backgroundColor: Colors.transparent, // Match app theme
                keyStyle: TextStyle(color: Colors.blueAccent),
                stringStyle: TextStyle(color: Colors.green),
                intStyle: TextStyle(color: Colors.orange),
                boolStyle: TextStyle(color: Colors.purple),
              ),
            ),
          ),
        ],
      );
    } else {
      // Raw Text View
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(response.body),
      );
    }
  }

  Widget _buildHeadersTab(ResponseModel response) {
    return ListView.separated(
      padding: const EdgeInsets.all(0),
      itemCount: response.headers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final key = response.headers.keys.elementAt(index);
        final value = response.headers[key]?.join(', ') ?? '';
        return ListTile(
          visualDensity: VisualDensity.compact,
          title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          subtitle: SelectableText(value, style: const TextStyle(fontSize: 13)),
        );
      },
    );
  }
}
