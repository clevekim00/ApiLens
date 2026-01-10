import 'dart:convert';
import 'package:apilens/features/request/models/request_model.dart';
import '../../features/request/models/key_value_item.dart';

class RequestHeaderBuilder {
  static const String _userAgent = 'ApiLens/1.0';

  /// Calculates the set of automatic headers based on the request configuration.
  /// These headers are "implied" by the protocol or tool defaults (Postman style).
  static Map<String, String> buildAutoHeaders(RequestModel request) {
    final Map<String, String> autoHeaders = {};

    // 1. Host
    if (request.url.isNotEmpty) {
      try {
        final uri = Uri.parse(request.url);
        if (uri.host.isNotEmpty) {
          autoHeaders['Host'] = uri.host;
        }
      } catch (_) {
        // Ignore invalid URLs for auto-header generation
      }
    }

    // 2. User-Agent
    autoHeaders['User-Agent'] = _userAgent;

    // 3. Accept
    autoHeaders['Accept'] = '*/*';

    // 4. Accept-Encoding
    autoHeaders['Accept-Encoding'] = 'gzip, deflate, br';

    // 5. Connection
    autoHeaders['Connection'] = 'keep-alive';

    // 6. Content-Type (based on Body Type)
    // Only set if not explicitly empty or if method supports body
    if (_methodSupportsBody(request.method)) {
      switch (request.bodyType) {
        case RequestBodyType.json:
          autoHeaders['Content-Type'] = 'application/json';
          break;
        case RequestBodyType.form:
          // Standard form-urlencoded. Multipart logic handled by Dio/Client usually, 
          // but we can hint it here. Postman sets "multipart/form-data; boundary=..." 
          // but boundary is dynamic. We'll set the base type.
          // Note: If using FormData, Dio sets this automatically. 
          // For now, let's assume urlencoded as the default "form" unless file upload is explicit.
          // Clarification needed: RequestBodyType.form usually implies urlencoded in simple apps, 
          // or we might need a separate 'multipart' type.
          // Looking at RequestModel, we have json, text, form.
          // Let's assume form-data for now if that's what "form" means, or urlencoded.
          // Postman default for "x-www-form-urlencoded" is "application/x-www-form-urlencoded".
          // Let's assume urlencoded for the generic "form" type unless specific.
          autoHeaders['Content-Type'] = 'application/x-www-form-urlencoded'; 
          break;
        case RequestBodyType.text:
           autoHeaders['Content-Type'] = 'text/plain';
           break;
        case RequestBodyType.none:
          break;
      }
    }

    // 7. Authorization
    // If Auth is enabled and not "None", we add it. 
    // Postman adds it to headers.
    if (request.authType == AuthType.bearer) {
      final token = request.authData?['token'] ?? '';
      if (token.isNotEmpty) {
        autoHeaders['Authorization'] = 'Bearer $token';
      }
    } else if (request.authType == AuthType.basic) {
      final user = request.authData?['username'] ?? '';
      final pass = request.authData?['password'] ?? '';
      if (user.isNotEmpty || pass.isNotEmpty) {
        final basicAuth = 'Basic ${base64Encode(utf8.encode('$user:$pass'))}';
        autoHeaders['Authorization'] = basicAuth;
      }
    }
    // ApiKey is generic, often header or query. If header, add it.
    // For now assuming we handle Bearer/Basic primarily in auto-headers.

    return autoHeaders;
  }

  static bool _methodSupportsBody(String method) {
    final m = method.toUpperCase();
    return m == 'POST' || m == 'PUT' || m == 'PATCH' || m == 'DELETE';
  }

  /// Merges auto-generated headers with user-defined headers.
  /// User headers take precedence.
  static Map<String, String> mergeHeaders(Map<String, String> autoHeaders, List<KeyValueItem> userHeaders) {
    final Map<String, String> merged = {...autoHeaders};
    
    for (final item in userHeaders) {
      if (item.isEnabled && item.key.isNotEmpty) {
        // User header overrides auto header (case-insensitive check ideally, but Map is case-sensitive)
        // For distinct visualization, we might strictly replace. 
        // HTTP headers are case-insensitive. 
        // We should normalize keys if we want strict overriding.
        
        // Simple override:
        merged[item.key] = item.value;
        
        // Remove case-variant duplicates from autoHeaders to avoid sending two Content-Types
        final matchingKey = merged.keys.firstWhere(
            (k) => k.toLowerCase() == item.key.toLowerCase() && k != item.key, 
            orElse: () => '');
        if (matchingKey.isNotEmpty) {
          merged.remove(matchingKey);
        }
      }
    }
    return merged;
  }
}
