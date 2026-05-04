# Linux 构建指南

### 预备条件
- **Flutter SDK:** [安装指南](https://docs.flutter.dev/get-started/install/linux)
- **依赖项:** `sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev`

### 构建步骤
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build linux --release`

### 结果
`build/linux/x64/release/bundle/apilens`

---
其他语言: [English](BUILD_LINUX.md) | [한국어](BUILD_LINUX_KO.md)
