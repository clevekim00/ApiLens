# Load Hub testainers 검증 가이드

이 문서는 Docker 컨테이너를 사용해 Load Hub의 원격 에이전트 연동 흐름을 로컬에서 검증하는 방법을 설명한다.

## 목적

일반 unit/widget test는 Docker 없이 빠르게 실행한다. testainers 검증은 실제 컨테이너 endpoint를 원격 에이전트처럼 띄워 다음 항목을 확인한다.

- Docker 기반 원격 agent endpoint가 reachable 상태인지
- Load Hub `AgentRegistry`가 여러 원격 머신과 원격 에이전트를 등록하는지
- heartbeat payload에 포함된 `MachineResourceSnapshot`이 저장되는지
- CPU/memory pressure 상태가 `isUnderPressure`로 판정되는지

## 설치된 소프트웨어

로컬 검증용으로 다음 도구를 사용한다.

- Docker CLI
- Colima
- Dart dev dependency: `testainers`

macOS에서 새 환경을 준비할 때:

```bash
brew install docker colima
colima start --cpu 2 --memory 4 --disk 20
```

Docker daemon 상태 확인:

```bash
docker ps
```

## 테스트 위치

```text
test/features/remote_runner/load_hub_testainers_test.dart
```

이 테스트는 기본 `flutter test test/features/remote_runner`에서도 발견되지만, `APILENS_DOCKER_TESTS=1` 환경변수가 없으면 skip된다.

## 실행 방법

Docker 검증만 실행:

```bash
APILENS_DOCKER_TESTS=1 flutter test test/features/remote_runner/load_hub_testainers_test.dart
```

일반 Load Hub 회귀 테스트:

```bash
flutter test test/features/remote_runner
```

일반 테스트에서는 Docker 검증이 skip되므로 Docker Desktop/Colima가 없어도 기존 회귀 테스트를 실행할 수 있다.

## 현재 검증 범위

현재 테스트는 `TestainersHttpbucket` 컨테이너 2개를 원격 agent endpoint처럼 띄운다. 각 endpoint가 HTTP 200을 반환하는지 확인한 뒤, Load Hub registry에 다음 데이터를 넣어 검증한다.

- `docker-machine-1`, `docker-machine-2`
- `docker-agent-1`, `docker-agent-2`
- agent endpoint URL
- capacity
- resource heartbeat
- pressure 상태

## 다음 확장

실제 원격 daemon과 Load Hub transport가 구현되면 이 테스트를 다음 단계로 확장한다.

- `load-hub-server` 컨테이너 기동
- `remote-agent` custom image 기동
- agent registration HTTP/WebSocket 계약 검증
- metric ingest와 backpressure end-to-end 검증
- agent upgrade orchestration의 SSH/health check/rollback 검증
