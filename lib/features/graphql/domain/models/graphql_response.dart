class GraphQLResponse {
  final Map<String, dynamic>? data;
  final List<dynamic>? errors;
  final String rawText;
  final int statusCode;
  final int durationMs;
  final Map<String, dynamic> responseHeaders;

  GraphQLResponse({
    this.data,
    this.errors,
    required this.rawText,
    required this.statusCode,
    required this.durationMs,
    this.responseHeaders = const {},
  });
  
  bool get hasErrors => errors != null && errors!.isNotEmpty;
  bool get isSuccess => statusCode >= 200 && statusCode < 300 && !hasErrors;
}
