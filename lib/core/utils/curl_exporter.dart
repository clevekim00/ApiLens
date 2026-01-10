import '../../features/request/models/request_model.dart';

class CurlExporter {
  static String export(RequestModel request) {
    final buffer = StringBuffer();
    buffer.write('curl -X ${request.method} "${request.url}"');
    
    // Headers
    for (var h in request.headers) {
      if (h.isEnabled) {
        buffer.write(' -H "${h.key}: ${h.value}"');
      }
    }
    
    // Auth (Bearer)
    if (request.authType == AuthType.bearer) {
      buffer.write(' -H "Authorization: Bearer ${request.authData?['token'] ?? ''}"');
    }
    // Basic?
    // API Key?
    
    // Body
    if (request.body != null && request.body!.isNotEmpty) {
      // Escape body quotes for shell safety (Simplified)
      final escaped = request.body!.replaceAll('"', '\\"');
      buffer.write(' -d "$escaped"');
    }
    
    return buffer.toString();
  }
}
