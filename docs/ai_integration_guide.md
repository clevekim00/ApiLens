# ApiLens (👁️) - AI 프롬프트 통합 가이드

이 문서는 ApiLens에서 AI 프롬프트를 활용하여 API 요청을 생성하고 워크플로우를 구성하는 방법, 그리고 추천 AI 모델 및 사용법에 대해 설명합니다.

---

## 🤖 추천 AI 모델 (Recommended AI Models)

ApiLens의 자연어 처리 효율을 극대화하기 위해 다음과 같은 모델 사용을 권장합니다.

| 모델명 | 특징 | 추천 용도 |
| :--- | :--- | :--- |
| **Claude 3.5 Sonnet** | 매우 정교한 JSON 출력 및 코드 이해도 | 복잡한 워크플로우 체인 설계 및 데이터 매핑 |
| **GPT-4o** | 범용적인 창의성과 높은 정확도 | 자연어를 활용한 즉각적인 API 요청 생성 및 테스트 |
| **Gemini 1.5 Pro** | 초거대 컨텍스트 윈도우 지원 | 방대한 분량의 API 명세서(Swagger/OpenAPI) 분석 및 자동화 |
| **Ollama (Llama 3)** | 로컬 실행 가능 (데이터 유출 방지) | 보안이 중요한 엔터프라이즈 환경에서의 프라이빗 API 테스트 |

---

## 🛠 AI 활용 방법 (Usage Guide)

### 1. 전제 조건 (Prerequisites)
AI를 통해 ApiLens의 구성을 변경하려면 AI에게 응답 형식을 **JSON**으로 반환하도록 강제해야 합니다. System Prompt에 다음 규칙을 포함시키세요.

### 2. API 요청 생성 프롬프트 (Request Generation)
AI에게 특정 기능의 API를 만들어 달라고 할 때 다음 스키마를 따르도록 유도하십시오.

**System Prompt 템플릿:**
```text
You are an API Expert. Generate an API request in the following JSON format:
{
  "name": "Quick descriptive name",
  "method": "GET|POST|PUT|DELETE|PATCH",
  "url": "full URL",
  "headers": {"key": "value"},
  "body": "stringified body if any",
  "queryParams": {"key": "value"}
}
Only return the raw JSON.
```

**User Prompt 예시:**
> "JSONPlaceholder에서 ID가 1인 포스트를 가져오는 GET 요청을 만들어줘."

---

### 3. 시각적 플로우 설정 프롬프트 (Flow Setup)
복잡한 워크플로우를 설계할 때는 노드(Node)와 엣지(Edge)의 관계를 명시해야 합니다.

**System Prompt 템플릿:**
```text
Generate a workflow graph in JSON format:
{
  "nodes": [
    {"id": "node_1", "type": "api", "label": "Login", "requestId": "uuid_if_exists"},
    {"id": "node_2", "type": "if", "label": "Check Status", "config": {"condition": "status == 200"}}
  ],
  "edges": [
    {"id": "edge_1", "fromNodeId": "node_1", "toNodeId": "node_2"}
  ]
}
```

**User Prompt 예시:**
> "로그인 API를 먼저 호출하고, 성공하면 사용자 정보를 가져오는 로직을 플로우 에디터에 설정해줘."

---

## 🚀 향후 로드맵 (Future Roadmap)

1.  **Native AI Prompt Input**: 앱 내에 직접 프롬프트를 입력할 수 있는 전용 창 추가.
2.  **API Context Awareness**: 현재 로드된 컬렉션 데이터를 AI에게 주입하여 더 정확한 자동화 제안.
3.  **Local LLM Connector**: Ollama와 같은 로컬 모델을 설정 창에서 바로 연동할 수 있는 플러그인 제공.

---
© 2026 clevekim. ApiLens Project.
