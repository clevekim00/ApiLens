# ApiLens

<div align="center">
  <img src="assets/apilens_icon.svg" alt="ApiLens Icon" width="128" />
  <br/>
  <img src="docs/assets/intro.png" alt="ApiLens Intro" width="100%" />
</div>

<br/>

ApiLens는 REST, WebSocket, GraphQL을 하나의 워크플로우로 연결할 수 있는 데스크톱/웹 기반 API 도구입니다.

## 주요 기능
- **Multi-Client**: REST / WebSocket / GraphQL Client 지원
- **Workflow Editor**: 복잡한 API 시나리오를 노드로 연결 및 자동화
- **Workgroup System**: 프로젝트 단위 격리 및 관리
- **OpenAPI Import**: 태그 필터링 및 선택적 Import 기능 지원
- **Team Collaboration**: Workgroup 파일 Export/Import로 팀 공유
- **Platform**: Desktop (macOS, Windows) 및 Web 지원
- **Theme**: Light / Dark 테마 지원

## Getting Started
Send your first request in 5 minutes.

- 📘 Guide: [docs/getting-started/first-request.ko.md](docs/getting-started/first-request.ko.md)
- 📘 Guide (EN): [docs/getting-started/first-request.en.md](docs/getting-started/first-request.en.md)

## Contributing
We welcome contributions from the community.

- 📘 Contributor Guide (KR): [docs/CONTRIBUTING.ko.md](docs/CONTRIBUTING.ko.md)
- 📘 Contributor Guide (EN): [docs/CONTRIBUTING.en.md](docs/CONTRIBUTING.en.md)

Quick start:
```bash
git clone https://github.com/apilens/apilens.git
cd apilens
flutter pub get
flutter run
```

## Quick Start
1. **ApiLens 실행**: 애플리케이션을 실행합니다.
2. **Workgroup 생성**: 사이드바에서 `+` 버튼을 눌러 새 그룹을 만듭니다.
3. **OpenAPI Import**: 그룹 우클릭 -> `Import Swagger`로 API 명세를 불러옵니다.
4. **Request 실행**: 목록에서 요청을 선택하고 `Send` 버튼을 누릅니다.
5. **Workflow 생성**: `+ Workflow`를 눌러 여러 요청을 연결하여 실행합니다.

## 문서
더 자세한 내용은 공식 가이드를 참고하세요.
- **전체 사용자 가이드**: [docs/GUIDE.ko.md](docs/GUIDE.ko.md)
