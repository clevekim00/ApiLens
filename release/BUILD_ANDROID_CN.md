# Android 构建指南

### 预备条件
- **Java Development Kit (JDK):** 推荐版本 17。
- **Android Studio 和 SDK。**

### 构建步骤
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build apk --release` (生成 APK)
   或
   `flutter build appbundle --release` (用于 Google Play 商店的 AAB)

### 结果
APK: `build/app/outputs/flutter-apk/app-release.apk`
AAB: `build/app/outputs/bundle/release/app-release.aab`

---
其他语言: [English](BUILD_ANDROID.md) | [한국어](BUILD_ANDROID_KO.md)
