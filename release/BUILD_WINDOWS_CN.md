# Windows 构建指南

### 预备条件
- **Flutter SDK:** [安装指南](https://docs.flutter.dev/get-started/install/windows)
- **Visual Studio 2022:** 安装“使用 C++ 的桌面开发”。

### 构建步骤
1. `flutter pub get`
2. `dart run build_runner build --delete-conflicting-outputs`
3. `flutter build windows --release`

### 结果
`build\windows\x64\runner\Release\apilens.exe`

---
其他语言: [English](BUILD_WINDOWS.md) | [한국어](BUILD_WINDOWS_KO.md)
