import 'dart:io';

import 'package:apilens/features/remote_runner/application/agent_registry.dart';
import 'package:apilens/features/remote_runner/application/machine_inventory_service.dart';
import 'package:apilens/features/remote_runner/data/remote_machine_repository.dart';
import 'package:apilens/features/remote_runner/domain/models/machine_resource_snapshot.dart';
import 'package:apilens/features/remote_runner/domain/models/remote_agent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testainers/testainers.dart';

void main() {
  final dockerTestsEnabled =
      Platform.environment['APILENS_DOCKER_TESTS'] == '1';

  group(
    'Load Hub Docker 검증',
    () {
      final containers = <TestainersHttpbucket>[];

      tearDownAll(() async {
        for (final container in containers.reversed) {
          try {
            await container.stop();
          } catch (_) {
            // Container startup may fail before Docker creates it.
          }
        }
      });

      test('testainers remote agent endpoints feed resource heartbeats',
          () async {
        final now = DateTime.utc(2026, 5, 11, 1);
        final machineInventory = MachineInventoryService(
          repository: InMemoryRemoteMachineRepository(),
          now: () => now,
        );
        await machineInventory.addMachine(
          id: 'docker-machine-1',
          name: 'Docker agent 1',
          host: 'localhost',
        );
        await machineInventory.addMachine(
          id: 'docker-machine-2',
          name: 'Docker agent 2',
          host: 'localhost',
        );

        final registry = AgentRegistry(
          machineInventory: machineInventory,
          now: () => now,
        );

        final agentEndpoints = <String>[];
        for (var index = 0; index < 2; index += 1) {
          final container = TestainersHttpbucket(
            healthCmd: '',
            healthInterval: 0,
            healthRetries: 0,
            healthTimeout: 0,
            healthStartPeriod: 0,
            noHealthcheck: true,
          );
          await container.start(bootSleep: const Duration(seconds: 2));
          containers.add(container);
          final endpoint = 'http://localhost:${container.httpPort}';
          agentEndpoints.add(endpoint);

          final response = await _getWithRetry('$endpoint/status/200');
          expect(response.statusCode, 200);
        }

        await registry.register(
          AgentRegistration(
            id: 'docker-agent-1',
            machineId: 'docker-machine-1',
            endpoint: agentEndpoints[0],
            version: '1.0.0',
            protocolVersion: '1',
            supportedNodeTypes: const ['api'],
            capacity: const RemoteAgentCapacity(
              maxVirtualUsers: 100,
              maxConcurrency: 20,
            ),
            resourceSnapshot: MachineResourceSnapshot(
              cpuUsagePercent: 42,
              memoryUsagePercent: 55,
              memoryUsedBytes: 512 * 1024 * 1024,
              memoryTotalBytes: 1024 * 1024 * 1024,
              diskReadBytesPerSecond: 2 * 1024 * 1024,
              diskWriteBytesPerSecond: 1024 * 1024,
              networkRxBytesPerSecond: 512 * 1024,
              networkTxBytesPerSecond: 768 * 1024,
              capturedAt: now,
            ),
          ),
        );
        await registry.register(
          AgentRegistration(
            id: 'docker-agent-2',
            machineId: 'docker-machine-2',
            endpoint: agentEndpoints[1],
            version: '1.0.0',
            protocolVersion: '1',
            supportedNodeTypes: const ['api'],
            capacity: const RemoteAgentCapacity(
              maxVirtualUsers: 100,
              maxConcurrency: 20,
            ),
          ),
        );

        registry.heartbeat(
          'docker-agent-2',
          resourceSnapshot: MachineResourceSnapshot(
            cpuUsagePercent: 91,
            memoryUsagePercent: 92,
            memoryUsedBytes: 940 * 1024 * 1024,
            memoryTotalBytes: 1024 * 1024 * 1024,
            diskReadBytesPerSecond: 5 * 1024 * 1024,
            diskWriteBytesPerSecond: 4 * 1024 * 1024,
            networkRxBytesPerSecond: 3 * 1024 * 1024,
            networkTxBytesPerSecond: 2 * 1024 * 1024,
            loadAverage1m: 3.8,
            capturedAt: now.add(const Duration(seconds: 1)),
          ),
        );

        final agents = registry.agents;

        expect(agents, hasLength(2));
        expect(
          agents.every((agent) => agent.endpoint.startsWith('http://')),
          isTrue,
        );
        expect(registry.schedulableAgents(), hasLength(2));
        expect(
          registry.getById('docker-agent-1')?.resourceSnapshot?.isUnderPressure,
          isFalse,
        );
        expect(
          registry.getById('docker-agent-2')?.resourceSnapshot?.isUnderPressure,
          isTrue,
        );
      }, timeout: const Timeout(Duration(minutes: 3)));
    },
    skip: dockerTestsEnabled
        ? false
        : 'Docker 검증은 APILENS_DOCKER_TESTS=1 일 때만 실행합니다.',
  );
}

Future<HttpClientResponse> _getWithRetry(String url) async {
  Object? lastError;
  for (var attempt = 0; attempt < 10; attempt += 1) {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        return response;
      }
      lastError = 'HTTP ${response.statusCode}';
    } catch (error) {
      lastError = error;
    } finally {
      client.close(force: true);
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw StateError('컨테이너 endpoint가 준비되지 않았습니다: $lastError');
}
