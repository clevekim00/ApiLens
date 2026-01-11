import 'package:flutter/material.dart';
import '../../../../core/ui/tokens/app_tokens.dart';
import '../../../../core/ui/components/app_card.dart';
import '../../../../core/ui/components/app_section_header.dart';
import '../../../../core/ui/components/app_badge.dart';

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

    return AppCard(
      padding: EdgeInsets.zero,
      backgroundColor: theme.colorScheme.secondary.withOpacity(0.3), // Slightly distinct
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: 'Auto Headers',
            count: widget.autoHeaders.length,
            isExpanded: _isExpanded,
            onToggle: () => setState(() => _isExpanded = !_isExpanded),
            trailing: const AppBadge(label: 'READ-ONLY', variant: AppBadgeVariant.outline),
          ),
          if (_isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Column(
                children: widget.autoHeaders.entries.map((entry) {
                  return Container(
                    height: 36,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.5))),
                      color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16), // Indent
                        Expanded(
                          flex: 1,
                          child: Text(
                            entry.key, 
                            style: AppTokens.monoStyle.copyWith(
                              fontSize: 12, 
                              color: theme.colorScheme.onSurface.withOpacity(0.7)
                            )
                          ),
                        ),
                        VerticalDivider(width: 1, thickness: 1, color: borderColor),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Text(
                              entry.value, 
                              style: AppTokens.monoStyle.copyWith(
                                fontSize: 12, 
                                color: theme.colorScheme.onSurface.withOpacity(0.7)
                              )
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
