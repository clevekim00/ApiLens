# ApiLens 설치 가이드 (Installation Guide)

ApiLens를 사용해 주셔서 감사합니다! 각 운영체제별 설치 및 실행 방법을 안내해 드립니다.

---

## 🍎 macOS 설치 방법

1. **다운로드**: `release/ApiLens_macOS.zip` 파일을 다운로드합니다.
2. **압축 해제**: 다운로드한 파일의 압축을 풉니다.
3. **응용 프로그램 폴더로 이동**: 압축 해제된 `ApiLens.app` 파일을 `Applications` (응용 프로그램) 폴더로 드래그하여 이동시킵니다.
4. **실행**: 응용 프로그램 폴더에서 `ApiLens`를 실행합니다.
   - *참고*: "확인되지 않은 개발자" 메시지가 뜰 경우, `시스템 설정 > 개인정보 보호 및 보안`에서 '확인 없이 열기'를 선택해 주세요.

---

## 🪟 Windows 설치 방법

1. **빌드 안내**: 현재 릴리스 폴더에는 macOS용 파일만 포함되어 있습니다. Windows에서 사용하시려면 다음 과정을 통해 직접 빌드하실 수 있습니다.
2. **사전 준비**: [Flutter SDK](https://docs.flutter.dev/get-started/install/windows)가 설치되어 있어야 합니다.
3. **명령어 실행**:
   ```powershell
   # 의존성 설치
   flutter pub get
   # Windows 릴리스 빌드
   flutter build windows
   ```
4. **실행**: `build/windows/runner/Release/ApiLens.exe` 파일을 실행합니다.

---

## 🌐 Web 버전 (Lite)

별도의 설치 없이 웹 브라우저에서도 사용 가능합니다.
- [apilens.app](https://apilens.app) (준비 중)

---

## 🚀 문제 해결

- **M1/M2/M3 Mac**: Apple Silicon을 기본 지원하므로 별도의 설정 없이 최상의 성능으로 작동합니다.
- **권한 오류**: macOS에서 네트워크 요청 권한이 필요할 경우 시스템 팝업에서 '허용'을 선택해 주세요.

더 궁금하신 점은 [GitHub Issues](https://github.com/clevekim00/ApiLens/issues)에 남겨주세요!
