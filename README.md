# ApiLens

ApiLens는 Flutter, Riverpod, Hive로 구축된 강력한 로컬 우선(Local-first) API 테스팅 도구로, 요청 빌더, 응답 분석, 그리고 시각적 워크플로우 오케스트레이션 기능을 제공합니다.

![App Banner](docs/apilens_banner.png)

## 🌟 주요 기능 (Key Features)

### 1. Request Builder
- **메소드**: GET, POST, PUT, DELETE, PATCH 등 지원.
- **헤더/파라미터**: 토글(Toggle)을 지원하는 키-값(Key-Value) 에디터.
- **Body 포맷**: JSON, Text, None. JSON 템플릿 변수 지원.
- **인증(Auth)**: Bearer Token, Basic Auth, API Key.
- **cURL 통합**: cURL 명령어 가져오기/내보내기 지원.

### 2. Environment Manager (환경 변수)
- 개발(Dev), 운영(Prod) 등 환경별 변수 관리.
- URL, 헤더, Body 어디서든 `{{baseUrl}}`, `{{token}}` 문법 사용 가능.
- 실행 시 변수 자동 치환.

### 3. Visual Workflow Orchestrator (New)
API를 연결하고 복잡한 로직을 구성할 수 있는 그래프 기반 실행 엔진입니다.
- **Drag & Drop 인터페이스**: 시각적으로 흐름을 디자인합니다.
- **노드(Node) 타입**:
    - **Start/End**: 흐름의 시작과 끝 정의.
    - **HTTP Node**: API 요청 실행. 성공(2xx)/실패 경로 분기.
    - **Condition Node**: 조건식에 따른 분기 처리 (예: `{{node.api.response.status}} == 200`).
- **데이터 전달**: 이전 노드의 결과를 참조 (`{{node.{nodeId}.response.body.{field}}}`).
- **디버깅**: 
    - 실시간 상태 강조 (실행중, 성공, 실패).
    - **Context Inspector**: 각 노드의 실행 결과(JSON) 상세 조회.
- **영속성**: 워크플로우 로컬 저장/불러오기 및 JSON Export/Import.

### 4. WebSocket Automation (New)
실시간 WebSocket 연결 및 메시징을 지원합니다.
- **WebSocket Client**: 별도의 클라이언트 화면에서 연결, 메시지 전송, 로그 확인 가능.
- **Workflow Integration**: `ws_connect`, `ws_send`, `ws_wait` 노드를 통해 자동화 시나리오 구성.
- **REST 연계**: API 로그인 후 토큰을 소켓 연결에 사용하는 체이닝 지원.

---

## 🚀 시작하기 (Getting Started)

### 필수 요구사항 (Prerequisites)
- Flutter SDK (3.x 이상)
- macOS, Windows 또는 Linux (현재 데스크톱에 최적화됨)

### 설치 (Installation)
```bash
# 리포지토리 복제
git clone https://github.com/clevekim00/ApiLens.git

# 의존성 설치
flutter pub get

# macOS에서 실행 (권장)
flutter run -d macos
```

---

## 📖 워크플로우 템플릿 문법

워크플로우 엔진은 동적 데이터 처리를 위해 Handlebars 스타일의 문법을 지원합니다.

### 1. 환경 변수 (Environment Variables)
선택된 환경의 변수에 접근합니다.
- `{{env.baseUrl}}`
- `{{env.apiKey}}`

### 2. 노드 데이터 참조 (Node Data References)
**Node ID**를 사용하여 이전 실행 결과를 참조합니다.
- **상태 코드**: `{{node.{nodeId}.response.statusCode}}`
- **Body 필드**: `{{node.{nodeId}.response.body.accessToken}}` (중첩 JSON 지원)
- **헤더**: `{{node.{nodeId}.response.headers.content-type}}`

### 3. 조건식 (Condition Expressions)
**Condition Node**에서 분기 로직을 결정할 때 사용합니다.
- `{{node.login.response.statusCode}} == 200`
- `{{node.user.response.body.age}} > 18`
- `{{node.response.body.message}} contains "success"`

---

## 📚 문서 (Documentation)

### 🇰🇷 한국어 (Korean)
- [설치 가이드 (Installation)](docs/INSTALLATION.ko.md)
- [빌드 및 배포 (Build & Deploy)](docs/BUILD_AND_DEPLOY.ko.md)
- [사용자 가이드 (Usage Guide)](docs/USAGE_GUIDE.ko.md)
- [WebSocket 가이드 (WebSocket Guide)](docs/WEBSOCKET_GUIDE.ko.md)

### 🇺🇸 English
- [Installation Guide](docs/INSTALLATION.en.md)
- [Build & Deploy Guide](docs/BUILD_AND_DEPLOY.en.md)
- [Usage Guide](docs/USAGE_GUIDE.en.md)

---

### 기술 문서 (Technical Docs)
- [AI Integration Guide](docs/ai_integration_guide.md)
- [Workflow Implementation Plan](docs/workflow_implementation_plan_KR.md)

---

## 🗺️ 로드맵 (Roadmap)

- [x] 기본 요청/응답 (Basic Request/Response)
- [x] 환경 변수 관리 (Environment Variables)
- [x] 시각적 워크플로우 에디터 (Visual Workflow Editor)
- [x] 워크플로우 저장 및 내보내기 (Persistence & Export)
- [x] 디버그 패널 및 컨텍스트 인스펙터 (Debug Panel & Context Inspector)
- [x] WebSocket 지원
- [ ] GraphQL 지원
- [ ] 클라우드 동기화 / 팀 공유 (Cloud Sync)
- [ ] CI/CD용 CLI Runner

---

## 라이선스 (License)
MIT
