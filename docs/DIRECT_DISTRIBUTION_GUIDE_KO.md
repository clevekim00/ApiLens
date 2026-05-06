# ApiLens 직접 배포 가이드 (Direct Distribution Guide)

App Store를 통하지 않고 웹사이트나 GitHub를 통해 직접 실행 파일(`.dmg` 또는 `.pkg`)을 배포하는 방법을 설명합니다. macOS의 보안 정책(Gatekeeper)을 준수하기 위해 **코드 서명(Code Signing)**과 **공증(Notarization)** 과정이 필수적입니다.

---

## 🛠 1. 준비 사항

*   **Apple Developer Program 가입**: Developer ID 인증서를 발급받기 위해 필요합니다.
*   **Xcode Command Line Tools**: 최신 버전이 설치되어 있어야 합니다.
*   **Developer ID Application 인증서**: Xcode 설정에서 'Developer ID Application' 유형의 인증서를 생성하고 키체인에 설치해야 합니다.
*   **앱 전용 암호(App-Specific Password)**: 공증을 위해 [appleid.apple.com](https://appleid.apple.com/)에서 생성한 암호가 필요합니다.

---

## 📝 2. Xcode 설정

직접 배포를 위해서는 'Hardened Runtime'이 활성화되어야 합니다.

1.  `macos/Runner.xcworkspace`를 Xcode로 엽니다.
2.  **Runner** 타겟 선택 -> **Signing & Capabilities** 탭으로 이동합니다.
3.  **+ Capability**를 클릭하여 **Hardened Runtime**을 추가합니다.
4.  배포 환경에 따라 **App Sandbox** 설정을 확인합니다. (파일 시스템 접근 등이 필요한 경우 Entitlements 설정 필요)

---

## 🚀 3. 빌드 및 배포 단계

### 1단계: 릴리즈 빌드
터미널에서 다음 명령어를 실행하여 릴리즈 버전의 앱 번들을 생성합니다.
```bash
flutter build macos --release
```
빌드 결과물은 `build/macos/Build/Products/Release/ApiLens.app`에 생성됩니다.

### 2단계: 코드 서명 (Code Signing)
인증서를 사용하여 앱 번들에 서명합니다.
```bash
codesign --options=runtime --deep --force --verbose --sign "Developer ID Application: Your Name (Team ID)" "build/macos/Build/Products/Release/ApiLens.app"
```

### 3단계: 패키징 (ZIP 또는 DMG)
공증을 위해 앱을 압축하거나 DMG 파일로 만듭니다. 간단한 방법으로 ZIP 압축을 사용합니다.
```bash
ditto -c -k --sequesterRsrc --keepParent "build/macos/Build/Products/Release/ApiLens.app" "ApiLens_macOS_v1.0.0.zip"
```

### 4단계: Apple 공증 (Notarization)
Apple 서버에 업로드하여 검사를 받습니다. 이 과정이 완료되어야 사용자가 앱을 실행할 때 "악성 소프트웨어가 있는지 확인할 수 없습니다"라는 경고가 뜨지 않습니다.
```bash
xcrun notarytool submit "ApiLens_macOS_v1.0.0.zip" \
  --apple-id "your-apple-id@email.com" \
  --password "your-app-specific-password" \
  --team-id "YOUR_TEAM_ID" \
  --wait
```

### 5단계: 티켓 스테이플링 (Stapling)
공증이 성공하면 Apple의 승인 티켓을 앱에 직접 붙입니다.
```bash
xcrun stapler staple "build/macos/Build/Products/Release/ApiLens.app"
```

---

## 📦 4. 배포하기

1.  **GitHub Releases**: 생성된 `.zip` 또는 `.dmg` 파일을 GitHub 저장소의 Releases 섹션에 업로드합니다.
2.  **웹사이트**: 자신의 웹사이트나 블로그에 다운로드 링크를 제공합니다.

---

## 💡 참고: 인증서 없이 배포하기 (비공식)

개발자 계정이 없는 경우, 빌드된 `.app` 파일을 그대로 전달할 수 있지만 사용자는 다음과 같은 불편을 겪게 됩니다.
1.  앱 실행 시 "확인되지 않은 개발자" 경고가 뜹니다.
2.  사용자는 **시스템 설정 -> 개인정보 보호 및 보안**에서 "확인 없이 열기"를 클릭하거나, 앱을 **우클릭 -> 열기**로 실행해야 합니다.

가장 전문적인 사용자 경험을 위해서는 **Apple Developer ID 인증서**를 통한 배포를 강력히 권장합니다.
