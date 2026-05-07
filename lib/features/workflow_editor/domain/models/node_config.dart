import 'dart:convert';

abstract class NodeConfig {
  Map<String, dynamic> toJson();

  ExecutionPolicy get executionPolicy => const ExecutionPolicy();
}

class RetryPolicy {
  final int maxAttempts;
  final int backoffMs;
  final List<int> retryOnStatusCodes;
  final bool retryOnTimeout;

  const RetryPolicy({
    this.maxAttempts = 0,
    this.backoffMs = 250,
    this.retryOnStatusCodes = const [408, 429, 500, 502, 503, 504],
    this.retryOnTimeout = true,
  });

  Map<String, dynamic> toJson() => {
        'maxAttempts': maxAttempts,
        'backoffMs': backoffMs,
        'retryOnStatusCodes': retryOnStatusCodes,
        'retryOnTimeout': retryOnTimeout,
      };

  factory RetryPolicy.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RetryPolicy();

    return RetryPolicy(
      maxAttempts: (json['maxAttempts'] as num?)?.toInt() ?? 0,
      backoffMs: (json['backoffMs'] as num?)?.toInt() ?? 250,
      retryOnStatusCodes: (json['retryOnStatusCodes'] as List?)
              ?.map((value) => (value as num).toInt())
              .toList() ??
          const [408, 429, 500, 502, 503, 504],
      retryOnTimeout: json['retryOnTimeout'] as bool? ?? true,
    );
  }
}

class ExecutionPolicy {
  final int? timeoutMs;
  final RetryPolicy retry;

  const ExecutionPolicy({
    this.timeoutMs,
    this.retry = const RetryPolicy(),
  });

  Map<String, dynamic> toJson() => {
        'timeoutMs': timeoutMs,
        'retry': retry.toJson(),
      };

  ExecutionPolicy copyWith({
    int? timeoutMs,
    RetryPolicy? retry,
  }) {
    return ExecutionPolicy(
      timeoutMs: timeoutMs ?? this.timeoutMs,
      retry: retry ?? this.retry,
    );
  }

  factory ExecutionPolicy.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ExecutionPolicy();

    return ExecutionPolicy(
      timeoutMs: (json['timeoutMs'] as num?)?.toInt(),
      retry: RetryPolicy.fromJson(json['retry'] as Map<String, dynamic>?),
    );
  }
}

class HttpNodeConfig implements NodeConfig {
  final String url;
  final String method;
  final Map<String, String>? headers;
  final String? body;
  @override
  final ExecutionPolicy executionPolicy;

  HttpNodeConfig({
    required this.url,
    required this.method,
    this.headers,
    this.body,
    this.executionPolicy = const ExecutionPolicy(),
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'http',
        'url': url,
        'method': method,
        'headers': headers,
        'body': body,
        'execution': executionPolicy.toJson(),
      };

  factory HttpNodeConfig.fromJson(Map<String, dynamic> json) => HttpNodeConfig(
        url: json['url'] as String,
        method: json['method'] as String,
        headers:
            (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
        body: json['body'] as String?,
        executionPolicy: ExecutionPolicy.fromJson(
            json['execution'] as Map<String, dynamic>?),
      );
}

class ConditionNodeConfig implements NodeConfig {
  final String expression;
  @override
  final ExecutionPolicy executionPolicy;

  ConditionNodeConfig({
    required this.expression,
    this.executionPolicy = const ExecutionPolicy(),
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'condition',
        'expression': expression,
        'execution': executionPolicy.toJson(),
      };

  factory ConditionNodeConfig.fromJson(Map<String, dynamic> json) =>
      ConditionNodeConfig(
        expression: json['expression'] as String,
        executionPolicy: ExecutionPolicy.fromJson(
            json['execution'] as Map<String, dynamic>?),
      );
}

// WebSocket Configs
// WebSocket Configs

class WebSocketConnectNodeConfig implements NodeConfig {
  final String mode; // 'direct' | 'configRef'
  final String? url; // for direct
  final String? configRefId; // for configRef
  final List<String> protocols;
  final bool autoReconnect;
  final Map<String, dynamic> reconnectPolicy; // { maxAttempts, backoffMs }
  final String storeAs; // sessionKey
  final Map<String, String>? headers;
  @override
  final ExecutionPolicy executionPolicy;

  WebSocketConnectNodeConfig({
    this.mode = 'direct',
    this.url,
    this.configRefId,
    this.protocols = const [],
    this.autoReconnect = false,
    this.reconnectPolicy = const {'maxAttempts': 0, 'backoffMs': 0},
    this.storeAs = 'mainWs',
    this.headers,
    this.executionPolicy = const ExecutionPolicy(),
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ws_connect',
        'mode': mode,
        'url': url,
        'configRefId': configRefId,
        'protocols': protocols,
        'autoReconnect': autoReconnect,
        'reconnectPolicy': reconnectPolicy,
        'storeAs': storeAs,
        'headers': headers,
        'execution': executionPolicy.toJson(),
      };

  factory WebSocketConnectNodeConfig.fromJson(Map<String, dynamic> json) =>
      WebSocketConnectNodeConfig(
        mode: json['mode'] as String? ?? 'direct',
        url: json['url'] as String?,
        configRefId: json['configRefId'] as String?,
        protocols: (json['protocols'] as List?)?.cast<String>() ?? const [],
        autoReconnect: json['autoReconnect'] as bool? ?? false,
        reconnectPolicy: json['reconnectPolicy'] as Map<String, dynamic>? ??
            const {'maxAttempts': 0, 'backoffMs': 0},
        storeAs: json['storeAs'] as String? ?? 'mainWs',
        headers:
            (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
        executionPolicy: ExecutionPolicy.fromJson(
            json['execution'] as Map<String, dynamic>?),
      );
}

class WebSocketSendNodeConfig implements NodeConfig {
  final String sessionKey;
  final String payloadFormat; // 'text' | 'json'
  final String payload;
  @override
  final ExecutionPolicy executionPolicy;

  WebSocketSendNodeConfig({
    required this.sessionKey,
    this.payloadFormat = 'text',
    required this.payload,
    this.executionPolicy = const ExecutionPolicy(),
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ws_send',
        'sessionKey': sessionKey,
        'payloadFormat': payloadFormat,
        'payload': payload,
        'execution': executionPolicy.toJson(),
      };

  factory WebSocketSendNodeConfig.fromJson(Map<String, dynamic> json) =>
      WebSocketSendNodeConfig(
        sessionKey: json['sessionKey'] as String? ?? 'mainWs',
        payloadFormat: json['payloadFormat'] as String? ?? 'text',
        payload: (json['payload'] ?? json['message'])
            as String, // failover for backward compat
        executionPolicy: ExecutionPolicy.fromJson(
            json['execution'] as Map<String, dynamic>?),
      );
}

class WebSocketWaitNodeConfig implements NodeConfig {
  final String sessionKey;
  final int timeoutMs;
  final Map<String, dynamic> match; // { type: "containsText", value: "Pong" }
  @override
  final ExecutionPolicy executionPolicy;

  WebSocketWaitNodeConfig({
    required this.sessionKey,
    this.timeoutMs = 5000,
    required this.match,
    ExecutionPolicy? executionPolicy,
  }) : executionPolicy =
            executionPolicy ?? ExecutionPolicy(timeoutMs: timeoutMs);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'ws_wait',
        'sessionKey': sessionKey,
        'timeoutMs': timeoutMs,
        'match': match,
        'execution': executionPolicy.toJson(),
      };

  factory WebSocketWaitNodeConfig.fromJson(Map<String, dynamic> json) =>
      WebSocketWaitNodeConfig(
        sessionKey: json['sessionKey'] as String? ?? 'mainWs',
        timeoutMs: (json['timeoutMs'] as int?) ?? 5000,
        match: json['match'] is String
            ? {
                'type': 'containsText',
                'value': json['match']
              } // Backward compat
            : json['match'] as Map<String, dynamic>,
        executionPolicy:
            ExecutionPolicy.fromJson(json['execution'] as Map<String, dynamic>?)
                .copyWith(timeoutMs: (json['timeoutMs'] as int?) ?? 5000),
      );
}

class GraphQLNodeConfig implements NodeConfig {
  final String mode; // 'direct' | 'configRef'
  final String? endpoint; // for direct
  final String? configRefId; // for configRef
  final Map<String, String>? headers;
  final Map<String, dynamic>
      auth; // {type: 'none'|'bearer'|'basic'|'apiKey', ...}
  final String query;
  final String variablesJson;
  final String storeAs;
  @override
  final ExecutionPolicy executionPolicy;

  GraphQLNodeConfig({
    this.mode = 'direct',
    this.endpoint,
    this.configRefId,
    this.headers,
    this.auth = const {'type': 'none'},
    this.query = '',
    this.variablesJson = '{}',
    this.storeAs = 'gqlResult',
    this.executionPolicy = const ExecutionPolicy(),
  });

  String get url => endpoint ?? '';

  Map<String, dynamic> get variables {
    try {
      if (variablesJson.trim().isEmpty) return {};
      return Map<String, dynamic>.from(jsonDecode(variablesJson));
    } catch (_) {
      return {};
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': 'gql_request',
        'mode': mode,
        'endpoint': endpoint,
        'configRefId': configRefId,
        'headers': headers,
        'auth': auth,
        'query': query,
        'variablesJson': variablesJson,
        'storeAs': storeAs,
        'execution': executionPolicy.toJson(),
      };

  factory GraphQLNodeConfig.fromJson(Map<String, dynamic> json) {
    final legacyConfig = json['config'] is Map
        ? Map<String, dynamic>.from(json['config'] as Map)
        : null;
    final source = legacyConfig ?? json;

    return GraphQLNodeConfig(
      mode: source['mode'] as String? ?? 'direct',
      endpoint: (source['endpoint'] ?? source['url']) as String?,
      configRefId: source['configRefId'] as String?,
      headers:
          (source['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
      auth: Map<String, dynamic>.from(source['auth'] ?? {'type': 'none'}),
      query: source['query'] ?? '',
      variablesJson: source['variablesJson'] ?? '{}',
      storeAs: source['storeAs'] ?? 'gqlResult',
      executionPolicy:
          ExecutionPolicy.fromJson(json['execution'] as Map<String, dynamic>?),
    );
  }
}

class EmptyNodeConfig implements NodeConfig {
  const EmptyNodeConfig();

  @override
  ExecutionPolicy get executionPolicy => const ExecutionPolicy();

  @override
  Map<String, dynamic> toJson() => {'type': 'empty'};
}
