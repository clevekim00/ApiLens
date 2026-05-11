# Load Hub 원격 로드 러너 설계

Load Hub는 ApiLens의 Workflow를 여러 원격 머신의 원격 에이전트에서 분산 실행하고, 결과를 실시간으로 취합해 성능 테스트를 수행하는 기능이다. 현재 구현은 로컬 앱 안에서 동작하는 domain/application/UI 뼈대와 fake agent 기반 시뮬레이션까지 포함한다.

## 핵심 용어

| 용어 | 의미 |
|---|---|
| Load Hub / 로드 허브 | 원격 머신, 원격 에이전트, 분산 실행, 실시간 metrics, agent upgrade, report를 관리하는 중앙 화면과 기능 영역 |
| Coordinator | Load Hub 내부에서 run 계획, shard dispatch, cancellation, disconnect 처리를 담당하는 service |
| 원격 머신 | 원격 에이전트가 설치되는 host |
| 원격 에이전트 | workflow shard를 실행하고 `MetricWindowEvent`를 Load Hub로 보내는 daemon |
| Shard | 하나의 run을 여러 agent에 나눈 실행 조각 |
| MetricWindowEvent | 원격 에이전트가 1초 또는 5초 단위로 local aggregation한 지표 이벤트 |
| MachineResourceSnapshot | 원격 에이전트가 실행 중인 머신의 CPU, memory, disk I/O, network 상태를 짧은 주기로 측정한 heartbeat payload |
| Backpressure | Load Hub가 ingest 부하를 감지해 agent 전송량을 줄이도록 지시하는 흐름 제어 |

## 구현 구조

```text
lib/features/remote_runner
  application/
    agent_registry.dart
    agent_upgrade_service.dart
    backpressure_controller.dart
    load_hub_coordinator.dart
    machine_inventory_service.dart
    metric_ingest_service.dart
    metrics_aggregator.dart
    remote_run_planner.dart
    remote_run_validator.dart
    run_report_service.dart
  data/
    agent_client.dart
    remote_machine_repository.dart
    remote_run_repository.dart
  domain/models/
  presentation/
```

## 실행 흐름

1. 사용자가 Workflow와 Load Profile을 선택한다.
2. `RemoteRunValidator`가 workflow graph, load profile, agent eligibility를 검증한다.
3. `RemoteRunPlanner`가 agent capacity를 기준으로 deterministic shard plan을 만든다.
4. `LoadHubCoordinator`가 `AgentClient`를 통해 shard를 agent에 dispatch한다.
5. 원격 에이전트가 heartbeat마다 `MachineResourceSnapshot`을 함께 보내 머신 자원 상태를 갱신한다.
6. `FakeAgentClient` 또는 향후 실제 remote transport가 shard lifecycle event와 `MetricWindowEvent`를 보낸다.
7. `MetricIngestService`가 event dedupe, sequence gap detection, queue 상태 관리를 수행한다.
8. `MetricsAggregator`가 histogram과 count를 merge해 `RunMetricsSnapshot`을 만든다.
9. `RunReportService`가 최종 report를 JSON/CSV/Markdown으로 export한다.

## 실시간 취합 설계

성능 병목을 피하기 위해 개별 요청 raw event 전체를 전송하지 않는다. 원격 에이전트는 짧은 시간창마다 local aggregation을 수행하고 `MetricWindowEvent`만 보낸다.

```text
Remote Agent
  -> local aggregation
  -> MetricWindowEvent
  -> MetricIngestService
  -> MetricsAggregator
  -> RunMetricsSnapshot
  -> Load Hub UI / Report
```

Load Hub는 중복 event id를 버리고, sequence gap을 감지하며, queue depth나 lag가 커지면 `BackpressureController`가 window size 증가, sampling 감소, raw event 일시 중단 같은 command를 생성한다.

## 현재 구현된 검증

- `flutter test test/features/remote_runner`
- `dart analyze`
- `dart run scripts/remote_runner/run_fake_distributed_test.dart`
- `dart run scripts/remote_runner/stress_metric_ingest.dart 3 5`
- `dart run scripts/remote_runner/export_run_report.dart markdown`

## 아직 실제화가 필요한 영역

- 실제 remote agent daemon 프로세스
- 실제 WebSocket/gRPC/HTTP batch transport
- Hive/Isar 기반 Load Hub 영속 저장소
- 사용자가 직접 run을 생성하는 production form
- 실제 workflow runtime을 agent process에서 실행하는 packaging
