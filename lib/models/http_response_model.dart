class HttpResponseModel {
  final int statusCode;
  final String statusMessage;
  final Map<String, dynamic> headers;
  final String body;
  final int responseTime; // in milliseconds
  final int contentLength; // in bytes
  final String? error;

  HttpResponseModel({
    required this.statusCode,
    required this.statusMessage,
    required this.headers,
    required this.body,
    required this.responseTime,
    required this.contentLength,
    this.error,
  });

  // Check if response is successful (2xx status code)
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  // Check if response is client error (4xx status code)
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  // Check if response is server error (5xx status code)
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  // Get status code color based on status
  String get statusColor {
    if (isSuccessful) return 'green';
    if (isClientError) return 'orange';
    if (isServerError) return 'red';
    return 'blue'; // For 1xx and 3xx
  }

  // Format response time for display
  String get formattedResponseTime {
    if (responseTime < 1000) {
      return '${responseTime}ms';
    } else {
      return '${(responseTime / 1000).toStringAsFixed(2)}s';
    }
  }

  // Format content length for display
  String get formattedContentLength {
    if (contentLength < 1024) {
      return '${contentLength}B';
    } else if (contentLength < 1024 * 1024) {
      return '${(contentLength / 1024).toStringAsFixed(2)}KB';
    } else {
      return '${(contentLength / (1024 * 1024)).toStringAsFixed(2)}MB';
    }
  }
}
