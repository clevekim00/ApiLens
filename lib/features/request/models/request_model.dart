import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'key_value_item.dart';

enum RequestBodyType { json, text, form, none }
enum AuthType { none, bearer, basic, apiKey }

@immutable
class RequestModel {
  final String id;
  final String name;
  final String method;
  final String url;
  final List<KeyValueItem> headers;
  final List<KeyValueItem> params; // Query Params
  final List<KeyValueItem> pathParams;
  final String? body;
  final RequestBodyType bodyType;
  final AuthType authType;
  final Map<String, String>? authData;
  final String? groupId;
  final Map<String, dynamic>? source; // Metadata like OpenAPI info

  const RequestModel({
    required this.id,
    this.name = 'New Request',
    this.method = 'GET',
    this.url = '',
    this.headers = const [],
    this.params = const [], // Query Params
    this.pathParams = const [],
    this.body,
    this.bodyType = RequestBodyType.json,
    this.authType = AuthType.none,
    this.authData,
    this.groupId,
    this.source,
  });

  factory RequestModel.initial({String? groupId}) {
    return RequestModel(
      id: const Uuid().v4(),
      headers: [KeyValueItem.initial()],
      params: [KeyValueItem.initial()],
      pathParams: [],
      groupId: groupId,
    );
  }

  RequestModel copyWith({
    String? id,
    String? name,
    String? method,
    String? url,
    List<KeyValueItem>? headers,
    List<KeyValueItem>? params, // Query
    List<KeyValueItem>? pathParams,
    String? body,
    RequestBodyType? bodyType,
    AuthType? authType,
    Map<String, String>? authData,
    String? groupId,
    Map<String, dynamic>? source,
  }) {
    return RequestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      params: params ?? this.params,
      pathParams: pathParams ?? this.pathParams,
      body: body ?? this.body,
      bodyType: bodyType ?? this.bodyType,
      authType: authType ?? this.authType,
      authData: authData ?? this.authData,
      groupId: groupId ?? this.groupId,
      source: source ?? this.source,
    );
  }

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'] as String,
      name: json['name'] as String,
      method: json['method'] as String,
      url: json['url'] as String,
      headers: (json['headers'] as List?)
          ?.map((e) => KeyValueItem.fromJson(e))
          .toList() ?? [],
      params: (json['params'] as List?) // Query
          ?.map((e) => KeyValueItem.fromJson(e))
          .toList() ?? [],
      pathParams: (json['pathParams'] as List?)
          ?.map((e) => KeyValueItem.fromJson(e))
          .toList() ?? [],
      body: json['body'] as String?,
      bodyType: RequestBodyType.values.firstWhere(
          (e) => e.toString() == 'RequestBodyType.${json['bodyType']}',
          orElse: () => RequestBodyType.json),
      authType: AuthType.values.firstWhere(
          (e) => e.toString() == 'AuthType.${json['authType']}',
          orElse: () => AuthType.none),
      authData: (json['authData'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      groupId: json['groupId'] as String?,
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'method': method,
      'url': url,
      'headers': headers.map((e) => e.toJson()).toList(),
      'params': params.map((e) => e.toJson()).toList(),
      'pathParams': pathParams.map((e) => e.toJson()).toList(),
      'body': body,
      'bodyType': bodyType.name,
      'authType': authType.name,
      'authData': authData,
      'groupId': groupId,
      'source': source,
    };
  }
}
