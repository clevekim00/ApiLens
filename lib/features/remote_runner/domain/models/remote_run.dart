import '../../../workflow_editor/domain/models/workflow.dart';
import 'load_profile.dart';
import 'run_shard.dart';

enum RemoteRunStatus {
  draft,
  planned,
  running,
  completed,
  failed,
  cancelled,
}

class RemoteRunDraft {
  final String id;
  final Workflow workflowSnapshot;
  final LoadProfile loadProfile;
  final Map<String, dynamic> env;
  final DateTime createdAt;

  const RemoteRunDraft({
    required this.id,
    required this.workflowSnapshot,
    required this.loadProfile,
    this.env = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'workflowSnapshot': workflowSnapshot.toJson(),
        'loadProfile': loadProfile.toJson(),
        'env': env,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RemoteRunDraft.fromJson(Map<String, dynamic> json) {
    return RemoteRunDraft(
      id: json['id'] as String? ?? '',
      workflowSnapshot: Workflow.fromJson(
        json['workflowSnapshot'] as Map<String, dynamic>? ?? const {},
      ),
      loadProfile: LoadProfile.fromJson(
        json['loadProfile'] as Map<String, dynamic>? ?? const {},
      ),
      env: json['env'] as Map<String, dynamic>? ?? const {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class RemoteRunPlan {
  final String id;
  final RemoteRunDraft draft;
  final List<RunShard> shards;
  final RemoteRunStatus status;
  final DateTime plannedAt;

  const RemoteRunPlan({
    required this.id,
    required this.draft,
    required this.shards,
    this.status = RemoteRunStatus.planned,
    required this.plannedAt,
  });

  RemoteRunPlan copyWith({
    String? id,
    RemoteRunDraft? draft,
    List<RunShard>? shards,
    RemoteRunStatus? status,
    DateTime? plannedAt,
  }) {
    return RemoteRunPlan(
      id: id ?? this.id,
      draft: draft ?? this.draft,
      shards: shards ?? this.shards,
      status: status ?? this.status,
      plannedAt: plannedAt ?? this.plannedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'draft': draft.toJson(),
        'shards': shards.map((shard) => shard.toJson()).toList(),
        'status': status.name,
        'plannedAt': plannedAt.toIso8601String(),
      };

  factory RemoteRunPlan.fromJson(Map<String, dynamic> json) {
    return RemoteRunPlan(
      id: json['id'] as String? ?? '',
      draft: RemoteRunDraft.fromJson(
        json['draft'] as Map<String, dynamic>? ?? const {},
      ),
      shards: (json['shards'] as List?)
              ?.map((item) => RunShard.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      status: RemoteRunStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RemoteRunStatus.planned,
      ),
      plannedAt: json['plannedAt'] != null
          ? DateTime.parse(json['plannedAt'] as String)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
