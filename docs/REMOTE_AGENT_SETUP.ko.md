# 원격 에이전트 설정 가이드

이 문서는 Load Hub의 원격 에이전트 개념과 현재 개발용 fake agent 실행 방법을 설명한다. 실제 원격 daemon은 아직 구현 전이며, 현재는 `FakeAgentClient`와 스크립트로 coordinator 계약을 검증한다.

## 원격 머신 등록 개념

원격 머신은 다음 정보를 가진다.

- machine id
- name
- host
- platform
- labels
- credential reference
- agent install path
- admin state: `enabled`, `disabled`, `draining`

현재 구현 파일:

- `MachineInventoryService`
- `RemoteMachineRepository`
- `InMemoryRemoteMachineRepository`

## 원격 에이전트 등록 개념

원격 에이전트는 다음 정보를 Load Hub에 보고한다.

- agent id
- machine id
- endpoint
- version
- protocol version
- supported node types
- capacity
- heartbeat

에이전트 상태:

- `unknown`
- `online`
- `busy`
- `draining`
- `disabled`
- `offline`
- `incompatible`
- `upgradeRequired`

현재 구현 파일:

- `AgentRegistry`
- `AgentRegistration`
- `RemoteAgent`

## 개발용 fake agent 실행

fake agent 등록 시뮬레이션:

```bash
dart run scripts/remote_runner/simulate_agents.dart 3
```

fake distributed run:

```bash
dart run scripts/remote_runner/run_fake_distributed_test.dart
```

metric ingest stress:

```bash
dart run scripts/remote_runner/stress_metric_ingest.dart 10 100
```

## 실제 에이전트 구현 시 필요한 계약

실제 에이전트는 최소 다음 command/event를 지원해야 한다.

Command:

- `dispatchShard`
- `cancelShard`
- `drain`
- `restartAgent`
- `upgradeAgent`
- `rollbackAgent`
- `healthCheck`

Event:

- `heartbeat`
- `shardStatus`
- `metricWindow`
- `sampledNodeResult`
- `failureEvent`
- `log`

## 운영 기본값

- heartbeat timeout은 테스트 가능하도록 clock 주입 구조를 유지한다.
- disabled/draining/offline/incompatible agent는 shard 배정에서 제외한다.
- 성공 raw event 전체 전송은 기본 비활성화한다.
- 실패 raw event는 rate limit을 둔다.
- metrics는 `MetricWindowEvent` 중심으로 전송한다.

