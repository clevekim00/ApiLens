# Linux 빌드 가이드

### 사전 준비
- **Flutter SDK:** [설치 가이드](https://docs.flutter.dev/get-started/install/linux)
- **의존성 설치:** `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`

### 빌드 단계
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build linux --release`

### 결과물
`build/linux/x64/release/bundle/apilens`

---
다른 언어: [English](BUILD_LINUX.md) | [中文](BUILD_LINUX_CN.md)
