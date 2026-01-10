# 비주얼 워크플로우 에디터 구현 계획

ApiLens를 선형적인 컬렉션 실행기에서 강력한 그래프 기반 비주얼 워크플로우 에디터로 전환하여, 모듈식 API 오케스트레이션과 정밀한 데이터 매핑을 가능하게 합니다.

## 사용자 검토 필요 사항 (User Review Required)

> [!IMPORTANT]
> 이 변경 사항은 컬렉션에 그래프 기반 데이터 구조를 도입합니다. 기존의 선형적인 컬렉션을 플로우 에디터에서 보려면 변환 로직이 필요합니다.

> [!NOTE]
> 비주얼 캔버스의 경우, Flutter의 `CustomPainter`와 `GestureDetector`를 사용하여 커스텀 그래프 UI를 구현함으로써 부드러운 성능과 프리미엄 사용감을 보장할 것입니다.

## 제안된 변경 사항 (Proposed Changes)

### 1. 데이터 모델 리팩토링
- **[수정] [api_collection_model.dart](file:///Users/youngwhankim/Project/api_tester/lib/models/api_collection_model.dart)**: 
  - `List<WorkflowNode> nodes` 와 `List<WorkflowEdge> edges` 추가.
  - `WorkflowNode`는 위치(x, y), 요청 참조, 포트 정보를 포함합니다.
  - `WorkflowEdge`는 출력 포트와 입력 포트 간의 연결을 정의합니다.

### 2. 비주얼 플로우 에디터 컴포넌트
- **[신규] `lib/widgets/flow_editor/`**:
  - `workflow_canvas.dart`: 메인 인터랙티브 그리기 영역.
  - `api_node_widget.dart`: 입출력 포트를 가진 API 요청의 시각적 표현.
  - `connection_painter.dart`: 노드 간의 베지어 곡선 그리기.

### 3. 데이터 매핑 UI ("엔티티" 느낌)
- **[신규] `lib/dialogs/data_mapping_dialog.dart`**:
  - 응답 본문 필드(JSONPath 사용)가 다음 요청의 헤더, 쿼리 파라미터, 또는 바디에 어떻게 매핑될지 정의하는 모달.
  - ER 다이어그램 연결과 유사한 필드의 시각적 표현.

### 4. 실행 엔진 업데이트
- **[수정] `lib/services/batch_execution_service.dart`**:
  - 순차적 반복 실행에서 그래프 순회 실행으로 업데이트.
  - 분기 로직(성공/실패 경로) 지원.

## 검증 계획 (Verification Plan)

### 자동화 테스트 (Automated Tests)
- 그래프 순회 로직을 테스트하여 모든 도달 가능한 노드가 실행되는지 확인.
- JSONPath 추출 및 변수 주입 검증.

### 수동 검증 (Manual Verification)
- `token`을 "프로필 조회" API로 전달하는 로그인 워크플로우 생성.
- 노드를 드래그하고 이동하여 UI 안정성 검증.
- 401 Unauthorized 응답을 시뮬레이션하여 "실패" 경로로 트리거되는지 "If" 로직 검증.
