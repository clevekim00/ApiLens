# Android 빌드 가이드

### 사전 준비
- **Java Development Kit (JDK):** 17 버전 권장.
- **Android Studio 및 SDK.**

### 빌드 단계
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build apk --release` (APK 파일 생성)
   또는
   `flutter build appbundle --release` (Google Play 스토어용 AAB 생성)

### 결과물
APK: `build/app/outputs/flutter-apk/app-release.apk`
AAB: `build/app/outputs/bundle/release/app-release.aab`

---
다른 언어: [English](BUILD_ANDROID.md) | [中文](BUILD_ANDROID_CN.md)
