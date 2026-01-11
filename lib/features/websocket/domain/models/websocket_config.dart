import 'package:uuid/uuid.dart';

enum WebSocketAuthType { none, bearer, basic, apiKey }

class WebSocketAuthConfig {
  final WebSocketAuthType type;
  final String? token; // For Bearer
  final String? username; // For Basic
  final String? password; // For Basic
  final String? key; // For ApiKey
  final String? value; // For ApiKey
  final String? addTo; // 'header' or 'query' for ApiKey

  const WebSocketAuthConfig({
    this.type = WebSocketAuthType.none,
    this.token,
    this.username,
    this.password,
    this.key,
    this.value,
    this.addTo,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    if (token != null) 'token': token,
    if (username != null) 'username': username,
    if (password != null) 'password': password,
    if (key != null) 'key': key,
    if (value != null) 'value': value,
    if (addTo != null) 'addTo': addTo,
  };

  factory WebSocketAuthConfig.fromJson(Map<String, dynamic> json) {
    return WebSocketAuthConfig(
      type: WebSocketAuthType.values.byName(json['type'] ?? 'none'),
      token: json['token'],
      username: json['username'],
      password: json['password'],
      key: json['key'],
      value: json['value'],
      addTo: json['addTo'],
    );
  }
}

class WebSocketReconnectConfig {
  final int maxAttempts;
  final int backoffMs;

  const WebSocketReconnectConfig({
    this.maxAttempts = 3,
    this.backoffMs = 1000,
  });

  Map<String, dynamic> toJson() => {
    'maxAttempts': maxAttempts,
    'backoffMs': backoffMs,
  };

  factory WebSocketReconnectConfig.fromJson(Map<String, dynamic> json) =>
      WebSocketReconnectConfig(
        maxAttempts: json['maxAttempts'] ?? 3,
        backoffMs: json['backoffMs'] ?? 1000,
      );
}

class WebSocketConfig {
  final String id;
  final String name;
  final String url;
  final List<String> protocols;
  final Map<String, String> headers;
  final WebSocketAuthConfig auth;
  final bool autoReconnect;
  final WebSocketReconnectConfig reconnect;
  final DateTime createdAt;
  final DateTime updatedAt;

  WebSocketConfig({
    required this.id,
    required this.name,
    required this.url,
    this.protocols = const [],
    this.headers = const {},
    this.auth = const WebSocketAuthConfig(),
    this.autoReconnect = false,
    this.reconnect = const WebSocketReconnectConfig(),
    required this.createdAt,
    required this.updatedAt,
  });

  factory WebSocketConfig.create({
    required String name,
    required String url,
  }) {
    final now = DateTime.now();
    return WebSocketConfig(
      id: const Uuid().v4(),
      name: name,
      url: url,
      createdAt: now,
      updatedAt: now,
    );
  }

  WebSocketConfig copyWith({
    String? name,
    String? url,
    List<String>? protocols,
    Map<String, String>? headers,
    WebSocketAuthConfig? auth,
    bool? autoReconnect,
    WebSocketReconnectConfig? reconnect,
  }) {
    return WebSocketConfig(
      id: id,
      name: name ?? this.name,
      url: url ?? this.url,
      protocols: protocols ?? this.protocols,
      headers: headers ?? this.headers,
      auth: auth ?? this.auth,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      reconnect: reconnect ?? this.reconnect,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'protocols': protocols,
      'headers': headers,
      'auth': auth.toJson(),
      'autoReconnect': autoReconnect,
      'reconnect': reconnect.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WebSocketConfig.fromJson(Map<String, dynamic> json) {
    return WebSocketConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      protocols: (json['protocols'] as List<dynamic>?)?.cast<String>() ?? [],
      headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>() ?? {},
      auth: json['auth'] != null
          ? WebSocketAuthConfig.fromJson(json['auth'])
          : const WebSocketAuthConfig(),
      autoReconnect: json['autoReconnect'] ?? false,
      reconnect: json['reconnect'] != null
          ? WebSocketReconnectConfig.fromJson(json['reconnect'])
          : const WebSocketReconnectConfig(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
