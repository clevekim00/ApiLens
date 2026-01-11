# WebSocket 사용 가이드

## 1. 개요
**ApiFlow Studio**는 REST API와 더불어 실시간 양방향 통신을 위한 **WebSocket** 프로토콜을 지원합니다.  
단순한 연결 테스트뿐만 아니라, **워크플로우(Workflow)** 내에서 WebSocket 연결, 메시지 전송, 특정 응답 대기 등의 작업을 자동화할 수 있습니다.

### 언제 사용하나요?
- 채팅 서버, 주식 호가, 알림 서비스 등 실시간성이 중요한 API를 테스트할 때
- REST API로 인증 토큰을 받고, 바로 WebSocket에 연결하여 데이터 흐름을 검증해야 할 때
- 서버가 특정 메시지(예: `ping`)에 대해 올바르게 응답(예: `pong`)하는지 시나리오 테스트가 필요할 때

---

## 2. WebSocket Client 사용법 (Manual Test)
워크플로우를 작성하기 전, 단일 연결에 대한 수동 테스트를 진행할 수 있습니다.

1. **메뉴 접근**: 상단 메뉴바에서 `WebSocket` -> `Open Client`를 선택하거나, `Request Builder` 화면의 `WebSocket` 탭을 이용합니다.
2. **연결 (Connect)**:
   - **URL**: `ws://` 또는 `wss://`로 시작하는 주소를 입력합니다.  
     *(예: `wss://echo.websocket.org`)*
   - **Connect 버튼**: 연결을 시도합니다. 성공 시 상태 배지가 **CONNECTED**(녹색)로 변경됩니다.
3. **메시지 전송 (Send)**:
   - 하단 입력창에 메시지를 입력하고 `Send` 버튼을 누릅니다.
   - 텍스트 뿐만 아니라 JSON 형식의 메시지도 전송 가능합니다.
4. **로그 확인**:
   - **초록색 화살표(⬇)**: 수신된 메시지
   - **파란색 화살표(⬆)**: 송신한 메시지
   - **회색 정보(ℹ)**: 시스템 메시지 (연결 성공, 에러 등)
5. **설정 저장**:
   - 자주 쓰는 URL은 좌측 패널(또는 설정 메뉴)을 통해 저장해두고 불러올 수 있습니다.

---

## 3. 인증과 Web 환경 제약 (중요)

### 플랫폼 간 차이 (Desktop/Mobile vs Web)
Flutter(Dart)의 기술적 특성상, **Desktop(macOS/Windows)** 및 **Mobile** 앱에서는 표준 WebSocket 구현(`dart:io`)을 사용하여 **Custom Header**를 자유롭게 설정할 수 있습니다.

하지만 **Web 브라우저** 환경에서는 브라우저 보안 정책 및 표준 API(`WebSocket` Web API)의 제약으로 인해 **WebSocket Handshake 시 Custom Header(예: `Authorization`)를 직접 추가하는 것이 불가능**할 수 있습니다.

### 권장 인증 방식
Web 환경 호환성을 위해 다음과 같은 인증 방식을 권장합니다:

1. **Query Parameter (가장 권장)**
   - 연결 URL에 토큰을 포함합니다.
   - 예: `wss://api.example.com/socket?token=YOUR_ACCESS_TOKEN`
   
2. **Subprotocol**
   - `Sec-WebSocket-Protocol` 헤더를 이용한 인증입니다.
   - 예: `protocols=['auth_token_xyz']`

> **Note**: Desktop 버전만 사용한다면 Custom Header(`Authorization: Bearer ...`)를 사용해도 무방합니다.

---

## 4. Workflow에서 WebSocket 사용
단순 테스트를 넘어 복잡한 시나리오를 구성할 때는 **Workflow Editor**를 사용합니다.

### 주요 노드(Node)

#### 1) WS Connect (`ws_connect`)
- **역할**: WebSocket 서버에 연결하고 세션을 유지합니다.
- **주요 설정**:
  - **Mode**: URI를 직접 입력(`Direct`)하거나 저장된 설정을 참조(`Config Ref`)할 수 있습니다.
  - **Store As (Session Key)**: 이 연결 세션의 고유 이름입니다. (예: `mainWs`). 이후 노드에서 이 키를 사용하여 메시지를 보내거나 기다립니다.
  - **Auto Reconnect**: 연결 끊김 시 재접속 여부.

#### 2) WS Send (`ws_send`)
- **역할**: 연결된 세션으로 메시지를 보냅니다.
- **주요 설정**:
  - **Session Key**: 메시지를 보낼 연결의 키 (예: `mainWs`).
  - **Payload**: 보낼 메시지 내용. 이전 노드의 결과값을 템플릿(`{{...}}`)으로 포함할 수 있습니다.

#### 3) WS Wait (`ws_wait`)
- **역할**: 특정 메시지가 수신될 때까지 워크플로우 진행을 일시 정지합니다.
- **주요 설정**:
  - **Session Key**: 메시지를 기다릴 연결의 키.
  - **Timeout**: 지정된 시간(ms) 내에 메시지가 안 오면 실패 처리됩니다.
  - **Match Type**:
    - `Contains Text`: 메시지에 특정 문자열이 포함되면 통과.
    - `JSON Path Equals`: JSON 응답의 특정 필드값이 일치하면 통과. (예: `$.type` == `pong`)
    - `Any Message`: 아무 메시지나 오면 통과.

---

## 5. 샘플 시나리오

### Scenario A: Echo Test (Direct)
가장 기초적인 연결 및 응답 테스트입니다.
1. **WS Connect**: `wss://echo.websocket.org` 연결, `storeAs: echo`
2. **WS Send**: `Hello` 전송, `sessionKey: echo`
3. **WS Wait**: `Hello`가 포함된 메시지 대기, `sessionKey: echo`

### Scenario B: Saved Config Usage
미리 저장해둔 설정을 불러와 테스트합니다.
1. **WebSocket Client** 메뉴에서 로컬 개발 서버(`ws://localhost:8080`) 설정을 저장.
2. **WS Connect**: `Config Ref` 모드 선택, 저장된 설정 ID 선택.
3. **WS Wait**: 서버 환영 메시지(`Welcome`) 대기.

### Scenario C: REST Auth → WebSocket (Chain)
REST API로 로그인 후 토큰을 받아 소켓 연결에 사용합니다.
1. **API Node**: 포스트맨 Echo API 등으로 로그인 요청 (`POST /login`).
2. **WS Connect**: URL에 토큰 바인딩.  
   예: `wss://myapp.com/ws?token={{steps.step1.response.body.token}}`
3. **WS Send**: 인증된 세션으로 개인화 데이터 요청.
4. **WS Wait**: 응답 데이터 검증.

---

## 6. 문제 해결 (Troubleshooting)

- **Q: Web에서 연결은 되는데 인증이 실패해요.**
  - A: 앞서 언급한 **Header 제약** 때문일 수 있습니다. 브라우저 개발자 도구의 Network 탭에서 Handshake 요청 헤더를 확인해보세요. 가능하다면 Query Parameter 방식으로 서버 설정을 변경해 보세요.

- **Q: `ws_wait`에서 계속 Timeout이 발생해요.**
  - A: 서버가 메시지를 보내지 않았거나, **Match 조건**이 너무 엄격할 수 있습니다. `Any Message`로 변경하여 뭐라도 들어오는지 확인하거나, Timeout 시간을 늘려보세요.

- **Q: 변수(`{{...}}`)가 치환되지 않아요.**
  - A: 템플릿 문법이 정확한지 확인하세요. 이전 단계(Step)의 ID가 정확해야 합니다. (예: `steps.api_login.response.body.id`)
