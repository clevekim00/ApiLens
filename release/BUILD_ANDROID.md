# Android Build Guide

### Prerequisites
- **Java Development Kit (JDK):** Version 17 recommended.
- **Android Studio & SDK.**

### Build Steps
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build apk --release` (for APK)
   OR
   `flutter build appbundle --release` (for Google Play Store)

### Result
APK: `build/app/outputs/flutter-apk/app-release.apk`
AAB: `build/app/outputs/bundle/release/app-release.aab`

---
Other languages: [한국어](BUILD_ANDROID_KO.md) | [中文](BUILD_ANDROID_CN.md)
