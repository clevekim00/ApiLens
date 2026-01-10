# ApiFlow Studio 설치 가이드

본 문서는 macOS, Windows, Web 환경에서 **ApiFlow Studio**를 설정하고 실행하는 방법을 안내합니다.

## 필수 요건 (Prerequisites)

프로젝트 실행 전 다음 항목이 설치되어 있어야 합니다:

1.  **Flutter SDK**: 최신 Stable 버전 권장.
    ```bash
    flutter doctor
    ```
2.  **Dart SDK**: Flutter에 포함됨.
3.  **플랫폼 별 요구사항**:
    *   **macOS**: Xcode (최신 버전), CocoaPods (`sudo gem install cocoapods`), Command Line Tools (`xcode-select --install`).
    *   **Windows**: Visual Studio 2022 ('C++를 사용한 데스크톱 개발' 워크로드 포함), Windows SDK.
    *   **Web**: Google Chrome (디버깅용).

## 소스 코드 가져오기 (Getting the Source)

저장소를 로컬 머신에 복제합니다:

```bash
git clone https://github.com/your-org/apilens.git
cd apilens
# 서브모듈이 있는 경우
# git submodule update --init --recursive
```

## 의존성 설치 (Install Dependencies)

Flutter 패키지를 설치합니다:

```bash
flutter pub get
```

코드 생성(Code Generation)이 필요한 경우 (예: Freezed, Hive 등):

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 디버그 모드 실행 (Run in Debug Mode)

### macOS Desktop
```bash
flutter run -d macos
```

### Windows Desktop
```bash
flutter run -d windows
```

### Web
개발 시에는 기본 HTML 렌더러를, 성능 테스트 시에는 CanvasKit을 권장합니다.

```bash
# 기본 모드
flutter run -d chrome

# CanvasKit (데스크톱 렌더링과 유사)
flutter run -d chrome --web-renderer canvaskit
```

## 환경 참고사항 (Environment Notes)

### 저장소 (Hive)
*   **Desktop**: 애플리케이션 문서 디렉토리에 데이터 파일이 저장됩니다.
*   **Web**: 브라우저의 **IndexedDB**를 사용합니다. 브라우저 캐시 및 데이터를 삭제하면 저장된 워크플로우도 삭제됩니다.

### 웹 CORS 제한 (Web CORS Limitations)
웹 환경에서 외부 API를 직접 호출할 때 **CORS (Cross-Origin Resource Sharing)** 정책에 의해 차단될 수 있습니다.
*   **개발 환경**: Postman 등은 제한이 없으나, 브라우저는 보안상의 이유로 이를 차단합니다.
*   **해결책**: CORS 프록시 서버를 사용하거나, 타겟 API 서버가 `localhost` 또는 배포 도메인에서의 요청을 허용하도록 설정해야 합니다.

## 문제 해결 (Troubleshooting)

### Flutter 이슈
빌드가 예상치 못하게 실패하는 경우, 환경 설정을 확인하세요:
```bash
flutter doctor -v
```

### 빌드 캐시 정리
링킹 에러나 오래된 캐시로 인한 문제가 의심될 때:
```bash
flutter clean
flutter pub get
```

### 웹 빌드 오류
`flutter run -d chrome`이 멈추거나 실패할 때:
1.  Chrome 브라우저 업데이트 확인.
2.  `build/web` 폴더 수동 삭제.
3.  `flutter clean` 실행.
