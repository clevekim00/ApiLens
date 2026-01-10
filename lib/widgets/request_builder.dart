import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/request_provider.dart';
import 'key_value_editor.dart';

class RequestBuilder extends StatefulWidget {
  const RequestBuilder({super.key});

  @override
  State<RequestBuilder> createState() => _RequestBuilderState();
}

class _RequestBuilderState extends State<RequestBuilder> {
  final TextEditingController _urlController = TextEditingController();
  final List<String> _methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD', 'OPTIONS'];

  @override
  void initState() {
    super.initState();
    final provider = context.read<RequestProvider>();
    _urlController.text = provider.currentRequest.url;
    
    // Listen to provider changes and update controller
    provider.addListener(_updateControllerFromProvider);
  }
  
  void _updateControllerFromProvider() {
    final provider = context.read<RequestProvider>();
    if (_urlController.text != provider.currentRequest.url) {
      _urlController.text = provider.currentRequest.url;
    }
  }

  @override
  void dispose() {
    final provider = context.read<RequestProvider>();
    provider.removeListener(_updateControllerFromProvider);
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Request',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Method and URL row
                Row(
                  children: [
                    // Method dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: provider.currentRequest.method,
                        underline: const SizedBox(),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        items: _methods.map((method) {
                          return DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            provider.updateMethod(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // URL input
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          hintText: 'Enter request URL',
                          prefixIcon: Icon(Icons.link),
                        ),
                        onChanged: (value) {
                          provider.updateUrl(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Send button
                    ElevatedButton.icon(
                      onPressed: provider.isLoading
                          ? null
                          : () => provider.executeRequest(),
                      icon: provider.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(provider.isLoading ? 'Sending...' : 'Send'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tabs for Headers, Body, Query Params
                DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        tabs: const [
                          Tab(text: 'Headers'),
                          Tab(text: 'Body'),
                          Tab(text: 'Query Params'),
                        ],
                      ),
                      SizedBox(
                        height: 200,
                        child: TabBarView(
                          children: [
                            _buildHeadersTab(provider),
                            _buildBodyTab(provider),
                            _buildQueryParamsTab(provider),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeadersTab(RequestProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: KeyValueEditor(
        initialData: provider.currentRequest.headers,
        onChanged: (headers) {
          provider.updateHeaders(headers);
        },
        keyHint: 'Header Key',
        valueHint: 'Value',
      ),
    );
  }

  Widget _buildBodyTab(RequestProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        maxLines: null,
        decoration: const InputDecoration(
          hintText: 'Enter request body (JSON, XML, or plain text)',
        ),
        onChanged: (value) {
          provider.updateBody(value);
        },
      ),
    );
  }

  Widget _buildQueryParamsTab(RequestProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: KeyValueEditor(
        initialData: provider.currentRequest.queryParams,
        onChanged: (params) {
          provider.updateQueryParams(params);
        },
        keyHint: 'Param Key',
        valueHint: 'Value',
      ),
    );
  }
}
