# 🍎 Apple App Store 등록 가이드 (macOS/iOS)

ApiLens와 같은 앱을 Apple App Store에 등록하기 위한 전체 프로세스를 단계별로 정리했습니다.

---

## 🛠 1. 준비 사항 (Prerequisites)

*   **Apple Developer Program 가입**: 개인 또는 조직 계정으로 가입해야 합니다 (연간 $99). [Apple Developer 사이트](https://developer.apple.com/programs/)에서 진행합니다.
*   **Xcode 설치**: 최신 버전의 Xcode가 필요합니다.
*   **앱 아이콘 및 스크린샷**: 각 해상도별 스크린샷과 1024x1024 사이즈의 앱 아이콘이 필요합니다.

---

## 📝 2. App Store Connect 앱 생성

1.  [App Store Connect](https://appstoreconnect.apple.com/)에 로그인합니다.
2.  **나의 앱 (My Apps)** 메뉴에서 **+** 아이콘을 클릭하여 **신규 앱**을 생성합니다.
3.  **플랫폼(iOS/macOS)**, **이름**, **기본 언어**, **번들 ID(Bundle ID)**, **SKU**를 입력합니다.
    *   *Tip: 번들 ID는 Apple Developer 포털의 'Identifiers'에서 미리 생성해야 합니다.*

---

## 🔐 3. 인증서 및 프로파일 설정 (Code Signing)

1.  **Certificates**: 'Apple Distribution' 인증서를 생성합니다.
2.  **Identifiers**: 앱의 App ID(Bundle ID)를 등록하고 필요한 Capability(예: Sandbox, Network)를 설정합니다.
3.  **Profiles**: 'App Store'용 프로비저닝 프로파일을 생성하여 앱과 연결합니다.

---

## 🏗 4. 앱 빌드 및 아카이브 (Flutter 기준)

ApiLens(Flutter)를 App Store용으로 빌드하는 방법입니다.

1.  **버전 확인**: `pubspec.yaml`에서 버전과 빌드 번호를 업데이트합니다.
2.  **macOS 빌드**:
    ```bash
    flutter build macos --release
    ```
3.  **Xcode 열기**: `macos/Runner.xcworkspace` 파일을 Xcode로 엽니다.
4.  **Signing & Capabilities**: 'Automatically manage signing'을 체크하거나 수동으로 생성한 프로파일을 선택합니다.
5.  **Archive**: 상단 메뉴에서 `Product` -> `Archive`를 선택하여 아카이브를 생성합니다.

---

## 📤 5. 앱 업로드

1.  Archive가 완료되면 **Distribute App** 버튼을 클릭합니다.
2.  **App Store Connect**를 선택하고 **Upload**를 진행합니다.
3.  업로드가 완료되면 App Store Connect의 **TestFlight** 탭에서 처리 중인 앱을 확인할 수 있습니다.

---

## 📄 6. 앱 정보 및 심사 제출

App Store Connect의 앱 페이지에서 다음 정보를 입력합니다.

*   **앱 정보**: 개인정보 처리방침(Privacy Policy) URL, 카테고리 등.
*   **가격 및 판매**: 무료 또는 유료 설정, 판매 국가 선택.
*   **심사 정보**: 연락처 정보, 데모 계정(로그인이 필요한 경우).
*   **스크린샷**: 홍보 문구와 함께 각 기기 규격에 맞는 스크린샷 업로드.

모든 입력이 완료되면 **심사 준비 완료 (Submit for Review)** 버튼을 클릭합니다.

---

## 💡 주요 팁 및 유의사항

*   **App Sandbox (macOS 전용)**: App Store에 등록하는 macOS 앱은 반드시 **Sandbox**가 활성화되어야 합니다. 네트워크 접근 권한 등이 올바르게 설정되었는지 확인하세요.
*   **심사 기간**: 보통 1~3일 정도 소요되며, 거절(Reject)될 경우 가이드라인에 따라 수정 후 재제출해야 합니다.
*   **Hardened Runtime**: macOS 앱은 보안을 위해 Hardened Runtime이 활성화되어야 합니다.

---
> [!TIP]
> ApiLens의 경우 네트워크 요청을 보내는 도구이므로, Xcode의 `Entitlements` 설정에서 **Outgoing Connections (Client)** 권한이 반드시 체크되어 있어야 합니다.
