# macOS 构建指南

### 预备条件
- **Flutter SDK:** [安装指南](https://docs.flutter.dev/get-started/install/macos)
- **Xcode:** 从 App Store 安装。
- **CocoaPods:** `sudo gem install cocoapods`

### 构建步骤
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build macos --release`

### 结果
`build/macos/Build/Products/Release/ApiLens.app`

---
其他语言: [English](BUILD_MACOS.md) | [한국어](BUILD_MACOS_KO.md)
