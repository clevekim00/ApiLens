# Web Build Guide

### Build Steps
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build web --release`

### Result
`build/web/` (Host these files on any static web server).

---
Other languages: [한국어](BUILD_WEB_KO.md) | [中文](BUILD_WEB_CN.md)
