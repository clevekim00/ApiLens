# ApiLens 安装指南

本指南涵盖了在 macOS、Windows 和 Web 环境中设置和安装 **ApiLens** 的过程。

## 预备条件
在运行项目之前，请确保已安装以下软件：
1. **Flutter SDK**: 推荐使用最新的稳定版本。
2. **Dart SDK**: 包含在 Flutter 中。
3. **平台特定要求**:
   - **macOS**: Xcode, CocoaPods, Command Line Tools。
   - **Windows**: Visual Studio 2022 (包含 C++ 桌面开发工作负载)。
   - **Web**: Google Chrome。

## 获取源码
```bash
git clone https://github.com/apilens/apilens.git
cd apilens
```

## 安装依赖
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 运行
- **macOS**: `flutter run -d macos`
- **Windows**: `flutter run -d windows`
- **Web**: `flutter run -d chrome`

---
其他语言: [English](INSTALLATION.md) | [한국어](INSTALLATION_KO.md)
