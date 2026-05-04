# ApiLens 사용자 가이드

## 1. API 명세 가져오기
- **Swagger URL**: Swagger UI 주소를 붙여넣으면 ApiLens가 자동으로 명세를 찾아냅니다.
- **로컬 파일**: `JSON` 또는 `YAML` 형식의 OpenAPI 파일을 직접 업로드할 수 있습니다.
- **필터링**: 태그 기반 필터링을 사용하여 필요한 엔드포인트만 선택적으로 가져옵니다.

## 2. 워크플로우 에디터
- **노드 종류**: 시작(Start), API 요청, 조건(Condition), 종료(End) 노드를 제공합니다.
- **연결**: 포트 사이를 드래그하여 실행 흐름을 정의합니다.
- **변수 활용**: `$.responses.nodeId.body.path` 문법을 사용하여 노드 간 데이터를 전달합니다.

---
다른 언어: [English](USER_GUIDE.md) | [中文](USER_GUIDE_CN.md)
