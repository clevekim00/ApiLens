# ApiLens 프로젝트 분석 및 개선 제안

작성일: 2026-05-01

## 1. 한 줄 요약

ApiLens는 REST, WebSocket, GraphQL 요청을 하나의 데스크톱/웹 앱 안에서 다루고, 이를 Workflow Editor로 자동화하려는 Flutter 기반 API 작업 도구입니다. 현재 코드는 기능 범위가 넓고 제품 방향은 선명하지만, 데이터 계층 일관성, 워크플로 실행 엔진 완성도, 작업형 UI의 밀도와 정보 구조를 다듬으면 훨씬 강한 도구가 될 수 있습니다.

## 2. 현재 제품 방향

ApiLens의 핵심 가치는 "API 요청을 만들고 실행하는 화면"에서 끝나지 않고, 여러 프로토콜과 실행 흐름을 한 작업 공간에서 연결하는 데 있습니다.

주요 기능은 다음과 같습니다.

- REST 요청 작성, 실행, 응답 확인
- WebSocket 연결, 메시지 송수신, 설정 저장
- GraphQL 요청 작성 및 실행
- Workgroup 기반 요청/워크플로 분류
- OpenAPI/Swagger 스펙 import
- Workflow Editor 기반 노드 실행 흐름 구성
- History, Environment, Theme 설정
- 로컬 저장소 기반 작업 상태 유지

제품 포지션은 Postman/Insomnia류 API 클라이언트와 Node-RED류 흐름 편집기의 중간 지점에 가깝습니다. 이 방향은 꽤 좋습니다. 특히 API 테스트를 "단일 요청"이 아니라 "시나리오"로 다루려는 개발자에게 매력이 있습니다.

## 3. 코드 구조

### 앱 진입과 초기화

- 진입점: `lib/main.dart`
- 테마: `lib/core/ui/theme/app_theme_light.dart`, `lib/core/ui/theme/app_theme_dark.dart`
- 설정 저장소: `lib/core/settings/settings_repository.dart`
- Hive 기반 저장소: Workgroup, Request, Workflow, WebSocket Config
- Isar 기반 저장소: History, Environment

현재 `main.dart`는 Hive 초기화, Workflow Hive adapter 등록, 주요 Repository 초기화를 수행한 뒤 Provider override로 앱에 주입합니다. 이 구조는 이전보다 안전한 방향입니다. 다만 저장소 종류가 Hive와 Isar로 나뉘어 있어 장기적으로는 데이터 계층의 경계와 책임을 더 명확히 할 필요가 있습니다.

### Feature 구조

`lib/features` 아래에 기능별로 비교적 잘 분리되어 있습니다.

- `request`: REST 요청 모델, provider, 편집 UI
- `response`: 응답 뷰어, 비교 다이얼로그, 응답 provider
- `history`: 실행 기록 저장/검색
- `environments`: 환경 변수 관리
- `workgroup`: 프로젝트/폴더 단위 관리
- `import`: OpenAPI/Swagger import
- `graphql`: GraphQL 클라이언트
- `websocket`: WebSocket 클라이언트와 설정
- `workflow_editor`: 노드 기반 워크플로 편집
- `execution`: 워크플로 실행 엔진

분리 방향은 좋습니다. 다만 일부 파일은 UI, 상태 변경, 저장소 호출, 변환 로직이 한 곳에 같이 들어가 있어 규모가 커질수록 테스트하기 어려워질 수 있습니다.

## 4. 기능별 상태

### REST Request Builder

상태가 가장 안정적인 축입니다. `RequestModel`, `RequestNotifier`, `ResponseNotifier`, `ApiService`, `DioClient` 흐름이 비교적 이해하기 쉽습니다.

좋은 점:

- Params, Headers, Body, Auth가 별도 탭으로 분리되어 있음
- Environment 변수 치환을 지원함
- 자동 헤더와 사용자 헤더를 병합함
- 실행 후 History 저장 흐름이 있음
- 응답 body/jsonBody/header/metrics를 모델로 보존함

개선 포인트:

- Basic Auth, API Key Auth 구현이 주석 수준에 머물러 있음
- Path parameter 치환 UX와 실제 URL 반영 흐름을 더 명확히 해야 함
- 요청 저장/현재 편집 buffer/히스토리 restore의 ID 정책을 더 명확히 해야 함
- 에러 응답과 네트워크 실패를 UI에서 더 구분해서 보여줄 필요가 있음

### Response Viewer

JSON 응답과 raw text 응답을 나눠 보여주는 기본기는 좋습니다. 상태 코드, 응답 시간, 크기 표시도 API 도구에 필요한 정보입니다.

개선 포인트:

- Body, Headers 외에 Cookies, Timeline, Preview 같은 확장 탭 여지가 있음
- 큰 JSON 응답에서 검색, 접기/펼치기, copy path 같은 기능이 필요함
- status summary bar가 색과 텍스트 위주라 긴 상태 메시지/작은 화면에서 밀릴 수 있음
- 에러 상태에서는 request/response 구분, retry, curl copy 같은 회복 동작이 있으면 좋음

### Workgroup

Workgroup은 ApiLens의 좋은 차별화 요소입니다. 요청과 워크플로를 프로젝트 단위로 묶을 수 있어 팀 공유와 시나리오 관리에 잘 맞습니다.

좋은 점:

- 시스템 root 그룹 개념이 있음
- 그룹 하위 요청 export/import 흐름이 있음
- 삭제 시 요청 이동/삭제 정책을 선택할 수 있는 구조가 있음

개선 포인트:

- Workgroup, Request, Workflow 간 참조 무결성 검사가 더 필요함
- Import 시 이름 충돌, 중복 요청, 버전 호환 정책을 문서화해야 함
- Workgroup별 Environment baseUrl 정책이 OpenAPI import와 더 긴밀히 연결되면 좋음

### OpenAPI Import

최근 코드 기준으로 JSON/YAML 파싱, Swagger UI HTML에서 spec URL 탐색, 태그/검색/선택 import가 들어가 있습니다. 제품 가치가 큰 영역입니다.

좋은 점:

- JSON과 YAML을 모두 처리함
- `servers`, Swagger 2.0 `host/basePath/schemes`를 일부 지원함
- operation 단위 선택 import를 고려하고 있음
- body sample strategy, auth detect, baseUrl behavior 같은 옵션 모델이 있음

개선 포인트:

- `$ref` schema 해석이 제한적일 가능성이 큼
- requestBody의 multipart/form-data, x-www-form-urlencoded 샘플 생성이 아직 약함
- securitySchemes를 실제 Auth 설정으로 변환하는 로직이 더 필요함
- import 전 preview에서 "생성될 요청"을 사용자에게 더 정확히 보여줘야 함
- OpenAPI import 회귀 테스트가 필요함

### GraphQL

GraphQL 클라이언트가 별도 탭으로 존재하고, query/variables/auth/header/operationName 실행 흐름이 있습니다.

개선 포인트:

- schema introspection, docs explorer, query history가 있으면 사용성이 크게 올라감
- variables JSON validation과 formatter가 필요함
- GraphQL 응답의 `data`, `errors`를 시각적으로 분리하면 좋음
- REST request와 동일한 Environment/History/Save UX를 맞추는 것이 중요함

### WebSocket

WebSocket Manager와 Config Repository가 있고, 연결/전송/로그 stream 구조가 잡혀 있습니다.

개선 포인트:

- header 인자가 `WebSocketChannel.connect`에 실제 반영되지 않는 구조일 수 있어 확인이 필요함
- reconnect 정책 모델은 있지만 실행 로직은 더 보강해야 함
- 메시지 로그 검색, pin, export 기능이 있으면 실사용성이 올라감
- workflow engine의 WebSocket configRef 하드코딩을 제거해야 함

### Workflow Editor

ApiLens의 가장 큰 차별화 포인트입니다. Canvas, NodePalette, Inspector, Toolbar, Debug Panel 구조가 이미 잡혀 있습니다.

좋은 점:

- 노드/엣지 모델이 분리되어 있음
- Start/End/API/Condition/WebSocket/GraphQL 노드 방향성이 있음
- 저장된 workflow 목록과 editor state가 분리되어 있음
- 실행 로그와 node result 표시를 위한 기반이 있음

개선 포인트:

- 실행 엔진에서 일부 노드 타입 처리가 아직 빠져 있거나 임시 로직임
- `ws-config-001` 같은 하드코딩은 제거해야 함
- GraphQL node config 모델은 있지만 실행 엔진 연동은 더 확인해야 함
- 노드 실행 context의 변수 참조 문법과 JSON path 정책을 명확히 해야 함
- cycle detection은 있으나 branch/parallel/retry/timeout 정책은 아직 제한적임
- Workflow 실행 회귀 테스트가 필요함

## 5. 기술 부채 및 리스크

### P0: 런타임 안정성

- 저장소 초기화와 provider 주입 경로가 조금만 어긋나도 late initialization 문제가 날 수 있음
- Hive adapter 등록은 앱 진입점에 있으나 테스트/도구 실행 경로에서도 일관되게 보장해야 함
- History와 Environment는 Isar, 나머지는 Hive라 백업/마이그레이션 전략이 복잡해질 수 있음

### P1: 워크플로 실행 신뢰성

- Workflow Editor의 UI 완성도에 비해 ExecutionEngine은 아직 MVP 성격이 강함
- 노드별 실패/성공 port, context 저장, retry, timeout 정책이 제품 스펙으로 정리되어야 함
- WebSocket/GraphQL 노드가 REST 노드만큼 테스트되지 않으면 핵심 차별화 기능의 신뢰도가 떨어질 수 있음

### P1: 테스트 전략

- 네트워크 테스트는 로컬 서버 기반 회귀 테스트로 전환된 점이 좋음
- 추가로 OpenAPI parser, template resolver, expression evaluator, workflow execution에 단위 테스트가 필요함
- 위젯 테스트는 fake repository 기반으로 잘 분리하는 방향이 맞음

### P2: 코드 정리

- 일부 파일에 오래된 주석, 임시 구현 흔적, 사용되지 않는 변수와 import가 남아 있음
- UI 컴포넌트가 `core/ui/components`에 있지만 실제 화면에서 Material 기본 Card와 혼용되고 있음
- `RequestRepository`처럼 모델에 `toJson/fromJson`이 있음에도 repository에 별도 mapper가 남아 있는 부분은 정리 후보임

## 6. 추천 로드맵

### 1단계: 안정화

- `flutter analyze` 경고 정리
- 저장소 초기화, adapter 등록, migration 경로 문서화
- `test/network_test.dart` 같은 회귀 테스트 패턴을 parser/execution에도 확장
- `ApiService`, `GraphQLService`, `ExecutionEngine`의 응답 디코딩 방식을 일관화

### 2단계: Workflow MVP 완성

- Start, End, HTTP, Condition, GraphQL, WS Connect, WS Send, WS Wait 노드 실행 스펙 확정
- configRef 하드코딩 제거
- 노드별 timeout/retry/error port 정책 추가
- workflow run result를 저장하거나 export할 수 있게 설계
- 샘플 workflow를 테스트 fixture로 활용

### 3단계: OpenAPI Import 고도화

- `$ref` resolution 지원
- securitySchemes to Auth 변환
- requestBody schema sample 생성 강화
- import preview 화면 고도화
- import 결과 summary와 rollback 또는 undo UX 제공

### 4단계: UI/UX 정리

- 전체 앱을 "API 작업대"처럼 재배치
- 정보 밀도는 높이되 시각 잡음을 줄임
- 기능별 탭보다 작업 흐름 중심의 좌/중/우 레이아웃 강화
- 응답/히스토리/워크그룹/환경 변수 간 이동 동선을 줄임

## 7. UI 개선 의견

ApiLens는 마케팅형 화면보다 작업형 도구 화면이 어울립니다. 화려한 첫 화면보다, 실행하고 비교하고 저장하는 시간이 긴 개발자용 인터페이스가 중심이어야 합니다.

### 방향성

추천하는 시각 방향은 "quiet technical workspace"입니다.

- 배경은 밝은 회색/흰색 또는 차분한 다크 표면
- 주요 액션만 선명한 파란색 계열
- 성공/실패/경고는 상태 색상으로만 제한적으로 사용
- 카드 남발보다 패널, split view, table, toolbar 중심
- 큰 제목보다 작은 라벨, 상태 뱃지, compact control 중심

현재 테마는 기본 토큰이 있고 Light/Dark가 분리되어 있어 출발점은 좋습니다. 다만 화면 단위에서는 `Card`, `AppCard`, 기본 Material 컴포넌트가 섞여 있어 제품의 결이 살짝 흔들립니다.

### 메인 Request 화면 제안

현재는 상단 AppBar + 탭 + HTTP 화면 내부 split 구조입니다. 더 강한 API 도구 UX로 가려면 다음 구조가 좋습니다.

- 좌측: Workgroup Explorer + History를 고정 sidebar로 제공
- 중앙 상단: Method + URL + Send + Save를 한 줄 toolbar로 고정
- 중앙 본문: Params/Headers/Auth/Body 탭
- 우측 또는 하단: Response Viewer
- 상단 전역 탭: REST/WebSocket/GraphQL보다 "Client", "Workflow", "Import", "Settings" 같은 작업 단위로 재검토

특히 History가 drawer 안에 숨어 있으면 반복 작업 속도가 떨어집니다. API 도구에서는 과거 요청과 현재 요청 사이를 빠르게 오가는 것이 핵심이라 sidebar 고정이 더 맞습니다.

### Response Viewer 제안

응답 패널은 API 도구의 얼굴입니다. 아래 개선을 추천합니다.

- 상태 바를 compact metric row로 정리: status, time, size, content-type
- Body 탭에 JSON tree, raw, preview 모드 제공
- Headers 탭은 table 형태로 key/value/copy 액션 제공
- JSON 검색과 path copy 기능 추가
- 실패 시에는 error banner와 retry/copy curl 액션 제공

### Workflow Editor 제안

Workflow Editor는 "노드 편집기"보다 "시나리오 빌더"로 보여야 합니다.

- 좌측 Node Palette는 아이콘 중심 compact list
- 중앙 Canvas는 넓게, grid와 zoom controls 제공
- 우측 Inspector는 선택 노드의 설정만 집중해서 표시
- 하단 Debug Panel은 run logs, node output, variables 탭으로 분리
- 실행 중인 노드는 border/halo/progress로 상태를 보여주고, 완료된 노드는 작은 status chip만 유지

Node 카드의 텍스트와 포트 표기는 지금보다 더 조밀해져도 됩니다. 개발자 도구에서는 "예쁜 큰 카드"보다 "빠르게 읽히는 작은 노드"가 오래 씁니다.

### OpenAPI Import 화면 제안

OpenAPI Import는 많은 정보를 다루므로 table UX가 유리합니다.

- 상단: URL/file 입력, baseUrl 옵션, auth 옵션
- 좌측: tag filter
- 중앙: operation table
- 우측: 선택한 operation preview
- 하단: selected count, import destination, import button

operation list는 카드보다 table이 좋습니다. method, path, summary, tags, auth, body 여부를 한 줄에서 스캔할 수 있어야 합니다.

### WebSocket/GraphQL 화면 제안

WebSocket:

- 연결 설정과 메시지 로그를 좌우 split으로 유지
- 메시지 composer는 하단 고정
- receive/send 로그는 색보다 방향, timestamp, payload 구조로 구분

GraphQL:

- query editor, variables editor, response viewer를 3-pane으로 구성
- operationName, headers, auth는 접이식 side panel로 이동
- 응답은 data/errors/extensions를 분리

## 8. 디자인 시스템 제안

이미 `AppTokens`, `AppThemeLight`, `AppThemeDark`, `core/ui/components`가 있으므로 새 디자인 시스템을 크게 만들 필요는 없습니다. 대신 기존 토큰을 실제 화면에 더 일관되게 적용하는 편이 좋습니다.

추천 원칙:

- radius는 6-8px 중심으로 제한
- toolbar 높이, input 높이, tab 높이를 고정
- table/list row density를 정해 반복 화면에 재사용
- status badge 색상은 HTTP method 색상과 분리
- `AppCard`와 기본 `Card` 사용 기준을 정리
- compact icon button + tooltip 패턴을 공통화

컴포넌트 후보:

- `AppToolbar`
- `AppSplitPane`
- `AppStatusChip`
- `AppMetricBar`
- `AppDataTable`
- `AppEmptyState`
- `AppErrorBanner`
- `AppCodeEditorShell`

## 9. 다음 작업 추천

가장 효과가 큰 순서는 다음입니다.

1. Workflow execution 회귀 테스트 추가
2. OpenAPI parser 회귀 테스트 추가
3. Request 화면을 sidebar + split pane 기반으로 재배치
4. Response Viewer를 metric bar + table headers + JSON tooling 중심으로 개선
5. Workflow Editor의 Inspector와 Debug Panel UX 정리
6. 데이터 계층 저장소 전략 문서화 및 migration 테스트 추가

제품 관점에서는 3번과 4번이 체감 개선이 가장 큽니다. 기술 관점에서는 1번과 2번이 앞으로의 변경 속도를 지켜줍니다. 지금 ApiLens는 "기능을 더 넣어야 하는 단계"라기보다 "있는 기능을 작업 도구답게 연결하고 신뢰도를 높이는 단계"에 와 있습니다.

## 10. 2026-05-01 UI 리팩터링 진행 현황

이번 리팩터링에서는 Request, Response, Workgroup, History, WebSocket, GraphQL, Workflow Editor의 화면 구조를 "작업형 API 도구" 방향으로 정리했습니다. 핵심 목표는 화면을 예쁘게 꾸미는 것보다 반복 작업 속도, 정보 밀도, 좁은 화면 대응, 응답/로그 가독성을 개선하는 것이었습니다.

완료된 항목:

- Request 화면을 좌측 Workgroup/History sidebar, 중앙 요청 편집기, 응답 패널 구조로 재배치
- 좁은 화면에서 Request sidebar가 접히고 drawer로 열리도록 반응형 처리
- Response Viewer를 metric/status 중심 헤더, Body/Headers 탭, empty/loading/error 상태가 있는 패널로 정리
- Headers, Params, Auth, Body 편집 UI를 compact form/table/card 스타일로 통일
- Workgroup Explorer와 History Panel을 개발자 도구형 list/card 밀도로 정리
- Environment/Workgroup selector를 작은 toolbar 컨트롤로 정돈
- WebSocket 화면을 connection panel, message log, composer panel 중심으로 재구성
- GraphQL 화면을 endpoint/action bar, query/variables editor, response panel 구조로 정리
- Workflow Editor의 toolbar, Node Palette, Inspector, Debug Panel을 패널형 UI로 통일
- Workflow Editor 좁은 화면에서 Canvas 아래에 Nodes/Inspector/Debug tab panel이 배치되도록 반응형 처리
- Node Palette에서 클릭 추가와 canvas drag/drop 추가를 모두 지원
- Response Viewer에 body 검색, 검색 결과 highlight, body/header 복사, header 필터 추가
- WebSocket Message Log에 payload 검색, sent/received/system 방향 필터, payload 복사 추가
- 주요 UI 변경에 대한 smoke test를 보강하고 기존 widget/network 회귀 테스트를 통과
- Response Viewer body 검색과 header 필터에 대한 위젯 회귀 테스트 추가

현재 남은 UI 개선 후보:

- 실제 기기/브라우저 크기별 시각 QA: 390px, 768px, 1280px, 1440px 이상
- Response Viewer의 JSON tree 접기/펼치기 세부 제어, copy path 기능
- GraphQL schema introspection/docs explorer와 variables validation
- WebSocket 로그 pin, export 기능
- Workflow Canvas zoom controls, minimap, fit-to-screen, node alignment guide
- 공통 컴포넌트 추출: `AppToolbar`, `AppSplitPane`, `AppStatusChip`, `AppEmptyState`, `AppCodeEditorShell`
- OpenAPI Import 화면의 table/preview 중심 재설계

검증 기준:

- `dart analyze`로 변경 UI 파일 전체 정적 분석 통과
- `flutter test test/widget_test.dart test/smoke/app_smoke_test.dart test/network_test.dart test/response_viewer_test.dart` 회귀 테스트 통과
- `git diff --check`로 공백/패치 위생 검사 통과
