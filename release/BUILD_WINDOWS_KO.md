# Windows 빌드 가이드

### 사전 준비
- **Flutter SDK:** [설치 가이드](https://docs.flutter.dev/get-started/install/windows)
- **Visual Studio 2022:** "C++를 사용한 데스크톱 개발" 포함 설치.

### 빌드 단계
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build windows --release`

### 결과물
`build\windows\x64\runner\Release\apilens.exe`

---
다른 언어: [English](BUILD_WINDOWS.md) | [中文](BUILD_WINDOWS_CN.md)
