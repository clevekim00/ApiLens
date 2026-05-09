# ApiLens: 统一的可视化 API 编排平台

<div align="center">
  <img src="assets/apilens_icon.svg" alt="ApiLens Icon" width="128" />
  <br/>
  <h3>连接。自动化。可视化。</h3>
  <p>一款专为 REST、WebSocket 和 GraphQL 编排打造的高性能、高级开发人员工具。</p>
</div>

---

## 🎯 项目目的

在现代软件开发中，开发人员经常需要切换多个互不关联的工具：使用 Postman 测试 REST，编写自定义脚本实现自动化，以及使用专门的客户端测试 WebSocket 或 GraphQL。**ApiLens** 的诞生就是为了将这些体验统一到一个无缝的平台中。

我们的目标是**弥补简单 API 测试与复杂工作流自动化之间的鸿沟**。通过提供带有实时反馈的基于节点的可视化编辑器，ApiLens 允许开发人员：
- **统一协议**：在一个地方管理 REST、WebSocket 和 GraphQL。
- **消除样板代码**：用强大的可视化逻辑取代脆弱的 bash/python 测试脚本。
- **增强可见性**：通过实时可视化调试，精确查看数据在系统中的流动方式。
- **加速开发**：利用专业的命令面板和模板，以前所未有的速度推进工作。

---

## ✨ 核心功能

### 🚀 先进的编排能力
- **可视化工作流编辑器**：使用基于节点的界面设计复杂的序列（例如：身份验证 -> 获取令牌 -> 连接 WebSocket）。
- **实时可视化调试**：实时观看工作流的执行。成功的路径变为**绿色**，失败变为**红色**，活动节点会以**蓝色**光晕脉动显示。
- **工作流模板**：内置场景库，如“认证流程”、“CRUD 同步”和“GraphQL 资源管理器”。

### 🧭 Load Hub 分布式性能测试
- **远程工作流压测**：将一个 Workflow 分配给多台远程机器上的代理执行，支持类似 LoadRunner 的性能测试流程。
- **远程机器与代理管理**：集中查看机器状态、代理 heartbeat、容量、版本和连接健康度。
- **实时指标汇总**：汇总代理侧 `MetricWindowEvent`，展示 RPS、错误率和 p50/p90/p95/p99 延迟。
- **代理升级编排**：通过 drain、install、restart、health check、rollback 流程分阶段升级远程代理。
- **报告导出**：将完成的执行结果导出为 JSON、CSV 或 Markdown 报告。

### 📊 实时仪表板与分析
- **中央控制中心**：启动应用程序时首先看到的专业级仪表板。一目了然地掌握整个 API 生态系统的健康状况。
- **性能指标可视化**：通过实时统计卡片提供 API 健康检查、平均响应时间、请求成功率和错误率。
- **流量趋势**：使用精美的图表可视化过去 24 小时的流量变化，即时发现系统瓶颈。

### 🛠 专业开发人员工具
- **多协议支持**：功能齐全的客户端，支持 REST、WebSocket（支持子协议）和 GraphQL（支持变量和内省）。
- **命令面板 (Cmd+K)**：即时搜索数千个请求和工作流。无需离开键盘即可切换主题或设置。
- **OpenAPI / Swagger 导入**：现代化的过滤导入系统，一键导入您的整个 API 规范。

### 💎 高级体验
- **毛玻璃 UI (Glassmorphism)**：使用 Flutter 构建的高级现代界面，具有流畅的 60FPS 动画和精选的深色模式。
- **工作组系统**：按项目而非列表组织工作。隔离环境和共享数据。
- **跨平台**：随时随地运行——支持 macOS、Windows、Linux 和 Web 端。
- **稳健的 UI 测试**：通过核心界面（仪表板、请求、导入）的自动化 Widget 测试，确保 UI 的稳定性。

---

## 📖 如何使用

### 1. 通过仪表板掌握现状
启动 ApiLens 后，首先会显示 **仪表板** 选项卡。
- 检查实时 API 健康状态和响应性能。
- 通过最近运行的 API 性能指标诊断当前系统状态。

### 2. 使用工作组进行组织
ApiLens 使用**工作组**来保持项目的独立性。
- 点击侧边栏中的 **+** 图标创建您的第一个项目。
- 使用**导入 (Import)** 功能引入现有的 OpenAPI (Swagger) JSON/YAML 文件。

### 2. 构建您的第一个请求
- 从顶部选项卡中选择协议 (REST/WS/GQL)。
- 输入您的 URL 和参数。ApiLens 支持**模板变量** `{{ variable_name }}`，可实现动态解析。
- 点击 **发送 (Send)** 查看格式化的响应、标头和执行时间。

### 3. 设计可视化工作流
- 导航到**工作流选项卡**。
- 将节点从调色板拖放到画布上。
- 连接端口以定义逻辑流（例如：将登录节点的 `success` 输出连接到获取节点的 `input`）。
- 点击 **运行 (Run)** 执行并观看实时可视化调试。

### 4. 使用 Load Hub 监控性能测试
- 从主导航打开 **Load Hub**。
- 在 Machines 中查看远程机器和代理状态。
- 在 Runs 和 Metrics 中查看分布式执行、RPS、错误率和延迟百分位。
- 在 Agent Updates 中跟踪分阶段升级和 rollback 状态。

### 5. 利用命令面板提升效率
- 随时按下 **Cmd + K** (或 **Ctrl + K**)。
- 输入以搜索特定的请求、工作流或应用程序命令。
- 使用方向键和 **Enter** 键即时跳转。

---

## 🛠 技术栈
- **框架**：[Flutter](https://flutter.dev)，打造高性能、多平台 UI。
- **状态管理**：[Riverpod](https://riverpod.dev)，实现强大且响应迅速的数据流。
- **本地存储**：[Hive](https://pub.dev/packages/hive) 和 [Isar](https://isar.dev)，实现快速、加密的本地数据存储。
- **网络**：带有自定义拦截器的 [Dio](https://pub.dev/packages/dio)，用于高级协议处理。

---

## 🚀 开始使用

### 📦 下载 (v1.0.0)
- **macOS**: [下载 macOS 版 ApiLens v1.0.0 (.zip)](release/ApiLens_macOS_v1.0.0.zip)
- **其他平台**: 从源代码构建 (见安装指南)

### 📖 指南
- **安装方法**: [完整安装指南](docs/INSTALLATION_GUIDE_CN.md)
- **使用方法**: [详细使用指南](docs/USAGE_GUIDE_CN.md)
- **Load Hub 设计**: [远程 Load Runner 设计](docs/REMOTE_LOAD_RUNNER_DESIGN.ko.md)
- **Load Hub 运维**: [Load Hub 运维指南](docs/LOAD_HUB_OPERATIONS.ko.md)
- **开发指南**: [面向开发人员的技术指南](docs/DEVELOP_GUIDE_KO.md)

### 🛠 本地开发
1. 确保您已安装 [Flutter](https://flutter.dev)。
2. 克隆仓库并运行 `flutter pub get`。
3. 使用 `flutter run` 运行。

---

## 🌍 相关资源
- **使用指南**：[详细使用指南](docs/USAGE_GUIDE_CN.md)
- **Load Hub 文档**：[设计](docs/REMOTE_LOAD_RUNNER_DESIGN.ko.md)、[运维](docs/LOAD_HUB_OPERATIONS.ko.md)、[远程代理设置](docs/REMOTE_AGENT_SETUP.ko.md)
- **技术文档**：查看 `docs/` 目录中的协议特定指南（GraphQL、WebSocket）。

---
*其他语言: [English](README.md) | [한국어](README_KO.md)*
