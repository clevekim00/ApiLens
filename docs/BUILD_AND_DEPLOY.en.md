# Build and Deploy Guide

This document outlines the process for building release versions of **ApiFlow Studio** and preparing them for distribution.

## Build Targets

### 1. macOS Desktop (Release)
Create a release build optimized for macOS.

```bash
flutter build macos --release
```
*   **Output**: `build/macos/Build/Products/Release/ApiFlow Studio.app`
*   **Running**: You can run the `.app` file directly to test.

### 2. Windows Desktop (Release)
Create a release build for Windows.

```bash
flutter build windows --release
```
*   **Output**: `build/windows/runner/Release/`
*   **Contents**: `ApiFlow Studio.exe` along with `flutter_windows.dll` and `data/` folder.
*   **Requirement**: End-users may need the [Visual C++ Redistributable](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist) installed.

### 3. Web App (Release)
Build a static web application.

```bash
flutter build web --release --web-renderer canvaskit
```
*   **Output**: `build/web/` directory.
*   **Optimization**: `--web-renderer canvaskit` ensures consistent font rendering and performance similar to desktop.

## Packaging & Distribution

### macOS
*   **DMG/PKG**: To distribute outside the App Store, wrap the `.app` in a DMG. You can use tools like `create-dmg` or Disk Utility.
*   **Signing**: For public distribution, you must sign the app with an Apple Developer ID and notarize it to avoid "Unidentified Developer" warnings.

### Windows
*   **Installer**: Deliver the output folder as a ZIP file, or create an installer (`.msi` / `.exe`) using tools like **Inno Setup** or **WiX Toolset**.
*   **Signing**: Recommend signing the `.exe` with a code signing certificate to prevent "Windows SmartScreen" warnings.

### Web Hosting
Deploy the contents of `build/web` to any static file host.
*   **GitHub Pages**:
    ```bash
    # Example deployment
    cd build/web
    git init
    git remote add origin ...
    git checkout -b gh-pages
    git add . && git commit -m "Deploy"
    git push -f origin gh-pages
    ```
*   **Vercel / Netlify**: Simply drag and drop the `build/web` folder or connect your Git repository.
*   **S3 + CloudFront**: Upload files to S3 bucket and configure CloudFront for SSL/CDN.

## Versioning

Manage versions in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```
*   **1.0.0**: Version name (visible to user).
*   **+1**: Build number (internal, auto-increment for stores).

## Deployment Checklist

1.  [ ] **Configuration**: Ensure `env` variables or base URLs are set for production.
2.  [ ] **Seed Data**: Note that local Hive data is **not** bundled. The app starts empty.
3.  [ ] **Web CORS**: Verify that APIs you intend to call allow requests from your deployment domain.
4.  [ ] **Asset Optimization**: Check that images/icons are optimized.

## CI/CD (Optional)

You can automate builds using **GitHub Actions**. define a `.github/workflows/build.yml` to run `flutter build ...` on push to `main` and upload artifacts.

## Security Notes

*   **Token Storage**: Tokens saved in existing Workflows are stored in Hive (local file/IndexDB). They are **specifically** not encrypted at rest in this version.
*   **Web Context**: Be careful accessing sensitive APIs from the browser application; tokens persist in browser storage.
