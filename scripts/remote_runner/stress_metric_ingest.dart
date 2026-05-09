import 'dart:io';

import 'package:apilens/features/remote_runner/application/metric_ingest_service.dart';
import 'package:apilens/features/remote_runner/domain/models/metric_window_event.dart';

void main(List<String> args) {
  final agentCount = args.isNotEmpty ? int.tryParse(args[0]) ?? 10 : 10;
  final eventsPerAgent = args.length > 1 ? int.tryParse(args[1]) ?? 100 : 100;
  final service = MetricIngestService(maxQueueDepth: 100000);
  final startedAt = DateTime.now();

  for (var agentIndex = 1; agentIndex <= agentCount; agentIndex++) {
    for (var sequence = 1; sequence <= eventsPerAgent; sequence++) {
      service.ingest(MetricWindowEvent(
        id: 'agent-$agentIndex-event-$sequence',
        runId: 'stress-run',
        shardId: 'shard-$agentIndex',
        agentId: 'agent-$agentIndex',
        nodeId: 'api1',
        windowStartedAt: startedAt.add(Duration(seconds: sequence)),
        windowMs: 1000,
        sequence: sequence,
        requestCount: 100,
        errorCount: sequence % 10 == 0 ? 1 : 0,
        statusCounts: {
          '200': sequence % 10 == 0 ? 99 : 100,
          if (sequence % 10 == 0) '500': 1,
        },
        latency: const LatencyHistogram(
          buckets: {100: 60, 250: 30, 500: 10},
          minMs: 5,
          maxMs: 500,
          sumMs: 17500,
          count: 100,
        ),
      ));
    }
  }

  final snapshot = service.snapshot('stress-run');
  final elapsed = DateTime.now().difference(startedAt);
  stdout.writeln(
    'agents=$agentCount events=${agentCount * eventsPerAgent} '
    'requests=${snapshot.requestCount} errors=${snapshot.errorCount} '
    'elapsedMs=${elapsed.inMilliseconds}',
  );
}
