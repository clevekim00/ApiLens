# GraphQL 사용 가이드

## 1. 개요
ApiFlow Studio는 REST, WebSocket과 더불어 강력한 **GraphQL** 지원 기능을 제공합니다. 복잡한 데이터 요구사항을 가진 최신 API 환경에서, 필요한 데이터만 정확하게 요청(Query)하고 변경(Mutation)할 수 있습니다.

### REST vs GraphQL 차이점
- **REST**: 여러 엔드포인트(`/users`, `/posts`)를 호출하여 데이터를 조립해야 할 수 있습니다. 불필요한 데이터까지 받아오는 Over-fetching 문제가 발생하기도 합니다.
- **GraphQL**: 단일 엔드포인트(`/graphql`)로 필요한 필드만 명시하여 요청합니다. 단 한 번의 요청으로 연관된 데이터를 모두 가져올 수 있습니다.

ApiFlow Studio에서는 **전용 Client**와 **Workflow 통합**을 통해 GraphQL API를 쉽게 테스트하고 자동화할 수 있습니다.

---

## 2. GraphQL Client 사용법
Request Builder 화면에서 **`GraphQL` 탭**을 선택하여 시작합니다.

### 1) Endpoint 설정
- GraphQL API 서버 주소를 입력합니다. (예: `https://rickandmortyapi.com/graphql`)
- 환경 변수(`{{baseUrl}}`)를 사용할 수 있습니다.

### 2) Headers / Auth
- **Headers**: `Authorization` 등의 헤더를 추가할 수 있습니다.
- **Auth**: Bearer Token 등을 설정하면 요청 시 자동으로 헤더에 추가됩니다.

### 3) Query 작성
- **Query Editor**: 좌측 상단 에디터에 GraphQL 쿼리문을 작성합니다.
- 문법 하이라이팅이 지원되며, `query`, `mutation`, `subscription` 등을 작성할 수 있습니다.

### 4) Variables 작성
- **Variables Editor**: 좌측 하단 에디터에 JSON 형식으로 변수를 정의합니다.
- 쿼리 내에서 `$variableName`으로 선언된 변수에 값을 매핑합니다.

### 5) 실행 및 결과 확인
- **Execute** 버튼(▶)을 눌러 요청을 보냅니다.
- **Response Viewer**: 우측 패널에서 응답 결과를 확인합니다.
    - **JSON Pretty**: 보기 좋게 정렬된 JSON을 제공합니다.
    - **Data/Errors**: 성공 데이터(`data`)와 에러(`errors`)를 명확하게 구분하여 보여줍니다.

---

## 3. 예제 쿼리

### 단순 Query 예시
Rick and Morty API에서 특정 캐릭터 정보를 가져옵니다.
```graphql
query GetCharacter {
  character(id: 1) {
    name
    status
    species
  }
}
```

### Variables 사용하는 예시
ID를 변수로 받아 동적으로 조회합니다.

**Query:**
```graphql
query GetCharacter($id: ID!) {
  character(id: $id) {
    name
    image
  }
}
```

**Variables (JSON):**
```json
{
  "id": "2"
}
```

### Mutation 예시
새로운 데이터를 생성하거나 수정합니다.
```graphql
mutation CreateUser($name: String!, $job: String!) {
  createUser(name: $name, job: $job) {
    id
    createdAt
  }
}
```

---

## 4. Workflow에서 GraphQL 사용
**Visual Workflow Editor**에서도 `gql_request` 노드를 사용하여 GraphQL 요청을 자동화 시나리오에 포함시킬 수 있습니다.

### 노드 추가 및 설정
1. 파레트에서 **GraphQL Request** 노드를 캔버스로 드래그합니다.
2. 노드를 선택하고 우측 **Inspector 패널**에서 설정을 입력합니다.

### 주요 설정 필드
- **Operation Mode**:
    - `Direct`: 노드에 직접 엔드포인트와 쿼리를 입력합니다.
    - `Config Reference`: 저장된 GraphQL 설정을 불러와 실행합니다.
- **Endpoint**: API 주소 (템플릿 사용 가능).
- **Query / Variables**: 실행할 쿼리와 변수.
- **Store As (Result Key)**: 실행 결과(`data`)를 Context에 저장할 키 이름입니다. (예: `userData`)

### 예시 흐름: REST 로그인 후 GraphQL 요청
1. **REST Request (Login)**: 로그인 API 호출 → 토큰 획득.
2. **GraphQL Request (Fetch Profile)**:
    - **Endpoint**: `https://api.example.com/graphql`
    - **Header**: `Authorization: Bearer {{node.login.response.body.token}}`
    - **Query**: 내 정보 조회 쿼리.
3. **Condition**: `{{node.profile.response.data.me.isActive}} == true` 확인.

---

## 5. 템플릿과 데이터 연결
워크플로우 내에서는 Handlebars 문법(`{{ ... }}`)을 사용하여 동적인 데이터를 쿼리나 변수에 주입할 수 있습니다.

### 환경 변수 사용
```graphql
query {
  serverInfo(env: "{{env.environmentName}}") {
    version
  }
}
```

### 이전 노드 결과 참조
이전 REST 요청의 결과나 다른 로직의 산출물을 Variables JSON에 넣을 수 있습니다.

**Variables (JSON):**
```json
{
  "userId": "{{node.loginSuccess.response.body.userId}}",
  "authToken": "{{node.auth.response.headers.x-auth-token}}"
}
```

---

## 6. 문제 해결 (Troubleshooting)

### 400 Bad Request
- 쿼리 문법이 잘못되었거나, 필수 변수가 누락되었을 수 있습니다.
- Response Viewer의 `errors` 필드 메시지를 확인하세요.

### 인증 오류 (401/403)
- Auth 탭에서 토큰이 올바르게 설정되었는지 확인하세요.
- Workflow의 경우, 이전 로그인 노드가 성공했는지 디버그 패널에서 확인하세요.

### Variables JSON 오류
- Variables 에디터의 내용이 유효한 JSON 형식인지 확인하세요. (따옴표 누락, 콤마 등)
