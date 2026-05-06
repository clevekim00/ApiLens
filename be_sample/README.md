# ApiLens 테스트용 샘플 백엔드 (be_sample)

이 서버는 ApiLens의 다양한 기능을 테스트하기 위해 설계된 멀티 프로토콜 샘플 백엔드입니다. REST, WebSocket, GraphQL 및 다양한 인증 방식을 모두 지원합니다.

## 🚀 시작하기

### 1. 의존성 설치
```bash
cd be_sample
npm install
```

### 2. 서버 실행
```bash
node index.js
```
서버는 기본적으로 `http://localhost:4000`에서 실행됩니다.

---

## 🛠 지원 기능 및 엔드포인트

### 1. REST API & Swagger
- **Swagger 문서**: `http://localhost:4000/docs`
- **인증 (Login)**:
  - `POST /auth/login-jwt`: 사용자명(`admin`)과 비밀번호(`password123`)로 JWT 토큰 발급.
  - `POST /auth/login-session`: HTTP-Only 쿠키를 통한 세션 기반 로그인.
- **데이터 (Protected)**:
  - `GET /api/items`: Bearer 토큰(JWT)이 있어야 접근 가능.
  - `GET /api/profile`: 세션 쿠키가 있어야 접근 가능.

### 2. GraphQL
- **엔드포인트**: `http://localhost:4000/graphql`
- **Query**:
  ```graphql
  query {
    hello
    getItems {
      id
      name
      value
    }
  }
  ```
- **Mutation**:
  ```graphql
  mutation {
    addItem(name: "New Item", value: "New Content") {
      id
    }
  }
  ```

### 3. WebSocket (Socket.io)
- **엔드포인트**: `ws://localhost:4000`
- **테스트 시나리오**:
  - `message` 이벤트 전송: `{ "text": "Hello" }`
  - `response` 이벤트 수신: `{ "text": "Echo: Hello", "timestamp": "..." }`

---

## 🔐 인증 방식 설명

1.  **JWT (JSON Web Token)**: 현대적인 무상태(Stateless) 인증 방식입니다. `Authorization: Bearer <token>` 헤더를 사용하여 테스트할 수 있습니다.
2.  **Session/Cookie**: 전통적인 상태 유지 인증 방식입니다. 서버에서 브라우저(또는 클라이언트)에 쿠키를 설정하며, 이후 요청 시 자동으로 포함됩니다.
3.  **Cross-Protocol Auth**: JWT를 사용하여 WebSocket 연결 시 인증을 수행하거나, GraphQL 요청 헤더에 토큰을 담아 보내는 시나리오를 테스트할 수 있습니다.

---

## 🧪 ApiLens에서 테스트하기

### 1. 워크플로우(Workflow) 테스트
제공된 `.json` 파일을 ApiLens의 **Workflow** 탭에서 불러와 실행할 수 있습니다.
- **[apilens_test_workflow.json](apilens_test_workflow.json)**: JWT 인증 -> 토큰 추출 -> 데이터 조회 시나리오.
- **[apilens_full_test_workflow.json](apilens_full_test_workflow.json)**: GraphQL 쿼리 -> WebSocket 연결 -> 메시지 전송 통합 시나리오.

### 2. 프로토콜별 개별 테스트
- **REST**: `POST /auth/login-jwt`로 토큰을 얻은 후, 해당 토큰을 환경 변수나 헤더에 설정하여 `GET /api/items`를 호출해 보세요.
2.  **WebSocket**: WebSocket 탭에서 `ws://localhost:4000`에 연결한 후 JSON 메시지를 주고받아 보세요.
3.  **GraphQL**: GraphQL 탭에서 인트로스펙션(Introspection)이 작동하는지 확인하고 쿼리를 실행해 보세요.
