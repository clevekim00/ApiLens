# Windows Build Guide

### Prerequisites
- **Flutter SDK:** [Install Flutter](https://docs.flutter.dev/get-started/install/windows)
- **Visual Studio 2022:** Install with "Desktop development with C++" workload.

### Build Steps
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build windows --release`

### Result
`build\windows\x64\runner\Release\apilens.exe`

---
Other languages: [한국어](BUILD_WINDOWS_KO.md) | [中文](BUILD_WINDOWS_CN.md)
