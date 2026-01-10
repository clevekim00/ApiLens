import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KeyValueEditor extends StatefulWidget {
  final Map<String, String> initialData;
  final Function(Map<String, String>) onChanged;
  final String keyHint;
  final String valueHint;

  const KeyValueEditor({
    super.key,
    required this.initialData,
    required this.onChanged,
    this.keyHint = 'Key',
    this.valueHint = 'Value',
  });

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  late List<MapEntry<String, String>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = widget.initialData.entries.toList();
    if (_entries.isEmpty) {
      _entries.add(const MapEntry('', ''));
    }
  }

  void _update() {
    final Map<String, String> result = {};
    for (var entry in _entries) {
      if (entry.key.isNotEmpty) {
        result[entry.key] = entry.value;
      }
    }
    widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _entries.length,
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: widget.keyHint,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          isDense: true,
                        ),
                        controller: TextEditingController(text: entry.key)
                          ..selection = TextSelection.collapsed(offset: entry.key.length),
                        onChanged: (val) {
                          _entries[index] = MapEntry(val, entry.value);
                          _update();
                        },
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: widget.valueHint,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          isDense: true,
                        ),
                        controller: TextEditingController(text: entry.value)
                          ..selection = TextSelection.collapsed(offset: entry.value.length),
                        onChanged: (val) {
                          _entries[index] = MapEntry(entry.key, val);
                          _update();
                        },
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppTheme.errorRed),
                      onPressed: () {
                        setState(() {
                          _entries.removeAt(index);
                          if (_entries.isEmpty) {
                            _entries.add(const MapEntry('', ''));
                          }
                          _update();
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _entries.add(const MapEntry('', ''));
            });
          },
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text('Add Row', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(foregroundColor: AppTheme.cyanTeal),
        ),
      ],
    );
  }
}
