# iOS 和 iPadOS 构建指南

### 预备条件
- **安装了 Xcode 的 macOS 电脑。**
- **Apple 开发者账号**（用于真机部署）。
- **CocoaPods:** `sudo gem install cocoapods`

### 构建步骤
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `cd ios && pod install && cd ..`
4. `flutter build ios --release`

### 部署
在 Xcode 中打开 `ios/Runner.xcworkspace` 以配置签名并部署到真机。

---
其他语言: [English](BUILD_IOS.md) | [한국어](BUILD_IOS_KO.md)
