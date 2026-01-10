import 'package:dio/dio.dart';

/// Example of an Interceptor that adds Postman-like default headers.
/// In standard Dio usage, Dio itself sets many of these (like User-Agent, Content-Type, Content-Length).
/// However, if we want strict control or specific values (like "PostmanRuntime/..." style),
/// we can use an interceptor like this.
class AutoHeaderInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 1. User-Agent
    if (!options.headers.containsKey('User-Agent')) {
      options.headers['User-Agent'] = 'ApiLensRuntime/1.0';
    }

    // 2. Accept
    if (!options.headers.containsKey('Accept')) {
      options.headers['Accept'] = '*/*';
    }

    // 3. Accept-Encoding
    if (!options.headers.containsKey('Accept-Encoding')) {
      options.headers['Accept-Encoding'] = 'gzip, deflate, br';
    }

    // 4. Connection
    if (!options.headers.containsKey('Connection')) {
      options.headers['Connection'] = 'keep-alive';
    }

    // 5. Host
    // Usually handled by network stack, but for specific purposes:
    // try {
    //   final uri = options.uri;
    //   if (!options.headers.containsKey('Host') && uri.host.isNotEmpty) {
    //     options.headers['Host'] = uri.host;
    //   }
    // } catch (_) {}

    // 6. Content-Type (Body Check)
    // Dio handles this if using FormData/transformers, but to be explicit:
    if (options.data != null && !options.headers.containsKey('Content-Type')) {
       // Heuristics
       if (options.data is Map || options.data is List) { // Assuming JSON
           // options.headers['Content-Type'] = 'application/json'; // Dio transformer does this
       }
    }

    super.onRequest(options, handler);
  }
}
