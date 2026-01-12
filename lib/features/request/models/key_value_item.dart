import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

@immutable
class KeyValueItem {
  final String id;
  final String key;
  final String value;
  final bool isEnabled;
  final String? description;

  const KeyValueItem({
    required this.id,
    required this.key,
    required this.value,
    this.isEnabled = true,
    this.description,
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
    String? description,
  }) {
    return KeyValueItem(
      id: id,
      key: key ?? this.key,
      value: value ?? this.value,
      isEnabled: isEnabled ?? this.isEnabled,
      description: description ?? this.description,
    );
  }

  factory KeyValueItem.fromJson(Map<String, dynamic> json) {
    return KeyValueItem(
      id: json['id'] as String? ?? const Uuid().v4(),
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'isEnabled': isEnabled,
      'description': description,
    };
  }
}
