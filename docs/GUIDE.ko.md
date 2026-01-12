# ApiLens 사용자 가이드

## 1. 개요
### ApiLens란 무엇인가?
**ApiLens**는 REST API, WebSocket, GraphQL을 단일 인터페이스에서 테스트하고, 이를 **Workflow**로 연결하여 복잡한 시나리오를 자동화할 수 있는 강력한 데스크톱 및 웹 기반 도구입니다.

### 해결하는 문제
- **파편화된 도구**: REST는 Postman, WebSocket은 wscat, 자동화는 Python 스크립트로 따로 관리하던 문제를 해결합니다.
- **협업의 어려움**: API 명세와 테스트 시나리오를 파일(`json`) 하나로 쉽게 공유할 수 있습니다.
- **복잡한 테스트**: "로그인 후 토큰을 받아 웹소켓 연결"과 같은 연속적인 시나리오를 코딩 없이 워크플로우로 구성할 수 있습니다.

### 대상 사용자
- API를 개발하고 테스트하는 **백엔드/프론트엔드 개발자**
- API 시나리오 검증이 필요한 **QA 엔지니어**
- 여러 프로토콜(HTTP, WS, GQL)을 다루는 **시스템 아키텍트**

---

## 2. 설치 및 실행
### Desktop (macOS / Windows)
1. 릴리즈 페이지에서 OS에 맞는 설치 파일(`.dmg`, `.exe`)을 다운로드합니다.
2. 설치 후 애플리케이션을 실행합니다.
3. 별도의 설정 없이 바로 로컬 DB(Hive/Isar)가 초기화됩니다.

### Web
1. 호스팅된 URL(예: `apilens.app`)에 접속합니다.
2. 브라우저의 로컬 스토리지(IndexedDB)를 사용하여 데이터가 저장됩니다.
   > **주의**: 브라우저 캐시를 지우면 데이터가 유실될 수 있으므로 중요 데이터는 자주 Export 하세요.

### 테스트 백엔드 연결 방법
ApiLens 개발 및 테스트를 위해 로컬에서 백엔드 서버를 실행할 수 있습니다.
```bash
# 백엔드 서버 실행 (Python/Node 등 프로젝트 환경에 따라)
npm run start:server
```
기본적으로 `http://localhost:3000` 또는 `ws://localhost:8080` 등을 사용합니다.

---

## 3. 핵심 개념
### Request
API 호출의 기본 단위입니다.
- **REST**: GET, POST, PUT, DELETE 등 HTTP 메서드 지원. Params, Headers, Body 설정 가능.
- **WebSocket**: 연결(Connect), 메시지 전송(Send), 수신 대기(Wait).
- **GraphQL**: Query/Mutation 실행 및 변수(Variables) 지원.

### Workflow
여러 Request를 노드(Node) 형태로 연결한 순서도입니다.
- **Start Node**: 실행 시작점.
- **Request Node**: REST/GQL 요청 수행.
- **WebSocket Node**: 연결 및 메시지 송수신.
- **Delay/Script Node**: 대기하거나 간단한 값 변환 수행.

### Workgroup
프로젝트 단위의 폴더 개념입니다. 로컬 파일 시스템의 폴더처럼 Request와 Workflow를 격리하여 관리합니다.

### Environment
`{{env.baseUrl}}`과 같이 전역 변수를 관리하여 개발/운영 환경을 쉽게 전환할 수 있습니다. (현재 개발 중)

---

## 4. Workgroup 사용법
### Workgroup 생성/선택
- **생성**: 사이드바 상단의 `+` 버튼을 클릭하여 새 그룹 이름을 입력합니다.
- **선택**: 사이드바에서 그룹을 클릭하면 활성화되며, 이후 생성되는 Request는 해당 그룹에 속하게 됩니다.

### no-workgroup (시스템 그룹)
- 특정 그룹을 선택하지 않은 상태에서 만든 항목들은 `System Default` 또는 `No Workgroup`에 저장됩니다.
- 사이드바 최상단에서 접근할 수 있습니다.

### 관리 및 이동
- **이동**: Request를 드래그하여 다른 Workgroup으로 이동시킬 수 있습니다.
- **삭제**: 그룹을 우클릭하여 삭제할 수 있습니다. (내부 데이터 보존 여부 선택 가능)

### Export / Import (팀 공유)
1. **Export**: Workgroup을 우클릭하고 `Export`를 선택하면 `.json` 파일로 저장됩니다.
2. **Import**: 사이드바 상단 `Import` 버튼(또는 메뉴)을 통해 `.json` 파일을 불러옵니다.
   > **ID 충돌 방지**: Import 시 기존 데이터와 ID가 겹치면 자동으로 새 ID를 발급하여 충돌을 방지합니다.

---

## 5. REST Request Builder
### 새 요청 만들기
1. 상단 탭에서 `HTTP / REST` 선택.
2. 메서드(GET, POST 등) 선택 및 URL 입력.

### 상세 설정
- **Params**: Query Parameter를 Key-Value로 입력.
- **Headers**: `Content-Type`, `Authorization` 등 헤더 설정.
- **Body**: JSON, Text, Form Data 등 선택. JSON은 문법 하이라이팅 지원.
- **Auth**: Basic, Bearer Token 등 간편 설정.

### 실행 및 결과
- `Send` 버튼을 클릭하면 우측(또는 하단) 패널에 응답 결과(Status, Time, Size, Body)가 표시됩니다.
- JSON 응답은 Tree View로 보기 좋게 포맷팅됩니다.

### Workgroup과의 관계
요청을 저장(`Ctrl+S` / `Cmd+S`)하면 현재 활성화된 Workgroup에 저장됩니다.

---

## 6. WebSocket
### WebSocket Client 사용법
1. 상단 탭에서 `WebSocket` 선택.
2. URL(예: `wss://echo.websocket.org`) 입력 후 `Connect` 클릭.
3. 연결 성공 시 초록색 상태 표시.
4. 메시지 입력 후 `Send`로 전송.
5. 송수신 로그가 실시간으로 쌓입니다.

### Workflow에서 사용
웹소켓은 상태가 유지되므로 Workflow에서 강력합니다.
- **ws_connect 노드**: 연결을 맺고 세션 ID 반환.
- **ws_send 노드**: 특정 세션으로 메시지 전송.
- **ws_wait 노드**: 특정 메시지나 패턴이 수신될 때까지 대기(테스트 검증용).

---

## 7. GraphQL
### GraphQL Client 사용법
1. 상단 탭에서 `GraphQL` 선택.
2. Endpoint URL 입력.
3. 좌측 에디터에 Query/Mutation 작성.
4. 필요한 경우 하단 Variables 탭에 JSON 변수 입력.
5. `Execute` 버튼으로 실행.

### REST → GraphQL 연계
Workflow에서 REST API로 인증 토큰을 받은 뒤, 이를 GraphQL 헤더(`Authorization: Bearer {{token}}`)에 넣어 요청할 수 있습니다.

---

## 8. Workflow Editor
### 노드 추가/연결
1. 상단 메뉴나 `+ Workflow` 버튼으로 에디터 진입.
2. 좌측 팔레트에서 노드를 드래그하여 캔버스에 배치.
3. 노드의 핸들(점)을 드래그하여 다른 노드와 연결(Edge 생성).

### 실행 방법
- 우측 상단 `Run` 버튼을 클릭.
- 실행 중인 노드는 테두리가 깜빡이며, 완료 시 초록색, 실패 시 빨간색으로 표시됩니다.
- 하단 로그 패널에서 각 단계별 실행 결과를 확인합니다.

### 디버깅 팁
- **Inspector**: 노드를 클릭하면 우측 패널에서 입력/출력 데이터를 상세히 볼 수 있습니다.
- **Partial Run**: 연결을 끊거나 특정 노드만 선택하여 부분 테스트를 진행할 수 있습니다.

---

## 9. OpenAPI Import
### Import 방법
1. Workgroup 우클릭 -> `Import Swagger` 선택.
2. **URL 로드**: `swagger.json` URL 입력 후 Load.
3. **파일 로드**: 로컬 파일 선택.

### 필터링 및 선택
- **Tag 필터**: 좌측에서 원하는 태그(예: `User`, `Order`)만 체크.
- **검색**: 상단 검색창에서 API Path나 Summary로 검색.
- **선택**: 리스트에서 가져올 API만 체크박스로 선택.

### Import 옵션
- **Base URL**: OpenAPI 명세의 Server URL을 사용할지, 환경변수(`{{env.baseUrl}}`)로 치환할지 선택.
- **Auto-Generate Body**: Request Body 예제를 자동으로 생성할지 여부.
- **Auth**: 보안 스키마(API Key 등)를 헤더에 자동 포함할지 여부.

---

## 10. 테마 및 환경 설정
### Dark / Light 전환
- 우측 상단 메뉴 -> `Settings` 진입.
- `Theme Mode`에서 Light / Dark / System 선택.

### 기타 설정
- **Timeout**: 요청 타임아웃 시간 설정 (기본 30초).
- **Logging**: 디버그 로그 활성화 여부.

---

## 11. 문제 해결
### 자주 묻는 질문 (FAQ)
**Q. REST 요청 시 CORS 에러가 발생합니다.**
A. Web 버전에서는 브라우저 보안 정책상 CORS 제약이 있습니다. 데스크톱 앱을 사용하거나, 서버에서 CORS를 허용해주세요.

**Q. Import 실패 ("Invalid Format")**
A. OpenAPI 3.0/3.1 규격을 준수하는지 확인하세요. YAML 포맷 문제일 수 있으니 JSON 변환 후 시도해보세요.

**Q. Workgroup이 사라졌습니다.**
A. 브라우저 캐시를 지우면 데이터가 초기화될 수 있습니다(Web). 중요 데이터는 주기적으로 Export 하여 백업하세요.
