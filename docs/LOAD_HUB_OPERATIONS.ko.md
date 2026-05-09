# Load Hub 운영 가이드

Load Hub는 원격 머신과 원격 에이전트를 관리하고, workflow 기반 부하 테스트를 분산 실행하며, metrics와 report를 제공하는 운영 콘솔이다.

## 화면 구성

앱 메인 workspace 상단에서 `Load Hub / 로드 허브` 탭 또는 오른쪽 hub 아이콘으로 진입한다.

현재 화면 탭:

- Machines
- Runs
- Metrics
- Logs
- Agent Updates

## 머신 운영

원격 머신은 `enabled`, `disabled`, `draining` admin state를 가진다.

- `enabled`: shard 배정 가능
- `disabled`: shard 배정 금지
- `draining`: 새 shard 배정 금지, 진행 중 작업 정리

관련 구현:

- `MachineInventoryService`
- `MachineTable`

## Run 운영

분산 run은 `RemoteRunDraft`에서 시작해 `RemoteRunPlan`으로 계획되고, `LoadHubCoordinator`가 shard를 agent에 dispatch한다.

지원 상태:

- `draft`
- `planned`
- `running`
- `completed`
- `failed`
- `cancelled`

Shard 상태:

- `queued`
- `dispatching`
- `running`
- `completed`
- `failed`
- `cancelled`
- `lost`

agent disconnect가 발생하면 active shard는 `lost`로 전환되고 run은 실패 상태가 된다.

## Metrics 운영

실시간 취합은 `MetricWindowEvent` 중심으로 설계되어 있다.

- 중복 event id는 dedupe한다.
- sequence gap은 감지한다.
- histogram bucket을 merge해 p50/p90/p95/p99를 계산한다.
- queue depth나 ingest lag가 커지면 backpressure command를 만든다.

관련 구현:

- `MetricIngestService`
- `MetricsAggregator`
- `BackpressureController`

## 에이전트 업그레이드

기본 upgrade 흐름:

```text
drain -> install -> restart -> health check -> completed
```

health check 실패 시 rollback package가 있으면 다음 흐름을 수행한다.

```text
health check failed -> rollback -> rolledBack
```

rollback도 실패하면 해당 머신은 scheduling disabled 처리된다.

관련 구현:

- `AgentUpgradeService`
- `AgentUpgradeExecutor`
- `FakeAgentUpgradeExecutor`
- `AgentUpdatePanel`

## Report/Export

run 종료 후 `RunReportService`가 다음 정보를 포함한 report를 만든다.

- configured VU
- achieved request count
- error count/rate
- node별 p50/p90/p95/p99
- status code bucket
- error type breakdown
- agent별 shard/VU/completed/failed/lost summary

지원 export:

- JSON
- CSV
- Markdown

실행 예:

```bash
dart run scripts/remote_runner/export_run_report.dart markdown
dart run scripts/remote_runner/export_run_report.dart json
dart run scripts/remote_runner/export_run_report.dart csv
```

## 회귀 검증 명령

```bash
dart analyze
flutter test test/features/remote_runner
flutter test test/widget_test.dart
dart run scripts/remote_runner/run_fake_distributed_test.dart
dart run scripts/remote_runner/stress_metric_ingest.dart 3 5
dart run scripts/remote_runner/export_run_report.dart markdown
```

