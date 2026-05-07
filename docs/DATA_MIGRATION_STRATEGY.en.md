# ApiLens Data Migration Strategy

Date: 2026-05-07

## Goal

ApiLens uses both Hive and Isar. Workgroups, Requests, Workflows, and WebSocket Configs are stored in Hive. History and Environments are stored in Isar. The migration strategy keeps existing local data compatible with the current app schema while making every migration safe to run repeatedly.

## Current Structure

Migration entry point:

- Code: `lib/core/data/migration_service.dart`
- Called from: `lib/main.dart`
- Metadata box: `apilens_migrations`
- Backup box: `apilens_migration_backups`
- Current app migration version: `MigrationService.currentSchemaVersion`
- Current Workflow schema version: `WorkflowMigrationSchema.currentVersion`

Each migration has a stable ID. Applied IDs are recorded in the metadata box and skipped on later launches. Previous values for changed entries are stored in the backup box.

## Active Migrations

### `001_ensure_system_workgroup`

Ensures the `no-workgroup` system Workgroup exists.

- Creates it when missing.
- Normalizes existing records to `isSystem: true` with a default description.

### `002_normalize_saved_requests`

Normalizes Request storage.

- Moves legacy entries from the old `requests` box into the current `saved_requests` box.
- Normalizes the `workgroupId` alias into `groupId`.
- Re-links missing, empty, or unknown `groupId` values to `no-workgroup`.
- Rewrites entries through `RequestModel.toJson()`.

### `003_normalize_workflows`

Normalizes Workflow storage.

- Re-links missing, empty, or unknown `groupId` values to `no-workgroup`.
- Updates `schemaVersion` to `WorkflowMigrationSchema.currentVersion`.
- Normalizes executable node ports to `success/failure`.
- Ensures HTTP, GraphQL, and WebSocket nodes have the default `execution` policy shape.

## Operating Rules

- Every migration must be idempotent.
- Prefer repair and relinking over deletion.
- Back up changed values before writing.
- Surface migration failures during app startup.
- Never edit an existing migration ID; append a new migration step instead.

## Adding A Migration

1. Add a new `_MigrationStep` to the `migrations` list in `MigrationService.run()`.
2. Use a monotonic ID such as `004_descriptive_name`.
3. Back up changed entries with `_backupEntry()`.
4. Make repeated runs produce the same final data.
5. Add coverage in `test/migration_service_test.dart`.
6. Bump `MigrationService.currentSchemaVersion` or the relevant domain schema version.

## Verification

Current regression coverage:

- System Workgroup creation and Request group link repair
- Legacy `requests` to `saved_requests` migration
- Workflow group link, schemaVersion, and execution policy normalization
- Re-running migrations skips already applied steps

Commands:

```bash
flutter test -r expanded test/migration_service_test.dart
dart analyze
```
