# 원격 로드 러너 Codex 자동화 설계서
> Created: 2026-05-09
> Purpose: Codex 구현 설계서

## 0. Goals and Deliverables

### Primary Goal
ApiLens의 기존 Workflow 실행 기능을 단일 로컬 실행에서 여러 원격 머신의 에이전트 기반 분산 실행으로 확장한다. 사용자는 LoadRunner처럼 워크플로우를 여러 원격 머신에서 실행하여 성능 테스트를 수행하고, 중앙에서 원격 머신 관리, 에이전트 업그레이드, 실행 상태 모니터링, 결과 수집, 리포트 생성을 할 수 있어야 한다.

### Success Definition
- 사용자는 ApiLens UI에서 하나의 Workflow를 선택하고 부하 프로파일을 설정한 뒤 여러 원격 에이전트에서 동시에 실행할 수 있다.
- 각 원격 머신의 상태, 에이전트 버전, 리소스, 연결 품질, 실행 이력, 업그레이드 상태를 중앙에서 관리할 수 있다.
- 사용자는 원격 머신을 인벤토리에 등록하고, 그룹/태그/활성화/비활성화/drain 상태로 운영할 수 있다.
- 사용자는 Load Hub(Coordinator)에서 원격 머신의 에이전트를 안전하게 업그레이드하고, 단계적 배포, health check, rollback 결과를 확인할 수 있다.
- 각 에이전트의 할당량, 현재 TPS/RPS, 오류율, 지연 시간, 로그가 실시간 또는 준실시간으로 Load Hub에 집계된다.
- 테스트 종료 후 run summary, node-level metrics, percentile latency, error breakdown, raw event export를 확인할 수 있다.
- 기존 로컬 `ExecutionEngine` 테스트는 유지되고, 원격 실행 기능은 coordinator/agent 계약 테스트와 최소 1개 통합 테스트로 검증된다.

### Out of Scope
- 클라우드 VM 자동 프로비저닝, Kubernetes 오토스케일링, 비용 최적화는 1차 범위에서 제외한다. 단, 이미 준비된 원격 머신의 등록, 상태 관리, 에이전트 업그레이드는 범위에 포함한다.
- 브라우저 기반 UI 부하 테스트와 실제 사용자의 렌더링 성능 측정은 제외한다.
- 외부 APM 제품과의 양방향 통합은 제외하고, CSV/JSON export 및 webhook 수준만 1차로 다룬다.
- 인증서 발급, 조직 단위 권한 체계, 멀티테넌트 SaaS 운영 기능은 별도 보안/운영 단계로 분리한다.

## 1. Working Context

### Background
현재 ApiLens는 Flutter/Dart 기반 데스크톱/웹 앱이며 REST, GraphQL, WebSocket 요청을 Workflow Editor에서 연결해 자동화할 수 있다. 실행은 [execution_engine.dart](/Users/youngwhankim/Project/ApiLens/lib/features/execution/application/execution_engine.dart)의 `ExecutionEngine.runWorkflow()` 스트림을 중심으로 이루어지고, `WorkflowRunnerController`가 UI의 debug panel에 결과와 로그를 반영한다.

성능 테스트 기능을 넣으려면 기존 Workflow 모델과 실행 엔진을 재사용하되, 실행 단위를 여러 머신으로 분산하고 중앙에서 제어하는 계층이 필요하다. 또한 원격 에이전트는 단순 실행 프로세스가 아니라 운영 대상이므로, 머신 인벤토리, 버전 관리, 업그레이드, 장애 격리까지 설계 범위에 포함해야 한다.

### Objective
Codex 구현 작업은 기존 workflow 모델과 execution engine을 보존하면서 다음 계층을 추가한다.

1. 부하 테스트 run을 정의하는 domain model
2. Load Hub(Coordinator)가 remote machine inventory와 agent lifecycle을 관리하는 management layer
3. Load Hub가 agent pool에 work shard를 배정하는 scheduling layer
4. 원격 agent daemon이 workflow shard를 실행하고 metrics/event stream을 전송하는 runner layer
5. ApiLens UI가 run 생성, 머신/agent 등록 및 업그레이드, 실시간 모니터링, 결과 분석을 제공하는 presentation layer
6. 테스트와 문서로 remote execution contract를 고정하는 validation layer

### Scope
- Included: coordinator API, 원격 머신 인벤토리, agent registration/heartbeat, agent lifecycle and upgrade management, distributed run planning, workflow shard dispatch, real-time metrics ingest, run cancellation, result persistence, UI monitor screens, JSON/CSV export, local simulation mode.
- Excluded: VM 생성 자동화, enterprise RBAC, 장기 metrics warehouse, browser synthetic monitoring, 외부 APM deep integration.

### Inputs
| Item | Format | Source | Notes |
|---|---|---|---|
| Workflow definition | JSON / 기존 `Workflow` model | ApiLens workflow repository | 기존 nodes, edges, env, execution policy를 재사용한다. |
| Load profile | JSON / Dart model | UI 사용자 입력 | virtual users, duration, ramp-up, iterations, think time, concurrency cap을 포함한다. |
| Remote machine inventory | JSON / Dart model | 사용자 입력, import, discovery endpoint | machine id, host, labels, credentials reference, platform, agent install path를 포함한다. |
| Agent registration | HTTP/WebSocket message | Remote agent daemon | agent id, version, hostname, tags, capacity, supported protocols를 포함한다. |
| Agent upgrade package | URL / checksum / version manifest | 사용자 또는 release server | target version, package URL, checksum, migration notes, rollback package를 정의한다. |
| Run control command | JSON API request | ApiLens UI 또는 Load Hub | start, pause, cancel, drain, retry failed shard를 수행한다. |
| Machine management command | JSON API request | ApiLens UI 또는 Load Hub | drain, enable, disable, tag, restart agent, upgrade agent, rollback agent를 수행한다. |
| Agent event stream | NDJSON / WebSocket frames | Remote agents | heartbeat, logs, node results, metric windows, shard status를 전송한다. |

### Outputs
| Item | Format | Destination | Notes |
|---|---|---|---|
| Distributed run record | Dart model / persisted JSON | Local Hive/Isar 또는 Load Hub storage | run id, status, profile, agent assignments를 추적한다. |
| Machine inventory view | Dart model / persisted JSON | ApiLens UI 및 Load Hub storage | machine status, labels, version, capacity, upgrade state를 추적한다. |
| Upgrade rollout record | JSON / table model | ApiLens UI 및 Load Hub storage | target version, selected machines, per-machine status, health check, rollback status를 추적한다. |
| Live metrics snapshot | JSON stream | ApiLens UI state | RPS, latency percentiles, failures, active users, agent health를 제공한다. |
| Node-level results | JSON / table model | Result viewer 및 export | workflow node, status code, error type 기준으로 집계한다. |
| Raw event archive | NDJSON | 개발 중 `output/stepNN_<name>.<ext>`, 이후 앱 export | replay와 debugging에 사용한다. |
| Final report | Markdown/HTML/CSV/JSON | 사용자 export path | summary, charts, errors, agent utilization을 포함한다. |

### Constraints
- Backward compatibility: 기존 workflow JSON과 로컬 실행 동작은 깨지면 안 된다.
- Determinism: scheduling, shard id, run state transition, metric aggregation은 결정적이고 테스트 가능해야 한다.
- Network resilience: agent disconnect, Load Hub restart, partial result upload failure, cancellation race를 명시적으로 처리해야 한다.
- Security: 원격 에이전트는 인증되지 않은 Load Hub의 임의 workflow 실행을 허용하면 안 된다. 1차는 shared-token 인증으로 시작하고, 향후 mTLS를 문서화한다.
- Resource safety: agent concurrency, max outbound RPS, body size limit, log retention limit은 설정 가능해야 한다.
- Upgrade safety: agent upgrade는 사용자가 force mode를 명시하지 않는 한 active load run을 중단하면 안 된다. 기본값은 drain-before-upgrade, post-upgrade health check, rollback이다.
- UX fit: UI는 운영 콘솔처럼 밀도 있고 반복 작업에 적합해야 하며, 마케팅 페이지처럼 보이면 안 된다.

### Terms
| Term | Definition |
|---|---|
| Load Hub | 원격 성능 테스트의 중앙 제어 서버. run 생성, machine inventory, agent lifecycle, shard scheduling, result ingest, metrics aggregation, UI monitor API를 담당한다. 코드/문서에서는 `Coordinator`와 같은 의미로 사용하되, 사용자-facing 용어는 “Load Hub”를 기본값으로 쓴다. |
| Coordinator | Load Hub의 내부 아키텍처 명칭. run state 소유, shard 배정, metrics 수집, ApiLens UI용 monitor data 제공을 담당하는 중앙 process/API. |
| Remote Machine | 하나의 ApiLens load agent를 실행할 수 있는 물리/가상/container host. 현재 agent process와 독립된 inventory metadata를 가진다. |
| Remote Agent | load generator machine에서 실행되는 원격 daemon. 할당된 workflow shard를 실행하고 event stream을 Load Hub로 전송한다. 사용자-facing 용어는 “원격 에이전트”를 기본값으로 쓴다. |
| Agent | Remote Agent의 짧은 내부 명칭. 코드 model과 protocol payload에서는 `agent`로 표현한다. |
| Agent Version | 원격 머신에 설치된 load agent build. semantic version, protocol version, checksum, feature flags를 포함한다. |
| Upgrade Rollout | 선택된 agent를 batch 단위로 drain, install, restart, health check, optional rollback하는 관리 작업. |
| Shard | 하나의 load test run을 특정 agent에 배정하기 위한 결정적 조각. 예: users 1-100 또는 특정 time window. |
| Load Profile | virtual users, ramp-up, duration, iterations, think time, limits를 포함하는 성능 테스트 형태. |
| Metric Window | 보통 1초 또는 5초 단위의 작은 time bucket. request count, errors, latency histogram을 포함한다. |
| Local Aggregation | 원격 에이전트가 개별 요청 결과를 즉시 Load Hub로 보내지 않고 짧은 시간창 단위로 count, error, latency histogram을 먼저 집계하는 방식. |
| Ingest Queue | Load Hub가 에이전트의 metrics/event stream을 즉시 UI/state에 반영하지 않고 비동기 buffer에 받아 처리하는 내부 queue. 순간 트래픽과 UI 업데이트 부하를 분리한다. |
| Backpressure | Load Hub나 네트워크가 처리 한계에 가까워질 때 에이전트에게 전송 주기 증가, log sampling, raw event 축소를 지시하는 흐름 제어 방식. |
| Raw Event | 개별 node execution, request failure, log line 같은 원본 이벤트. 기본적으로 전체 실시간 전송 대상이 아니며 sampling 또는 오류 중심으로 제한한다. |
| Aggregate Event | 원격 에이전트가 metric window별로 요약한 이벤트. 실시간 취합의 기본 전송 단위다. |
| Run | immutable workflow snapshot과 load profile을 가진 하나의 분산 성능 테스트 실행. |

## 2. Workflow Definition

### End-to-End Flow
`Workflow + Load Profile + Machine Inventory + Agent Pool -> Step 01 Validate Inputs -> Step 02 Register Machines and Agents -> Step 03 Plan Run -> Step 04 Simulate Agents -> Step 05 Dispatch Shards -> Step 06 Stream Metrics -> Step 07 Monitor UI -> Step 08 Upgrade Agents -> Step 09 Finalize Report -> Step 10 Document and Validate -> Final Output`

### LLM vs Code Boundary
| LLM handles | Code handles |
|---|---|
| 구현 계획이 사용자 의도와 맞는지 검토, tradeoff 요약, 빠진 UX/운영 가정 탐지, release note와 문서 문장 작성 | Workflow serialization, schema validation, run scheduling, HTTP/WebSocket protocol, heartbeat timer, metrics aggregation, persistence, tests |

#### Step 01: Validate Inputs
1) Step Goal:
선택한 Workflow와 load profile이 원격에서 정의되지 않은 동작 없이 실행 가능한지 확인한다.

2) Input / Output:
- Input: 기존 `Workflow`, 선택된 environment variables, 사용자 정의 load profile.
- Output: validation warning과 blocking error를 포함한 `RemoteRunDraft`.

3) LLM Decision Area:
지원하지 않는 node type, 위험한 부하 수준, 운영상 주의점에 대한 warning copy와 문서가 충분히 명확한지 검토한다.

4) Code Processing Area:
workflow graph, node config schema, template reference, timeout/retry policy, profile bounds, required secrets를 검증한다.

5) Success Criteria:
잘못된 run은 시작할 수 없고, 유효한 run은 immutable workflow snapshot과 normalized load profile을 생성한다.

6) Validation Method:
schema/profile validation 단위 테스트와 accepted/rejected workflow golden fixture를 사용한다.

7) Failure Handling:
blocking validation error는 UI에 반환한다. 복구 가능한 문제는 warning으로 표시하고 dispatch 전 사용자 확인을 요구한다.

8) Skills / Scripts:
- Skill: none
- Test: `test/features/remote_runner/remote_run_validator_test.dart`

9) Intermediate Artifact Rule:
`output/step01_validate_inputs.json`

#### Step 02: Plan Distributed Run
1) Step Goal:
normalized load profile을 결정적인 agent shard assignment로 변환한다.

2) Input / Output:
- Input: `RemoteRunDraft`, 사용 가능한 agent capabilities, 요청된 distribution policy.
- Output: run id, shard ids, agent eligibility, schedule windows, limits를 포함한 `RemoteRunPlan`.

3) LLM Decision Area:
문서에서 equal split과 capacity-weighted split 같은 scheduling policy tradeoff를 비교 설명한다.

4) Code Processing Area:
run ids, shard ids, virtual user ranges, ramp-up offsets, per-agent limits, expected metric windows를 생성한다.

5) Success Criteria:
동일한 draft와 agent pool은 사용자가 distribution policy를 바꾸지 않는 한 항상 동일한 plan을 생성한다.

6) Validation Method:
deterministic scheduling, capacity weighting, min/max agent counts, edge cases에 대한 순수 Dart 단위 테스트를 작성한다.

7) Failure Handling:
eligible agent가 없으면 명확한 이유와 함께 `NEEDS_USER_INPUT` 상태로 전환한다. capacity가 부족하면 부하 감소 또는 agent 대기를 제안한다.

8) Skills / Scripts:
- Skill: none
- Test: `test/features/remote_runner/remote_run_planner_test.dart`

9) Intermediate Artifact Rule:
`output/step02_plan_distributed_run.json`

#### Step 03: Manage Machines and Agents
1) Step Goal:
원격 머신과 설치된 에이전트의 availability, version compatibility, health, capacity, labels, administrative state를 정확한 운영 인벤토리로 유지한다.

2) Input / Output:
- Input: machine records, agent registration requests, heartbeats, capability updates, machine management commands.
- Output: `MachineInventoryState`, `AgentRegistryState`, agent health events.

3) LLM Decision Area:
agent setup 문서와 troubleshooting message에 들어갈 운영 권장 사항을 요약한다.

4) Code Processing Area:
agent 인증, machine/agent registry upsert, labels/tags 적용, heartbeat expiry, active shards 추적, enabled/disabled/draining 상태 관리, UI용 machine status 노출을 처리한다.

5) Success Criteria:
machine과 agent가 `unknown`, `online`, `busy`, `draining`, `disabled`, `offline`, `incompatible`, `upgrade_required` 상태 사이를 예측 가능하게 이동한다.

6) Validation Method:
registration/management payload 계약 테스트, heartbeat expiry fake-clock 테스트, inventory persistence repository 테스트를 작성한다.

7) Failure Handling:
incompatible agent는 이유와 함께 거절한다. heartbeat가 끊긴 machine은 timeout 이후 offline으로 표시한다. disabled machine에는 shard를 배정하지 않는다. 시작 전 shard는 requeue하고 active shard는 run policy에 따라 fail 또는 reassign한다.

8) Skills / Scripts:
- Skill: `remote-runner-ops`
- Script: `scripts/remote_runner/simulate_agents.dart`

9) Intermediate Artifact Rule:
`output/step03_register_monitor_agents.json`

#### Step 04: Upgrade Agents
1) Step Goal:
선택한 원격 에이전트를 안전하게 업그레이드하면서 run integrity를 보존하고, 사용자에게 진행률, health, rollback 정보를 명확히 제공한다.

2) Input / Output:
- Input: selected machine ids, target agent version manifest, rollout policy, current machine/agent state.
- Output: `AgentUpgradePlan`, `AgentUpgradeRolloutState`, per-machine upgrade events, final rollout summary.

3) LLM Decision Area:
upgrade release notes를 검토하고 operator-facing risk를 요약하며, 실패한 upgrade의 troubleshooting 문구를 작성한다.

4) Code Processing Area:
package checksum 검증, rollout batch 생성, active agent drain, upgrade command 전송, install/restart monitoring, post-upgrade health check, 설정된 rollback 실행을 처리한다.

5) Success Criteria:
agent가 staged batch로 target version에 업그레이드된다. 기본 모드에서는 active run이 중단되지 않는다. incompatible 또는 failed agent는 실행 가능한 상태 메시지를 가진다.

6) Validation Method:
rollout planning 단위 테스트, 성공/실패/rollback 경로 fake-agent 통합 테스트, upgrade command payload 계약 테스트를 작성한다.

7) Failure Handling:
machine이 busy이면 policy에 따라 drain을 기다리거나 skip한다. install이 실패하면 가능하면 이전 agent를 계속 실행한다. restart 후 health check가 실패하면 rollback package가 있을 때 이전 버전으로 되돌리고, 없으면 `upgrade_failed`로 표시한 뒤 해당 machine의 scheduling을 비활성화한다.

8) Skills / Scripts:
- Skill: `remote-runner-ops`
- Test: `test/features/remote_runner/agent_upgrade_service_test.dart`

9) Intermediate Artifact Rule:
`output/step04_upgrade_agents.json`

#### Step 05: Dispatch and Execute Shards
1) Step Goal:
workflow snapshot과 shard assignment를 원격 agent에 전송하고, 재사용 가능한 workflow runtime으로 각 shard를 실행한다.

2) Input / Output:
- Input: `RemoteRunPlan`, agent connections, immutable workflow snapshot.
- Output: shard lifecycle events와 node execution events.

3) LLM Decision Area:
target system impact 같은 원격 실행 위험에 대한 문서와 user-facing warning을 검토한다.

4) Code Processing Area:
workflow snapshot serialization, dispatch command 전송, virtual user 또는 iteration별 `ExecutionEngine` 실행, rate/concurrency control 적용, event streaming을 처리한다.

5) Success Criteria:
각 shard가 `queued`, `running`, `completed`, `cancelled`, `failed` 중 하나에 도달한다. cancellation은 새 iteration 시작을 막고 in-flight request를 timeout 내 drain한다.

6) Validation Method:
in-process fake coordinator와 fake agents를 사용한 통합 테스트를 작성하고, 기존 `execution_engine_test.dart`는 계속 통과해야 한다.

7) Failure Handling:
일시적 transport failure는 dispatch를 재시도한다. agent가 shard 중간에 disconnect되면 shard를 lost로 표시하고, load profile이 replay를 허용할 때만 reassign한다.

8) Skills / Scripts:
- Skill: none
- Script: `scripts/remote_runner/run_fake_distributed_test.dart`

9) Intermediate Artifact Rule:
`output/step05_dispatch_execute_shards.ndjson`

#### Step 06: Stream and Aggregate Metrics
1) Step Goal:
모든 agent의 aggregate event와 제한된 raw event를 live run metrics와 monitor-friendly summary로 변환한다.

2) Input / Output:
- Input: agent event stream, shard lifecycle events, aggregate metric windows, sampled node results, heartbeat metrics.
- Output: `RunMetricsSnapshot`, node-level aggregates, error breakdown, latency histograms.

3) LLM Decision Area:
deterministic metrics 계산 이후 final report note를 해석하고 unusual pattern을 사용자 검토용으로 강조한다.

4) Code Processing Area:
event ingest queue, event id 기반 dedupe, time window bucketing, histogram merge, p50/p90/p95/p99 계산, raw/aggregate data persistence, backpressure signal 전송을 처리한다.

5) Success Criteria:
UI가 bounded memory growth를 유지하면서 live throughput, latency, errors, active VUs, completed iterations, agent utilization을 표시할 수 있다. 에이전트 수가 늘어나도 Load Hub는 개별 요청 raw event 전송량에 선형으로 압도되지 않는다.

6) Validation Method:
고정 event fixture와 expected percentile/error output을 사용한 aggregator 단위 테스트를 작성한다.

7) Failure Handling:
duplicate event는 버리고, malformed event는 quarantine한다. log volume이나 ingest lag가 설정 한도를 넘으면 backpressure, sampling, window interval 증가, raw event 축소를 적용한다.

8) Skills / Scripts:
- Skill: none
- Script: `scripts/remote_runner/stress_metric_ingest.dart`
- Test: `test/features/remote_runner/metrics_aggregator_test.dart`

9) Intermediate Artifact Rule:
`output/step06_stream_aggregate_metrics.json`

#### Step 07: Finalize Results and Report
1) Step Goal:
run을 종료하고 유용한 raw data를 보존하며 최종 성능 결과를 사용자에게 제공한다.

2) Input / Output:
- Input: final run state, aggregate metrics, raw event archive, validation warnings.
- Output: report model, export files, UI result screen.

3) LLM Decision Area:
문서 또는 optional report note에 들어갈 간결한 설명 요약을 생성하되, 사실과 해석을 명확히 분리한다.

4) Code Processing Area:
run status finalize, final aggregates 계산, export file 생성, report metadata 저장, dashboard/result widgets 렌더링을 처리한다.

5) Success Criteria:
사용자는 configured load와 achieved load를 비교하고, node/agent/status 기준 failure를 살펴보며, 재현 가능한 증거를 export할 수 있다.

6) Validation Method:
result UI widget test, export snapshot test, raw event에서 report를 재구성하는 replay test를 작성한다.

7) Failure Handling:
final aggregation이 실패하면 raw events를 보존하고 partial report status를 표시한다. export가 실패하면 run data를 유지하고 retry action을 제공한다.

8) Skills / Scripts:
- Skill: `remote-runner-ops`
- Script: `scripts/remote_runner/export_run_report.dart`

9) Intermediate Artifact Rule:
`output/step07_finalize_results_report.md`

### State Model
| State | Entry Condition | Exit Condition | Next State |
|---|---|---|---|
| `COLLECTING_REQUIREMENTS` | 사용자가 원격 load runner 설계나 구현을 요청했지만 scope가 아직 불명확함 | 최소 가정이 기록되고 로컬 구조를 확인함 | `PLANNING` |
| `PLANNING` | 설계서 또는 구현 계획을 구성 중임 | model, protocol, UI, test strategy가 정의됨 | `RUNNING_SCRIPT` 또는 `VALIDATING` |
| `RUNNING_SCRIPT` | validation, simulation, formatter, analyzer, test가 실행 중임 | script가 성공하거나 actionable failure output을 생성함 | `VALIDATING` 또는 `FAILED` |
| `VALIDATING` | 설계서, code, protocol fixture, UI behavior를 확인 중임 | validation result가 확인됨 | `DONE` 또는 `NEEDS_USER_INPUT` 또는 `FAILED` |
| `NEEDS_USER_INPUT` | replay-on-agent-loss 또는 authentication mode처럼 정책 선택이 필요함 | 사용자가 정책을 선택하거나 default를 수락함 | `PLANNING` 또는 `DONE` |
| `DONE` | 설계서 또는 구현 milestone이 완료되고 검증됨 | Terminal | [none] |
| `FAILED` | 자동 복구가 불가능한 validation failure 또는 필수 dependency unavailable 상태 | Terminal | [none] |

## 3. Implementation Spec

### Recommended Folder Structure
```text
/project-root
  AGENTS.md
  /.agents
    /skills
      /remote-runner-ops
        SKILL.md
        /scripts
        /references
  /.codex
    /agents
      # 1차 구현에서는 별도 custom subagent 불필요
  /output
  /scripts
      /remote_runner
        simulate_agents.dart
        run_fake_distributed_test.dart
        export_run_report.dart
        stress_metric_ingest.dart
  /docs
    REMOTE_LOAD_RUNNER_DESIGN.ko.md
    REMOTE_AGENT_SETUP.ko.md
    LOAD_HUB_OPERATIONS.ko.md
    LOAD_HUB_IMPLEMENTATION_PROMPTS.ko.md
  /lib
    /features
      /remote_runner
        /domain
          /models
        /application
        /data
        /presentation
      /execution
        /application
          execution_engine.dart
```

### AGENTS.md Responsibilities
- 원격 load runner 구현 작업은 기존 Flutter/Dart 컨벤션을 따르고, `dart format`, `dart analyze`, targeted `flutter test` 실행을 요구한다.
- `ExecutionEngine`은 기존 로컬 workflow runtime으로 취급한다. 새 remote code는 workflow node 동작을 다시 작성하지 말고 이를 감싸거나 adapter로 재사용한다.
- protocol 변경은 schema fixture, backward-compatible migration note, coordinator/agent contract test를 포함해야 한다.
- UI 변경은 `lib/features/remote_runner/presentation`에 두고, run lifecycle model이 안정화되기 전까지 기존 workflow editor에 monitoring widget을 섞지 않는다.

### Custom Agent Definitions
| Name | Path | Role | Required Fields |
|---|---|---|---|
| none | none | 1차 구현은 제품 코드 구현 작업이므로 single Codex agent plus skills/scripts로 충분하다. 반복 운영용 custom subagent는 아직 필요하지 않다. | none |

### Skill and Script Inventory
| Name | Type | Role | Trigger Condition |
|---|---|---|---|
| `remote-runner-ops` | skill | 운영 문서, machine inventory 설정, agent upgrade rollout, fake distributed run replay, troubleshooting checklist를 안내한다. | remote machine management, agent deployment, upgrade, monitoring workflow 구현/문서화 시 사용한다. |
| `simulate_agents.dart` | script | local fake agent와 sample event 생성을 제공한다. | 실제 원격 머신 없이 agent protocol을 개발할 때 사용한다. |
| `run_fake_distributed_test.dart` | script | coordinator, fake agent, shard execution, metrics ingest를 함께 검증한다. | pre-merge integration validation에 사용한다. |
| `stress_metric_ingest.dart` | script | 여러 fake agent가 대량 `MetricWindowEvent`를 보내는 상황에서 Load Hub ingest queue, aggregation, backpressure를 검증한다. | 실시간 취합 성능 회귀 테스트에 사용한다. |
| `export_run_report.dart` | script | 저장된 run data에서 markdown/CSV/JSON report를 생성한다. | run 완료 후 또는 regression fixture에서 사용한다. |

### Skill Creation Rules

> 이 설계서에 정의된 모든 스킬은 구현 시 반드시 `skill-creator` 스킬(`/skill-creator`)을 사용하여 생성할 것.
> 직접 SKILL.md를 수동 작성하지 말 것 — 규격 불일치 및 트리거 실패의 원인이 됨.

skill-creator가 보장하는 규격:
1. SKILL.md frontmatter (`name`, `description`) 필수 필드 준수
2. `description`의 트리거 정확도 최적화 (eval 기반 optimization loop)
3. 스킬 저장 위치 `.agents/skills/<skill-name>/` 규격 준수
4. 폴더 구조 (`SKILL.md` + `scripts/` + `references/`) 규격 준수
5. Progressive disclosure: SKILL.md 본문 500줄 이내, 대용량 참조는 `references/`로 분리
6. 테스트 프롬프트 실행 및 품질 검증 완료

### Core Artifacts
| Path | Format | Producer | Purpose |
|---|---|---|---|
| `output/step01_validate_inputs.json` | JSON | Step 01 | 검증된 workflow/profile draft를 기록한다. |
| `output/step02_plan_distributed_run.json` | JSON | Step 02 | 결정적 shard plan을 기록한다. |
| `output/step03_register_monitor_agents.json` | JSON | Step 03 | fake 또는 real machine/agent registry snapshot을 기록한다. |
| `output/step04_upgrade_agents.json` | JSON | Step 04 | upgrade plan, rollout events, per-machine result를 기록한다. |
| `output/step05_dispatch_execute_shards.ndjson` | NDJSON | Step 05 | raw shard lifecycle과 node events를 기록한다. |
| `output/step06_stream_aggregate_metrics.json` | JSON | Step 06 | aggregate metrics fixture를 기록한다. |
| `output/step07_finalize_results_report.md` | Markdown | Step 07 | 개발 중 final report output을 기록한다. |

### Recommended Domain Model
| Model | Responsibility | Notes |
|---|---|---|
| `RemoteMachine` | machine identity, hostname/IP, platform, labels, credential reference, admin state, last seen time을 가진다. | host lifecycle과 agent process lifecycle을 분리한다. |
| `RemoteAgent` | agent identity, machine id, endpoint, version, protocol version, tags, capacity, supported node types, status를 가진다. | public export에는 secrets를 포함하지 않는다. |
| `AgentVersionManifest` | target version, package URL, checksum, protocol compatibility, minimum coordinator version, rollback package를 정의한다. | 안전한 upgrade operation에 필요하다. |
| `AgentUpgradePlan` | selected machines, target version, batch size, drain timeout, health check, rollback policy를 가진다. | 결정적인 rollout plan이다. |
| `AgentUpgradeRolloutState` | per-machine upgrade state, timestamps, logs, health status, rollback result를 가진다. | UI 표시 및 audit용으로 저장한다. |
| `LoadProfile` | duration, ramp-up, virtual users, iterations, think time, pacing, limits를 가진다. | run snapshot과 함께 저장한다. |
| `RemoteRunDraft` | workflow snapshot과 validation result를 포함한 pre-dispatch object다. | agent assignment 전에 생성한다. |
| `RemoteRunPlan` | immutable shard assignment와 schedule을 가진다. | 결정적이고 테스트 가능해야 한다. |
| `RunShard` | 하나의 agent에 배정되는 remote execution 단위다. | lifecycle과 replay policy를 가진다. |
| `AgentHeartbeat` | health, clock, active shards, CPU/memory hints, current throughput을 가진다. | monitor와 scheduling guardrail에 사용한다. |
| `RemoteExecutionEvent` | run, shard, node, log, heartbeat, metrics events의 envelope이다. | dedupe를 위해 event id를 포함한다. |
| `MetricWindowEvent` | agent가 local aggregation으로 만든 시간창 단위 aggregate event다. | request count, error count, status buckets, latency histogram, min/max/sum을 포함한다. |
| `IngestQueueState` | Load Hub의 event queue depth, lag, dropped/sampled count, backpressure level을 가진다. | 운영 UI와 backpressure 판단에 사용한다. |
| `BackpressureCommand` | agent별 전송 조절 명령이다. | window size 증가, raw event sampling rate 감소, log level 변경 등을 포함한다. |
| `RunMetricsSnapshot` | UI용 aggregated current state다. | frequent read에 최적화한다. |

### Load Hub Metrics Ingestion Design
실시간 결과 취합은 “모든 요청을 원본 이벤트로 Load Hub에 전송”하는 방식으로 설계하지 않는다. 부하 테스트 중 원격 에이전트가 수천~수만 RPS를 만들 수 있으므로, raw event 중심 구조는 네트워크, JSON decode, UI state update, 저장소 write amplification을 동시에 유발한다. 기본 설계는 원격 에이전트의 local aggregation과 Load Hub의 비동기 ingest pipeline을 조합한다.

#### 용어 기준
| 용어 | 기본 의미 | 사용자-facing 표현 |
|---|---|---|
| Load Hub | 중앙 제어/취합 서버 | Load Hub |
| Coordinator | Load Hub의 내부 컴포넌트명 | 필요할 때만 coordinator 병기 |
| Remote Machine | 원격 에이전트가 설치된 host | 원격 머신 |
| Remote Agent | 원격 머신에서 실행되는 load runner daemon | 원격 에이전트 |
| Metric Window | 짧은 시간창 단위의 집계 결과 | 지표 구간 |
| Raw Event | 개별 요청/노드/로그 이벤트 | 원본 이벤트 |
| Aggregate Event | 원격 에이전트가 집계 후 보낸 이벤트 | 집계 이벤트 |

#### 데이터 흐름
```text
Remote Agent
  -> local per-node/per-status latency histogram 생성
  -> 1s 또는 5s MetricWindowEvent 생성
  -> WebSocket/gRPC-stream/HTTP batch로 Load Hub 전송
  -> Load Hub Ingest Queue에 append
  -> Dedupe + validation + histogram merge
  -> hot metrics snapshot 갱신
  -> raw/aggregate storage에 비동기 flush
  -> UI monitor stream에 throttled snapshot publish
```

#### 에이전트 측 집계 규칙
| 항목 | 설계 |
|---|---|
| 기본 전송 단위 | 개별 요청이 아니라 `MetricWindowEvent`를 기본으로 전송한다. |
| window 크기 | 기본 1초, 고부하 또는 backpressure 상태에서는 5초 이상으로 늘릴 수 있다. |
| latency | raw latency list 대신 merge 가능한 histogram 또는 fixed bucket count를 전송한다. |
| status/error | node id, method/type, status code bucket, error type별 count를 전송한다. |
| raw event | 실패, timeout, assertion failure, sampled success만 제한적으로 전송한다. |
| log | 기본은 warning/error 중심이며 debug log는 sampling 또는 on-demand pull로 제한한다. |
| sequence | agent id, run id, shard id, window start, sequence number를 포함해 dedupe와 gap detection을 가능하게 한다. |

#### Load Hub ingest pipeline
| 단계 | 역할 | 성능 보호 장치 |
|---|---|---|
| Stream receiver | agent connection에서 frame을 읽고 최소 validation 수행 | connection별 read limit, payload size limit |
| Ingest queue | decode된 event를 비동기 queue에 적재 | bounded queue, overflow policy, lag metric |
| Dedupe/gap check | event id와 sequence number로 중복/누락 감지 | duplicate drop, gap warning |
| Aggregator worker | histogram merge와 count aggregation 수행 | worker isolate 또는 background service 분리 |
| Snapshot publisher | UI가 읽는 `RunMetricsSnapshot` 갱신 | 250ms~1s throttle, changed-field publish |
| Storage flusher | raw/aggregate event를 저장소에 기록 | batch write, compression, retention policy |
| Backpressure controller | queue lag와 메모리 사용량 기준으로 agent 전송량 조절 | sampling rate/window size/log level command |

#### 전송 프로토콜 선택
| 선택지 | 1차 권장도 | 이유 |
|---|---|---|
| WebSocket + binary/JSON frame | 높음 | Flutter/Dart 구현 난도가 낮고 기존 WebSocket 경험과 맞다. 초기 구현에 적합하다. |
| HTTP batch upload | 중간 | 단순하고 방화벽 친화적이지만 실시간성이 떨어진다. WebSocket 장애 시 fallback으로 적합하다. |
| gRPC streaming | 중장기 | backpressure와 typed contract가 좋지만 Flutter/web 호환성과 의존성 비용을 검토해야 한다. |

1차 구현은 WebSocket stream을 기본으로 하고, agent가 연결 불안정 시 HTTP batch upload로 metric window를 재전송할 수 있게 한다. 프로토콜 payload는 JSON으로 시작하되, histogram/event volume이 커지면 MessagePack 또는 protobuf 같은 binary encoding을 검토한다.

#### 성능 기준
| 기준 | 목표 |
|---|---|
| UI update rate | 기본 1초, 빠른 dashboard는 250ms throttle까지 허용 |
| agent metric window | 기본 1초, backpressure 시 5초 이상 |
| raw success event 전송 | 기본 비활성 또는 낮은 sampling rate |
| raw failure event 전송 | 기본 활성, 단 per-agent rate limit 적용 |
| Load Hub memory | active run당 bounded queue와 fixed-size rolling window 사용 |
| 저장소 write | event별 write 금지, batch write와 압축 사용 |

#### 장애 및 복구
| 상황 | 처리 |
|---|---|
| agent 연결 끊김 | agent status를 degraded/offline으로 전환하고 마지막 sequence 이후 gap을 표시한다. |
| metric window 재전송 | event id와 sequence number로 dedupe한다. |
| Load Hub queue 지연 | backpressure command로 window size 증가, raw event sampling 감소, log level 상향을 지시한다. |
| 저장소 flush 실패 | hot snapshot은 유지하고 flush retry queue에 보관한다. 한도 초과 시 raw event부터 drop하고 aggregate는 보존한다. |
| UI 구독자 과다 | UI stream은 snapshot cache를 공유하고 구독자별 전체 aggregation을 반복하지 않는다. |

### Protocol Plan
| Channel | Direction | Payloads | Default Transport |
|---|---|---|---|
| Agent registration | Agent -> Coordinator | `register`, `capabilities`, `authToken` | HTTP POST |
| Machine management | UI -> Coordinator | `addMachine`, `updateMachine`, `disableMachine`, `enableMachine`, `tagMachine`, `removeMachine` | Coordinator API |
| Agent lifecycle control | Coordinator -> Agent | `dispatchShard`, `cancelShard`, `drain`, `ping`, `restartAgent`, `upgradeAgent`, `rollbackAgent`, `healthCheck` | WebSocket 또는 HTTP long poll fallback |
| Event stream | Agent -> Load Hub | `heartbeat`, `shardStatus`, `metricWindow`, `sampledNodeResult`, `failureEvent`, `log` | WebSocket, HTTP batch fallback |
| Backpressure control | Load Hub -> Agent | `setMetricWindow`, `setSamplingRate`, `setLogLevel`, `pauseRawEvents`, `resumeRawEvents` | WebSocket control frame |
| UI monitor | Load Hub -> ApiLens UI | `runSnapshot`, `machineSnapshot`, `agentSnapshot`, `upgradeSnapshot`, `metricWindow` | service stream 기반 in-app provider |

### Implementation Phases
| Phase | Goal | Main Files | Tests |
|---|---|---|---|
| Phase 1 | Domain models and validation | `domain/models/*`, `remote_run_validator.dart` | `remote_run_validator_test.dart` |
| Phase 2 | Machine inventory and agent registry | `machine_inventory_service.dart`, `agent_registry.dart`, `remote_machine_repository.dart` | `agent_registry_test.dart` |
| Phase 3 | Shard planner | `remote_run_planner.dart` | `remote_run_planner_test.dart` |
| Phase 4 | Fake agent simulator | `agent_client.dart`, `simulate_agents.dart`, `run_fake_distributed_test.dart` | `fake_agent_contract_test.dart` |
| Phase 5 | Load Hub coordinator | `load_hub_coordinator.dart` | `load_hub_coordinator_test.dart` |
| Phase 6 | Metrics ingest, aggregation, backpressure | `metric_ingest_service.dart`, `metrics_aggregator.dart`, `backpressure_controller.dart`, `stress_metric_ingest.dart` | `metrics_aggregator_test.dart`, `backpressure_controller_test.dart` |
| Phase 7 | Monitoring UI and navigation | `load_hub_screen.dart`, `presentation/widgets/*`, `main_workspace_screen.dart` | `load_hub_ui_test.dart`, `load_hub_navigation_test.dart` |
| Phase 8 | Agent upgrade orchestration | `agent_upgrade.dart`, `agent_upgrade_service.dart`, `agent_update_panel.dart` | `agent_upgrade_service_test.dart` |
| Phase 9 | Report/export | `run_report.dart`, `remote_run_repository.dart`, `run_report_service.dart`, `export_run_report.dart` | `run_report_service_test.dart` |
| Phase 10 | Documentation and regression validation | `docs/REMOTE_LOAD_RUNNER_DESIGN.ko.md`, `docs/REMOTE_AGENT_SETUP.ko.md`, `docs/LOAD_HUB_OPERATIONS.ko.md`, `docs/LOAD_HUB_IMPLEMENTATION_PROMPTS.ko.md` | `dart analyze`, `flutter test test/features/remote_runner`, fake run/stress/report scripts |

### 현재 구현 상태

2026-05-09 기준 1차 구현은 앱 내부에서 동작하는 Load Hub domain/application/UI, fake agent 기반 분산 실행, 실시간 metric ingest/backpressure, agent upgrade orchestration, report/export까지 포함한다. 실제 원격 daemon, 네트워크 API 서버, 인증/mTLS, Hive/Isar 영속 저장소는 다음 운영화 단계에서 구현한다.

주요 진입점은 다음과 같다.

| 영역 | 구현 파일 |
|---|---|
| 화면 | `lib/features/remote_runner/presentation/screens/load_hub_screen.dart` |
| 메인 내비게이션 | `lib/core/widgets/main_workspace_screen.dart`, `lib/core/widgets/splash_screen.dart` |
| 중앙 조율 | `lib/features/remote_runner/application/load_hub_coordinator.dart` |
| 원격 머신/에이전트 | `machine_inventory_service.dart`, `agent_registry.dart`, `agent_client.dart` |
| 지표 취합 | `metric_ingest_service.dart`, `metrics_aggregator.dart`, `backpressure_controller.dart` |
| 업그레이드 | `agent_upgrade_service.dart` |
| 리포트 | `run_report_service.dart`, `remote_run_repository.dart`, `scripts/remote_runner/export_run_report.dart` |

## 4. Validation Checklist

- [ ] 모든 workflow step이 9개 필수 필드를 가진다.
- [ ] 중간 산출물이 `output/stepNN_<name>.<ext>` 규칙을 따른다.
- [ ] LLM과 code 책임이 명확히 분리되어 있다.
- [ ] human review 지점이 필요한 곳에 명시되어 있다.
- [ ] Codex skill path가 `.agents/skills/...`를 사용한다.
- [ ] Codex custom subagent가 필요할 경우 `.codex/agents/*.toml`을 사용한다.
- [ ] skill 추가/수정은 `skill-creator`를 언급한다.
