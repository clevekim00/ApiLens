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
    final startTime = DateTime.now();

    try {
      final headers = _buildHeaders(config);

      // Parse variables
      Map<String, dynamic>? variables;
      try {
        if (config.variablesJson.trim().isNotEmpty) {
          variables = jsonDecode(config.variablesJson);
        }
      } catch (e) {
        throw Exception('Invalid Variables JSON');
      }

      final body = {
        'query': config.query,
        if (variables != null) 'variables': variables,
        if (config.operationName != null && config.operationName!.isNotEmpty)
          'operationName': config.operationName,
      };

      final response = await _dio.post(
        config.endpoint,
        options: Options(
          headers: headers,
          responseType: ResponseType.plain, // Get raw first
          validateStatus: (status) => true, // Handle all status codes
        ),
        data: jsonEncode(body),
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;

      // Parse Body
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
      } catch (_) {
        // Not a JSON response or not standard GraphQL
      }

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
