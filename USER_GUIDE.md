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

---
Other languages: [한국어](USER_GUIDE_KO.md) | [中文](USER_GUIDE_CN.md)
