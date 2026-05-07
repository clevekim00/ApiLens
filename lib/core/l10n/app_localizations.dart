import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'dashboard': 'Dashboard',
      'requests': 'Requests',
      'workflows': 'Workflows',
      'import': 'Import',
      'explorer': 'Explorer',
      'history': 'HISTORY',
      'filter_requests': 'Filter requests...',
      'settings': 'Settings',
      'language': 'Language',
      'theme': 'Theme',
      'help': 'Documentation',
      'getting_started': 'Getting Started',
      'rest_builder': 'REST Request Builder',
      'workflow_editor': 'Workflow Editor',
      'shortcuts': 'Keyboard Shortcuts',
      'params': 'Params',
      'auth': 'Auth',
      'headers': 'Headers',
      'body': 'Body',
      'scripts': 'Scripts',
      'response': 'Response',
      'import_curl': 'Import cURL',
      'export_curl': 'Export cURL',
      'cancel': 'Cancel',
      'copy': 'Copy',
      'close': 'Close',
      'samples': 'Samples',
      'new': 'New',
      'open': 'Open',
      'save': 'Save',
      'run': 'Run',
      'save_as': 'Save as',
      'unsaved': 'Unsaved',
      'saved': 'Saved',
    },
    'ko': {
      'dashboard': '대시보드',
      'requests': '요청',
      'workflows': '워크플로우',
      'import': '가져오기',
      'explorer': '탐색기',
      'history': '히스토리',
      'filter_requests': '요청 필터링...',
      'settings': '설정',
      'language': '언어',
      'theme': '테마',
      'help': '도움말',
      'getting_started': '시작하기',
      'rest_builder': 'REST 요청 빌더',
      'workflow_editor': '워크플로우 에디터',
      'shortcuts': '단축키',
      'params': '파라미터',
      'auth': '인증',
      'headers': '헤더',
      'body': '바디',
      'scripts': '스크립트',
      'response': '응답',
      'import_curl': 'cURL 가져오기',
      'export_curl': 'cURL 내보내기',
      'cancel': '취소',
      'copy': '복사',
      'close': '닫기',
      'samples': '샘플',
      'new': '신규',
      'open': '열기',
      'save': '저장',
      'run': '실행',
      'save_as': '다른 이름으로 저장',
      'unsaved': '저장되지 않음',
      'saved': '저장됨',
    },
    'zh': {
      'dashboard': '仪表板',
      'requests': '请求',
      'workflows': '工作流',
      'import': '导入',
      'explorer': '资源管理器',
      'history': '历史记录',
      'filter_requests': '筛选请求...',
      'settings': '设置',
      'language': '语言',
      'theme': '主题',
      'help': '文档',
      'getting_started': '入门指南',
      'rest_builder': 'REST 请求构建器',
      'workflow_editor': '工作流编辑器',
      'shortcuts': '键盘快捷键',
      'params': '参数',
      'auth': '认证',
      'headers': '请求头',
      'body': '主体',
      'scripts': '脚本',
      'response': '响应',
      'import_curl': '导入 cURL',
      'export_curl': '导出 cURL',
      'cancel': '取消',
      'copy': '复制',
      'close': '关闭',
      'samples': '样本',
      'new': '新建',
      'open': '打开',
      'save': '保存',
      'run': '运行',
      'save_as': '另存为',
      'unsaved': '未保存',
      'saved': '已保存',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // --- Help Content (returning Map for complex structures) ---

  Map<String, dynamic> get helpContent {
    switch (locale.languageCode) {
      case 'ko':
        return _koHelp;
      case 'zh':
        return _zhHelp;
      case 'en':
      default:
        return _enHelp;
    }
  }

  static final Map<String, dynamic> _enHelp = {
    'getting_started': {
      'title': 'Getting Started with ApiLens',
      'p1':
          'ApiLens is a highly optimized, workflow-centric API workspace designed for backend developers and QA engineers.',
      'h2': 'The Workspace Layout',
      'p2': 'The main workspace is divided into three primary regions:',
      'b1':
          'Top Navigation: Switch between HTTP Requests, Workflows, and Swagger Imports.',
      'b2':
          'Explorer (Left): Organize your requests into nested workgroups and folders.',
      'b3':
          'Main Editor (Right): Craft requests, view responses, or design complex logic visually.',
    },
    'workflow_editor': {
      'title': 'Workflow Editor',
      'p1':
          'The Workflow Editor allows you to chain multiple API requests together, parse responses, and create complex testing scenarios.',
      'h2_1': '1. Types of Nodes',
      'n1': 'Entry Point: Execution begins here.',
      'n2': 'HTTP Request: Executes an API call.',
      'n3': 'Logic: Evaluates a JSONPath condition.',
      'n4': 'Loop: Iterates over an array.',
      'h2_2': '2. Connecting Nodes',
      'p2': 'Drag from the output port to the input port of another node.',
      'h2_3': '3. Data Binding',
      'p3': r'Use syntax like $.responses.<node_id>.data.<path>.',
    },
  };

  static final Map<String, dynamic> _koHelp = {
    'getting_started': {
      'title': 'ApiLens 시작하기',
      'p1':
          'ApiLens는 백엔드 개발자와 QA 엔지니어를 위해 설계된 고도로 최적화된 워크플로우 중심의 API 워크스페이스입니다.',
      'h2': '워크스페이스 레이아웃',
      'p2': '메인 워크스페이스는 세 가지 주요 영역으로 나뉩니다:',
      'b1': '상단 네비게이션: HTTP 요청, 워크플로우, Swagger 가져오기 간의 전환.',
      'b2': '탐색기 (좌측): 요청을 중첩된 워크그룹 및 폴더로 구성.',
      'b3': '메인 에디터 (우측): 요청 제작, 응답 확인 또는 복잡한 로직 시각적 설계.',
    },
    'workflow_editor': {
      'title': '워크플로우 에디터',
      'p1':
          '워크플로우 에디터는 여러 API 요청을 체인으로 연결하고, 응답을 파싱하며, 복잡한 테스트 시나리오를 생성할 수 있게 해줍니다.',
      'h2_1': '1. 노드 유형',
      'n1': '진입점 (Start): 여기서부터 실행이 시작됩니다.',
      'n2': 'HTTP 요청 노드: API 호출을 실행합니다.',
      'n3': '로직 (조건) 노드: JSONPath 조건을 평가합니다.',
      'n4': '루프 노드: 배열을 순회합니다.',
      'h2_2': '2. 노드 연결',
      'p2': '출력 포트에서 다른 노드의 입력 포트로 드래그하여 연결합니다.',
      'h2_3': '3. 데이터 바인딩',
      'p3': r'$.responses.<node_id>.data.<path> 와 같은 문법을 사용하세요.',
    },
  };

  static final Map<String, dynamic> _zhHelp = {
    'getting_started': {
      'title': 'ApiLens 入门指南',
      'p1': 'ApiLens 是一个高度优化的、以工作流为中心的 API 工作区，专为后端开发人员和 QA 工程师设计。',
      'h2': '工作区布局',
      'p2': '主工作区分为三个主要区域：',
      'b1': '顶部导航：在 HTTP 请求、工作流和 Swagger 导入之间切换。',
      'b2': '资源管理器（左侧）：将请求组织到嵌套的工作组和文件夹中。',
      'b3': '主编辑器（右侧）：制作请求、查看响应或以可视化方式设计复杂的逻辑。',
    },
    'workflow_editor': {
      'title': '工作流编辑器',
      'p1': '工作流编辑器允许您将多个 API 请求链接在一起，解析响应并创建复杂的测试场景。',
      'h2_1': '1. 节点类型',
      'n1': '入口点：执行从此开始。',
      'n2': 'HTTP 请求节点：执行 API 调用。',
      'n3': '逻辑（条件）节点：评估 JSONPath 条件。',
      'n4': '循环节点：遍历数组。',
      'h2_2': '2. 连接节点',
      'p2': '从输出端口拖动到另一个节点的输入端口。',
      'h2_3': '3. 数据绑定',
      'p3': r'使用类似 $.responses.<node_id>.data.<path> 的语法。',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ko', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
