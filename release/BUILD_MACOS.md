# macOS Build Guide

### Prerequisites
- **Flutter SDK:** [Install Flutter](https://docs.flutter.dev/get-started/install/macos)
- **Xcode:** Install from App Store.
- **CocoaPods:** `sudo gem install cocoapods`

### Build Steps
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build macos --release`

### Result
`build/macos/Build/Products/Release/ApiLens.app`

---
Other languages: [한국어](BUILD_MACOS_KO.md) | [中文](BUILD_MACOS_CN.md)
