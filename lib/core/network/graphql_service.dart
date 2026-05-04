import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/graphql/domain/models/graphql_request_config.dart';
import '../../features/graphql/domain/models/graphql_response.dart';

class GraphQLService {
  final Dio _dio = Dio();

  static const String introspectionQuery = '''
query ApiLensSchemaExplorer {
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      kind
      name
      description
      fields(includeDeprecated: true) {
        name
        description
        args {
          name
          description
          type { kind name ofType { kind name ofType { kind name } } }
        }
        type { kind name ofType { kind name ofType { kind name } } }
        isDeprecated
        deprecationReason
      }
      inputFields {
        name
        description
        type { kind name ofType { kind name ofType { kind name } } }
        defaultValue
      }
      enumValues(includeDeprecated: true) {
        name
        description
        isDeprecated
        deprecationReason
      }
    }
  }
}
''';

  Future<GraphQLResponse> execute(GraphQLRequestConfig config) async {
    return query(
      config.url,
      config.query,
      variables: config.variables,
      headers: config.headers,
      operationName: config.operationName,
    );
  }

  Future<GraphQLResponse> query(
    String url,
    String query, {
    Map<String, dynamic> variables = const {},
    Map<String, String> headers = const {},
    String? operationName,
  }) async {
    final startTime = DateTime.now();

    try {
      final mergedHeaders = Map<String, String>.from(headers);
      mergedHeaders['Content-Type'] = 'application/json';

      final body = {
        'query': query,
        'variables': variables,
        if (operationName != null && operationName.isNotEmpty)
          'operationName': operationName,
      };

      final response = await _dio.post(
        url,
        options: Options(
          headers: mergedHeaders,
          responseType: ResponseType.plain,
          validateStatus: (status) => true,
        ),
        data: jsonEncode(body),
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      Map<String, dynamic>? data;
      List<dynamic>? errors;

      try {
        final Map<String, dynamic> jsonBody = jsonDecode(response.data);
        if (jsonBody.containsKey('data')) {
          data = jsonBody['data'];
        }
        if (jsonBody.containsKey('errors')) {
          errors = jsonBody['errors'];
        }
      } catch (_) {}

      return GraphQLResponse(
        data: data,
        errors: errors,
        rawText: response.data.toString(),
        statusCode: response.statusCode ?? 0,
        durationMs: duration,
        responseHeaders: response.headers.map,
      );
    } catch (e) {
      final endTime = DateTime.now();
      return GraphQLResponse(
        rawText: e.toString(),
        statusCode: 0,
        durationMs: endTime.difference(startTime).inMilliseconds,
        errors: [
          {'message': e.toString()}
        ],
      );
    }
  }

  Future<Map<String, dynamic>> introspectSchema(
    GraphQLRequestConfig config,
  ) async {
    final headers = _buildHeaders(config);
    final response = await _dio.post(
      config.endpoint,
      options: Options(
        headers: headers,
        responseType: ResponseType.plain,
        validateStatus: (status) => true,
      ),
      data: jsonEncode({'query': introspectionQuery}),
    );

    final decoded = jsonDecode(response.data.toString());
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Schema response is not a JSON object.');
    }
    if (decoded['errors'] is List && (decoded['errors'] as List).isNotEmpty) {
      throw Exception(
          'Schema introspection failed: ${jsonEncode(decoded['errors'])}');
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic> ||
        data['__schema'] is! Map<String, dynamic>) {
      throw Exception(
          'Schema introspection response does not include __schema.');
    }

    return data['__schema'] as Map<String, dynamic>;
  }

  Map<String, String> _buildHeaders(GraphQLRequestConfig config) {
    final headers = Map<String, String>.from(config.headers);

    if (config.auth['type'] == 'bearer') {
      headers['Authorization'] = 'Bearer ${config.auth['token']}';
    } else if (config.auth['type'] == 'basic') {
      final token = base64Encode(
        utf8.encode('${config.auth['username']}:${config.auth['password']}'),
      );
      headers['Authorization'] = 'Basic $token';
    } else if (config.auth['type'] == 'apiKey') {
      headers[config.auth['key']] = config.auth['value'];
    }

    headers['Content-Type'] = 'application/json';
    return headers;
  }
}

final graphQLServiceProvider = Provider<GraphQLService>((ref) {
  return GraphQLService();
});
