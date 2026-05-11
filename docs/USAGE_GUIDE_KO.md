# ApiLens 사용 가이드

본 문서는 **ApiLens**의 인터페이스 설명과 자동화 워크플로우를 생성, 설정, 실행하는 방법을 안내합니다.

## 빠르게 둘러보기 (Quick Tour)

화면은 크게 6가지 영역으로 구성됩니다:

    *   **Dashboard (메인)**: 실시간 API 헬스체크, 응답 시간, 트래픽 통계를 보여주는 중앙 관제 센터.
    *   **Navigation (상단)**: 대시보드, 요청(Requests), 워크플로우(Workflows), 가져오기(Import), Load Hub 간의 빠른 전환.
    *   **Explorer (좌측)**: 워크그룹 및 폴더 단위의 요청 관리.
    *   **Canvas (중앙)**: 워크플로우를 디자인하는 무한 작업 공간.
    *   **Load Hub**: 원격 머신과 원격 에이전트 기반 분산 성능 테스트를 관제하는 화면.
    *   **Command Palette (Cmd + K)**: 작업 검색, 워크플로우 전환, 설정을 한 번에 실행하는 전역 검색창.

## 첫 번째 워크플로우 만들기

### 1. 새 워크플로우 시작
*   상단 바의 워크플로우 이름을 클릭하여 메뉴를 엽니다.
*   **New Workflow**를 선택합니다 (단축키: `Cmd/Ctrl + N`).
*   **Template 사용**: "Workflow Templates" 메뉴에서 미리 정의된 시나리오(로그인, 데이터 동기화 등)를 선택하여 즉시 시작할 수 있습니다.

### 2. 노드 추가
*   **Node Palette**에서 **Start** 노드를 캔버스로 드래그합니다. (모든 흐름의 시작점입니다).
*   **HTTP** 노드와 **End** 노드도 드래그하여 배치합니다.

### 3. 노드 연결
*   `Start` 노드의 **Output Port** (오른쪽 점)를 클릭 또는 드래그합니다. "Connection Mode" 메시지가 나타납니다.
*   `HTTP` 노드의 **Input Port** (왼쪽 점)를 클릭하면 선이 연결됩니다.
*   동일한 방식으로 `HTTP` 노드의 출력을 `End` 노드의 입력에 연결합니다.

### 4. HTTP 요청 설정
*   캔버스에서 **HTTP Node**를 클릭하여 선택합니다.
*   우측 **Inspector Panel**에서 다음을 설정합니다:
    *   **Method**: `GET` 선택.
    *   **URL**: 테스트 API 입력 (예: `https://jsonplaceholder.typicode.com/todos/1`).
    *   **Headers/Body**: 테스트를 위해 비워둡니다.

## 템플릿 변수 사용 (Using Templates)

`{{ }}` 문법을 사용하여 노드 간에 데이터를 동적으로 전달할 수 있습니다.

*   **노드 응답 참조**: 이전 노드의 실행 결과를 가져옵니다.
    *   문법: `{{node.<node_id>.response.body.<field>}}`
    *   예시: `{{node.http_1.response.body.title}}`
*   **환경 변수** (추후 지원 예정):
    *   문법: `{{env.API_KEY}}`

## 워크플로우 실행 (Running)

1.  상단 메뉴의 **Run** 버튼을 누르거나 `Cmd/Ctrl + Enter`를 입력합니다.
2.  `Start` 노드부터 순차적으로 실행됩니다.
3.  **실시간 시각적 디버깅 (Visual Debugging)**:
    *   **활성 노드**: 실행 중인 노드는 **파란색** 글로우(Glow) 효과와 함께 펄스 애니메이션이 적용됩니다.
    *   **활성 경로(Edge)**: 데이터가 흐르는 경로가 실시간으로 하이라이트됩니다.
        *   **초록색 경로**: 이전 노드 실행 성공 시.
        *   **빨간색 경로**: 에러 발생 또는 조건 불일치 시.
    *   **상태 코드 애니메이션**: 응답 결과에 따라 상태 코드가 화면에 팝업되며 시각적 피드백을 제공합니다.
4.  **로그 확인**: 하단 패널을 열어 각 단계의 요청/응답 상세 내용을 확인합니다.

### Timeout/Retry 정책

실행형 노드(HTTP, GraphQL, WebSocket Connect/Send/Wait)는 공통 `execution` 정책을 가질 수 있습니다.

*   **Timeout**: `timeoutMs`는 노드 실행 시도 1회당 제한 시간입니다.
*   **Retry**: `retry.maxAttempts`는 최초 실행 이후 추가 재시도 횟수입니다. 기본값은 `0`이라 기존 워크플로우는 자동 재시도하지 않습니다.
*   **Backoff**: `retry.backoffMs`는 재시도 전 대기 시간입니다.
*   **Status Code Retry**: HTTP/GraphQL 노드는 기본적으로 `408`, `429`, `500`, `502`, `503`, `504`를 재시도 대상으로 사용할 수 있습니다.
*   **Failure Routing**: 모든 재시도가 실패하면 노드는 `failure` 포트로 이동합니다. 실패 처리 경로를 연결해두면 에러 로깅/복구 시나리오를 구성할 수 있습니다.

자세한 정책 JSON 예시는 [Workflow Timeout/Retry 정책](WORKFLOW_TIMEOUT_RETRY_POLICY.ko.md)을 참고하세요.

## Load Hub로 분산 성능 테스트하기

Load Hub는 작성한 Workflow를 여러 원격 에이전트에 shard 단위로 나누어 실행하고, 결과를 실시간으로 취합하는 성능 테스트 콘솔입니다.

### 1. Load Hub 진입
*   상단 내비게이션에서 **Load Hub / 로드 허브** 탭을 선택합니다.
*   우측 상단 hub 아이콘이나 커맨드 팔레트의 `Open Load Hub` 명령으로도 이동할 수 있습니다.

### 2. 원격 머신과 에이전트 확인
*   **Machines** 탭에서 원격 머신의 admin state(`enabled`, `disabled`, `draining`)와 에이전트 상태를 확인합니다.
*   heartbeat, version, capacity, supported node type을 기준으로 shard 배정 가능 여부를 판단합니다.
*   **Machine Health** 탭에서 CPU, 메모리, disk I/O, network 사용량과 pressure 상태를 확인합니다.

### 3. 실행과 지표 모니터링
*   **Runs** 탭은 run 상태와 shard lifecycle을 보여줍니다.
*   **Metrics** 탭은 RPS, 오류율, p50/p90/p95/p99 latency, agent utilization을 보여줍니다.
*   Load Hub는 개별 요청 raw event 전체가 아니라 에이전트가 짧은 시간창으로 집계한 `MetricWindowEvent`를 취합합니다.

### 4. 에이전트 업그레이드와 결과 export
*   **Agent Updates** 탭에서 drain, install, restart, health check, rollback 흐름을 확인합니다.
*   완료된 run은 JSON, CSV, Markdown report로 내보낼 수 있습니다.

자세한 운영 절차는 [Load Hub 운영 가이드](LOAD_HUB_OPERATIONS.ko.md), 원격 에이전트 계약은 [원격 에이전트 설정 가이드](REMOTE_AGENT_SETUP.ko.md)를 참고하세요.

## 저장 및 불러오기

*   **Save**: `Menu -> Save` (`Cmd/Ctrl + S`) 변경 사항을 로컬에 저장합니다.
*   **Open**: `Menu -> Open` (`Cmd/Ctrl + O`) 저장된 목록을 불러옵니다.
*   **Export JSON**: 워크플로우 구조를 JSON 텍스트로 클립보드에 복사합니다.
*   **Import JSON**: 텍스트로 된 JSON 구조를 붙여넣어 워크플로우를 복원합니다.

## 조건 분기 (Condition Node)

**Condition** 노드를 사용하여 참/거짓 분기를 처리합니다:

1.  Condition 노드를 추가합니다.
2.  Inspector에서 **Expression**을 설정합니다.
    *   예시: `{{node.http_1.response.status}} == 200`
3.  **True** 포트를 성공 경로에 연결합니다.
4.  **False** 포트를 실패/에러 처리 경로에 연결합니다.

## 웹 사용자 팁 (Tips for Web)

### CORS 문제
웹 브라우저에서 실행 시 HTTP 요청이 즉시 네트워크 에러로 실패한다면?
*   **CORS (Cross-Origin Resource Sharing)** 정책 때문일 가능성이 높습니다. 브라우저는 허용되지 않은 외부 서버로의 요청을 차단합니다.
*   **해결책**: CORS 프록시 서비스를 사용하거나, 백엔드 서버가 `localhost` 출처를 허용하도록 설정해야 합니다.

### 성능
*   로그에 매우 큰 JSON 응답이 남을 경우 UI가 일시적으로 느려질 수 있습니다.

## 자주 묻는 질문 (FAQ)

**Q: 워크플로우가 중간에 멈춥니다.**
A: 연결이 끊긴 구간이 없는지 확인하세요. 예를 들어 Condition 노드의 False 경로가 연결되지 않았는데 조건이 거짓이 되면 실행이 중단됩니다.

**Q: 파일은 어디에 저장되나요?**
A: 앱 내부 데이터베이스(Hive)에 자동 저장됩니다. 안전한 백업이나 공유를 위해서는 "Export JSON" 기능을 사용하세요.

**Q: 반복문(Loop)이 가능한가요?**
A: 단순한 순환 연결은 가능하지만, 무한 루프에 대한 보호 장치가 아직 없습니다. 주의해서 사용하세요.

## 웹소켓 자동화 (WebSocket Automation)

ApiLens는 테스트 및 자동화 워크플로우 모두에서 웹소켓 기능을 지원합니다.

### 1. 웹소켓 테스터 (클라이언트)
상단 메뉴의 **Tools -> WebSocket Tester**를 통해 접근합니다.
*   서버 연결 및 메시지 송수신 테스트.
*   Text/JSON 메시지 로그 확인.
*   설정 저장 및 관리.

### 2. 워크플로우 통합
다음 3가지 노드를 사용하여 복잡한 웹소켓 시나리오를 구성할 수 있습니다:

*   **WS Connect**: 연결을 시작합니다.
    *   *Store Session As*: 세션 키(예: `mainWs`)를 지정하여 이후 노드에서 해당 연결을 참조합니다.
    *   *Mode*: "Direct"(동적 URL) 또는 "Config Ref"(저장된 설정 사용) 중 선택.
*   **WS Send**: 활성 세션으로 메시지를 전송합니다.
    *   *Payload*: 템플릿 문법을 지원합니다 (예: `{"token": "{{node.login.response.body.token}}"}`).
*   **WS Wait**: 특정 메시지가 수신될 때까지 대기합니다.
    *   *Match Type*: 텍스트 포함, JSON Path 일치 여부(예: `$.type == "pong"`) 등을 지원.
    *   *Timeout*: 지정된 시간 내 메시지가 없으면 실패 처리.

### 3. 웹(Web) 플랫폼 제약 사항
브라우저 환경(Web)에서 실행 시 주의사항:
*   **커스텀 헤더 불가**: 표준 브라우저 WebSocket API는 핸드쉐이크 시 커스텀 HTTP 헤더(예: `Authorization: Bearer ...`)를 지원하지 않습니다.
*   **우회 방법**: 인증 토큰을 전달하려면 **Query Parameter** (예: `?token=...`)를 사용하거나 **Subprotocol**을 활용해야 합니다.
*   *참고*: 데스크탑 앱(macOS/Windows)에서는 헤더 사용에 제약이 없습니다.

## GraphQL 자동화 (GraphQL Automation)

GraphQL API를 워크플로우에 통합하여 복잡한 데이터 조회를 자동화할 수 있습니다.

*   **GraphQL Request Node**: 전용 노드를 사용하여 쿼리를 실행합니다.
    *   **URL**: GraphQL 엔드포인트 주소.
    *   **Query**: `.graphql` 표준 문법을 지원하는 쿼리 입력창.
    *   **Variables**: JSON 형식의 변수 입력. 템플릿 변수(`{{ }}`)를 섞어서 사용할 수 있습니다.
*   **자동 인트로스펙션**: URL 입력 시 자동으로 스키마를 분석하여 쿼리 작성을 도와줍니다. (추후 고도화 예정)
*   **결과 참조**: `{{node.<id>.response.body.data.<field>}}` 문법으로 데이터에 접근합니다.
