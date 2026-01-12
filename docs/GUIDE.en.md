# ApiLens User Guide

## 1. Overview
**ApiLens** is a powerful all-in-one tool designed to help developers design, test, and automate APIs. It supports REST, WebSocket, and GraphQL within a unified interface and goes beyond simple request testing by enabling complex scenario automation via a node-based workflow editor.

### Key Features
- **Multi-Protocol Support**: Manage REST APIs, WebSockets, and GraphQL in one place.
- **Workflow Automation**: Connect API requests via an n8n-style visual editor to orchestrate data flow.
- **Workgroup System**: Organize resources by project or team with isolated environments.
- **OpenAPI Import**: Import Swagger/OpenAPI specifications and instantly convert them into runnable requests.

### Target Audience
- Backend engineers developing and testing APIs.
- Frontend developers verifying API behavior before integration.
- QA engineers validating complex API scenarios (e.g., Auth -> Fetch Data -> Process).

---

## 2. Installation & Run

### Desktop (macOS / Windows)
1. Download the installer (.dmg or .exe) for your OS from the Releases page.
2. Install and launch the application.
3. It operates offline using a local database.

### Web
1. Access the deployed web URL.
2. Uses IndexedDB for data storage.
   - *Note*: Clearing browser cache may delete your data. Use the `Export` feature to back up your work.

### Connecting to Test Backends
ApiLens connects to both local (localhost) and remote servers.
- **Desktop**: Can access local addresses (e.g., `http://localhost:8080`) directly.
- **Web**: Accessing local servers may require proxy settings or CORS configuration due to browser security policies.

---

## 3. Core Concepts

### Request
The smallest executable unit in ApiLens.
- **REST**: Standard HTTP requests like GET, POST, PUT, DELETE.
- **WebSocket**: Persistent sessions for real-time message exchange.
- **GraphQL**: Execution of Queries, Mutations, and Subscriptions.

### Workflow
An automation script linking multiple requests in a logical sequence. Built using a drag-and-drop visual node editor.

### Workgroup
Similar to a filesystem 'folder' but offers stronger isolation. Each Workgroup maintains its own Environment variables and resources.

### Environment
Manages dynamic values like `{{baseUrl}}` or `{{token}}`. Variables are scoped per Workgroup.

---

## 4. Using Workgroups

### Creation & Selection
1. **Create**: Click the `+` button at the top of the sidebar to create a new Workgroup.
2. **Select**: Click a folder in the sidebar to activate that group.
3. **No Workgroup**: The default system group. Items not assigned to any specific group reside here.

### Resource Management
- **Move**: Drag and drop Requests or Workflows between Workgroup folders.
- **Structure**: Create sub-folders within Workgroups for hierarchical organization.

### Sharing (Export / Import)
Use this to share API specifications with teammates.
1. **Export**: Right-click a Workgroup -> Select `Export JSON`. Saves as a `.json` file.
2. **Import**: Click the `Import` button in the sidebar header -> Select a `.json` file. Restores as a new Workgroup.

---

## 5. REST Request Builder

### Creating a Request
1. Click `+ Request` and select the `REST` tab.
2. **Method**: Choose HTTP method (GET, POST, etc.).
3. **URL**: Enter the endpoint URL (e.g., `{{baseUrl}}/users`).

### Components
- **Params**: Enter Query Parameters as key-value pairs.
- **Headers**: Set headers like Authorization tokens or Content-Type.
- **Body**: Compose the request body in JSON, Form Data, or Text format.

### Execution
- Click `Send` to execute.
- View Status Code, Response Body, and Headers in the bottom panel.

---

## 6. WebSocket

### Connect & Send
1. Select the `WebSocket` tab when creating a request.
2. Enter the URL (ws:// or wss://) and click `Connect`.
3. **Message**: Type text or JSON and click `Send`.
4. **Log**: View the timeline of sent and received messages.

### Workflow Integration
- **ws_connect**: Establishes a socket connection at the start of a flow.
- **ws_send**: Sends a message when conditions are met.
- **ws_wait**: Waits for a specific incoming message or verifies a response.

---

## 7. GraphQL

### Usage
1. Select the `GraphQL` tab when creating a request.
2. **Query**: Write your GraphQL query in the editor.
3. **Variables**: Input variables in JSON format.
4. Click `Run` to execute and view results.

### Workflow Node (gql_request)
- Supports scenarios like feeding a value from a REST API (e.g., User ID) into a GraphQL variable for subsequent execution.

---

## 8. Workflow Editor

The core automation feature of ApiLens.

### Steps
1. Click `+ Workflow` to open an empty canvas.
2. **Add Nodes**: Drag Request nodes or Logic nodes (If, Loop, Delay) from the palette.
3. **Connect**: Link the output port of one node to the input of another.
4. **Data Mapping**: Use results from previous nodes (e.g., `{{node1.data.id}}`) as inputs for subsequent nodes.

### Example: Signup & Profile Fetch
1. **HTTP Request 1**: `POST /signup` (User Registration).
2. **Set Variable**: Extract `token` from the response.
3. **HTTP Request 2**: `GET /profile` (Set header `Authorization: Bearer {{token}}`).
4. **Debug**: Output the final result.

---

## 9. OpenAPI Import

Quickly generate requests from existing Swagger/OpenAPI specifications.

### How to Run
1. Right-click a Workgroup -> Select `Import Swagger`.
2. **Load**: Enter the `OpenAPI Spec URL` or upload a JSON/YAML file.

### Filtering & Selection
Once loaded, a 3-pane layout appears:
- **Left (Tags)**: List of API tags. Check/uncheck to filter.
- **Center (Endpoints)**: Filtered list of APIs. Search by Path or Summary.
- **Select**: Pick specific endpoints or use `Select All Filtered`.

### Import Options
- **Base URL**: Choose between using Environment Variable (`{{env.baseUrl}}`) or the fixed URL from the spec.
- **Body Sample**: Decide whether to generate body examples based on Schema or use provided Examples.
- **Auth**: Choose to auto-detect authentication types or ignore security settings.

---

## 10. Theme & Settings
- **Theme**: Toggle between Dark and Light modes via the top-right settings menu.

---

## 11. Troubleshooting

**Q. I get CORS errors on the Web version.**
A. Browsers block cross-origin requests by default. The server needs to allow the origin (`Access-Control-Allow-Origin: *`), or you should use the Desktop version of ApiLens.

**Q. WebSocket keeps disconnecting.**
A. Check if your network firewall blocks WebSocket traffic. Also, verify the server's idle timeout settings.

**Q. Some APIs are missing after Import.**
A. We recommend OpenAPI 3.0+ (versions prior to 3.1). Check the parse logs for any error messages regarding specific definitions.
