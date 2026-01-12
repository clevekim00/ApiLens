import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../request/models/request_model.dart';
import '../../request/models/key_value_item.dart';
import '../domain/models/openapi_operation_model.dart';

class SwaggerParserService {
  
  List<RequestModel> parse(String content, {String? baseUrlOverride}) {
    final result = parseToResult(content);
    if (result == null) return [];
    
    final baseUrl = baseUrlOverride ?? result.baseUrl ?? '';
    // Default options for legacy/direct parse
    const options = ImportOptions(); 
    
    return result.operations.map((op) => convertOperationToRequest(op, options, baseUrl)).toList();
  }

  OpenApiParseResult? parseToResult(String content) {
    if (content.trim().isEmpty) return null;
    try {
      final map = jsonDecode(content);
      return _parseJsonToResult(map);
    } catch (e) {
      print('JSON Decode Error: $e');
      return null;
    }
  }

  OpenApiParseResult _parseJsonToResult(Map<String, dynamic> root) {
    final operations = <OpenApiOperation>[];
    final baseUrl = _findBaseUrl(root);
    final info = root['info'] as Map<String, dynamic>? ?? {};

    final paths = root['paths'] as Map<String, dynamic>?;
    if (paths != null) {
      paths.forEach((path, pathItem) {
        if (pathItem is Map<String, dynamic>) {
          final pathParamsRaw = pathItem['parameters'] as List?;

          pathItem.forEach((method, operation) {
            if (_isHttpMethod(method) && operation is Map<String, dynamic>) {
               final opParamsRaw = operation['parameters'] as List?;
               final combinedParams = [...?pathParamsRaw, ...?opParamsRaw];
               
               operations.add(OpenApiOperation(
                 id: const Uuid().v4(),
                 path: path,
                 method: method.toUpperCase(),
                 summary: operation['summary'],
                 description: operation['description'],
                 operationId: operation['operationId'],
                 tags: (operation['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
                 parameters: combinedParams,
                 requestBody: operation['requestBody'],
                 security: operation['security'] as List? ?? [],
               ));
            }
          });
        }
      });
    }

    return OpenApiParseResult(
      baseUrl: baseUrl,
      info: info,
      operations: operations,
    );
  }

  bool _isHttpMethod(String key) {
    const methods = ['get', 'post', 'put', 'delete', 'patch', 'options', 'head'];
    return methods.contains(key.toLowerCase());
  }

  String _findBaseUrl(Map<String, dynamic> root) {
    final servers = root['servers'] as List?;
    if (servers != null && servers.isNotEmpty) {
      String url = servers.first['url'] ?? '';
      final variables = servers.first['variables'] as Map<String, dynamic>?;
      if (variables != null) {
        variables.forEach((key, val) {
          final defaultVal = val['default']?.toString() ?? '';
          url = url.replaceAll('{$key}', defaultVal);
        });
      }
      return url;
    }
    final host = root['host'];
    final basePath = root['basePath'] ?? '';
    final schemes = root['schemes'] as List?;
    final scheme = schemes != null && schemes.isNotEmpty ? schemes.first : 'https';
    if (host != null) return '$scheme://$host$basePath';
    return '';
  }


  RequestModel convertOperationToRequest(
      OpenApiOperation op, 
      ImportOptions options, 
      String parsedBaseUrl
  ) {
    final name = op.summary ?? op.operationId ?? '${op.method} ${op.path}';
    
    // Base URL Handling
    String fullUrl;
    if (options.baseUrlBehavior == BaseUrlBehavior.env) {
      fullUrl = '{{env.baseUrl}}${op.path}';
    } else {
      fullUrl = '$parsedBaseUrl${op.path}';
    }

    // Separate Params
    final headers = <KeyValueItem>[];
    final queryParams = <KeyValueItem>[];
    final pathParamsList = <KeyValueItem>[];
    
    for (var p in op.parameters) {
      if (p is Map<String, dynamic>) {
        final name = p['name'] as String? ?? '';
        final inType = p['in'] as String? ?? ''; 
        final schema = p['schema'] as Map<String, dynamic>?;
        final example = p['example'] ?? schema?['example'] ?? schema?['default'];
        final val = example?.toString() ?? '';
        
        final item = KeyValueItem(
          id: const Uuid().v4(),
          key: name,
          value: val,
          isEnabled: true,
          description: inType, 
        );

        if (inType == 'query') {
          if (!queryParams.any((x) => x.key == name)) queryParams.add(item);
        } else if (inType == 'header') {
          if (!headers.any((x) => x.key == name)) headers.add(item);
        } else if (inType == 'path') {
          if (!pathParamsList.any((x) => x.key == name)) {
             pathParamsList.add(item.copyWith(value: '')); 
          }
        }
      }
    }

    // Body Parsing
    String body = '';
    RequestBodyType bodyType = RequestBodyType.none;
    
    if (op.requestBody != null) {
      final content = op.requestBody['content'] as Map<String, dynamic>?;
      if (content != null) {
        if (content.containsKey('application/json')) {
           bodyType = RequestBodyType.json;
           final schema = content['application/json']['schema'] as Map<String, dynamic>?;
           final example = content['application/json']['example'];
           
           if (options.bodySampleStrategy == BodySampleStrategy.example && example != null) {
             // Use explicit example if available
             try {
                body = const JsonEncoder.withIndent('  ').convert(example);
             } catch (_) { body = example.toString(); }
           } else if (options.bodySampleStrategy != BodySampleStrategy.minimal && schema != null) {
             body = _generateJsonFromSchema(schema);
           } else {
             body = '{}';
           }
        } else if (content.containsKey('application/x-www-form-urlencoded')) {
           bodyType = RequestBodyType.form;
        } else if (content.containsKey('multipart/form-data')) {
           bodyType = RequestBodyType.form; 
        }
      }
    }

    // Auth Parsing
    AuthType authType = AuthType.none;
    Map<String, String>? authData;
    
    if (options.authBehavior == AuthBehavior.detect && op.security.isNotEmpty) {
       // Simple detection
       authType = AuthType.bearer; 
    }

    return RequestModel(
      id: const Uuid().v4(),
      name: name,
      method: op.method,
      url: fullUrl, 
      headers: headers,
      params: queryParams,
      pathParams: pathParamsList,
      body: body,
      bodyType: bodyType,
      authType: authType,
      authData: authData,
      source: {
        'kind': 'openapi',
        'operationId': op.operationId,
        'summary': op.summary,
        'tags': op.tags,
      },
    );
  }

  String _generateJsonFromSchema(Map<String, dynamic> schema) {
     try {
       final obj = _generateSchemaValue(schema);
       const encoder = JsonEncoder.withIndent('  ');
       return encoder.convert(obj);
     } catch (_) {
       return '{}';
     }
  }

  dynamic _generateSchemaValue(Map<String, dynamic> schema) {
     final type = schema['type'];
     if (type == 'object') {
       final props = schema['properties'] as Map<String, dynamic>?;
       if (props != null) {
         final Map<String, dynamic> obj = {};
         props.forEach((key, propSchema) {
           if (propSchema is Map<String, dynamic>) {
              obj[key] = _generateSchemaValue(propSchema);
           }
         });
         return obj;
       }
       return {};
     } else if (type == 'array') {
       final items = schema['items'] as Map<String, dynamic>?;
       if (items != null) {
         return [_generateSchemaValue(items)];
       }
       return [];
     } else if (type == 'string') {
       return schema['example'] ?? 'string';
     } else if (type == 'integer' || type == 'number') {
       return schema['example'] ?? 0;
     } else if (type == 'boolean') {
       return schema['example'] ?? false;
     }
     return null;
  }
}
