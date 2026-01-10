import 'package:hive/hive.dart';
import 'node_port.dart';
import 'node_config.dart';

part 'workflow_node.g.dart';

@HiveType(typeId: 1)
class WorkflowNode {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final double x;

  @HiveField(3)
  final double y;

  // Keep 'data' for Hive backward compatibility if needed, 
  // but logically strictly mapped to `config`.
  // For this refactor, we replace the Map<String, dynamic> with NodeConfig wrapper or keep Map but add helpers.
  // Requirement says: "Common fields... inputPorts, outputPorts".
  
  // Since Hive can't store Polymorphic classes easily without distinct Adapters or wrappers, 
  // we will map `config` to a generic Map structure for storage properties, and expose typed getters.
  @HiveField(4)
  final Map<String, dynamic> data;

  @HiveField(5)
  final List<String> inputPortKeys;

  @HiveField(6)
  final List<String> outputPortKeys;

  // Transient / Computed properties for UI usage
  List<NodePort> get inputs {
    // Basic logic mapping keys to default ports based on Key
    // Real impl might store label separately.
    return inputPortKeys.map((k) => NodePort(key: k, label: k)).toList();
  }
  
  List<NodePort> get outputs {
     return outputPortKeys.map((k) => NodePort(key: k, label: k)).toList();
  }

  // Typed config helper
  NodeConfig get config {
    if (type == 'api') return HttpNodeConfig.fromJson(data);
    if (type == 'condition') return ConditionNodeConfig.fromJson(data);
    return const EmptyNodeConfig();
  }

  WorkflowNode({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    this.data = const {},
    List<String>? inputPortKeys,
    List<String>? outputPortKeys,
  }) : 
    this.inputPortKeys = inputPortKeys ?? _defaultInputs(type),
    this.outputPortKeys = outputPortKeys ?? _defaultOutputs(type);

  static List<String> _defaultInputs(String type) {
    if (type == 'start') return [];
    return ['input'];
  }

  static List<String> _defaultOutputs(String type) {
    if (type == 'end') return [];
    if (type == 'condition') return ['true', 'false'];
    if (type == 'api') return ['success', 'failure'];
    return ['output'];
  }
  
  WorkflowNode copyWith({
    String? id,
    String? type,
    double? x,
    double? y,
    Map<String, dynamic>? data,
  }) {
    return WorkflowNode(
      id: id ?? this.id,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      data: data ?? this.data,
      inputPortKeys: this.inputPortKeys,
      outputPortKeys: this.outputPortKeys,
    );
  }

  // toJson
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'x': x,
    'y': y,
    'data': data,
    'inputs': inputPortKeys,
    'outputs': outputPortKeys,
  };

  factory WorkflowNode.fromJson(Map<String, dynamic> json) {
    return WorkflowNode(
      id: json['id'],
      type: json['type'],
      x: json['x'],
      y: json['y'],
      data: json['data'] ?? {},
      inputPortKeys: (json['inputs'] as List?)?.cast<String>(),
      outputPortKeys: (json['outputs'] as List?)?.cast<String>(),
    );
  }
}
