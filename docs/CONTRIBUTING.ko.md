# Contributing to ApiLens

## 1. Welcome
ApiLens 오픈소스 프로젝트에 오신 것을 환영합니다! 🎉
ApiLens는 개발자들이 더 쉽고 강력하게 API를 테스트하고 자동화할 수 있도록 돕는 도구입니다.

우리는 여러분의 기여를 진심으로 환영합니다. 버그 수정, 새로운 기능 제안, 문서 개선, 디자인 아이디어 등 어떤 형태의 기여도 프로젝트를 더 나은 방향으로 이끄는 소중한 자산입니다.

### 어떤 기여를 할 수 있나요?
- **Bug Fixes**: 발견된 버그를 수정하여 안정성을 높여주세요.
- **New Features**: REST/WebSocket/GraphQL 기능 확장, 새로운 Workflow 노드, UI 개선 등을 제안해주세요.
- **Documentation**: 가이드, API 문서, 오타 수정 등 문서의 품질을 높여주세요.
- **Design / UX**: 사용자 경험을 개선할 수 있는 디자인 제안을 기다립니다.
- **Testing**: 테스트 커버리지를 높여 견고한 앱을 함께 만들어가요.

---

## 2. Getting Started

기여를 시작하기 위해 다음 도구들이 필요합니다:
- **Flutter SDK**: 최신 Stable 버전 권장
- **Dart SDK**: Flutter에 포함됨
- **Git**

### 저장소 클론 (Clone)
```bash
git clone https://github.com/apilens/apilens.git
cd apilens
```

### 의존성 설치
```bash
flutter pub get
```

### 앱 실행
```bash
flutter run -d macos   # or windows, chrome
```

---

## 3. Project Structure

ApiLens는 기능(Feature) 중심의 구조를 따릅니다.

```text
lib/
  main.dart       # 앱 진입점
  app/            # App 설정, 라우팅, 전역 테마
  features/       # 기능별 모듈
    workgroups/   # 워크그룹 관리
    requests/     # REST/WS/GQL 요청 처리
    workflow/     # 워크플로우 엔진 및 에디터
    settings/     # 사용자 설정
  core/           # 공통 유틸리티 및 코어 모듈
    ui/           # 공통 위젯 시스템
    storage/      # Hive/Isar 로컬 저장소
    network/      # 네트워크 클라이언트 래퍼
    utils/        # 헬퍼 함수들
test/             # 유닛 및 위젯 테스트
docs/             # 문서
```

---

## 4. Architecture

- **Clean Architecture-ish**: 유지보수성과 테스트 용이성을 위해 계층을 분리합니다.
- **Riverpod**: 상태 관리를 위해 Riverpod을 전적으로 사용합니다.
- **Hive**: 로컬 데이터 영속성을 위해 빠르고 가벼운 NoSQL 데이터베이스인 Hive를 사용합니다.
- **Workflow Engine**: 노드 기반의 워크플로우 실행 엔진은 `features/workflow` 내에 독립적으로 구성되어 있습니다.

---

## 5. Coding Guidelines

코드를 작성할 때 다음 스타일을 따라주세요:

- **Dart Style**: [Effective Dart](https://dart.dev/guides/language/effective-dart) 가이드를 준수합니다.
- **Feature-First**: 관련된 코드는 같은 기능 폴더(`features/xyz`) 내에 위치시킵니다.
- **Immutability**: 가능한 한 `final` 키워드를 사용하고 불변 객체를 지향합니다.
- **UI & Logic 분리**: 비즈니스 로직은 `Riverpod` Provider/Notifier로 분리하고, 위젯은 UI 렌더링에 집중합니다.
- **Keys**: 테스트 자동화를 위해 주요 위젯에는 `Key`를 부여해주세요.

### Riverpod 패턴 예시
```dart
@riverpod
class ExampleController extends _$ExampleController {
  @override
  int build() => 0;

  void increment() => state++;
}
```

---

## 6. Adding a Feature (Example)

예를 들어, "새로운 Workflow 노드"를 추가한다고 가정해 봅시다.

1. **모델 정의**: `lib/features/workflow/domain/nodes/`에 새로운 노드 클래스를 정의합니다.
2. **UI 패널 생성**: `lib/features/workflow/presentation/panels/`에 해당 노드의 설정 패널 위젯을 만듭니다.
3. **실행 로직 구현**: `lib/features/workflow/application/engine/`의 실행기(Executor)에 노드 처리 로직을 추가합니다.
4. **테스트 작성**: `test/features/workflow/`에 유닛 테스트를 추가하여 동작을 검증합니다.
5. **문서화**: 변경 사항을 문서에 반영합니다.

---

## 7. Running Tests

PR을 제출하기 전, 모든 테스트가 통과하는지 확인해주세요.

```bash
# 전체 테스트 실행
flutter test

# 주요 UI 스모크 테스트 실행
flutter test test/smoke/app_smoke_test.dart
```

CI 파이프라인에서도 이 테스트들이 자동으로 실행됩니다.

---

## 8. Commit & Branch Strategy

- `main`: 항상 배포 가능한 안정적인 상태를 유지합니다.
- `feature/*`: 새로운 기능 개발 (예: `feature/new-workflow-node`)
- `fix/*`: 버그 수정 (예: `fix/crash-on-launch`)

### Commit 메시지 규칙 (Conventional Commits)
- `feat`: 새로운 기능 추가
- `fix`: 버그 수정
- `docs`: 문서 변경
- `style`: 코드 포맷팅, 세미콜론 누락 등 (코드 동작에 영향 없음)
- `refactor`: 리팩토링 (기능 추가나 버그 수정 아님)
- `test`: 테스트 코드 추가/수정

예: `feat: Add websocket support to workflow engine`

---

## 9. Pull Request Guide

PR을 생성하기 전에 다음 체크리스트를 확인하세요:

- [ ] 앱이 에러 없이 빌드되는가?
- [ ] UI 스모크 테스트(`app_smoke_test.dart`)를 통과했는가?
- [ ] 새로운 기능에 대한 테스트 코드를 작성했는가?
- [ ] 관련된 문서를 업데이트했는가?

PR 템플릿에 따라 변경 사항을 명확하게 설명해주세요.

---

## 10. Code of Conduct

우리는 서로를 존중하고 환영하는 커뮤니티를 지향합니다.
- 비판보다는 **건설적인 피드백**을 주고받습니다.
- 서로의 다양성을 존중합니다.
- 함께 성장하는 문화를 만듭니다.

감사합니다! 여러분의 기여를 기다리고 있겠습니다. 🚀
