import '../../workflow_editor/domain/models/workflow.dart';
import '../domain/models/load_profile.dart';
import '../domain/models/remote_agent.dart';

enum RemoteRunValidationSeverity {
  warning,
  error,
}

class RemoteRunValidationIssue {
  final RemoteRunValidationSeverity severity;
  final String code;
  final String message;

  const RemoteRunValidationIssue({
    required this.severity,
    required this.code,
    required this.message,
  });

  bool get isError => severity == RemoteRunValidationSeverity.error;
}

class RemoteRunValidationResult {
  final List<RemoteRunValidationIssue> issues;

  const RemoteRunValidationResult(this.issues);

  bool get isValid => errors.isEmpty;

  List<RemoteRunValidationIssue> get errors {
    return issues.where((issue) => issue.isError).toList();
  }

  List<RemoteRunValidationIssue> get warnings {
    return issues.where((issue) => !issue.isError).toList();
  }
}

class RemoteRunValidator {
  const RemoteRunValidator();

  RemoteRunValidationResult validate({
    required Workflow workflow,
    required LoadProfile loadProfile,
    required List<RemoteAgent> agents,
  }) {
    final issues = <RemoteRunValidationIssue>[
      ..._validateWorkflow(workflow),
      ..._validateLoadProfile(loadProfile),
      ..._validateAgents(workflow, loadProfile, agents),
    ];

    return RemoteRunValidationResult(issues);
  }

  List<RemoteRunValidationIssue> _validateWorkflow(Workflow workflow) {
    final issues = <RemoteRunValidationIssue>[];

    if (workflow.nodes.isEmpty) {
      issues.add(const RemoteRunValidationIssue(
        severity: RemoteRunValidationSeverity.error,
        code: 'workflow.empty',
        message: '워크플로우에 노드가 없습니다.',
      ));
      return issues;
    }

    final startNodes = workflow.nodes.where((node) => node.type == 'start');
    if (startNodes.length != 1) {
      issues.add(RemoteRunValidationIssue(
        severity: RemoteRunValidationSeverity.error,
        code: 'workflow.start_node_count',
        message: '워크플로우에는 start 노드가 정확히 1개 있어야 합니다. '
            '현재 ${startNodes.length}개입니다.',
      ));
    }

    final nodeIds = workflow.nodes.map((node) => node.id).toSet();
    for (final edge in workflow.edges) {
      if (!nodeIds.contains(edge.sourceNodeId)) {
        issues.add(RemoteRunValidationIssue(
          severity: RemoteRunValidationSeverity.error,
          code: 'workflow.edge_missing_source',
          message: '엣지 ${edge.id}의 source node가 존재하지 않습니다.',
        ));
      }
      if (!nodeIds.contains(edge.targetNodeId)) {
        issues.add(RemoteRunValidationIssue(
          severity: RemoteRunValidationSeverity.error,
          code: 'workflow.edge_missing_target',
          message: '엣지 ${edge.id}의 target node가 존재하지 않습니다.',
        ));
      }
    }

    final executableNodes = workflow.nodes.where((node) {
      return node.type != 'start' && node.type != 'end';
    });
    if (executableNodes.isEmpty) {
      issues.add(const RemoteRunValidationIssue(
        severity: RemoteRunValidationSeverity.warning,
        code: 'workflow.no_executable_nodes',
        message: '원격에서 실행할 요청 노드가 없습니다.',
      ));
    }

    return issues;
  }

  List<RemoteRunValidationIssue> _validateLoadProfile(
    LoadProfile loadProfile,
  ) {
    final issues = <RemoteRunValidationIssue>[];

    if (loadProfile.virtualUsers <= 0) {
      issues.add(const RemoteRunValidationIssue(
        severity: RemoteRunValidationSeverity.error,
        code: 'load_profile.virtual_users',
        message: 'virtual users는 1 이상이어야 합니다.',
      ));
    }
    if (loadProfile.durationSeconds <= 0 && loadProfile.iterations <= 0) {
      issues.add(const RemoteRunValidationIssue(
        severity: RemoteRunValidationSeverity.error,
        code: 'load_profile.duration_or_iterations',
        message: 'durationSeconds 또는 iterations 중 하나는 1 이상이어야 합니다.',
      ));
    }
    if (loadProfile.rampUpSeconds < 0) {
      issues.add(const RemoteRunValidationIssue(
        severity: RemoteRunValidationSeverity.error,
        code: 'load_profile.ramp_up',
        message: 'rampUpSeconds는 음수일 수 없습니다.',
      ));
    }
    if (loadProfile.thinkTimeMs < 0) {
      issues.add(const RemoteRunValidationIssue(
        severity: RemoteRunValidationSeverity.error,
        code: 'load_profile.think_time',
        message: 'thinkTimeMs는 음수일 수 없습니다.',
      ));
    }
    if (loadProfile.concurrencyCap != null &&
        loadProfile.concurrencyCap! <= 0) {
      issues.add(const RemoteRunValidationIssue(
        severity: RemoteRunValidationSeverity.error,
        code: 'load_profile.concurrency_cap',
        message: 'concurrencyCap은 null이거나 1 이상이어야 합니다.',
      ));
    }

    return issues;
  }

  List<RemoteRunValidationIssue> _validateAgents(
    Workflow workflow,
    LoadProfile loadProfile,
    List<RemoteAgent> agents,
  ) {
    final issues = <RemoteRunValidationIssue>[];
    final schedulableAgents =
        agents.where((agent) => agent.isSchedulable).toList();

    if (schedulableAgents.isEmpty) {
      issues.add(const RemoteRunValidationIssue(
        severity: RemoteRunValidationSeverity.error,
        code: 'agents.none_schedulable',
        message: '실행 가능한 원격 에이전트가 없습니다.',
      ));
      return issues;
    }

    final totalVirtualUserCapacity = schedulableAgents.fold<int>(
      0,
      (sum, agent) => sum + agent.capacity.maxVirtualUsers,
    );
    if (totalVirtualUserCapacity < loadProfile.virtualUsers) {
      issues.add(RemoteRunValidationIssue(
        severity: RemoteRunValidationSeverity.error,
        code: 'agents.capacity_insufficient',
        message: '에이전트 총 VU 용량($totalVirtualUserCapacity)이 요청 VU'
            '(${loadProfile.virtualUsers})보다 작습니다.',
      ));
    }

    final nodeTypes = workflow.nodes
        .where((node) => node.type != 'start' && node.type != 'end')
        .map((node) => node.type)
        .toSet();
    final unsupportedTypes = nodeTypes.where((type) {
      return schedulableAgents.every((agent) => !agent.supportsNodeType(type));
    }).toList();

    if (unsupportedTypes.isNotEmpty) {
      issues.add(RemoteRunValidationIssue(
        severity: RemoteRunValidationSeverity.error,
        code: 'agents.unsupported_node_types',
        message: '실행 가능한 에이전트가 지원하지 않는 노드 타입이 있습니다: '
            '${unsupportedTypes.join(', ')}',
      ));
    }

    return issues;
  }
}
