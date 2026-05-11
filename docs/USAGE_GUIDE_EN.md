# Usage Guide for ApiLens

This guide explains the interface and how to build, configure, and execute automated workflows in **ApiLens**.

## Quick Tour

The primary interface consists of six main areas:

1.  **Dashboard (Home)**: The central command center showing real-time API health, performance metrics, and traffic trends.
2.  **Navigation (Top Bar)**: Quick switching between Dashboard, Requests, Workflows, Import, and Load Hub.
3.  **Explorer (Left Sidebar)**: Organize and manage your requests by workgroups and folders.
4.  **Canvas (Center)**: The infinite workspace where you design your flow.
5.  **Load Hub**: The distributed performance testing console for remote machines and agents.
6.  **Command Palette (Cmd + K)**: A global search and action bar to navigate and execute commands instantly.

## Create Your First Workflow

### 1. Start a New Workflow
*   Click the workflow name in the top bar to open the menu.
*   Select **New Workflow** (Shortcut: `Cmd/Ctrl + N`).
*   **Using Templates**: Choose from pre-defined scenarios in the "Workflow Templates" section to jumpstart your automation.

### 2. Add Nodes
*   From the **Node Palette**, drag a **Start** node onto the canvas. (Every workflow must have one).
*   Drag an **HTTP** node.
*   Drag an **End** node.

### 3. Connect Nodes
*   Click the **Output Port** (right side) of the `Start` node. You will see a "Connection Mode" overlay.
*   Click the **Input Port** (left side) of the `HTTP` node. A connection line will appear.
*   Repeat to connect `HTTP` output to `End` input.
*   *Tip: You can also drag from a port to start connecting.*

### 4. Configure HTTP Request
*   Click the **HTTP Node** to select it.
*   In the **Inspector Panel** on the right:
    *   **Method**: Select `GET`.
    *   **URL**: Enter a test API (e.g., `https://jsonplaceholder.typicode.com/todos/1`).
    *   **Headers/Body**: Leave empty for this test.

## Using Templates

You can pass data between nodes dynamically using the `{{ }}` syntax.

*   **Node Responses**: Access data from a previous node.
    *   Syntax: `{{node.<node_id>.response.body.<field>}}`
    *   Example: `{{node.http_1.response.body.title}}`
*   **Environment Variables** (Future Feature):
    *   Syntax: `{{env.API_KEY}}`

## Running Workflows

1.  Click the **Run** button in the top menu or press `Cmd/Ctrl + Enter`.
2.  The workflow will execute starting from the `Start` node.
3.  **Real-time Visual Debugging**:
    *   **Active Nodes**: Currently executing nodes glow **Blue** with a pulse animation.
    *   **Visual Paths (Edges)**: The flow of data is highlighted in real-time.
        *   **Green Path**: Highlighted when the previous node executes successfully.
        *   **Red Path**: Highlighted on error or condition mismatch.
    *   **Status Animations**: Response status codes pop up next to nodes for immediate feedback.
4.  **Check Logs**: Expand the bottom panel to see detailed request/response data for each step.

### Timeout/Retry Policy

Executable nodes (HTTP, GraphQL, WebSocket Connect/Send/Wait) can include a shared `execution` policy.

*   **Timeout**: `timeoutMs` limits each execution attempt, not the entire workflow.
*   **Retry**: `retry.maxAttempts` is the number of extra attempts after the first run. The default is `0`, so existing workflows do not retry automatically.
*   **Backoff**: `retry.backoffMs` controls the delay before the next attempt.
*   **Status Code Retry**: HTTP/GraphQL nodes can retry on `408`, `429`, `500`, `502`, `503`, and `504` by default.
*   **Failure Routing**: If all attempts fail, execution follows the `failure` port when it is connected.

See [Workflow Timeout/Retry Policy](WORKFLOW_TIMEOUT_RETRY_POLICY.en.md) for the current JSON shape and implementation notes.

## Distributed Performance Tests with Load Hub

Load Hub runs a Workflow across multiple remote agents as shards, then aggregates live metrics into one operational view.

*   **Open Load Hub**: Use the main `Load Hub` tab, the hub icon, or the `Open Load Hub` command.
*   **Machines**: Inspect machine admin state, agent heartbeat, version, capacity, and scheduling eligibility.
*   **Machine Health**: Monitor CPU, memory, disk I/O, network throughput, and pressure state from agent heartbeats.
*   **Runs and Metrics**: Monitor shard lifecycle, RPS, error rate, p50/p90/p95/p99 latency, and agent utilization.
*   **Agent Updates**: Track drain, install, restart, health check, and rollback progress.
*   **Reports**: Export completed run results as JSON, CSV, or Markdown.

See [Load Hub Operations](LOAD_HUB_OPERATIONS.ko.md) and [Remote Agent Setup](REMOTE_AGENT_SETUP.ko.md) for implementation and operations details.

## Saving & Loading

*   **Save**: `Menu -> Save` (`Cmd/Ctrl + S`) saves changes locally locally.
*   **Open**: `Menu -> Open` (`Cmd/Ctrl + O`) lists all saved workflows.
*   **Export JSON**: `Menu -> Export JSON` copies the workflow structure to your clipboard.
*   **Import JSON**: `Menu -> Import JSON` allows pasting a workflow structure from text.

## Condition Node logic (Branching)

Use the **Condition** node to branch logic (True/False):

1.  Add a Condition node.
2.  Set the **Expression** in the Inspector.
    *   Example: `{{node.http_1.response.status}} == 200`
3.  Connect the **True** port to the success path.
4.  Connect the **False** port to the error handling path.

## Tips for Web Users

### CORS Issues
If your HTTP Request fails immediately with a network error on Web:
*   This is likely due to **CORS**. Browsers block requests to servers that don't explicitly allow your origin.
*   **Workaround**: Use a CORS proxy service or run the backend with CORS enabled for `localhost`.

### Performance
*   Large JSON responses in the logs may slow down the UI log/debug panel.

## FAQ

**Q: Why does my workflow just stop?**
A: Ensure all nodes are connected. If a path (e.g., "False" path of a condition) is disconnected, execution stops there.

**Q: Where are my files saved?**
A: They are saved in an internal database (Hive). Use "Export JSON" to backup your work to a text file.

**Q: Can I loop?**
A: Currently, simple cycles are supported, but infinite loops are not protected against. Use with caution.

## WebSocket Automation

ApiLens supports WebSocket integration both for testing and automated workflows.

### 1. WebSocket Tester
Access via **Menu -> Tools -> WebSocket Tester**. This standalone tool lets you:
*   Connect to a WS server.
*   Send messages (Text/JSON).
*   View logs.
*   Save configurations for later use.

### 2. Workflow Integration
You can automate complex WebSocket flows using three new node types:

*   **WS Connect**: Initiates a connection.
    *   *Store Session As*: Define a key (e.g., `mainWs`) to reference this connection in subsequent nodes.
    *   *Mode*: Use "Direct" for dynamic URLs or "Config Ref" to use saved presets.
*   **WS Send**: Sends a message to an active session.
    *   *Payload*: Supports templates (e.g., `{"token": "{{node.login.response.body.token}}"}`).
*   **WS Wait**: Pauses execution until a matching message is received.
    *   *Match Type*: "Contains Text", "JSON Path" (e.g. `$.type == "pong"`), or "Any Message".
    *   *Timeout*: Fails if no match found within X ms.

### 3. Web Platform Limitations
When running ApiLens on the **Web** (Browser):
*   **Custom Headers**: The standard browser WebSocket API does **not** support custom HTTP headers during the handshake (e.g., `Authorization: Bearer ...`).
*   **Workaround**: Use Query Parameters (e.g., `wss://api.com?token=XYZ`) or Subprotocols (Sec-WebSocket-Protocol) for authentication.
*   *Note*: Desktop (macOS/Windows/Linux) versions support full custom headers.

## GraphQL Automation

Integrate GraphQL APIs directly into your workflows to automate complex data fetching.

*   **GraphQL Request Node**: Use a dedicated node to execute queries.
    *   **URL**: The GraphQL endpoint address.
    *   **Query**: A full-featured editor for `.graphql` syntax.
    *   **Variables**: Input JSON variables. Supports template injection (`{{ }}`).
*   **Visual Feedback**: Like other nodes, GraphQL nodes show real-time success (Green) or failure (Red) paths based on the `data` or `errors` fields in the response.
*   **Data Access**: Reference results using `{{node.<id>.response.body.data.<field>}}`.
