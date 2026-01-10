import 'package:flutter/foundation.dart';

@immutable
class ResponseModel {
  final int statusCode;
  final String statusMessage;
  final Map<String, List<String>> headers;
  final String body; // Raw body
  final dynamic jsonBody; // Parsed JSON (if applicable)
  final int durationMs;
  final int sizeBytes;
  final String? error; // standard error message if any

  const ResponseModel({
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
    required this.body,
    this.jsonBody,
    required this.durationMs,
    required this.sizeBytes,
    this.error,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
