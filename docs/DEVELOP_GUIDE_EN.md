# ApiLens Development Guide

This document provides a guide to the architecture, code style, and development workflow of the ApiLens project.

## 🏗 Architecture Overview

ApiLens follows a **Feature-first** structure and uses a layered architecture to ensure Separation of Concerns.

### Directory Structure
```text
lib/
├── core/               # Common utilities, design system (AppTokens), network layer
├── features/           # Feature-specific modules (e.g., dashboard, request, workflow_editor)
│   ├── [feature]/
│   │   ├── domain/      # Entity and model definitions
│   │   ├── data/        # Repositories and data sources
│   │   ├── application/ # Business logic and controllers (Riverpod Notifiers)
│   │   └── presentation/ # UI components and screens
└── main.dart           # App entry point and global configuration
```

---

## 💎 State Management & Data Flow

ApiLens uses **Riverpod** as the core for state management.

- **AsyncNotifier**: Recommended for managing asynchronous states (API calls, DB loads).
- **Provider Overrides**: Used to inject dependencies in testing and preview environments.
- **Auto-generation**: Ensure type safety by using `riverpod_generator`.

### Running Code Generation
After adding new providers or models, be sure to run the following command:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Data Migrations
When changing local storage schemas, add a versioned migration to `MigrationService`.

- Migration code: `lib/core/data/migration_service.dart`
- Strategy document: `docs/DATA_MIGRATION_STRATEGY.en.md`
- Regression tests: `test/migration_service_test.dart`

New steps should use monotonic IDs such as `004_...`, and changed values should be backed up before writing.

---

## 🎨 Design System & Theming

ApiLens is built on its own design system, `AppTokens`.

- **AppTokens**: Defines spacing (`s1`~`s8`), colors, rounding (`radiusLg`), typography, etc.
- **Aesthetics**: To maintain Glassmorphism effects and a sophisticated dark mode, use `AppTokens` or `Theme.of(context)` instead of hardcoded colors.

---

## 🧪 Testing Guide

Automated UI (Widget) tests are maintained to ensure the stability of the project.

### UI Testing Principles
- **Mocking**: Use Fake Repositories defined in `test/mocks.dart` instead of actual network calls or DB access.
- **ProviderScope Overrides**: Wrap the widget to be tested with `ProviderScope` and override the necessary providers.
- **Responsive Testing**: Use `tester.view.physicalSize` to verify both desktop and mobile layouts.

### Running Tests
```bash
# Run all tests
flutter test

# Run a specific feature test
flutter test test/features/dashboard/dashboard_ui_test.dart
```

---

## 🚀 Development Workflow

1.  **Branch Management**: Work on new features in `feature/[feature-name]` branches.
2.  **Lint Rules**: Adhere to `flutter_lints`, especially recommending the use of `const`.
3.  **Documentation**: When adding new UI components or complex logic, update the relevant `README` or documents in `docs/`.

---

## 📦 Release & Deployment

1.  **Version Management**: Update the version in `pubspec.yaml`.
2.  **Build**:
    - macOS: `flutter build macos`
    - Windows: `flutter build windows`
3.  **Check Guides**: Refer to `docs/APP_STORE_PUBLISH_GUIDE_KO.md` (or translated versions) for detailed deployment procedures.
