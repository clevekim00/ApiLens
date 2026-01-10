# ApiFlow Studio 사용 가이드

본 문서는 **ApiFlow Studio**의 인터페이스 설명과 자동화 워크플로우를 생성, 설정, 실행하는 방법을 안내합니다.

## 빠르게 둘러보기 (Quick Tour)

화면은 크게 5가지 영역으로 구성됩니다:

1.  **Workflow Menu (상단)**: 파일 관리(New, Save, Open) 및 실행(Run).
2.  **Node Palette (좌측)**: 캔버스로 드래그하여 추가할 수 있는 노드 목록 (Start, HTTP, Condition, End).
3.  **Canvas (중앙)**: 워크플로우를 디자인하는 무한 작업 공간. 빈 공간을 드래그하여 이동(Pan), 휠로 줌(Zoom) 가능.
4.  **Inspector Panel (우측)**: 선택된 노드의 속성(API URL, Method 등)을 설정하는 패널.
5.  **Debug/Log Panel (하단)**: 실행 로그 및 결과를 확인하는 패널.

## 첫 번째 워크플로우 만들기

### 1. 새 워크플로우 시작
*   상단 바의 워크플로우 이름을 클릭하여 메뉴를 엽니다.
*   **New Workflow**를 선택합니다 (단축키: `Cmd/Ctrl + N`).

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
3.  **시각적 피드백**:
    *   실행 중인 노드: **파란색** 발광.
    *   성공한 노드: **초록색** 테두리.
    *   실패한 노드: **빨간색** 테두리.
4.  **로그 확인**: 하단 패널을 열어 각 단계의 요청/응답 상세 내용을 확인합니다.

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
