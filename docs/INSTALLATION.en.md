# Installation Guide for ApiFlow Studio

This guide covers the setup and installation process for **ApiFlow Studio** on macOS, Windows, and Web environments.

## Prerequisites

Before running the project, ensure you have the following installed:

1.  **Flutter SDK**: Latest stable version recommended.
    ```bash
    flutter doctor
    ```
2.  **Dart SDK**: Included with Flutter.
3.  **Platform Specifics**:
    *   **macOS**: Xcode (latest), CocoaPods (`sudo gem install cocoapods`), Command Line Tools (`xcode-select --install`).
    *   **Windows**: Visual Studio 2022 (with Desktop development with C++ workload), Windows SDK.
    *   **Web**: Google Chrome (for debugging).

## Getting the Source

Clone the repository to your local machine:

```bash
git clone https://github.com/your-org/apilens.git
cd apilens
# If there are submodules
# git submodule update --init --recursive
```

## Install Dependencies

Install the Flutter packages:

```bash
flutter pub get
```

If the project uses code generation (e.g., Freezed, Hive, JSON Serializable), run the build runner:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Run in Debug Mode

### macOS Desktop
```bash
flutter run -d macos
```

### Windows Desktop
```bash
flutter run -d windows
```

### Web
We recommend using the standard HTML renderer for development or CanvasKit for performance testing.

```bash
# Standard
flutter run -d chrome

# With CanvasKit (closer to desktop rendering)
flutter run -d chrome --web-renderer canvaskit
```

## Environment Notes

### Storage (Hive)
*   **Desktop**: Data is stored in the application documents directory.
*   **Web**: Data is stored using **IndexedDB**. Clearing browser cache/data will wipe your saved workflows.

### Web CORS Limitations
When running on Web, calling external APIs directly from the browser is restricted by **CORS (Cross-Origin Resource Sharing)**.
*   **Development**: Apps like Postman avoid this, but browsers enforce it.
*   **Solution**: Use a CORS proxy or ensure your target API allows requests from `localhost` / your deployment domain.
*   For local testing with Chrome, you may need to disable web security (not recommended for daily use) or use a proxy server.

## Troubleshooting

### Flutter Issues
If the build fails unexpectedly, check the environment:
```bash
flutter doctor -v
```

### Cleaning Build Cache
If you encounter strange linking errors or cached artifacts:
```bash
flutter clean
flutter pub get
```

### Web Build Issues
If `flutter run -d chrome` hangs or fails:
1.  Update Chrome.
2.  Remove `build/web` directory manually.
3.  Try `flutter clean`.
