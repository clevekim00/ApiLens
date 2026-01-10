import 'dart:convert';
import '../models/http_request_model.dart';

class VariableSubstitutionService {
  // Replace variables in text with values from context
  // Supports: {{stepN.response.body.field}}, {{stepN.response.status}}, etc.
  String substituteVariables(String text, Map<String, dynamic> context) {
    if (!text.contains('{{')) {
      return text;
    }

    String result = text;
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      final variable = match.group(1)?.trim();
      if (variable != null) {
        final value = resolveByPath(context, variable);
        if (value != null) {
          result = result.replaceAll(match.group(0)!, value.toString());
        }
      }
    }

    return result;
  }

  // Resolve a variable path like "step0.response.body.userId" or just "response.body.userId"
  dynamic resolveByPath(dynamic data, String path) {
    if (path.isEmpty) return data;
    
    final parts = path.startsWith(r'$.') ? path.substring(2).split('.') : path.split('.');
    dynamic current = data;

    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else if (current is List && int.tryParse(part) != null) {
        final index = int.parse(part);
        if (index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }

    return current;
  }

  // Substitute variables in request
  Map<String, dynamic> substituteInRequest(
    Map<String, dynamic> request,
    Map<String, dynamic> context,
  ) {
    final result = <String, dynamic>{};

    for (final entry in request.entries) {
      if (entry.value is String) {
        result[entry.key] = substituteVariables(entry.value, context);
      } else if (entry.value is Map) {
        result[entry.key] = substituteInRequest(
          Map<String, dynamic>.from(entry.value),
          context,
        );
      } else if (entry.value is List) {
        result[entry.key] = (entry.value as List).map((item) {
          if (item is String) {
            return substituteVariables(item, context);
          } else if (item is Map) {
            return substituteInRequest(Map<String, dynamic>.from(item), context);
          }
          return item;
        }).toList();
      } else {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  // Build context from previous step results
  Map<String, dynamic> buildContext(List<Map<String, dynamic>> stepResults) {
    final context = <String, dynamic>{};

    for (int i = 0; i < stepResults.length; i++) {
      context['step$i'] = stepResults[i];
    }

    // Also add 'previous' as alias for last step
    if (stepResults.isNotEmpty) {
      context['previous'] = stepResults.last;
    }

    return context;
  }

  // Extract data from response for context
  Map<String, dynamic> responseToContext(dynamic response) {
    if (response == null) {
      return {'response': null};
    }

    final context = <String, dynamic>{
      'response': {
        'status': response.statusCode,
        'statusMessage': response.statusMessage,
        'headers': response.headers,
        'responseTime': response.responseTime,
      }
    };

    // Try to parse body as JSON
    try {
      if (response.body != null && response.body.isNotEmpty) {
        final bodyData = jsonDecode(response.body);
        context['response']['body'] = bodyData;
      } else {
        context['response']['body'] = response.body;
      }
    } catch (e) {
      // If not JSON, use raw body
      context['response']['body'] = response.body;
    }

    return context;
  }

  // Apply explicit mappings from an edge to a request
  HttpRequestModel applyMappings(
    HttpRequestModel request,
    Map<String, dynamic> sourceContext,
    Map<String, dynamic> mappings,
  ) {
    var updatedRequest = request;

    mappings.forEach((target, sourcePath) {
      final value = resolveByPath(sourceContext, sourcePath);
      if (value == null) return;

      final parts = target.split(':');
      if (parts.length < 2) return;

      final type = parts[0];
      final key = parts[1];

      switch (type) {
        case 'header':
          final headers = Map<String, String>.from(updatedRequest.headers);
          headers[key] = value.toString();
          updatedRequest = updatedRequest.copyWith(headers: headers);
          break;
        case 'query':
          final queryParams = Map<String, String>.from(updatedRequest.queryParams);
          queryParams[key] = value.toString();
          updatedRequest = updatedRequest.copyWith(queryParams: queryParams);
          break;
        case 'body':
          // For body, we might need to handle JSON structure if key is a path
          // For now, simplify to direct key assignment if body is JSON
          try {
            final bodyObj = jsonDecode(updatedRequest.body);
            if (bodyObj is Map) {
              bodyObj[key] = value;
              updatedRequest = updatedRequest.copyWith(body: jsonEncode(bodyObj));
            }
          } catch (e) {
            // Fallback for non-JSON body: append or ignore?
            // User probably expects JSON if they specify a key
          }
          break;
      }
    });

    return updatedRequest;
  }
}
