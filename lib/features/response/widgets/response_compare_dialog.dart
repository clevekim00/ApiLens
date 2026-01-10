import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/json_diff_util.dart';
import '../../history/providers/history_provider.dart';
import '../../history/models/history_item.dart';

class ResponseCompareDialog extends ConsumerStatefulWidget {
  final dynamic currentJson;
  const ResponseCompareDialog({super.key, required this.currentJson});

  @override
  ConsumerState<ResponseCompareDialog> createState() => _ResponseCompareDialogState();
}

class _ResponseCompareDialogState extends ConsumerState<ResponseCompareDialog> {
  HistoryItem? _selectedHistory;
  List<DiffNode>? _diffNodes;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyNotifierProvider);

    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Compare Response', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            
            // Selector
            Row(
              children: [
                const Text('Compare with: '),
                const SizedBox(width: 8),
                Expanded(
                  child: historyAsync.when(
                    data: (items) {
                      // Filter items that have a body/JSON? Or just all.
                      // Let's take top 10.
                      final recent = items.take(10).toList();
                      return DropdownButton<HistoryItem>(
                        isExpanded: true,
                        value: _selectedHistory,
                        hint: const Text('Select a previous request from history...'),
                        items: recent.map((e) {
                          return DropdownMenuItem(
                            value: e,
                            child: Text('[${e.method}] ${e.url} (${e.statusCode}) - ${e.createdAt.toString().substring(5, 16)}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedHistory = val;
                            _computeDiff();
                          });
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (_,__) => const Text('Failed to load history'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Diff View
            Expanded(
              child: _diffNodes == null 
                  ? const Center(child: Text('Select a comparison target to see differences.'))
                  : _diffNodes!.isEmpty 
                      ? const Center(child: Text('No Differences Found (Identical JSON)'))
                      : ListView.builder(
                          itemCount: _diffNodes!.length,
                          itemBuilder: (context, index) => _buildDiffItem(_diffNodes![index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _computeDiff() {
    if (_selectedHistory == null || widget.currentJson == null) return;
    
    // Try parse history body
    dynamic oldJson;
    try {
      if (_selectedHistory!.body != null) {
         oldJson = jsonDecode(_selectedHistory!.body!);
      }
    } catch (_) {}

    if (oldJson == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected history has no valid JSON body')));
      setState(() => _diffNodes = []);
      return;
    }

    setState(() {
      _diffNodes = JsonDiffUtil.compare(oldJson, widget.currentJson);
    });
  }

  Widget _buildDiffItem(DiffNode node, [int depth = 0]) {
    Color? color;
    IconData? icon;
    if (node.type == DiffType.added) {
      color = Colors.green.shade100;
      icon = Icons.add;
    } else if (node.type == DiffType.removed) {
      color = Colors.red.shade100;
      icon = Icons.remove;
    } else if (node.type == DiffType.changed) {
      color = Colors.orange.shade100;
      icon = Icons.edit;
    }

    final indent = EdgeInsets.only(left: depth * 16.0);

    if (node.children.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: color,
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4).add(indent),
            child: Row(
              children: [
                if(icon!=null) Icon(icon, size: 14),
                const SizedBox(width: 4),
                Text(node.key, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ...node.children.map((c) => _buildDiffItem(c, depth + 1)),
        ],
      );
    }

    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8).add(indent),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(icon!=null) Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(icon, size: 16, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontFamily: 'monospace'),
                children: [
                  TextSpan(text: '${node.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (node.type == DiffType.changed) ...[
                    TextSpan(text: '${node.oldValue}', style: const TextStyle(color: Colors.red, decoration: TextDecoration.lineThrough)),
                    const TextSpan(text: '  ➔  '),
                    TextSpan(text: '${node.newValue}', style: const TextStyle(color: Colors.green)),
                  ] else if (node.type == DiffType.added) ...[
                    TextSpan(text: '${node.newValue}', style: const TextStyle(color: Colors.green)),
                  ] else if (node.type == DiffType.removed) ...[
                    TextSpan(text: '${node.oldValue}', style: const TextStyle(color: Colors.red, decoration: TextDecoration.lineThrough)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
