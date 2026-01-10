class NodePort {
  final String key;
  final String label;
  final bool isMulti;

  const NodePort({
    required this.key,
    required this.label,
    this.isMulti = false,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'isMulti': isMulti,
  };

  factory NodePort.fromJson(Map<String, dynamic> json) => NodePort(
    key: json['key'] as String,
    label: json['label'] as String,
    isMulti: json['isMulti'] as bool? ?? false,
  );
}
