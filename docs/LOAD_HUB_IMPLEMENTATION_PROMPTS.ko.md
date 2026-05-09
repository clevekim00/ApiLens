# Load Hub 구현 단계 및 AI 인계 프롬프트

> 목적: 다른 AI 또는 다음 작업자가 ApiLens의 원격 워크플로우 성능 테스트 기능을 이어서 구현할 수 있도록 단계별 구현 범위와 실행 프롬프트를 제공한다.
> 기준 설계서: `blueprint-remote-load-runner.md`

## 용어 기준

| 용어 | 의미 |
|---|---|
| Load Hub / 로드 허브 | 원격 머신, 원격 에이전트, 분산 실행, 실시간 결과 취합, 에이전트 업그레이드를 관리하는 중앙 기능 영역 |
| Coordinator | Load Hub의 내부 orchestration service |
| Remote Machine / 원격 머신 | 원격 에이전트가 설치되는 물리/가상/container host |
| Remote Agent / 원격 에이전트 | 원격 머신에서 실행되어 workflow shard를 수행하고 결과를 Load Hub로 전송하는 daemon |
| Shard | 하나의 부하 테스트 run을 여러 agent에 나누기 위한 실행 조각 |
| MetricWindowEvent | 원격 에이전트가 1초 또는 5초 단위로 local aggregation한 성능 지표 |
| Ingest Queue | Load Hub가 agent event를 비동기로 받아 처리하는 내부 queue |
| Backpressure | Load Hub가 과부하 상황에서 agent의 전송량을 줄이도록 지시하는 흐름 제어 |

## 전체 구현 순서

1. 도메인 모델과 validation
2. 원격 머신/에이전트 registry
3. shard planner
4. fake agent simulator
5. Load Hub coordinator
6. metric ingest/aggregation/backpressure
7. monitoring UI
8. agent upgrade orchestration
9. report/export
10. 문서, 테스트 정리, 회귀 검증

## 현재 구현 상태

2026-05-09 기준 1~10단계의 1차 구현이 완료되었다. 현재 범위는 로컬 앱 내부 service와 fake agent simulation으로 Load Hub 기능을 검증하는 단계이며, 실제 원격 daemon 배포, 네트워크 API 서버, 인증/mTLS, 영속 저장소는 다음 운영화 단계로 남아 있다.

| 단계 | 상태 | 대표 산출물 | 대표 검증 |
|---|---|---|---|
| 1 | 완료 | `domain/models/*`, `remote_run_validator.dart` | `remote_run_validator_test.dart` |
| 2 | 완료 | `machine_inventory_service.dart`, `agent_registry.dart`, `remote_machine_repository.dart` | `agent_registry_test.dart` |
| 3 | 완료 | `remote_run_planner.dart` | `remote_run_planner_test.dart` |
| 4 | 완료 | `agent_client.dart`, `simulate_agents.dart`, `run_fake_distributed_test.dart` | `fake_agent_contract_test.dart` |
| 5 | 완료 | `load_hub_coordinator.dart` | `load_hub_coordinator_test.dart` |
| 6 | 완료 | `metric_ingest_service.dart`, `metrics_aggregator.dart`, `backpressure_controller.dart`, `stress_metric_ingest.dart` | `metrics_aggregator_test.dart`, `backpressure_controller_test.dart` |
| 7 | 완료 | `load_hub_screen.dart`, `presentation/widgets/*`, 메인 내비게이션 연결 | `load_hub_ui_test.dart`, `load_hub_navigation_test.dart` |
| 8 | 완료 | `agent_upgrade.dart`, `agent_upgrade_service.dart`, `agent_update_panel.dart` | `agent_upgrade_service_test.dart` |
| 9 | 완료 | `run_report.dart`, `remote_run_repository.dart`, `run_report_service.dart`, `export_run_report.dart` | `run_report_service_test.dart` |
| 10 | 완료 | `REMOTE_LOAD_RUNNER_DESIGN.ko.md`, `REMOTE_AGENT_SETUP.ko.md`, `LOAD_HUB_OPERATIONS.ko.md` | 문서 검토 및 전체 회귀 명령 |

---

## 1단계: 도메인 모델과 validation

### 구현 목표

Load Hub의 기본 데이터를 표현하는 Dart model을 추가한다. 기존 `Workflow`와 `ExecutionEngine`은 수정하지 않고, 원격 실행을 위한 모델을 별도 feature 영역에 둔다.

### 주요 산출물

- `lib/features/remote_runner/domain/models/remote_machine.dart`
- `lib/features/remote_runner/domain/models/remote_agent.dart`
- `lib/features/remote_runner/domain/models/load_profile.dart`
- `lib/features/remote_runner/domain/models/remote_run.dart`
- `lib/features/remote_runner/domain/models/run_shard.dart`
- `lib/features/remote_runner/domain/models/metric_window_event.dart`
- `lib/features/remote_runner/domain/models/agent_upgrade.dart`
- `lib/features/remote_runner/application/remote_run_validator.dart`
- `test/features/remote_runner/remote_run_validator_test.dart`

### 구현 프롬프트

```text
너는 ApiLens Flutter/Dart 코드베이스를 이어서 구현하는 AI다.

목표:
Load Hub 원격 성능 테스트 기능의 1단계로 도메인 모델과 validation을 구현해라.

반드시 확인할 파일:
- blueprint-remote-load-runner.md
- docs/LOAD_HUB_IMPLEMENTATION_PROMPTS.ko.md
- lib/features/workflow_editor/domain/models/workflow.dart
- lib/features/workflow_editor/domain/models/workflow_node.dart
- lib/features/workflow_editor/domain/models/node_config.dart
- lib/features/execution/application/execution_engine.dart

구현 요구:
1. `lib/features/remote_runner/domain/models/` 아래에 원격 실행 모델을 추가한다.
2. 최소 모델은 `RemoteMachine`, `RemoteAgent`, `LoadProfile`, `RemoteRunDraft`, `RemoteRunPlan`, `RunShard`, `MetricWindowEvent`, `AgentUpgradePlan`, `AgentUpgradeRolloutState`다.
3. 각 모델은 JSON 직렬화/역직렬화 메서드를 가진다. 현재 프로젝트 패턴에 맞춰 수동 `toJson/fromJson`을 우선 사용한다.
4. `RemoteRunValidator`를 만들어 workflow graph, load profile bounds, agent eligibility를 검증한다.
5. 기존 `Workflow`, `WorkflowNode`, `ExecutionEngine` 동작은 변경하지 않는다.
6. validation error와 warning을 구분하는 결과 타입을 만든다.

검증:
- `dart format lib/features/remote_runner test/features/remote_runner`
- `dart analyze`
- `flutter test test/features/remote_runner/remote_run_validator_test.dart`

완료 기준:
- 모델 round-trip JSON 테스트가 통과한다.
- 잘못된 load profile과 agent 없음 상황을 validation error로 반환한다.
- 기존 workflow 실행 테스트를 깨지 않는다.
```

---

## 2단계: 원격 머신/에이전트 registry

### 구현 목표

Load Hub가 원격 머신 인벤토리와 에이전트 heartbeat 상태를 관리할 수 있게 한다.

### 주요 산출물

- `lib/features/remote_runner/application/machine_inventory_service.dart`
- `lib/features/remote_runner/application/agent_registry.dart`
- `lib/features/remote_runner/data/remote_machine_repository.dart`
- `test/features/remote_runner/agent_registry_test.dart`

### 구현 프롬프트

```text
너는 ApiLens Load Hub 기능의 2단계를 구현하는 AI다.

목표:
원격 머신 인벤토리와 원격 에이전트 registry/heartbeat 관리를 구현해라.

전제:
1단계의 `RemoteMachine`, `RemoteAgent` 모델이 존재한다고 가정하되, 없다면 먼저 최소 모델을 추가해라.

구현 요구:
1. `MachineInventoryService`는 원격 머신 추가, 수정, 삭제, enable, disable, tag 변경을 지원한다.
2. `AgentRegistry`는 agent registration, heartbeat update, heartbeat timeout, 상태 전이를 관리한다.
3. agent 상태는 최소 `unknown`, `online`, `busy`, `draining`, `disabled`, `offline`, `incompatible`, `upgradeRequired`를 지원한다.
4. heartbeat timeout은 테스트 가능하도록 clock 또는 now provider를 주입할 수 있게 한다.
5. 저장소는 1차 구현에서 in-memory repository로 시작해도 된다. 단, interface를 분리해서 이후 Hive/Isar 저장소로 교체 가능해야 한다.
6. disabled machine에는 shard가 배정되지 않도록 eligibility 판단 메서드를 제공한다.

검증:
- `dart format lib/features/remote_runner test/features/remote_runner`
- `dart analyze`
- `flutter test test/features/remote_runner/agent_registry_test.dart`

완료 기준:
- agent registration 후 online 상태가 된다.
- heartbeat timeout 후 offline 상태가 된다.
- disabled/draining/busy 상태가 eligibility에 반영된다.
```

---

## 3단계: shard planner

### 구현 목표

사용자의 load profile과 agent capacity를 기준으로 deterministic shard plan을 만든다.

### 주요 산출물

- `lib/features/remote_runner/application/remote_run_planner.dart`
- `test/features/remote_runner/remote_run_planner_test.dart`

### 구현 프롬프트

```text
너는 ApiLens Load Hub 기능의 3단계를 구현하는 AI다.

목표:
LoadProfile과 사용 가능한 RemoteAgent 목록을 받아 결정적인 RemoteRunPlan을 생성하는 planner를 구현해라.

구현 요구:
1. `RemoteRunPlanner`를 추가한다.
2. 동일한 input은 항상 동일한 shard id와 assignment를 생성해야 한다.
3. 최소 정책은 equal split과 capacity-weighted split을 지원한다.
4. agent가 없거나 capacity가 부족한 경우 validation error 또는 planning failure를 반환한다.
5. 각 shard에는 run id, shard id, agent id, virtual user range, ramp-up offset, duration, per-agent concurrency limit이 포함되어야 한다.
6. `RemoteRunPlan`은 이후 dispatch에 사용할 수 있는 immutable snapshot이어야 한다.

검증:
- `dart format lib/features/remote_runner test/features/remote_runner`
- `dart analyze`
- `flutter test test/features/remote_runner/remote_run_planner_test.dart`

완료 기준:
- 같은 입력의 planner 결과가 반복 실행해도 동일하다.
- capacity-weighted split이 agent capacity 비율을 반영한다.
- disabled/offline/incompatible agent가 배정에서 제외된다.
```

---

## 4단계: fake agent simulator

### 구현 목표

실제 원격 머신 없이 coordinator, dispatch, metrics ingest를 테스트할 수 있는 fake agent를 만든다.

### 주요 산출물

- `scripts/remote_runner/simulate_agents.dart`
- `scripts/remote_runner/run_fake_distributed_test.dart`
- `test/features/remote_runner/fake_agent_contract_test.dart`

### 구현 프롬프트

```text
너는 ApiLens Load Hub 기능의 4단계를 구현하는 AI다.

목표:
실제 원격 머신 없이 Load Hub coordinator와 agent protocol을 테스트할 수 있는 fake agent simulator를 구현해라.

구현 요구:
1. `scripts/remote_runner/simulate_agents.dart`를 추가한다.
2. fake agent는 registration, heartbeat, dispatchShard 수신, metricWindow 전송을 흉내 내야 한다.
3. fake agent는 성공 run, 실패 run, 연결 끊김, 느린 heartbeat, 높은 metric volume을 시뮬레이션할 수 있어야 한다.
4. `run_fake_distributed_test.dart`는 여러 fake agent를 띄우고 하나의 run plan을 dispatch한 뒤 metric window를 수집하는 smoke flow를 제공한다.
5. 프로덕션 코드와 테스트 코드가 과하게 얽히지 않도록 fake agent는 script/test helper 성격으로 둔다.

검증:
- `dart format scripts/remote_runner test/features/remote_runner`
- `dart analyze`
- 관련 fake agent 테스트 실행

완료 기준:
- fake agent 여러 개가 동시에 heartbeat와 metric window를 보낼 수 있다.
- 연결 끊김과 재연결 상황을 재현할 수 있다.
- 이후 coordinator 구현의 통합 테스트 기반으로 사용할 수 있다.
```

---

## 5단계: Load Hub coordinator

### 구현 목표

Load Hub의 중앙 service를 만들어 run 생성, shard dispatch, cancellation, agent 상태 반영을 담당하게 한다.

### 주요 산출물

- `lib/features/remote_runner/application/load_hub_coordinator.dart`
- `lib/features/remote_runner/data/agent_client.dart`
- `test/features/remote_runner/load_hub_coordinator_test.dart`

### 구현 프롬프트

```text
너는 ApiLens Load Hub 기능의 5단계를 구현하는 AI다.

목표:
Load Hub coordinator를 구현해서 run plan을 agent에게 dispatch하고 shard lifecycle을 관리해라.

구현 요구:
1. 사용자-facing 이름은 Load Hub, 내부 service명은 `LoadHubCoordinator`를 사용한다.
2. coordinator는 `RemoteRunDraft -> RemoteRunPlan -> dispatch -> running -> completed/failed/cancelled` 흐름을 관리한다.
3. agent 통신은 `AgentClient` interface로 분리한다. 실제 transport 구현 전에는 fake/in-memory client를 둔다.
4. shard 상태는 `queued`, `dispatching`, `running`, `completed`, `failed`, `cancelled`, `lost`를 지원한다.
5. cancellation은 새 iteration 시작을 막고, in-flight 작업은 timeout 내 drain되도록 command를 보낸다.
6. agent disconnect 시 unstarted shard는 requeue하고, active shard는 run policy에 따라 lost 또는 retry로 처리한다.

검증:
- `dart format lib/features/remote_runner test/features/remote_runner`
- `dart analyze`
- `flutter test test/features/remote_runner/load_hub_coordinator_test.dart`

완료 기준:
- 여러 fake agent에 shard를 dispatch할 수 있다.
- cancellation과 agent disconnect가 deterministic하게 처리된다.
- 기존 `ExecutionEngine` 코드를 직접 재작성하지 않는다.
```

---

## 6단계: metric ingest/aggregation/backpressure

### 구현 목표

원격 에이전트들의 테스트 결과를 성능 이슈 없이 실시간으로 Load Hub에 취합한다.

### 주요 산출물

- `lib/features/remote_runner/application/metric_ingest_service.dart`
- `lib/features/remote_runner/application/metrics_aggregator.dart`
- `lib/features/remote_runner/application/backpressure_controller.dart`
- `scripts/remote_runner/stress_metric_ingest.dart`
- `test/features/remote_runner/metrics_aggregator_test.dart`
- `test/features/remote_runner/backpressure_controller_test.dart`

### 구현 프롬프트

```text
너는 ApiLens Load Hub 기능의 6단계를 구현하는 AI다.

목표:
여러 원격 에이전트가 보내는 성능 테스트 결과를 메인 스레드/UI 성능 문제 없이 실시간 취합하는 metric ingest/aggregation/backpressure 계층을 구현해라.

핵심 설계:
개별 요청 raw event를 모두 보내지 않는다. 원격 에이전트는 1초 또는 5초 단위 `MetricWindowEvent`를 local aggregation해서 보내고, Load Hub는 ingest queue에서 비동기 처리한다.

구현 요구:
1. `MetricIngestService`는 agent event를 bounded queue로 받아 validation, dedupe, gap detection을 수행한다.
2. `MetricsAggregator`는 agent별/window별 histogram과 count를 merge해 `RunMetricsSnapshot`을 만든다.
3. latency는 raw list가 아니라 merge 가능한 histogram 또는 fixed bucket count 기반으로 처리한다.
4. UI snapshot publish는 throttle한다. 기본 1초, 필요 시 250ms까지 허용한다.
5. raw success event는 기본 비활성 또는 낮은 sampling rate로 설계한다.
6. raw failure event는 전송하되 per-agent rate limit을 적용한다.
7. `BackpressureController`는 queue depth, ingest lag, memory pressure를 기준으로 agent에 `setMetricWindow`, `setSamplingRate`, `setLogLevel`, `pauseRawEvents` 같은 command를 생성한다.
8. 저장소 write는 event별 write가 아니라 batch write를 기준으로 설계한다.

검증:
- `dart format lib/features/remote_runner scripts/remote_runner test/features/remote_runner`
- `dart analyze`
- `flutter test test/features/remote_runner/metrics_aggregator_test.dart`
- `flutter test test/features/remote_runner/backpressure_controller_test.dart`

성능 테스트:
- `scripts/remote_runner/stress_metric_ingest.dart`로 여러 fake agent가 대량 `MetricWindowEvent`를 보내는 상황을 재현한다.

완료 기준:
- duplicate event가 dedupe된다.
- sequence gap이 감지된다.
- p50/p90/p95/p99가 fixture 기준으로 계산된다.
- queue lag가 커지면 backpressure command가 생성된다.
- UI snapshot 갱신이 과도하게 자주 발생하지 않는다.
```

---

## 7단계: monitoring UI

### 구현 목표

ApiLens 안에 Load Hub UI를 추가해 원격 머신, 실행 run, 실시간 metrics, logs, agent updates를 볼 수 있게 한다.

### 주요 산출물

- `lib/features/remote_runner/presentation/screens/load_hub_screen.dart`
- `lib/features/remote_runner/presentation/widgets/machine_table.dart`
- `lib/features/remote_runner/presentation/widgets/run_monitor_panel.dart`
- `lib/features/remote_runner/presentation/widgets/metrics_overview.dart`
- `lib/features/remote_runner/presentation/widgets/agent_update_panel.dart`
- `test/features/remote_runner/load_hub_ui_test.dart`

### 구현 프롬프트

```text
너는 ApiLens Load Hub 기능의 7단계를 구현하는 AI다.

목표:
Load Hub monitoring UI를 구현해 원격 머신, 원격 에이전트, 분산 run, 실시간 metrics를 볼 수 있게 해라.

UI 원칙:
운영 콘솔처럼 조밀하고 스캔하기 쉬워야 한다. 마케팅 페이지나 장식적인 hero 화면을 만들지 마라.

구현 요구:
1. Load Hub 화면은 최소 `Machines`, `Runs`, `Metrics`, `Logs`, `Agent Updates` 탭을 가진다.
2. Machines 탭은 machine status, agent version, capacity, labels, last heartbeat, admin state를 보여준다.
3. Runs 탭은 run status, active VUs, completed iterations, assigned agents, shard status를 보여준다.
4. Metrics 탭은 RPS, error rate, p50/p90/p95/p99 latency, agent utilization을 보여준다.
5. Logs 탭은 warning/error 중심이며 raw debug log 폭주를 피한다.
6. Agent Updates 탭은 upgrade rollout 상태와 rollback 결과를 보여준다.
7. Riverpod provider 패턴은 기존 코드 스타일을 따른다.
8. 텍스트가 좁은 화면에서 겹치지 않도록 responsive layout을 적용한다.

검증:
- `dart format lib/features/remote_runner test/features/remote_runner`
- `dart analyze`
- `flutter test test/features/remote_runner/load_hub_ui_test.dart`

완료 기준:
- fake coordinator state로 UI widget test가 통과한다.
- 좁은 화면에서도 핵심 status와 metric이 겹치지 않는다.
- run monitor가 snapshot throttle 구조와 잘 맞는다.
```

---

## 8단계: agent upgrade orchestration

### 구현 목표

Load Hub에서 선택한 원격 머신의 에이전트를 staged rollout으로 안전하게 업그레이드한다.

### 주요 산출물

- `lib/features/remote_runner/application/agent_upgrade_service.dart`
- `lib/features/remote_runner/domain/models/agent_upgrade.dart`
- `lib/features/remote_runner/presentation/widgets/agent_update_panel.dart`
- `test/features/remote_runner/agent_upgrade_service_test.dart`

### 구현 프롬프트

```text
너는 ApiLens Load Hub 기능의 8단계를 구현하는 AI다.

목표:
원격 에이전트를 Load Hub에서 안전하게 업그레이드하는 orchestration 계층을 구현해라.

기본 흐름:
drain -> install -> restart -> health check -> 완료 또는 rollback

구현 요구:
1. `AgentVersionManifest`는 target version, protocol compatibility, package URL, checksum, rollback package를 포함한다.
2. `AgentUpgradeService`는 selected machines와 rollout policy를 받아 `AgentUpgradePlan`을 만든다.
3. rollout은 batch size를 지원한다.
4. 기본 정책은 active run을 끊지 않는 drain-before-upgrade다.
5. busy machine은 policy에 따라 drain 대기 또는 skip한다.
6. install 실패 시 이전 agent가 살아 있으면 유지한다.
7. restart 후 health check 실패 시 rollback package가 있으면 rollback한다.
8. rollback도 실패하면 machine을 scheduling disabled로 전환하고 사용자에게 명확한 상태를 제공한다.
9. force upgrade는 별도 flag가 있을 때만 허용한다.

검증:
- `dart format lib/features/remote_runner scripts/remote_runner test/features/remote_runner`
- `dart analyze`
- `flutter test test/features/remote_runner/agent_upgrade_service_test.dart`

완료 기준:
- staged rollout 성공 테스트가 통과한다.
- busy machine drain 대기/skip 테스트가 통과한다.
- health check 실패 후 rollback 테스트가 통과한다.
- rollback 실패 시 scheduling disabled 상태가 된다.
```

---

## 9단계: report/export

### 구현 목표

테스트 종료 후 run summary, node-level metrics, error breakdown, latency percentile, agent별 처리량을 저장하고 export한다.

### 주요 산출물

- `lib/features/remote_runner/domain/models/run_report.dart`
- `lib/features/remote_runner/application/run_report_service.dart`
- `lib/features/remote_runner/data/remote_run_repository.dart`
- `scripts/remote_runner/export_run_report.dart`
- `test/features/remote_runner/run_report_service_test.dart`

### 구현 프롬프트

```text
너는 ApiLens Load Hub 기능의 9단계를 구현하는 AI다.

목표:
분산 성능 테스트 완료 후 결과 저장과 report/export 기능을 구현해라.

구현 요구:
1. `RunReportService`는 final `RunMetricsSnapshot`, node-level aggregates, error breakdown, agent utilization을 받아 report model을 만든다.
2. export format은 1차로 JSON과 CSV를 지원한다. Markdown export는 가능하면 추가한다.
3. report에는 configured load와 achieved load 비교가 있어야 한다.
4. node별 p50/p90/p95/p99 latency, error count, status code bucket을 포함한다.
5. agent별 처리량, 실패율, offline/degraded 구간을 포함한다.
6. raw event archive가 있을 경우 replay 가능하도록 metadata를 남긴다.
7. final aggregation이 실패하면 partial report를 만들고 raw aggregate data를 보존한다.

검증:
- `dart format lib/features/remote_runner scripts/remote_runner test/features/remote_runner`
- `dart analyze`
- `flutter test test/features/remote_runner/run_report_service_test.dart`

완료 기준:
- fixture 기반 report 생성 테스트가 통과한다.
- JSON/CSV export snapshot 테스트가 통과한다.
- partial report 상태가 표현된다.
```

---

## 10단계: 문서, 테스트 정리, 회귀 검증

### 구현 목표

Load Hub 기능의 사용법과 운영 방법을 문서화하고, 주요 회귀 테스트를 정리한다.

### 주요 산출물

- `docs/REMOTE_LOAD_RUNNER_DESIGN.ko.md`
- `docs/REMOTE_AGENT_SETUP.ko.md`
- `docs/LOAD_HUB_OPERATIONS.ko.md`
- `docs/LOAD_HUB_IMPLEMENTATION_PROMPTS.ko.md`
- 기존 `blueprint-remote-load-runner.md` 업데이트

### 구현 프롬프트

```text
너는 ApiLens Load Hub 기능의 10단계를 구현하는 AI다.

목표:
구현된 Load Hub 기능의 문서, 운영 가이드, 테스트 명령, 회귀 검증 목록을 정리해라.

구현 요구:
1. `docs/REMOTE_LOAD_RUNNER_DESIGN.ko.md`에 아키텍처와 데이터 흐름을 정리한다.
2. `docs/REMOTE_AGENT_SETUP.ko.md`에 원격 에이전트 설치, 등록, heartbeat, troubleshooting을 정리한다.
3. `docs/LOAD_HUB_OPERATIONS.ko.md`에 머신 관리, agent upgrade, backpressure, 장애 대응을 정리한다.
4. 모든 문서의 기본 언어는 한국어다.
5. 사용자-facing 용어는 `Load Hub / 로드 허브`, `원격 머신`, `원격 에이전트`를 사용한다.
6. 내부 구현 용어로 필요한 경우에만 `Coordinator`를 병기한다.
7. 구현된 테스트 명령과 수동 확인 절차를 문서 마지막에 넣는다.

검증:
- `dart format lib test scripts`
- `dart analyze`
- 관련 `flutter test`
- 필요 시 `python3 /Users/youngwhankim/.agents/skills/blueprint/scripts/validate_blueprint_doc.py ./blueprint-remote-load-runner.md`

완료 기준:
- 새 사용자가 문서만 보고 원격 머신 등록, fake agent 실행, 분산 run 실행, 결과 export 흐름을 이해할 수 있다.
- 주요 회귀 테스트 명령이 문서화되어 있다.
```

---

## AI 작업 시 공통 규칙

다른 AI가 어떤 단계를 맡더라도 다음 규칙을 따른다.

1. 기존 `ExecutionEngine`을 재작성하지 말고 remote runner가 감싸서 사용한다.
2. 기존 workflow JSON과 로컬 workflow 실행은 깨지면 안 된다.
3. 원격 실시간 취합은 raw event 전체 전송이 아니라 `MetricWindowEvent` 중심으로 설계한다.
4. UI는 운영 콘솔처럼 조밀하고 명확해야 한다.
5. 문서와 사용자-facing 메시지는 한국어를 기본으로 한다.
6. 사용자-facing 이름은 `Load Hub / 로드 허브`를 사용한다.
7. 내부 orchestration service명은 필요할 때 `Coordinator`를 사용한다.
8. 모든 단계는 테스트를 같이 추가하거나, 테스트가 어려운 경우 이유와 수동 검증 방법을 남긴다.
9. `dart format`, `dart analyze`, 관련 `flutter test`를 가능한 범위에서 실행한다.
10. 기존 사용자 변경 사항을 되돌리지 않는다.

## 회귀 검증 명령

Load Hub 관련 변경 후 다음 명령을 우선 실행한다.

```bash
dart format lib/features/remote_runner test/features/remote_runner scripts/remote_runner lib/core/widgets/splash_screen.dart lib/core/widgets/main_workspace_screen.dart lib/core/l10n/app_localizations.dart
dart analyze
flutter test test/features/remote_runner
flutter test test/widget_test.dart
dart run scripts/remote_runner/run_fake_distributed_test.dart
dart run scripts/remote_runner/stress_metric_ingest.dart 3 5
dart run scripts/remote_runner/export_run_report.dart markdown
python3 /Users/youngwhankim/.agents/skills/blueprint/scripts/validate_blueprint_doc.py ./blueprint-remote-load-runner.md
```
