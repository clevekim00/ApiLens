import 'package:uuid/uuid.dart';

class HttpRequestModel {
  final String id;
  final String name;
  final String method;
  final String url;
  final Map<String, String> headers;
  final String body;
  final Map<String, String> queryParams;
  final DateTime timestamp;
  final int iterationCount; // Number of times to run this request

  HttpRequestModel({
    String? id,
    required this.name,
    required this.method,
    required this.url,
    Map<String, String>? headers,
    this.body = '',
    Map<String, String>? queryParams,
    DateTime? timestamp,
    this.iterationCount = 1,
  })  : id = id ?? const Uuid().v4(),
        headers = headers ?? {},
        queryParams = queryParams ?? {},
        timestamp = timestamp ?? DateTime.now();

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'method': method,
      'url': url,
      'headers': headers,
      'body': body,
      'queryParams': queryParams,
      'timestamp': timestamp.toIso8601String(),
      'iterationCount': iterationCount,
    };
  }

  // Create from JSON
  factory HttpRequestModel.fromJson(Map<String, dynamic> json) {
    return HttpRequestModel(
      id: json['id'],
      name: json['name'],
      method: json['method'],
      url: json['url'],
      headers: Map<String, String>.from(json['headers'] ?? {}),
      body: json['body'] ?? '',
      queryParams: Map<String, String>.from(json['queryParams'] ?? {}),
      timestamp: DateTime.parse(json['timestamp']),
      iterationCount: json['iterationCount'] ?? 1,
    );
  }

  // Create a copy with modified fields
  HttpRequestModel copyWith({
    String? id,
    String? name,
    String? method,
    String? url,
    Map<String, String>? headers,
    String? body,
    Map<String, String>? queryParams,
    DateTime? timestamp,
    int? iterationCount,
  }) {
    return HttpRequestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      queryParams: queryParams ?? this.queryParams,
      timestamp: timestamp ?? this.timestamp,
      iterationCount: iterationCount ?? this.iterationCount,
    );
  }
}
