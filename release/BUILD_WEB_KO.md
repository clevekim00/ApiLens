# Web 빌드 가이드

### 빌드 단계
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build web --release`

### 결과물
`build/web/` (이 폴더의 파일들을 정적 웹 서버에 호스팅하세요).

---
다른 언어: [English](BUILD_WEB.md) | [中文](BUILD_WEB_CN.md)
