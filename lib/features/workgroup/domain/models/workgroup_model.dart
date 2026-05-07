import 'package:uuid/uuid.dart';

enum WorkgroupType { requestCollection, workflowCollection, custom }

class WorkgroupModel {
  final String id;
  final String name;
  final String description;
  final String? parentId;
  final WorkgroupType type;
  final String? icon;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkgroupModel({
    required this.id,
    required this.name,
    this.description = '',
    this.parentId,
    required this.type,
    this.icon,
    this.isSystem = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WorkgroupModel.create({
    required String name,
    required WorkgroupType type,
    String? parentId,
    String description = '',
  }) {
    final now = DateTime.now();
    return WorkgroupModel(
      id: const Uuid().v4(),
      name: name,
      description: description,
      type: type,
      parentId: parentId,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory WorkgroupModel.systemRoot() {
    final now = DateTime.now();
    return WorkgroupModel(
      id: 'no-workgroup',
      name: 'No Workgroup',
      description: 'System default group',
      type: WorkgroupType.requestCollection,
      isSystem: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  WorkgroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? parentId,
    String? icon,
    bool? isSystem,
    DateTime? updatedAt,
  }) {
    return WorkgroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      parentId: parentId ?? this.parentId,
      type: type,
      icon: icon ?? this.icon,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parentId': parentId,
      'type': type.name,
      'icon': icon,
      'isSystem': isSystem,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WorkgroupModel.fromJson(Map<String, dynamic> json) {
    return WorkgroupModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled',
      description: json['description'] as String? ?? '',
      parentId: json['parentId'] as String?,
      type: WorkgroupType.values.firstWhere((e) => e.name == json['type'],
          orElse: () => WorkgroupType.requestCollection),
      icon: json['icon'] as String?,
      isSystem: json['isSystem'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : (json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now()),
    );
  }
}
