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
  final List<KeyValueItem> params;
  final String? body;
  final RequestBodyType bodyType;
  final AuthType authType;
  final Map<String, String>? authData; // Store auth details like token, username/password

  const RequestModel({
    required this.id,
    this.name = 'New Request',
    this.method = 'GET',
    this.url = '',
    this.headers = const [],
    this.params = const [],
    this.body,
    this.bodyType = RequestBodyType.json,
    this.authType = AuthType.none,
    this.authData,
  });

  factory RequestModel.initial() {
    return RequestModel(
      id: const Uuid().v4(),
      headers: [KeyValueItem.initial()],
      params: [KeyValueItem.initial()],
    );
  }

  RequestModel copyWith({
    String? id,
    String? name,
    String? method,
    String? url,
    List<KeyValueItem>? headers,
    List<KeyValueItem>? params,
    String? body,
    RequestBodyType? bodyType,
    AuthType? authType,
    Map<String, String>? authData,
  }) {
    return RequestModel(
      id: id ?? this.id,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      params: params ?? this.params,
      body: body ?? this.body,
      bodyType: bodyType ?? this.bodyType,
      authType: authType ?? this.authType,
      authData: authData ?? this.authData,
    );
  }
}
