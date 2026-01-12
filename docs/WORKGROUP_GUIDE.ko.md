# ApiLens Workgroup 가이드

ApiLens는 **Workgroup** 기능을 통해 API 요청과 워크플로우를 효율적으로 관리할 수 있습니다. 프로젝트별, 팀별, 또는 기능별로 작업을 그룹화하여 정리하세요.

## 주요 기능

### 1. Workgroup 구조
- **No Workgroup (System Default)**: 기본적으로 제공되는 공간입니다. 그룹에 속하지 않은 요청들이 이곳에 모입니다. 삭제하거나 이름을 변경할 수 없습니다.
- **Custom Groups**: 사용자가 직접 생성한 그룹입니다. 무제한으로 생성 가능하며, 하위 폴더 구조를 지원합니다(현재 1 depth 지원, 추후 확장 예정).

### 2. 생성 및 관리
- **생성**: Explorer 상단의 **New Folder** 아이콘을 클릭하여 새 그룹을 만듭니다.
- **수정**: 그룹 이름을 변경하려면 우클릭 메뉴에서 **Rename**을 선택하세요.
- **삭제**: 우클릭 메뉴에서 **Delete**를 선택합니다.
  - **Safe Delete**: 기본적으로 폴더 안의 내용물은 'No Workgroup'으로 이동되어 보존됩니다.
  - **Permanent Delete**: 체크박스를 해제하면 포함된 Request와 Workflow도 영구 삭제됩니다.

### 3. Drag & Drop 이동
- **Request 이동**: Request를 드래그하여 다른 폴더로 이동할 수 있습니다.
- **System으로 복귀**: Request를 Explorer 빈 공간이나 'No Workgroup' 폴더로 드래그하면 그룹 할당이 해제됩니다.

### 4. Import / Export (백업 및 공유)
- **Export (내보내기)**:
  - 그룹을 우클릭하고 **Export JSON**을 선택합니다.
  - 해당 그룹과 하위의 모든 Request, Workflow가 포함된 `.apilens-workgroup.json` 파일로 저장됩니다.
- **Import (가져오기)**:
  - Explorer 상단의 **Import** 아이콘(업로드 모양)을 클릭합니다.
  - `.apilens-workgroup.json` 파일을 선택하면 새로운 그룹으로 불러옵니다.
  - **충돌 방지**: 가져온 데이터는 새로운 ID를 부여받으며, 이름이 중복될 경우 `(Imported)` 접미사가 붙습니다.

### 5. Swagger / OpenAPI Import
- 기존 Swagger 문서를 한 번에 가져올 수 있습니다.
- 그룹 우클릭 메뉴 -> **Import Swagger** 선택.
- **From URL**: `https://.../swagger.json` 주소를 입력하여 가져옵니다.
- **Paste Content**: JSON 내용을 직접 붙여넣어 가져옵니다.
- 가져온 API 정의들은 자동으로 Request로 변환되어 해당 그룹에 추가됩니다.

## 팁
- **작업 환경 분리**: 개발 서버용 그룹과 운영 서버용 그룹을 나누어 관리해보세요.
- **환경 변수**: Environment 기능과 함께 사용하여 그룹별로 다른 변수 세트를 적용할 수 있습니다.
