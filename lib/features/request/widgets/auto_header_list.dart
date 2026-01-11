import 'package:flutter/material.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: theme.colorScheme.surface, // Sidebar color
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 16,
                  color: theme.iconTheme.color,
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto-generated headers (${widget.autoHeaders.length})',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.iconTheme.color,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text('READ-ONLY', style: TextStyle(fontSize: 10, color: theme.hintColor)),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Column(
              children: widget.autoHeaders.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                    border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.5))),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 32), // Indent to align with list
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            entry.key, 
                            style: TextStyle(
                              fontFamily: 'Fira Code',
                              fontSize: 12, 
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)
                            )
                          ),
                        ),
                      ),
                      VerticalDivider(width: 1, thickness: 1, color: borderColor),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            entry.value, 
                            style: TextStyle(
                              fontFamily: 'Fira Code',
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)
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
        Divider(height: 1, thickness: 1, color: borderColor),
      ],
    );
  }
}
