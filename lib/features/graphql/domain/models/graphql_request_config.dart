import 'package:uuid/uuid.dart';
import 'dart:convert';

class GraphQLRequestConfig {
  final String id;
  final String name;
  final String url;
  final Map<String, String> headers;
  final Map<String, dynamic>
      auth; // {type: 'none'|'bearer'|'basic', token: ..., username: ...}
  final String query;
  final String variablesJson;
  final String? operationName;
  final DateTime createdAt;
  final DateTime updatedAt;

  GraphQLRequestConfig({
    required this.id,
    this.name = 'Untitled GraphQL Request',
    this.url = '',
    this.headers = const {},
    this.auth = const {'type': 'none'},
    this.query = '',
    this.variablesJson = '{}',
    this.operationName,
    required this.createdAt,
    required this.updatedAt,
  });

  // Alias for backward compatibility if needed, but we'll use url/variables now
  String get endpoint => url;
  Map<String, dynamic> get variables {
    try {
      final trimmed = variablesJson.trim();
      if (trimmed.isEmpty) return {};
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {};
    } catch (_) {
      return {};
    }
  }

  factory GraphQLRequestConfig.create() {
    final now = DateTime.now();
    return GraphQLRequestConfig(
      id: const Uuid().v4(),
      createdAt: now,
      updatedAt: now,
    );
  }

  GraphQLRequestConfig copyWith({
    String? id,
    String? name,
    String? url,
    Map<String, String>? headers,
    Map<String, dynamic>? auth,
    String? query,
    String? variablesJson,
    String? operationName,
    DateTime? updatedAt,
  }) {
    return GraphQLRequestConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      auth: auth ?? this.auth,
      query: query ?? this.query,
      variablesJson: variablesJson ?? this.variablesJson,
      operationName: operationName ?? this.operationName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'headers': headers,
      'auth': auth,
      'query': query,
      'variablesJson': variablesJson,
      'operationName': operationName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GraphQLRequestConfig.fromJson(Map<String, dynamic> json) {
    String variablesJson = '{}';
    if (json['variablesJson'] != null) {
      variablesJson = json['variablesJson'].toString();
    } else if (json['variables'] is Map) {
      try {
        variablesJson = jsonEncode(json['variables']);
      } catch (_) {
        variablesJson = '{}';
      }
    }

    return GraphQLRequestConfig(
      id: json['id'],
      name: json['name'],
      url: json['url'] ?? json['endpoint'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      auth: Map<String, dynamic>.from(json['auth'] ?? {}),
      query: json['query'] ?? '',
      variablesJson: variablesJson,
      operationName: json['operationName'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
