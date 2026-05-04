# macOS 빌드 가이드

### 사전 준비
- **Flutter SDK:** [설치 가이드](https://docs.flutter.dev/get-started/install/macos)
- **Xcode:** 앱스토어에서 설치.
- **CocoaPods:** `sudo gem install cocoapods`

### 빌드 단계
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build macos --release`

### 결과물
`build/macos/Build/Products/Release/ApiLens.app`

---
다른 언어: [English](BUILD_MACOS.md) | [中文](BUILD_MACOS_CN.md)
