# iOS & iPadOS Build Guide

### Prerequisites
- **macOS machine with Xcode.**
- **Apple Developer Account** (for physical device deployment).
- **CocoaPods:** `sudo gem install cocoapods`

### Build Steps
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `cd ios && pod install && cd ..`
4. `flutter build ios --release`

### Deployment
Open `ios/Runner.xcworkspace` in Xcode to configure signing and deployment to physical devices.

---
Other languages: [한국어](BUILD_IOS_KO.md) | [中文](BUILD_IOS_CN.md)
