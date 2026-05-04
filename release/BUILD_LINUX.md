# Linux Build Guide

### Prerequisites
- **Flutter SDK:** [Install Flutter](https://docs.flutter.dev/get-started/install/linux)
- **Dependencies:** `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`

### Build Steps
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build linux --release`

### Result
`build/linux/x64/release/bundle/apilens`

---
Other languages: [한국어](BUILD_LINUX_KO.md) | [中文](BUILD_LINUX_CN.md)
