import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/ui/tokens/app_tokens.dart';
import '../../application/workflow_editor_controller.dart';
import '../../domain/models/workflow_node.dart';

class NodePalette extends ConsumerWidget {
  const NodePalette({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const sections = [
      _NodeSection(
        title: 'Core',
        items: [
          _NodePaletteItem('API Request', 'api', Icons.api, Colors.blue),
          _NodePaletteItem(
              'Condition', 'condition', Icons.call_split, Colors.orange),
          _NodePaletteItem('Start', 'start', Icons.play_arrow, Colors.green),
          _NodePaletteItem('End', 'end', Icons.stop, Colors.redAccent),
        ],
      ),
      _NodeSection(
        title: 'GraphQL',
        items: [
          _NodePaletteItem(
              'GraphQL Request', 'gql_request', Icons.code, Colors.pink),
        ],
      ),
      _NodeSection(
        title: 'WebSocket',
        items: [
          _NodePaletteItem(
              'WS Connect', 'ws_connect', Icons.link, Colors.purple),
          _NodePaletteItem(
              'WS Send', 'ws_send', Icons.send, Colors.purpleAccent),
          _NodePaletteItem(
              'WS Wait', 'ws_wait', Icons.hourglass_top, Colors.deepPurple),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PaletteHeader(),
        Divider(height: 1, color: Theme.of(context).dividerColor),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppTokens.s2),
            itemCount: sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s3),
            itemBuilder: (context, sectionIndex) {
              final section = sections[sectionIndex];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.s2,
                      vertical: AppTokens.s1,
                    ),
                    child: Text(
                      section.title.toUpperCase(),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.s1),
                  ...section.items.map(
                    (item) => _DraggableNodeTile(
                      item: item,
                      onAdd: () => _addNode(ref, item),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _addNode(WidgetRef ref, _NodePaletteItem item) {
    ref.read(workflowEditorProvider.notifier).addNode(
          WorkflowNode(
            id: const Uuid().v4(),
            type: item.type,
            x: 100,
            y: 100,
            data: {'name': item.label},
          ),
        );
  }
}

class _PaletteHeader extends StatelessWidget {
  const _PaletteHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s3,
        vertical: AppTokens.s2,
      ),
      child: Row(
        children: [
          Icon(Icons.widgets_outlined,
              size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.s2),
          Expanded(
            child: Text(
              'Nodes',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Drag or click',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggableNodeTile extends StatelessWidget {
  final _NodePaletteItem item;
  final VoidCallback onAdd;

  const _DraggableNodeTile({
    required this.item,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final tile = _NodeTileSurface(item: item);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s1),
      child: Draggable<Map<String, String>>(
        data: {'type': item.type, 'label': item.label},
        affinity: Axis.horizontal,
        feedback: Material(
          color: Colors.transparent,
          elevation: 10,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          child: SizedBox(
            width: 220,
            child: _NodeTileSurface(item: item, isFeedback: true),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.45, child: tile),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            child: tile,
          ),
        ),
      ),
    );
  }
}

class _NodeTileSurface extends StatelessWidget {
  final _NodePaletteItem item;
  final bool isFeedback;

  const _NodeTileSurface({
    required this.item,
    this.isFeedback = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppTokens.s2),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          item.color.withValues(alpha: isFeedback ? 0.12 : 0.055),
          theme.colorScheme.surface,
        ),
        border: Border.all(color: item.color.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            ),
            child: Icon(item.icon, color: item.color, size: 16),
          ),
          const SizedBox(width: AppTokens.s2),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            isFeedback ? Icons.open_with_rounded : Icons.add_circle_outline,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.48),
          ),
        ],
      ),
    );
  }
}

class _NodeSection {
  final String title;
  final List<_NodePaletteItem> items;

  const _NodeSection({
    required this.title,
    required this.items,
  });
}

class _NodePaletteItem {
  final String label;
  final String type;
  final IconData icon;
  final Color color;

  const _NodePaletteItem(this.label, this.type, this.icon, this.color);
}
