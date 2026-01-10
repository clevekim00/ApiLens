import 'dart:convert';
import 'package:dio/dio.dart';
import '../../features/request/models/request_model.dart';
import 'dio_client.dart';
import 'models/response_model.dart';
import '../utils/template_resolver.dart';
import 'request_header_builder.dart'; // NEW

class ApiService {
  final DioClient _dioClient;

  ApiService(this._dioClient);

  Future<ResponseModel> send(RequestModel req, {Map<String, String>? env}) async {
    // 1. Prepare URL & Headers (Environment substitution)
    String finalUrl = TemplateResolver.resolve(req.url, env ?? {});
    
    // Auto-headers logic
    final autoHeaders = RequestHeaderBuilder.buildAutoHeaders(req);
    
    // Resolve user headers
    // We can't use RequestHeaderBuilder.mergeHeaders directly because we need to RESOLVE templates in user headers first.
    // So let's resolve user headers, then merge.
    
    Map<String, String> resolvedUserHeaders = {};
    for (var h in req.headers) {
      if (h.isEnabled && h.key.isNotEmpty) {
        resolvedUserHeaders[TemplateResolver.resolve(h.key, env ?? {})] = 
            TemplateResolver.resolve(h.value, env ?? {});
      }
    }
    
    // Merge: User headers override auto headers
    final Map<String, String> finalHeaders = {...autoHeaders};
    resolvedUserHeaders.forEach((k, v) => finalHeaders[k] = v);
    
    // Auth Headers
    if (req.authType == AuthType.bearer && req.authData != null) {
      final token = TemplateResolver.resolve(req.authData!['token'] ?? '', env ?? {});
      finalHeaders['Authorization'] = 'Bearer $token';
    }
    // Basic / API Key logic would go here

    // 2. Prepare Body
    dynamic finalBody;
    if (req.body != null && req.body!.isNotEmpty) {
      finalBody = TemplateResolver.resolve(req.body!, env ?? {});
    }
    
    // 3. Prepare Params
    Map<String, dynamic> finalParams = {};
    for (var p in req.params) {
      if (p.isEnabled && p.key.trim().isNotEmpty) {
        finalParams[TemplateResolver.resolve(p.key, env ?? {})] = 
            TemplateResolver.resolve(p.value, env ?? {});
      }
    }

    try {
      final response = await _dioClient.dio.request(
        finalUrl,
        data: finalBody,
        queryParameters: finalParams,
        options: Options(
          method: req.method,
          headers: finalHeaders,
          // MVP: Timeout could be passed here if extended
        ),
      );

      final duration = response.extra['duration'] as int? ?? 0;
      final rawBody = response.data.toString();
      
      dynamic jsonBody;
      try {
        if (rawBody.trim().startsWith('{') || rawBody.trim().startsWith('[')) {
           jsonBody = jsonDecode(rawBody);
        }
      } catch (_) {}

      final headersMap = <String, List<String>>{};
      response.headers.forEach((k, v) {
        headersMap[k] = v;
      });

      return ResponseModel(
        statusCode: response.statusCode ?? 0,
        statusMessage: response.statusMessage ?? '',
        headers: headersMap,
        body: rawBody,
        jsonBody: jsonBody,
        durationMs: duration,
        sizeBytes: utf8.encode(rawBody).length,
      );

    } catch (e) {
      return ResponseModel(
        statusCode: 0,
        statusMessage: 'Error',
        headers: {},
        body: '',
        durationMs: 0,
        sizeBytes: 0,
        error: e.toString(),
      );
    }
  }
}
