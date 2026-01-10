import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_service.dart';
import '../providers/request_provider.dart';
import '../providers/collection_provider.dart';
import '../models/workflow_graph_model.dart';
import '../theme/app_theme.dart';

class AIAssistantDrawer extends StatefulWidget {
  const AIAssistantDrawer({super.key});

  @override
  State<AIAssistantDrawer> createState() => _AIAssistantDrawerState();
}

class _AIAssistantDrawerState extends State<AIAssistantDrawer> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  String? _lastResult;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'AI Prompt',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _promptController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'e.g., "Create a GET request to fetch users from jsonplaceholder"',
              hintStyle: TextStyle(color: Colors.grey[700], fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.black.withOpacity(0.2),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _generate(context, false), // Request
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Gen', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cyanTeal.withOpacity(0.1),
                          foregroundColor: AppTheme.cyanTeal,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _generate(context, false, executeImmediately: true), // Execute
                        icon: const Icon(Icons.flash_on, size: 16),
                        label: const Text('Run', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.withOpacity(0.1),
                          foregroundColor: Colors.orange[300],
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _generate(context, true), // Workflow
                        icon: const Icon(Icons.account_tree, size: 16),
                        label: const Text('Flow', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.withOpacity(0.1),
                          foregroundColor: Colors.purple[300],
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildLegend(),
              ],
            ),
          
          if (_lastResult != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Last Result Status:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _lastResult!,
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡 Tips:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _tipRow('Try: "Make a POST login request"'),
          _tipRow('Try: "Build a flow that checks login response"'),
        ],
      ),
    );
  }

  Widget _tipRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, size: 12, color: AppTheme.cyanTeal),
          const SizedBox(width: 4),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.grey))),
        ],
      ),
    );
  }

  Future<void> _generate(BuildContext context, bool isWorkflow, {bool executeImmediately = false}) async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a prompt')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _lastResult = 'Generating...';
    });

    try {
      final response = await AIService.generateSimulatedResponse(prompt, isWorkflow);
      
      if (!mounted) return;

      if (isWorkflow) {
        final result = AIService.parseWorkflow(response);
        if (result != null) {
          final collectionProvider = context.read<CollectionProvider>();
          final activeCollection = collectionProvider.activeCollection;
          
          if (activeCollection == null) {
            setState(() => _lastResult = 'Failed: No active collection');
          } else {
            // Inject nodes and edges into active collection
            collectionProvider.addWorkflowFromAI(
              activeCollection.id, 
              List<WorkflowNode>.from(result['nodes']), 
              List<WorkflowEdge>.from(result['edges'])
            );
            setState(() => _lastResult = 'Success: Workflow nodes added to "${activeCollection.name}"');
          }
        } else {
          setState(() => _lastResult = 'Failed: Could not parse workflow JSON');
        }
      } else {
        final request = AIService.parseRequest(response);
        if (request != null) {
          final requestProvider = context.read<RequestProvider>();
          requestProvider.loadRequest(request);
          
          if (executeImmediately) {
            await requestProvider.executeRequest();
            setState(() => _lastResult = 'Success: Request executed! See results below.');
          } else {
            setState(() => _lastResult = 'Success: Request loaded into builder');
          }
        } else {
          setState(() => _lastResult = 'Failed: Could not parse request JSON');
        }
      }
    } catch (e) {
      setState(() => _lastResult = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
