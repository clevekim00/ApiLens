import '../domain/models/load_profile.dart';
import '../domain/models/remote_agent.dart';
import '../domain/models/remote_run.dart';
import '../domain/models/run_shard.dart';

class RemoteRunPlanningFailure implements Exception {
  final String code;
  final String message;

  const RemoteRunPlanningFailure({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'RemoteRunPlanningFailure($code): $message';
}

class RemoteRunPlanner {
  const RemoteRunPlanner();

  RemoteRunPlan plan({
    required RemoteRunDraft draft,
    required List<RemoteAgent> agents,
    DateTime? plannedAt,
  }) {
    final eligibleAgents = agents.where((agent) => agent.isSchedulable).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (eligibleAgents.isEmpty) {
      throw const RemoteRunPlanningFailure(
        code: 'agents.none_schedulable',
        message: '실행 가능한 원격 에이전트가 없습니다.',
      );
    }

    final loadProfile = draft.loadProfile;
    final totalCapacity = eligibleAgents.fold<int>(
      0,
      (sum, agent) => sum + agent.capacity.maxVirtualUsers,
    );
    if (totalCapacity < loadProfile.virtualUsers) {
      throw RemoteRunPlanningFailure(
        code: 'agents.capacity_insufficient',
        message: '에이전트 총 VU 용량($totalCapacity)이 요청 VU'
            '(${loadProfile.virtualUsers})보다 작습니다.',
      );
    }

    final allocations = _allocateVirtualUsers(loadProfile, eligibleAgents);
    final shards = <RunShard>[];
    var nextVu = 1;
    var shardIndex = 1;
    for (final agent in eligibleAgents) {
      final vuCount = allocations[agent.id] ?? 0;
      if (vuCount <= 0) continue;

      final range = VirtualUserRange(
        startInclusive: nextVu,
        endInclusive: nextVu + vuCount - 1,
      );
      shards.add(RunShard(
        id: _shardId(draft.id, shardIndex),
        runId: draft.id,
        agentId: agent.id,
        virtualUserRange: range,
        rampUpOffsetMs: _rampUpOffsetMs(loadProfile, range.startInclusive),
        durationSeconds: loadProfile.durationSeconds,
        concurrencyLimit: _concurrencyLimit(loadProfile, agent, vuCount),
      ));
      nextVu += vuCount;
      shardIndex++;
    }

    return RemoteRunPlan(
      id: '${draft.id}-plan',
      draft: draft,
      shards: shards,
      plannedAt: plannedAt ?? DateTime.now(),
    );
  }

  Map<String, int> _allocateVirtualUsers(
    LoadProfile loadProfile,
    List<RemoteAgent> agents,
  ) {
    switch (loadProfile.distributionPolicy) {
      case LoadDistributionPolicy.equalSplit:
        return _equalSplit(loadProfile.virtualUsers, agents);
      case LoadDistributionPolicy.capacityWeighted:
        return _capacityWeightedSplit(loadProfile.virtualUsers, agents);
    }
  }

  Map<String, int> _equalSplit(int virtualUsers, List<RemoteAgent> agents) {
    final base = virtualUsers ~/ agents.length;
    var remainder = virtualUsers % agents.length;
    return {
      for (final agent in agents) agent.id: base + (remainder-- > 0 ? 1 : 0),
    };
  }

  Map<String, int> _capacityWeightedSplit(
    int virtualUsers,
    List<RemoteAgent> agents,
  ) {
    final totalCapacity = agents.fold<int>(
      0,
      (sum, agent) => sum + agent.capacity.maxVirtualUsers,
    );
    final allocations = <String, int>{};
    final fractions = <_AllocationFraction>[];
    var assigned = 0;

    for (final agent in agents) {
      final exact =
          virtualUsers * agent.capacity.maxVirtualUsers / totalCapacity;
      final floor = exact.floor();
      allocations[agent.id] = floor;
      assigned += floor;
      fractions.add(_AllocationFraction(
        agentId: agent.id,
        fraction: exact - floor,
      ));
    }

    fractions.sort((a, b) {
      final fractionCompare = b.fraction.compareTo(a.fraction);
      if (fractionCompare != 0) return fractionCompare;
      return a.agentId.compareTo(b.agentId);
    });

    var remaining = virtualUsers - assigned;
    var index = 0;
    while (remaining > 0) {
      final agentId = fractions[index % fractions.length].agentId;
      allocations[agentId] = (allocations[agentId] ?? 0) + 1;
      remaining--;
      index++;
    }

    return allocations;
  }

  int _rampUpOffsetMs(LoadProfile loadProfile, int startVirtualUser) {
    if (loadProfile.rampUpSeconds <= 0 || loadProfile.virtualUsers <= 1) {
      return 0;
    }
    final ratio = (startVirtualUser - 1) / loadProfile.virtualUsers;
    return (ratio * loadProfile.rampUpSeconds * 1000).round();
  }

  int _concurrencyLimit(
    LoadProfile loadProfile,
    RemoteAgent agent,
    int shardVirtualUsers,
  ) {
    final profileCap = loadProfile.concurrencyCap;
    final localLimit = profileCap == null
        ? shardVirtualUsers
        : (profileCap < shardVirtualUsers ? profileCap : shardVirtualUsers);
    return localLimit < agent.capacity.maxConcurrency
        ? localLimit
        : agent.capacity.maxConcurrency;
  }

  String _shardId(String runId, int shardIndex) {
    return '$runId-shard-${shardIndex.toString().padLeft(3, '0')}';
  }
}

class _AllocationFraction {
  final String agentId;
  final double fraction;

  const _AllocationFraction({
    required this.agentId,
    required this.fraction,
  });
}
