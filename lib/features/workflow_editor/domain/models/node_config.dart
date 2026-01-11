abstract class NodeConfig {
  Map<String, dynamic> toJson();
}

class HttpNodeConfig implements NodeConfig {
  final String url;
  final String method;
  final Map<String, String>? headers;
  final String? body;

  HttpNodeConfig({
    required this.url,
    required this.method,
    this.headers,
    this.body,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'http',
    'url': url,
    'method': method,
    'headers': headers,
    'body': body,
  };

  factory HttpNodeConfig.fromJson(Map<String, dynamic> json) => HttpNodeConfig(
    url: json['url'] as String,
    method: json['method'] as String,
    headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
    body: json['body'] as String?,
  );
}

class ConditionNodeConfig implements NodeConfig {
  final String expression;

  ConditionNodeConfig({required this.expression});

  @override
  Map<String, dynamic> toJson() => {
    'type': 'condition',
    'expression': expression,
  };

  factory ConditionNodeConfig.fromJson(Map<String, dynamic> json) => ConditionNodeConfig(
    expression: json['expression'] as String,
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

  WebSocketConnectNodeConfig({
    this.mode = 'direct',
    this.url,
    this.configRefId,
    this.protocols = const [],
    this.autoReconnect = false,
    this.reconnectPolicy = const {'maxAttempts': 0, 'backoffMs': 0},
    this.storeAs = 'mainWs',
    this.headers,
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
  };

  factory WebSocketConnectNodeConfig.fromJson(Map<String, dynamic> json) => WebSocketConnectNodeConfig(
    mode: json['mode'] as String? ?? 'direct',
    url: json['url'] as String?,
    configRefId: json['configRefId'] as String?,
    protocols: (json['protocols'] as List?)?.cast<String>() ?? const [],
    autoReconnect: json['autoReconnect'] as bool? ?? false,
    reconnectPolicy: json['reconnectPolicy'] as Map<String, dynamic>? ?? const {'maxAttempts': 0, 'backoffMs': 0},
    storeAs: json['storeAs'] as String? ?? 'mainWs',
    headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
  );
}

class WebSocketSendNodeConfig implements NodeConfig {
  final String sessionKey;
  final String payloadFormat; // 'text' | 'json'
  final String payload;

  WebSocketSendNodeConfig({
    required this.sessionKey,
    this.payloadFormat = 'text',
    required this.payload,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'ws_send',
    'sessionKey': sessionKey,
    'payloadFormat': payloadFormat,
    'payload': payload,
  };

  factory WebSocketSendNodeConfig.fromJson(Map<String, dynamic> json) => WebSocketSendNodeConfig(
    sessionKey: json['sessionKey'] as String? ?? 'mainWs',
    payloadFormat: json['payloadFormat'] as String? ?? 'text',
    payload: (json['payload'] ?? json['message']) as String, // failover for backward compat
  );
}

class WebSocketWaitNodeConfig implements NodeConfig {
  final String sessionKey;
  final int timeoutMs;
  final Map<String, dynamic> match; // { type: "containsText", value: "Pong" }

  WebSocketWaitNodeConfig({
    required this.sessionKey,
    this.timeoutMs = 5000,
    required this.match,
  });

  @override
  Map<String, dynamic> toJson() => {
    'type': 'ws_wait',
    'sessionKey': sessionKey,
    'timeoutMs': timeoutMs,
    'match': match,
  };

  factory WebSocketWaitNodeConfig.fromJson(Map<String, dynamic> json) => WebSocketWaitNodeConfig(
    sessionKey: json['sessionKey'] as String? ?? 'mainWs',
    timeoutMs: (json['timeoutMs'] as int?) ?? 5000,
    match: json['match'] is String 
        ? {'type': 'containsText', 'value': json['match']} // Backward compat
        : json['match'] as Map<String, dynamic>,
  );
}

class GraphQLNodeConfig implements NodeConfig {
  final String mode; // 'direct' | 'configRef'
  final String? endpoint; // for direct
  final String? configRefId; // for configRef
  final Map<String, String>? headers;
  final Map<String, dynamic> auth; // {type: 'none'|'bearer'|'basic'|'apiKey', ...}
  final String query;
  final String variablesJson;
  final String storeAs;

  GraphQLNodeConfig({
    this.mode = 'direct',
    this.endpoint,
    this.configRefId,
    this.headers,
    this.auth = const {'type': 'none'},
    this.query = '',
    this.variablesJson = '{}',
    this.storeAs = 'gqlResult',
  });

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
  };

  factory GraphQLNodeConfig.fromJson(Map<String, dynamic> json) => GraphQLNodeConfig(
    mode: json['mode'] as String? ?? 'direct',
    endpoint: json['endpoint'] as String?,
    configRefId: json['configRefId'] as String?,
    headers: (json['headers'] as Map<String, dynamic>?)?.cast<String, String>(),
    auth: Map<String, dynamic>.from(json['auth'] ?? {'type': 'none'}),
    query: json['query'] ?? '',
    variablesJson: json['variablesJson'] ?? '{}',
    storeAs: json['storeAs'] ?? 'gqlResult',
  );
}

class EmptyNodeConfig implements NodeConfig {
  const EmptyNodeConfig();
  
  @override
  Map<String, dynamic> toJson() => {'type': 'empty'};
}
