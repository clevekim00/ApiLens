# Visual Workflow 가이드

**Visual Workflow**는 ApiLens의 핵심 기능으로, 여러 API 요청과 로직을 시각적인 그래프(Node-Link) 형태로 연결하여 실행하는 자동화 도구입니다.

## 1. 주요 개념

### 1.1 노드 (Node)
워크플로우를 구성하는 각 단계를 의미합니다.
- **Start Node**: 실행이 시작되는 지점입니다. 모든 워크플로우는 반드시 하나의 Start 노드를 가져야 합니다.
- **API Node (HTTP)**: REST API를 호출합니다.
- **Condition Node**: 조건식에 따라 흐름을 분기합니다 (If-Else).
- **End Node**: 워크플로우 실행을 종료합니다.

### 1.2 엣지 (Edge)
노드와 노드를 연결하는 선입니다.
- **Flow**: 실행 순서를 결정합니다.
- **Branching**: 성공(`success`) vs 실패(`failure`), 또는 참(`true`) vs 거짓(`false`)에 따라 다른 경로로 이동합니다.

---

## 2. 노드 상세 설명

### API Node
HTTP 요청을 수행합니다.
- **Input**: 이전 노드에서 실행 권한을 받습니다.
- **Output**:
  - `success`: 응답 코드가 2xx일 때 실행됩니다.
  - `failure`: 응답 코드가 4xx/5xx이거나 네트워크 오류 시 실행됩니다.
- **설정**:
  - Method (GET, POST 등)
  - URL
  - Headers, Body
- **변수 참조**: 이전 노드의 응답 값을 사용할 수 있습니다.
  - 예: `{{node.login.response.body.token}}`
  - 형식: `{{node.<NodeID>.response.body.<JSONPath>}}`

### Condition Node
JavaScript 스타일의 표현식을 평가하여 흐름을 제어합니다.
- **Output**:
  - `true`: 조건이 참일 때 실행됩니다.
  - `false`: 조건이 거짓일 때 실행됩니다.
- **예제 표현식**:
  - `{{node.getUser.response.body.age}} > 18`
  - `{{node.search.response.statusCode}} == 200`

---

## 3. 사용 방법

### 3.1 워크플로우 생성
1. 사이드바 또는 상단 메뉴에서 **Workflow** 탭을 선택합니다.
2. `+ New Workflow` 버튼을 클릭합니다.
3. 캔버스에 자동으로 `Start` 노드가 생성됩니다.

### 3.2 노드 추가 및 연결
1. 좌측 팔레트에서 원하는 노드(예: API Request)를 드래그하여 캔버스에 놓습니다.
2. `Start` 노드의 `out` 포트를 클릭하고 드래그하여, API 노드의 `in` 포트에 놓습니다.
3. API 노드를 클릭하여 URL과 파라미터를 설정합니다.

### 3.3 로직 구성 (체이닝)
API 응답을 다음 요청에 사용하려면 **템플릿 문법**을 사용합니다.
1. **로그인 API** 노드 (ID: `login`) 생성 & 설정.
2. **유저 정보 API** 노드 생성.
3. 유저 정보 API의 Header 설정:
   - Key: `Authorization`
   - Value: `Bearer {{node.login.response.body.accessToken}}`

### 3.4 실행 (Run)
1. 우측 상단 `Run` 버튼(재생 아이콘)을 클릭합니다.
2. 그래프 상에서 실행 중인 노드는 **하이라이트**됩니다.
3. 실행 로그 패널에서 각 단계별 상세 결과(Status, Body 등)를 확인할 수 있습니다.

### 3.5 저장 및 불러오기
- **저장**: 작업 내용은 로컬 데이터베이스(Hive)에 저장됩니다. `Save` 버튼을 누르거나 `Ctrl+S`를 사용하세요.
- **불러오기**: `Open Saved` 메뉴에서 저장된 워크플로우 목록을 확인하고 불러올 수 있습니다.
- **내보내기**: JSON 형식으로 클립보드에 복사하거나 파일로 공유할 수 있습니다.

---

## 4. 예제 시나리오

**시나리오: 로그인 후 데이터 조회**
1. **Start** 노드 시작.
2. **API (Login)**: `POST /login` 수행.
   - `success` -> 다음 단계로.
   - `failure` -> **End (Fail)** 노드로 연결.
3. **API (Get Profile)**: `GET /profile` 수행.
   - Header에 토큰 포함.
4. **Condition**: `{{node.profile.response.body.isAdmin}} == true`
   - `true` -> **API (Admin Dashboard)** 실행.
   - `false` -> **End (User)** 종료.

---

## 5. FAQ

**Q. 변수 자동완성이 지원되나요?**
A. 현재는 텍스트로 직접 입력해야 합니다. 향후 업데이트에서 자동완성 기능이 추가될 예정입니다.

**Q. 파일 업로드는 어떻게 하나요?**
A. API 노드 설정에서 Body 타입을 `form-data`로 선택하여 파일을 첨부할 수 있습니다.

**Q. 동시에 여러 워크플로우를 실행할 수 있나요?**
A. 현재는 단일 탭에서 하나의 워크플로우만 실행 가능합니다. 탭 기능을 사용하여 여러 개를 열어둘 수는 있습니다.
