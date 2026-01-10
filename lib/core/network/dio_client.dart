import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        responseType: ResponseType.plain, // We parse manually to avoid Dio errors on malformed JSON
        validateStatus: (status) => true, // Accept all status codes (4xx/5xx are valid responses)
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.extra['start_time'] = DateTime.now().millisecondsSinceEpoch;
          if (kDebugMode) {
             print('--> ${options.method} ${options.uri}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          final start = response.requestOptions.extra['start_time'];
          if (start != null) {
            final end = DateTime.now().millisecondsSinceEpoch;
            response.extra['duration'] = end - start;
          }
          if (kDebugMode) {
            print('<-- ${response.statusCode} ${response.requestOptions.uri} (${response.extra['duration']}ms)');
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // Add custom logic for standardizing errors if needed, 
          // but since validStatus is true, most http errors come as Response.
          // Network errors (no internet) will land here.
          if (kDebugMode) {
            print('!!! Error: ${e.message}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
