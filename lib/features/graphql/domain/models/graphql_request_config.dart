import 'package:uuid/uuid.dart';
import 'dart:convert';

class GraphQLRequestConfig {
  final String id;
  final String name;
  final String url;
  final Map<String, String> headers;
  final Map<String, dynamic> auth; // {type: 'none'|'bearer'|'basic', token: ..., username: ...}
  final String query;
  final Map<String, dynamic> variables;
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
    this.variables = const {},
    this.operationName,
    required this.createdAt,
    required this.updatedAt,
  });

  // Alias for backward compatibility if needed, but we'll use url/variables now
  String get endpoint => url;
  String get variablesJson => jsonEncode(variables);

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
    Map<String, dynamic>? variables,
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
      variables: variables ?? this.variables,
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
      'variables': variables,
      'operationName': operationName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory GraphQLRequestConfig.fromJson(Map<String, dynamic> json) {
    return GraphQLRequestConfig(
      id: json['id'],
      name: json['name'],
      url: json['url'] ?? json['endpoint'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
      auth: Map<String, dynamic>.from(json['auth'] ?? {}),
      query: json['query'] ?? '',
      variables: Map<String, dynamic>.from(json['variables'] ?? (json['variablesJson'] != null ? jsonDecode(json['variablesJson']) : {})),
      operationName: json['operationName'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
