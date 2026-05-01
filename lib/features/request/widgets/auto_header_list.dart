import 'package:flutter/material.dart';

import '../../../../core/ui/components/app_badge.dart';
import '../../../../core/ui/components/app_card.dart';
import '../../../../core/ui/components/app_section_header.dart';
import '../../../../core/ui/tokens/app_tokens.dart';

class AutoHeaderList extends StatefulWidget {
  final Map<String, String> autoHeaders;

  const AutoHeaderList({super.key, required this.autoHeaders});

  @override
  State<AutoHeaderList> createState() => _AutoHeaderListState();
}

class _AutoHeaderListState extends State<AutoHeaderList> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.autoHeaders.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s4,
        AppTokens.s4,
        AppTokens.s4,
        0,
      ),
      child: AppCard(
        padding: EdgeInsets.zero,
        backgroundColor: Color.alphaBlend(
          theme.colorScheme.primary.withValues(alpha: 0.035),
          theme.colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: 'Auto Headers',
              count: widget.autoHeaders.length,
              isExpanded: _isExpanded,
              onToggle: () => setState(() => _isExpanded = !_isExpanded),
              trailing: const AppBadge(
                label: 'READ-ONLY',
                variant: AppBadgeVariant.outline,
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: Column(
                  children: widget.autoHeaders.entries.map((entry) {
                    return _AutoHeaderRow(
                      name: entry.key,
                      value: entry.value,
                    );
                  }).toList(),
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 160),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoHeaderRow extends StatelessWidget {
  final String name;
  final String value;

  const _AutoHeaderRow({
    required this.name,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.s2),
              child: SelectableText(
                name,
                style: AppTokens.monoStyle.copyWith(
                  fontSize: 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          VerticalDivider(width: 1, thickness: 1, color: theme.dividerColor),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.s2),
              child: SelectableText(
                value,
                style: AppTokens.monoStyle.copyWith(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
