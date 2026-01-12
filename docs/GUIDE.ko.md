# ApiLens 사용자 가이드

## 1. 개요
**ApiLens**는 개발자가 API를 설계, 테스트, 자동화할 수 있도록 돕는 강력한 올인원 도구입니다. REST, WebSocket, GraphQL을 모두 지원하며, 단순한 요청 테스트를 넘어 노드 기반의 워크플로우를 통해 복잡한 시나리오를 자동화할 수 있습니다.

### 주요 기능
- **다중 프로토콜 지원**: REST API, WebSocket, GraphQL을 하나의 인터페이스에서 관리합니다.
- **워크플로우 자동화**: n8n 스타일의 비주얼 에디터로 API 요청들을 연결하고 데이터를 흐르게 할 수 있습니다.
- **워크그룹(Workgroup) 시스템**: 프로젝트나 팀 단위로 리소스를 격리하고 정리합니다.
- **OpenAPI Import**: Swagger/OpenAPI 명세를 불러와 즉시 사용 가능한 요청으로 변환합니다.

### 대상 사용자
- 백엔드 API를 개발하고 테스트하는 엔지니어
- 프론트엔드 연동 전 API 동작을 확인해야 하는 개발자
- 복잡한 API 시나리오(인증 -> 데이터 조회 -> 가공)를 검증해야 하는 QA 엔지니어

---

## 2. 설치 및 실행

### Desktop (macOS / Windows)
1. 릴리스 페이지에서 OS에 맞는 설치 파일(.dmg 또는 .exe)을 다운로드합니다.
2. 설치 후 애플리케이션을 실행합니다.
3. 로컬 데이터베이스를 사용하여 인터넷 연결 없이도 동작합니다.

### Web
1. 배포된 웹 URL에 접속합니다.
2. 브라우저의 IndexedDB를 사용하여 데이터를 저장합니다.
   - *주의*: 브라우저 캐시를 비우면 데이터가 삭제될 수 있으므로 `Export` 기능을 활용하세요.

### 테스트 백엔드 연결
ApiLens는 개발 중인 로컬 서버(localhost) 및 원격 서버 모두와 통신할 수 있습니다.
- **Desktop**: `http://localhost:8080` 등 로컬 주소에 직접 접근 가능합니다.
- **Web**: 브라우저 보안 정책(CORS)으로 인해 로컬 서버 접근 시 프록시 설정이 필요할 수 있습니다.

---

## 3. 기본 개념

### Request
ApiLens에서 실행 가능한 가장 작은 단위입니다.
- **REST**: GET, POST, PUT, DELETE 등의 HTTP 요청.
- **WebSocket**: 서버와 연결을 맺고 메시지를 주고받는 세션.
- **GraphQL**: Query, Mutation, Subscription을 실행.

### Workflow
여러 Request를 논리적 순서로 연결한 자동화 스크립트입니다. 비주얼 노드 에디터를 통해 드래그 앤 드롭으로 구성합니다.

### Workgroup
파일 시스템의 '폴더'와 유사하지만 더 강력한 격리 공간입니다. 각 Workgroup은 독립된 환경 변수(Environment)와 리소스를 가집니다.

### Environment
`{{baseUrl}}`, `{{token}}`과 같이 자주 변하는 값을 변수로 관리합니다. Workgroup 단위로 설정됩니다.

---

## 4. Workgroup 사용법

### 생성 및 선택
1. **생성**: 사이드바 상단의 `+` 버튼을 클릭하여 새 Workgroup(폴더)을 만듭니다.
2. **선택**: 사이드바에서 폴더를 클릭하면 해당 그룹이 활성화됩니다.
3. **No Workgroup**: 기본 시스템 그룹입니다. 특정 그룹에 속하지 않은 항목들이 이곳에 보관됩니다.

### 리소스 관리
- **이동**: Request나 Workflow 항목을 드래그하여 다른 Workgroup 폴더로 이동시킬 수 있습니다.
- **구조화**: Workgroup 내부에 하위 폴더를 생성하여 계층적으로 정리할 수 있습니다.

### 공유 (Export / Import)
팀원과 API 명세를 공유할 때 사용합니다.
1. **Export**: Workgroup 우클릭 -> `Export JSON` 선택. `.json` 파일로 저장됩니다.
2. **Import**: 사이드바 상단 `Import` 버튼 -> `.json` 파일 선택. 새로운 Workgroup으로 복원됩니다.

---

## 5. REST Request Builder

### 새 요청 만들기
1. `+ Request` 버튼 클릭 후 `REST` 탭을 선택합니다.
2. **Method**: GET, POST 등을 선택합니다.
3. **URL**: 엔드포인트 주소를 입력합니다. (예: `{{baseUrl}}/users`)

### 구성 요소
- **Params**: Query Parameter를 키-값 쌍으로 입력합니다.
- **Headers**: 인증 토큰이나 Content-Type 등을 설정합니다.
- **Body**: JSON, Form Data, Text 등 요청 본문을 작성합니다.

### 실행
- `Send` 버튼을 눌러 요청을 전송합니다.
- 하단 패널에서 Status Code, Response Body, Headers를 확인합니다.

---

## 6. WebSocket

### 연결 및 메시지 전송
1. Request 생성 시 `WebSocket` 탭을 선택합니다.
2. URL(ws:// 또는 wss://)을 입력하고 `Connect`를 누릅니다.
3. **Message**: 전송할 텍스트나 JSON을 입력하고 `Send`를 누릅니다.
4. **Log**: 주고받은 메시지 내역이 타임라인 형태로 표시됩니다.

### Workflow 연동
- **ws_connect**: 워크플로우 시작 시 소켓 연결을 맺습니다.
- **ws_send**: 특정 조건 만족 시 메시지를 보냅니다.
- **ws_wait**: 특정 메시지가 올 때까지 대기하거나, 응답을 검증합니다.

---

## 7. GraphQL

### 사용법
1. Request 생성 시 `GraphQL` 탭을 선택합니다.
2. **Query**: 에디터에 GraphQL 쿼리문을 작성합니다.
3. **Variables**: JSON 형식으로 변수 데이터를 입력합니다.
4. `Run` 버튼으로 실행하고 결과를 확인합니다.

### Workflow 노드 (gql_request)
- REST API 결과(예: User ID)를 받아 GraphQL 변수로 주입하여 실행하는 시나리오가 가능합니다.

---

## 8. Workflow Editor

ApiLens의 가장 강력한 기능인 워크플로우 에디터입니다.

### 사용 단계
1. `+ Workflow`를 클릭하여 빈 캔버스를 엽니다.
2. **노드 추가**: 우측 팔레트에서 Request 노드, 로직 노드(If, Loop, Delay) 등을 드래그합니다.
3. **연결**: 노드의 출력 포트와 다음 노드의 입력 포트를 선으로 연결합니다.
4. **데이터 매핑**: 이전 노드의 결과(`{{node1.data.id}}`)를 다음 노드의 입력값으로 사용합니다.

### 예제: 회원 가입 후 프로필 조회
1. **HTTP Request 1**: `POST /signup` (회원가입)
2. **Set Variable**: 응답에서 `token` 추출하여 저장.
3. **HTTP Request 2**: `GET /profile` (헤더에 `Authorization: Bearer {{token}}` 설정)
4. **Debug**: 최종 결과 출력.

---

## 9. OpenAPI Import

기존 Swagger/OpenAPI 문서를 기반으로 빠르게 Request를 생성합니다.

### 실행 방법
1. Workgroup 우클릭 -> `Import Swagger` 선택.
2. **Load**: `OpenAPI 명세 URL`을 입력하거나 JSON/YAML 파일을 업로드합니다.

### 필터링 및 선택
명세가 로드되면 3단 레이아웃이 표시됩니다.
- **좌측 (Tags)**: API 태그 목록. 원하는 태그만 체크하여 필터링합니다.
- **중앙 (Endpoints)**: 필터링된 API 목록. 검색창을 통해 Path나 Summary로 검색할 수 있습니다.
- **선택**: 필요한 API만 체크박스로 선택하거나 `Select All Filtered`로 일괄 선택합니다.

### Import 옵션
- **Base URL**: 환경 변수(`{{env.baseUrl}}`)를 사용할지, 명세에 적힌 고정 URL을 사용할지 선택합니다.
- **Body Sample**: Request Body 예제를 생성할 때 Schema를 따를지, Example 값을 우선할지 설정합니다.
- **Auth**: 보안 설정을 감지하여 인증 타입을 자동 설정할지 여부를 선택합니다.

---

## 10. 테마 및 환경 설정
- **테마 변경**: 우측 상단 설정을 통해 Dark 모드와 Light 모드를 전환할 수 있습니다. 눈의 피로도에 따라 선택하세요.

---

## 11. 문제 해결 (Troubleshooting)

**Q. Web 버전에서 CORS 오류가 발생합니다.**
A. 브라우저 보안 정책상 웹 클라이언트가 다른 도메인의 API를 호출할 때 서버 측의 허용(CORS 헤더)이 필요합니다. 개발 서버에 `Access-Control-Allow-Origin: *` 설정을 추가하거나, ApiLens Desktop 버전을 사용하세요.

**Q. WebSocket 연결이 끊어집니다.**
A. 일부 네트워크 방화벽이 WebSocket 트래픽을 차단할 수 있습니다. 또한, 서버의 Idle Timeout 설정을 확인하세요.

**Q. Import 시 일부 API가 누락됩니다.**
A. OpenAPI 3.0 이상 3.1 미만 버전을 권장합니다. 파싱 로그에 에러 메시지가 있는지 확인해보세요.
