# Contributing to ApiLens

## 1. Welcome
Welcome to the ApiLens open source project! 🎉
ApiLens is a tool designed to help developers test and automate APIs more easily and powerfully.

We genuinely welcome your contributions. Whether it's bug fixes, new feature proposals, documentation improvements, design ideas, or anything else, your contributions are valuable assets that drive the project forward.

### How can you contribute?
- **Bug Fixes**: Fix discovered bugs to improve stability.
- **New Features**: Propose extensions for REST/WebSocket/GraphQL features, new Workflow nodes, UI improvements, etc.
- **Documentation**: Improve the quality of guides, API docs, or fix typos.
- **Design / UX**: We await design proposals that can enhance the user experience.
- **Testing**: Help us build a robust app by increasing test coverage.

---

## 2. Getting Started

To get started, you will need the following tools:
- **Flutter SDK**: Latest Stable version recommended
- **Dart SDK**: Included with Flutter
- **Git**

### Clone Repository
```bash
git clone https://github.com/apilens/apilens.git
cd apilens
```

### Install Dependencies
```bash
flutter pub get
```

### Run App
```bash
flutter run -d macos   # or windows, chrome
```

---

## 3. Project Structure

ApiLens follows a Feature-first structure.

```text
lib/
  main.dart       # App entry point
  app/            # App config, routing, global theme
  features/       # Feature modules
    workgroups/   # Workgroup management
    requests/     # REST/WS/GQL request handling
    workflow/     # Workflow engine and editor
    settings/     # User settings
  core/           # Common utilities and core modules
    ui/           # Common widget system
    storage/      # Hive/Isar local storage
    network/      # Network client wrapper
    utils/        # Helper functions
test/             # Unit and Widget tests
docs/             # Documentation
```

---

## 4. Architecture

- **Clean Architecture-ish**: Functional layers are separated for maintainability and testability.
- **Riverpod**: Used exclusively for state management.
- **Hive**: Used as a fast and lightweight NoSQL database for local data persistence.
- **Workflow Engine**: Node-based workflow execution engine is independently composed within `features/workflow`.

---

## 5. Coding Guidelines

Please follow these styles when writing code:

- **Dart Style**: Adhere to the [Effective Dart](https://dart.dev/guides/language/effective-dart) guide.
- **Feature-First**: Locate related code within the same feature folder (`features/xyz`).
- **Immutability**: Use `final` keywords where possible and aim for immutable objects.
- **UI & Logic Separation**: Separate business logic into `Riverpod` Providers/Notifiers, and keep Widgets focused on UI rendering.
- **Keys**: Assign `Key`s to major widgets for automated testing.

### Riverpod Pattern Example
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

For example, let's say you are adding a "New Workflow Node".

1. **Define Model**: Define the new node class in `lib/features/workflow/domain/nodes/`.
2. **Create UI Panel**: Create the settings panel widget for that node in `lib/features/workflow/presentation/panels/`.
3. **Implement Logic**: Add node processing logic to the Executor in `lib/features/workflow/application/engine/`.
4. **Write Tests**: Add unit tests in `test/features/workflow/` to verify behavior.
5. **Document**: Reflect changes in the documentation.

---

## 7. Running Tests

Please ensure all tests pass before submitting a PR.

```bash
# Run all tests
flutter test

# Run key UI smoke tests
flutter test test/smoke/app_smoke_test.dart
```

These tests are also automatically run in the CI pipeline.

---

## 8. Commit & Branch Strategy

- `main`: Always kept in a stable, deployable state.
- `feature/*`: New feature development (e.g., `feature/new-workflow-node`)
- `fix/*`: Bug fixes (e.g., `fix/crash-on-launch`)

### Commit Message Convention (Conventional Commits)
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation change
- `style`: Code formatting, missing semi-colons, etc. (no code change)
- `refactor`: Refactoring (neither new feature nor bug fix)
- `test`: Adding or missing tests

Example: `feat: Add websocket support to workflow engine`

---

## 9. Pull Request Guide

Check the following checklist before creating a PR:

- [ ] Does the app build without errors?
- [ ] Did it pass the UI smoke test (`app_smoke_test.dart`)?
- [ ] Have you written test code for the new feature?
- [ ] Have you updated relevant documentation?

Please describe your changes clearly following the PR template.

---

## 10. Code of Conduct

We aim for a community that respects and welcomes each other.
- Give and receive **constructive feedback** rather than criticism.
- Respect each other's diversity.
- Build a culture of growing together.

Thank you! We look forward to your contributions. 🚀
