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

class EmptyNodeConfig implements NodeConfig {
  const EmptyNodeConfig();
  
  @override
  Map<String, dynamic> toJson() => {'type': 'empty'};
}
