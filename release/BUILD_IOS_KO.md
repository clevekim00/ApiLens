# iOS 및 iPadOS 빌드 가이드

### 사전 준비
- **macOS 기기 및 Xcode 설치.**
- **Apple 개발자 계정** (실제 기기 배포 시 필요).
- **CocoaPods:** `sudo gem install cocoapods`

### 빌드 단계
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `cd ios && pod install && cd ..`
4. `flutter build ios --release`

### 배포
Xcode에서 `ios/Runner.xcworkspace`를 열어 서명(Signing) 설정을 완료한 후 기기에 배포하세요.

---
다른 언어: [English](BUILD_IOS.md) | [中文](BUILD_IOS_CN.md)
