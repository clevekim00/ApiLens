import 'package:uuid/uuid.dart';

class GraphQLRequestConfig {
  final String id;
  final String name;
  final String endpoint;
  final Map<String, String> headers;
  final Map<String, dynamic> auth; // {type: 'none'|'bearer'|'basic', token: ..., username: ...}
  final String query;
  final String variablesJson;
  final String? operationName;
  final DateTime createdAt;
  final DateTime updatedAt;

  GraphQLRequestConfig({
    required this.id,
    this.name = 'Untitled GraphQL Request',
    this.endpoint = '',
    this.headers = const {},
    this.auth = const {'type': 'none'},
    this.query = '',
    this.variablesJson = '{}',
    this.operationName,
    required this.createdAt,
    required this.updatedAt,
  });

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
    String? endpoint,
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
      endpoint: endpoint ?? this.endpoint,
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
      'endpoint': endpoint,
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
    return GraphQLRequestConfig(
      id: json['id'],
      name: json['name'],
      endpoint: json['endpoint'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      auth: Map<String, dynamic>.from(json['auth'] ?? {}),
      query: json['query'] ?? '',
      variablesJson: json['variablesJson'] ?? '{}',
      operationName: json['operationName'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
