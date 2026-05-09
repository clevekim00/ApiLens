# ApiLens 用户指南

## 0. 主仪表板
- **监控**: 在应用启动时显示的仪表板上监控 API 健康状况和响应速度。
- **统计**: 查看过去 24 小时的请求和错误流量趋势。

## 1. 导入 API 规范
- **Swagger URL**: 粘贴 Swagger UI 地址，ApiLens 将自动发现规范。
- **本地文件**: 直接上传 `JSON` 或 `YAML` 格式的 OpenAPI 文件。
- **过滤**: 使用基于标签的过滤，仅选择所需的端点。

## 2. 工作流编辑器
- **节点**: 开始、API 请求、条件和结束节点。
- **连接**: 在端口之间拖动线条以定义执行流。
- **变量**: 使用 `$.responses.nodeId.body.path` 在请求之间传递数据。

## 3. Load Hub
- **分布式性能测试**: 将一个 Workflow 分配给多个远程代理执行。
- **机器和代理管理**: 监控机器状态、代理 heartbeat、容量和版本。
- **实时指标**: 查看 shard 状态、RPS、错误率和延迟百分位。
- **代理升级**: 跟踪 drain、install、restart、health check 和 rollback 进度。
- **导出**: 为已完成的 run 生成 JSON、CSV 和 Markdown 报告。

详情请参考 [Load Hub 运维指南](docs/LOAD_HUB_OPERATIONS.ko.md) 和 [远程代理设置](docs/REMOTE_AGENT_SETUP.ko.md)。

---
其他语言: [English](USER_GUIDE.md) | [한국어](USER_GUIDE_KO.md)
