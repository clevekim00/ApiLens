# ApiLens 사용자 가이드

## 0. 메인 대시보드
- **모니터링**: 앱 실행 시 나타나는 대시보드에서 API 헬스체크와 응답 속도를 모니터링합니다.
- **통계**: 지난 24시간 동안의 요청 및 에러 트래픽 추이를 확인합니다.

## 1. API 명세 가져오기
- **Swagger URL**: Swagger UI 주소를 붙여넣으면 ApiLens가 자동으로 명세를 찾아냅니다.
- **로컬 파일**: `JSON` 또는 `YAML` 형식의 OpenAPI 파일을 직접 업로드할 수 있습니다.
- **필터링**: 태그 기반 필터링을 사용하여 필요한 엔드포인트만 선택적으로 가져옵니다.

## 2. 워크플로우 에디터
- **노드 종류**: 시작(Start), API 요청, 조건(Condition), 종료(End) 노드를 제공합니다.
- **연결**: 포트 사이를 드래그하여 실행 흐름을 정의합니다.
- **변수 활용**: `$.responses.nodeId.body.path` 문법을 사용하여 노드 간 데이터를 전달합니다.

## 3. Load Hub
- **분산 성능 테스트**: 하나의 Workflow를 여러 원격 머신의 원격 에이전트에 나누어 실행하는 성능 테스트 흐름입니다.
- **머신/에이전트 관리**: Machines 탭에서 원격 머신의 활성화, drain, 연결 상태, 에이전트 버전과 capacity를 확인합니다.
- **실시간 모니터링**: Runs와 Metrics 탭에서 shard 상태, RPS, 오류율, p50/p90/p95/p99 latency를 확인합니다.
- **업그레이드 관제**: Agent Updates 탭에서 drain, install, restart, health check, rollback 상태를 추적합니다.
- **결과 내보내기**: 완료된 run은 JSON, CSV, Markdown report로 내보낼 수 있습니다.

자세한 내용은 [Load Hub 운영 가이드](docs/LOAD_HUB_OPERATIONS.ko.md)와 [원격 에이전트 설정 가이드](docs/REMOTE_AGENT_SETUP.ko.md)를 참고하세요.

---
다른 언어: [English](USER_GUIDE.md) | [中文](USER_GUIDE_CN.md)
