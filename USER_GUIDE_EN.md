# ApiLens User Guide

ApiLens is a powerful tool designed to help you design, test, and manage API workflows through an intuitive, node-based interface.

---

## 1. Getting Started: Importing API Specifications

The first step in ApiLens is to import the API specifications you want to work with.

### Import via Swagger (OpenAPI) URL
- **Auto-Discovery**: Simply paste a Swagger UI address (e.g., `http://localhost:8080/swagger-ui/index.html`), and ApiLens will automatically discover the underlying JSON/YAML specification.
- **Glassmorphism Interface**: Use our modern card-based interface to enter URLs or upload files with ease.

### Import via Local Files
- You can directly upload OpenAPI specification files in `JSON` or `YAML` format.
- Use tag-based filtering and search functionality to select specific endpoints and generate a workflow or save them as individual requests.

---

## 2. Explorer and Workgroup Management

Manage all your assets in the **Workgroup Explorer** sidebar on the left.

- **Folder Hierarchy**: Create folders via right-click or the top toolbar to organize workflows and requests into logical groups.
- **Import/Export Groups**: Export entire folders as JSON to share with teammates or back up your data.
- **Quick Actions**: Hover over items to reveal quick action buttons, such as delete or run.

---

## 3. Workflow Editor

The Workflow Editor is your canvas for designing API business logic.

### Available Node Types
- **Start**: The entry point of your workflow. (Required)
- **API Request**: Performs an HTTP request. Automatically populated with imported endpoint data.
- **Condition**: A branching node that redirects the path based on logic.
- **End**: The termination point of your workflow.
- **GraphQL/WebSocket**: Dedicated nodes for specialized communication protocols.

### Basic Controls
- **Adding Nodes**: Click a node in the left palette to add it to the canvas.
- **Connecting Edges**: Drag a line from one node's output port to another node's input port.
- **Inspector Panel**: Click a node to open the **Inspector Panel** on the right, where you can edit URLs, headers, bodies, and other parameters.

---

## 4. Execution and Debugging

Run your workflows to verify your logic and see results in real-time.

- **Path Validation**: Upon running, ApiLens automatically checks for a valid path from the Start node to an End node.
- **Run**: Click the 'Play' button in the toolbar to execute the sequence.
- **Debug Panel**: Monitor status, response values, and execution logs in real-time via the bottom panel.

---

## 5. Keyboard Shortcuts

Boost your productivity with these essential shortcuts.

| Action | Shortcut (Mac) | Shortcut (Windows/Linux) |
| :--- | :--- | :--- |
| **Save** | `Cmd + S` | `Ctrl + S` |
| **Save As** | `Cmd + Shift + S` | `Ctrl + Shift + S` |
| **New Workflow** | `Cmd + N` | `Ctrl + N` |
| **Open Workflow** | `Cmd + O` | `Ctrl + O` |
| **Run Workflow** | `Cmd + Enter` | `Ctrl + Enter` |

---

## 6. Sharing Data (Export JSON)

Export your workflows as JSON files for sharing or documentation.
Clicking 'Export JSON' opens a **Preview Dialog** where you can copy the content to your clipboard or save it directly to your file system.
