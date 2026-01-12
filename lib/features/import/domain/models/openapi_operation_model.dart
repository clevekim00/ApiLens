import 'package:flutter/foundation.dart';

@immutable
class OpenApiOperation {
  final String path;
  final String method;
  final String? summary;
  final String? description;
  final String? operationId;
  final List<String> tags;
  final List<dynamic> parameters; // Raw parameters from parsing
  final dynamic requestBody;      // Raw requestBody
  final List<dynamic> security;   // Raw security requirements
  
  // Helper for UI
  final String id; // Unique ID for keying (internal use)

  const OpenApiOperation({
    required this.id,
    required this.path,
    required this.method,
    this.summary,
    this.description,
    this.operationId,
    this.tags = const [],
    this.parameters = const [],
    this.requestBody,
    this.security = const [],
  });

  OpenApiOperation copyWith({
    String? id,
    String? path,
    String? method,
    String? summary,
    String? description,
    String? operationId,
    List<String>? tags,
    List<dynamic>? parameters,
    dynamic requestBody,
    List<dynamic>? security,
  }) {
    return OpenApiOperation(
      id: id ?? this.id,
      path: path ?? this.path,
      method: method ?? this.method,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      operationId: operationId ?? this.operationId,
      tags: tags ?? this.tags,
      parameters: parameters ?? this.parameters,
      requestBody: requestBody ?? this.requestBody,
      security: security ?? this.security,
    );
  }
}

enum BaseUrlBehavior { fixed, env }
enum DuplicateBehavior { skip, rename, createNew }
enum BodySampleStrategy { minimal, schema, example }
enum AuthBehavior { detect, ignore }

class ImportOptions {
  final BaseUrlBehavior baseUrlBehavior;
  final DuplicateBehavior duplicateBehavior;
  final BodySampleStrategy bodySampleStrategy;
  final AuthBehavior authBehavior;

  const ImportOptions({
    this.baseUrlBehavior = BaseUrlBehavior.env,
    this.duplicateBehavior = DuplicateBehavior.skip,
    this.bodySampleStrategy = BodySampleStrategy.example,
    this.authBehavior = AuthBehavior.detect,
  });

  ImportOptions copyWith({
    BaseUrlBehavior? baseUrlBehavior,
    DuplicateBehavior? duplicateBehavior,
    BodySampleStrategy? bodySampleStrategy,
    AuthBehavior? authBehavior,
  }) {
    return ImportOptions(
      baseUrlBehavior: baseUrlBehavior ?? this.baseUrlBehavior,
      duplicateBehavior: duplicateBehavior ?? this.duplicateBehavior,
      bodySampleStrategy: bodySampleStrategy ?? this.bodySampleStrategy,
      authBehavior: authBehavior ?? this.authBehavior,
    );
  }
}

class OpenApiParseResult {
  final String? baseUrl;
  final Map<String, dynamic> info; // title, version, etc.
  final List<OpenApiOperation> operations;

  const OpenApiParseResult({
    this.baseUrl,
    this.info = const {},
    required this.operations,
  });
}
