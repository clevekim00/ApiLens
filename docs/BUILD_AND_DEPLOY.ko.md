# 빌드 및 배포 가이드 (Build and Deploy)

이 문서는 **ApiFlow Studio**의 배포 버전 빌드 및 배포 준비 과정을 설명합니다.

## 빌드 타겟 (Build Targets)

### 1. macOS Desktop (Release)
macOS용 최적화된 배포 버전을 빌드합니다.

```bash
flutter build macos --release
```
*   **산출물**: `build/macos/Build/Products/Release/ApiFlow Studio.app`
*   **실행**: 생성된 `.app` 파일을 더블 클릭하여 실행할 수 있습니다.

### 2. Windows Desktop (Release)
Windows용 배포 버전을 빌드합니다.

```bash
flutter build windows --release
```
*   **산출물**: `build/windows/runner/Release/`
*   **구성**: `ApiFlow Studio.exe`, `flutter_windows.dll` 및 `data/` 폴더.
*   **요구사항**: 사용자 PC에 [Visual C++ Redistributable](https://learn.microsoft.com/ko-kr/cpp/windows/latest-supported-vc-redist)이 설치되어 있어야 할 수 있습니다.

### 3. Web App (Release)
정적 웹 애플리케이션으로 빌드합니다.

```bash
flutter build web --release --web-renderer canvaskit
```
*   **산출물**: `build/web/` 디렉토리.
*   **최적화**: `--web-renderer canvaskit` 옵션은 데스크톱 앱과 유사한 폰트 렌더링 및 성능을 제공합니다.

## 패키징 및 배포 (Packaging & Distribution)

### macOS
*   **DMG/PKG**: 앱 스토어 외부 배포 시 `.app`을 DMG로 패키징하는 것이 일반적입니다. (`create-dmg` 등의 도구 사용)
*   **서명(Signing)**: 공카적인 배포를 위해서는 Apple Developer ID로 앱을 서명하고 공증(Notarize) 과정을 거쳐야 "확인되지 않은 개발자" 경고를 피할 수 있습니다.

### Windows
*   **설치파일**: 산출물 폴더 전체를 ZIP으로 압축하거나, **Inno Setup** 또는 **WiX Toolset**을 사용하여 설치파일(`.msi`, `.exe`)을 제작합니다.
*   **서명**: "Windows SmartScreen" 경고를 방지하기 위해 코드 서명 인증서로 `.exe`를 서명하는 것을 권장합니다.

### Web Hosting
`build/web` 폴더의 내용을 정적 파일 호스팅 서비스에 업로드합니다.
*   **GitHub Pages**:
    ```bash
    # 배포 예시
    cd build/web
    git init
    # ... remote 설정 ...
    git checkout -b gh-pages
    git add . && git commit -m "Deploy"
    git push -f origin gh-pages
    ```
*   **Vercel / Netlify**: `build/web` 폴더를 드래그 앤 드롭하거나 Git 저장소를 연동하여 자동 배포합니다.
*   **S3 + CloudFront**: S3 버킷에 파일을 업로드하고 CloudFront(CDN)를 연결합니다.

## 버전 관리 (Versioning)

`pubspec.yaml` 파일에서 버전을 관리합니다:

```yaml
version: 1.0.0+1
```
*   **1.0.0**: 버전 명 (사용자에게 표시됨).
*   **+1**: 빌드 번호 (내부 관리용, 스토어 업로드 시 증가 필요).

## 배포 체크리스트 (Deployment Checklist)

1.  [ ] **환경 설정**: 프로덕션용 기본 URL이나 환경 변수가 코드에 올바르게 설정되었는지 확인합니다.
2.  [ ] **초기 데이터**: 로컬 Hive 데이터는 번들링되지 않습니다. 앱은 빈 상태로 시작됨을 유의하세요.
3.  [ ] **Web CORS**: 배포할 도메인(Origin)에서 타겟 API 호출이 허용되는지 확인합니다.
4.  [ ] **에셋 최적화**: 이미지, 아이콘 등의 용량이 최적화되었는지 확인합니다.

## 보안 참고사항 (Security Notes)

*   **토큰 저장**: 워크플로우 내에 저장된 인증 토큰은 Hive(로컬 파일/IndexedDB)에 저장됩니다. 현재 버전에서는 데이터가 암호화되지 않습니다.
*   **웹 환경**: 브라우저 저장소에 토큰이 유지되므로, 공용 PC 등에서의 사용 시 주의가 필요합니다.
