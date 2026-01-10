# 워크플로우 오케스트레이터 구현 계획

## 목표
사용자가 API 요청과 로직 노드를 시각적으로 연결할 수 있는 n8n 스타일의 API 워크플로우 오케스트레이터를 구축합니다.

## 핵심 원칙
- **UI**: Flutter Desktop/Web (Material 3).
- **상태 관리**: Riverpod.
- **네트워크**: Dio (기존 코어 재사용).
- **저장소**: Hive (워크플로우용).
- **엔진**: 순수 Dart async/await 실행 및 변수 주입.

## 아키텍처

### 1. 데이터 모델 (`lib/features/workflow/models`)
- **Workflow**: `id`, `name`, `nodes` (List), `edges` (List).
- **WorkflowNode**:
    - `id`: 윈도우 고유 ID.
    - `type`: `api`, `start`, `end`, `condition`.
    - `position`: `Offset` (x, y).
    - `data`: JSON Map (URL, 메서드, 헤더, 검증 로직 등 저장).
- **WorkflowEdge**: `sourceNodeId`, `targetNodeId`, `sourcePort`, `targetPort`.

### 2. 실행 엔진 (`lib/features/workflow/engine`)
- **WorkflowEngine**:
    - `Workflow`와 `initialContext`를 입력받음.
    - 위상 정렬(Topological sort) 또는 순수 이벤트 기반 순회 (노드 A 완료 -> 노드 B 트리거).
    - **컨텍스트 저장소**: 제네릭 Map `Map<String, dynamic> executionContext`.
    - **변수 해석기 (Variable Resolver)**:
        - 문법: `{{node.nodeId.data.response.body.token}}`.
        - 로직: Regex로 `{{...}}` 파싱 -> `executionContext`에서 조회.

### 3. 캔버스 UI (`lib/features/workflow/ui`)
- **WorkflowCanvas**: 
    - `InteractiveViewer` (무한 팬/줌).
    - 노드를 위한 `Stack`.
    - 엣지를 위한 `CustomPaint` (베지어 곡선).
- **NodeWidget**: 단계를 나타내는 드래그 가능한 위젯.
- **PropertiesPanel**: 현재 선택된 노드를 편집하는 사이드바 (예: API 요청 구성).

## 구현 단계

### 1단계: 모델 및 저장소
- [ ] `hive` 및 `hive_flutter` 추가.
- [ ] Hive 어댑터를 포함한 `Workflow`, `Node`, `Edge` 모델 생성.
- [ ] `WorkflowRepository` 생성.

### 2단계: 캔버스 UI ("n8n" 스타일)
- [ ] `InteractiveViewer`를 사용한 `WorkflowCanvas` 구현.
- [ ] 드래그 가능한 노드 구현.
- [ ] 엣지 그리기 (노드 연결) 구현.

### 3단계: 구성 및 로직
- [ ] `NodeConfigurationPanel` 구축 (`RequestScreen` 위젯을 API 노드용으로 재사용).
- [ ] 조건 로직 에디터 구현.

### 4단계: 실행 엔진
- [ ] `Runner` 구축.
- [ ] 변수 치환 로직 구현.
- [ ] UI: "워크플로우 실행" 버튼 및 실행 시각화 (활성 노드 하이라이트).

## 사용자 검토 필요 사항
> [!NOTE]
> 히스토리/환경 설정에 사용되는 기존 Isar DB와는 별도로, 요청하신 대로 워크플로우 저장에는 **Hive**를 사용할 것입니다.
