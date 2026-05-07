# ApiLens 데이터 마이그레이션 전략

작성일: 2026-05-07

## 목표

ApiLens는 Hive와 Isar를 함께 사용합니다. Workgroup, Request, Workflow, WebSocket Config는 Hive에 저장되고, History와 Environment는 Isar에 저장됩니다. 마이그레이션 전략의 목표는 앱 시작 시 기존 로컬 데이터를 안전하게 최신 스키마로 맞추고, 같은 마이그레이션이 반복 실행되어도 데이터가 중복 변경되지 않도록 하는 것입니다.

## 현재 적용 구조

마이그레이션 진입점:

- 코드: `lib/core/data/migration_service.dart`
- 호출 위치: `lib/main.dart`
- 메타 박스: `apilens_migrations`
- 백업 박스: `apilens_migration_backups`
- 현재 앱 마이그레이션 버전: `MigrationService.currentSchemaVersion`
- 현재 Workflow 스키마 버전: `WorkflowMigrationSchema.currentVersion`

마이그레이션은 단계별 ID를 기록합니다. 이미 적용된 단계는 다음 앱 실행에서 skip되며, 변경 전 값은 `apilens_migration_backups`에 저장됩니다.

## 적용 중인 마이그레이션

### `001_ensure_system_workgroup`

`no-workgroup` 시스템 Workgroup을 보장합니다.

- 없으면 생성합니다.
- 이미 있으면 `isSystem: true`와 기본 설명을 정규화합니다.

### `002_normalize_saved_requests`

Request 저장소를 정규화합니다.

- 레거시 `requests` 박스에 있던 요청을 현재 `saved_requests` 박스로 이동합니다.
- `workgroupId` alias를 `groupId`로 정규화합니다.
- `groupId`가 비어 있거나 존재하지 않는 Workgroup을 가리키면 `no-workgroup`으로 연결합니다.
- 저장 형식은 `RequestModel.toJson()` 결과로 맞춥니다.

### `003_normalize_workflows`

Workflow 저장소를 정규화합니다.

- `groupId`가 비어 있거나 존재하지 않으면 `no-workgroup`으로 연결합니다.
- `schemaVersion`을 `WorkflowMigrationSchema.currentVersion`으로 맞춥니다.
- 실행형 노드의 기본 포트를 `success/failure`로 정규화합니다.
- HTTP, GraphQL, WebSocket 노드의 `execution` 정책 기본 구조를 보장합니다.

## 운영 원칙

- 모든 마이그레이션은 idempotent해야 합니다.
- 데이터 삭제보다 보정과 연결 복구를 우선합니다.
- 변경 전 값은 백업 박스에 보관합니다.
- 마이그레이션 실패 시 앱 시작을 중단하고 오류를 드러냅니다.
- 새 마이그레이션을 추가할 때는 단계 ID를 변경하지 말고, 새 ID를 추가합니다.

## 새 마이그레이션 추가 절차

1. `MigrationService.run()`의 `migrations` 목록에 새 `_MigrationStep`을 추가합니다.
2. ID는 `004_descriptive_name`처럼 단조 증가 형태로 만듭니다.
3. 변경 전 항목은 `_backupEntry()`로 저장합니다.
4. 동일 데이터를 다시 실행해도 결과가 바뀌지 않도록 작성합니다.
5. `test/migration_service_test.dart`에 회귀 테스트를 추가합니다.
6. `MigrationService.currentSchemaVersion` 또는 관련 도메인 스키마 버전을 올립니다.

## 검증

현재 회귀 테스트:

- 시스템 Workgroup 생성 및 Request group 링크 보정
- 레거시 `requests` 박스에서 `saved_requests` 박스로 이동
- Workflow group 링크, schemaVersion, execution 정책 정규화
- 동일 마이그레이션 재실행 시 skip 확인

명령어:

```bash
flutter test -r expanded test/migration_service_test.dart
dart analyze
```
