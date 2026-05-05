# ApiLens Installation Guide

Thank you for choosing ApiLens! Here are the instructions for installing and running the application on different platforms.

---

## 🍎 macOS Installation

1. **Download**: Get the `release/ApiLens_macOS.zip` file.
2. **Extract**: Unzip the downloaded file.
3. **Move to Applications**: Drag and drop the extracted `ApiLens.app` into your `Applications` folder.
4. **Launch**: Open `ApiLens` from your Applications folder.
   - *Note*: If you see an "Unidentified Developer" message, go to `System Settings > Privacy & Security` and select 'Open Anyway'.

---

## 🪟 Windows Installation

1. **Note**: The current release folder contains the macOS binary only. To use ApiLens on Windows, you can build it from source.
2. **Prerequisites**: Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) installed.
3. **Build Commands**:
   ```powershell
   # Install dependencies
   flutter pub get
   # Build for Windows
   flutter build windows
   ```
4. **Run**: Launch `build/windows/runner/Release/ApiLens.exe`.

---

## 🚀 Troubleshooting

- **Apple Silicon (M1/M2/M3)**: ApiLens provides native support for Apple Silicon for optimal performance.
- **Permissions**: If prompted for network permissions on macOS, please select 'Allow' to enable API requests.

For further assistance, please visit our [GitHub Issues](https://github.com/clevekim00/ApiLens/issues).
