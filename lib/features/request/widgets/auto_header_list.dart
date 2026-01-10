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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_more : Icons.expand_less,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Auto-generated headers (${widget.autoHeaders.length})',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            color: Colors.grey.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: widget.autoHeaders.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          entry.key, 
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.w500,
                            color: Colors.black87
                          )
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Text(
                          entry.value, 
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54
                          )
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
