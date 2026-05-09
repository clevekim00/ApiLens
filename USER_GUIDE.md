# ApiLens User Guide

## 0. Main Dashboard
- **Monitoring**: Monitor API health and response speeds on the dashboard that appears when the app starts.
- **Statistics**: Check request and error traffic trends for the past 24 hours.

## 1. Importing API Specifications
- **Swagger URL**: Paste a Swagger UI address, and ApiLens will auto-discover the specification.
- **Local Files**: Upload `JSON` or `YAML` OpenAPI files directly.
- **Filtering**: Use tag-based filtering to select only the endpoints you need.

## 2. Workflow Editor
- **Nodes**: Start, API Request, Condition, and End nodes.
- **Connections**: Drag lines between ports to define the execution flow.
- **Variables**: Use `$.responses.nodeId.body.path` to pass data between requests.

## 3. Load Hub
- **Distributed Performance Tests**: Split one Workflow across multiple remote agents.
- **Machine and Agent Management**: Monitor machine state, agent heartbeat, capacity, and versions.
- **Live Metrics**: Track shard status, RPS, error rate, and latency percentiles.
- **Agent Upgrades**: Follow drain, install, restart, health check, and rollback progress.
- **Exports**: Generate JSON, CSV, and Markdown reports for completed runs.

See [Load Hub Operations](docs/LOAD_HUB_OPERATIONS.ko.md) and [Remote Agent Setup](docs/REMOTE_AGENT_SETUP.ko.md) for details.

---
Other languages: [한국어](USER_GUIDE_KO.md) | [中文](USER_GUIDE_CN.md)
