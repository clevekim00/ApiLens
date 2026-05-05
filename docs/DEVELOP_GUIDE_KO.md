# ApiLens 개발 가이드 (Development Guide)

이 문서는 ApiLens 프로젝트의 아키텍처, 코드 스타일, 그리고 개발 워크플로우에 대한 가이드를 제공합니다.

## 🏗 아키텍처 개요

ApiLens는 **Feature-first** 구조를 따르며, 관심사 분리(Separation of Concerns)를 위해 계층화된 아키텍처를 사용합니다.

### 디렉토리 구조
```text
lib/
├── core/               # 공통 유틸리티, 디자인 시스템(AppTokens), 네트워크 레이어
├── features/           # 기능별 모듈 (예: dashboard, request, workflow_editor)
│   ├── [feature]/
│   │   ├── domain/      # 엔티티 및 모델 정의
│   │   ├── data/        # 저장소(Repository) 및 데이터 소스
│   │   ├── application/ # 비즈니스 로직 및 컨트롤러 (Riverpod Notifiers)
│   │   └── presentation/ # UI 컴포넌트 및 스크린
└── main.dart           # 앱 진입점 및 전역 설정
```

---

## 💎 상태 관리 및 데이터 흐름

ApiLens는 **Riverpod**을 상태 관리의 핵심으로 사용합니다.

- **AsyncNotifier**: 비동기 상태(API 호출, DB 로드)를 관리하는 데 권장됩니다.
- **Provider Overrides**: 테스트 및 미리보기 환경에서 의존성을 주입하기 위해 사용됩니다.
- **Auto-generation**: `riverpod_generator`를 사용하여 타입 안전성을 확보합니다.

### 코드 생성 실행
새로운 프로바이더나 모델을 추가한 후에는 반드시 다음 명령어를 실행하세요:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🎨 디자인 시스템 및 테마

ApiLens는 고유의 디자인 시스템인 `AppTokens`를 기반으로 빌드되었습니다.

- **AppTokens**: 간격(`s1`~`s8`), 색상, 라운딩(`radiusLg`), 타이포그래피 등을 정의합니다.
- **Aesthetics**: Glassmorphism 효과와 세련된 다크 모드를 유지하기 위해 하드코딩된 색상 대신 `AppTokens` 또는 `Theme.of(context)`를 사용하세요.

---

## 🧪 테스트 가이드

프로젝트의 안정성을 위해 UI(Widget) 테스트를 지속적으로 관리합니다.

### UI 테스트 작성 원칙
- **Mocking**: 실제 네트워크 호출이나 DB 접근 대신 `test/mocks.dart`에 정의된 Fake Repository를 사용합니다.
- **ProviderScope Overrides**: 테스트하려는 위젯을 `ProviderScope`로 감싸고 필요한 프로바이더를 재정의(Override)합니다.
- **Responsive Testing**: `tester.view.physicalSize`를 사용하여 데스크톱과 모바일 레이아웃을 모두 검증합니다.

### 테스트 실행
```bash
# 전체 테스트 실행
flutter test

# 특정 기능 테스트 실행
flutter test test/features/dashboard/dashboard_ui_test.dart
```

---

## 🚀 개발 워크플로우

1.  **브랜치 관리**: 새로운 기능은 `feature/[기능명]` 브랜치에서 작업합니다.
2.  **Lint 규칙**: `flutter_lints`를 준수하며, 특히 `const` 사용을 권장합니다.
3.  **문서화**: 새로운 UI 컴포넌트나 복잡한 로직을 추가할 경우 관련 `README`나 `docs/` 내 문서를 업데이트하세요.

---

## 📦 릴리즈 및 배포

1.  **버전 관리**: `pubspec.yaml`의 버전을 업데이트합니다.
2.  **빌드**:
    - macOS: `flutter build macos`
    - Windows: `flutter build windows`
3.  **가이드 확인**: 자세한 배포 절차는 `docs/APP_STORE_PUBLISH_GUIDE_KO.md`를 참조하세요.
