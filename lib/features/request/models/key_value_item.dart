import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

@immutable
class KeyValueItem {
  final String id;
  final String key;
  final String value;
  final bool isEnabled;

  const KeyValueItem({
    required this.id,
    required this.key,
    required this.value,
    this.isEnabled = true,
  });

  factory KeyValueItem.initial() {
    return KeyValueItem(
      id: const Uuid().v4(),
      key: '',
      value: '',
    );
  }

  KeyValueItem copyWith({
    String? key,
    String? value,
    bool? isEnabled,
  }) {
    return KeyValueItem(
      id: id,
      key: key ?? this.key,
      value: value ?? this.value,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
