import 'package:dio/dio.dart';
import '../models/http_response_model.dart';
import '../models/http_request_model.dart';

class HttpService {
  final Dio _dio;

  HttpService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            validateStatus: (status) => true, // Accept all status codes
          ),
        );

  Future<HttpResponseModel> executeRequest(HttpRequestModel request) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Build full URL with query parameters
      final uri = Uri.parse(request.url);
      final fullUri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          ...request.queryParams,
        },
      );

      // Prepare request options
      final options = Options(
        method: request.method,
        headers: request.headers,
        validateStatus: (status) => true, // Accept all status codes
      );

      // Execute request
      Response response;
      final dynamic requestBody = request.body.isNotEmpty ? request.body : null;

      response = await _dio.request(
        fullUri.toString(),
        data: requestBody,
        options: options,
      );

      stopwatch.stop();

      // Parse response
      final responseBody = response.data is String
          ? response.data
          : response.data?.toString() ?? '';

      return HttpResponseModel(
        statusCode: response.statusCode ?? 0,
        statusMessage: response.statusMessage ?? 'Unknown',
        headers: Map<String, dynamic>.from(response.headers.map),
        body: responseBody,
        responseTime: stopwatch.elapsedMilliseconds,
        contentLength: responseBody.length,
      );
    } on DioException catch (e) {
      stopwatch.stop();

      // Handle Dio errors
      String errorMessage = 'Request failed';
      int statusCode = 0;

      if (e.response != null) {
        statusCode = e.response!.statusCode ?? 0;
        errorMessage = e.response!.statusMessage ?? e.message ?? 'Unknown error';
      } else {
        errorMessage = e.message ?? 'Network error';
      }

      return HttpResponseModel(
        statusCode: statusCode,
        statusMessage: errorMessage,
        headers: e.response?.headers.map ?? {},
        body: e.response?.data?.toString() ?? '',
        responseTime: stopwatch.elapsedMilliseconds,
        contentLength: 0,
        error: errorMessage,
      );
    } catch (e) {
      stopwatch.stop();

      return HttpResponseModel(
        statusCode: 0,
        statusMessage: 'Error',
        headers: {},
        body: '',
        responseTime: stopwatch.elapsedMilliseconds,
        contentLength: 0,
        error: e.toString(),
      );
    }
  }
}
