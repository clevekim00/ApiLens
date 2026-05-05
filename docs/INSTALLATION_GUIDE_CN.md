# ApiLens 安装指南

感谢您选择 ApiLens！以下是在不同平台上安装和运行该应用程序的说明。

---

## 🍎 macOS 安装

1. **下载**：获取 `release/ApiLens_macOS.zip` 文件。
2. **解压**：解压下载的文件。
3. **移动到应用程序**：将解压后的 `ApiLens.app` 拖放到您的 `Applications`（应用程序）文件夹中。
4. **启动**：从应用程序文件夹打开 `ApiLens`。
   - *注意*：如果您看到“身份不明的开发者”消息，请前往`系统设置 > 隐私与安全性`并选择“仍要打开”。

---

## 🪟 Windows 安装

1. **说明**：当前发布文件夹仅包含 macOS 二进制文件。要在 Windows 上使用 ApiLens，您可以从源代码构建。
2. **先决条件**：确保您已安装 [Flutter SDK](https://docs.flutter.dev/get-started/install/windows)。
3. **构建命令**：
   ```powershell
   # 安装依赖
   flutter pub get
   # 为 Windows 构建
   flutter build windows
   ```
4. **运行**：启动 `build/windows/runner/Release/ApiLens.exe`。

---

## 🚀 故障排除

- **Apple Silicon (M1/M2/M3)**：ApiLens 原生支持 Apple Silicon，以获得最佳性能。
- **权限**：如果在 macOS 上提示网络权限，请选择“允许”以启用 API 请求。

如需进一步帮助，请访问我们的 [GitHub Issues](https://github.com/clevekim00/ApiLens/issues)。
