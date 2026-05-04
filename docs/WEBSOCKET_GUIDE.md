# WebSocket Usage Guide

## 1. Overview
**ApiFlow Studio** supports **WebSocket** protocols for real-time bidirectional communication alongside standard REST APIs.  
You can perform manual tests via the client or automate complex scenarios involving connection handling, message sending, and response waiting using **Workflows**.

### Use Cases
- Testing real-time services like chat servers, stock tickers, or notifications.
- Verifying data flow by connecting to a WebSocket immediately after receiving an auth token via REST API.
- rigorous scenario testing where the client must simulate specific message sequences (e.g., verifying `ping` -> `pong` responses).

---

## 2. Using the WebSocket Client (Manual Test)
Before building a workflow, you can perform manual tests to verify connectivity.

1. **Access**: Go to `WebSocket` -> `Open Client` in the top menu bar, or use the `WebSocket` tab in the `Request Builder`.
2. **Connect**:
   - **URL**: Enter an address starting with `ws://` or `wss://`.  
     *(e.g., `wss://echo.websocket.org`)*
   - **Connect Button**: Initiates the connection. Upon success, the status badge turns **CONNECTED** (Green).
3. **Send Message**:
   - Type your message in the bottom input field and click `Send`.
   - Supports both plain text and JSON formats.
4. **View Logs**:
   - **Green Arrow (⬇)**: Received messages.
   - **Blue Arrow (⬆)**: Sent messages.
   - **Grey Info (ℹ)**: System messages (Connected, Error, etc.).
5. **Manage Configs**:
   - Save frequently used URLs via the side panel to quickly load them later.

---

## 3. Authentication & Web Limitations (Important)

### Platform Differences (Desktop vs. Web)
Due to technical characteristics of Flutter (Dart), the **Desktop (macOS/Windows)** and **Mobile** versions use the standard I/O implementation (`dart:io`), allowing full control over **Custom Headers**.

However, in **Web Browser** environments, due to browser security policies and Web API limitations, **adding Custom Headers (e.g., `Authorization`) during the WebSocket Handshake is strictly restricted**.

### Recommended Authentication Methods
To ensure compatibility across all platforms, including Web, we recommend the following:

1. **Query Parameter (Highly Recommended)**
   - Include the token directly in the URL.
   - e.g., `wss://api.example.com/socket?token=YOUR_ACCESS_TOKEN`
   
2. **Subprotocol**
   - Use the `Sec-WebSocket-Protocol` header for authentication.
   - e.g., `protocols=['auth_token_xyz']`

> **Note**: If you strictly use the Desktop version, using Custom Headers (`Authorization: Bearer ...`) is fully supported.

---

## 4. Using WebSocket in Workflows
Use the **Workflow Editor** to orchestrate complex scenarios beyond simple connection testing.

### Key Nodes

#### 1) WS Connect (`ws_connect`)
- **Role**: Establishes and maintains a session with a WebSocket server.
- **Key Settings**:
  - **Mode**: Direct URL entry (`Direct`) or use a saved configuration (`Config Ref`).
  - **Store As (Session Key)**: A unique identifier for this session (e.g., `mainWs`). This key is used by subsequent nodes to reference this connection.
  - **Auto Reconnect**: Whether to attempt reconnection if the connection drops.

#### 2) WS Send (`ws_send`)
- **Role**: Sends a message through an active session.
- **Key Settings**:
  - **Session Key**: The key of the connection to use (e.g., `mainWs`).
  - **Payload**: The message content. Supports template interpolation (`{{...}}`) using data from previous nodes.

#### 3) WS Wait (`ws_wait`)
- **Role**: Pauses the workflow until a specific message is received.
- **Key Settings**:
  - **Session Key**: The key of the connection to listen to.
  - **Timeout**: Fails if the message does not arrive within the specified time (ms).
  - **Match Type**:
    - `Contains Text`: Passes if the message contains the specified string.
    - `JSON Path Equals`: Passes if a specific field in the JSON response matches the value (e.g., `$.type` == `pong`).
    - `Any Message`: Passes as soon as any message is received.

---

## 5. Sample Scenarios

### Scenario A: Echo Test (Direct)
A basic connection and response test.
1. **WS Connect**: Connect to `wss://echo.websocket.org`, `storeAs: echo`.
2. **WS Send**: Send `Hello`, `sessionKey: echo`.
3. **WS Wait**: Wait for message containing `Hello`, `sessionKey: echo`.

### Scenario B: Saved Config Usage
Using a pre-configured setup (e.g., Local Dev).
1. **WebSocket Client**: Save a config for `ws://localhost:8080`.
2. **WS Connect**: Select `Config Ref` mode and choose the saved config ID.
3. **WS Wait**: Wait for the server's welcome message.

### Scenario C: REST Auth → WebSocket (Chain)
Login via REST API and use the received token for the socket connection.
1. **API Node**: POST request to login endpoint (`/login`).
2. **WS Connect**: Bind token to URL.  
   e.g., `wss://myapp.com/ws?token={{steps.step1.response.body.token}}`
3. **WS Send**: Request user data using the authenticated session.
4. **WS Wait**: Verify the response data.

---

## 6. Troubleshooting

- **Q: Connection works on Web, but authentication fails.**
  - A: This is likely due to the **Header Limitation**. Check the Network tab in your browser's developer tools. If possible, update the server to accept tokens via Query Parameters.

- **Q: `ws_wait` keeps timing out.**
  - A: The server might not be sending a message, or your **Match Condition** is too strict. Try changing it to `Any Message` to see if anything is arriving, or increase the Timeout value.

- **Q: Variables (`{{...}}`) are not being replaced.**
  - A: Check your template syntax. Ensure you are referencing the correct Step ID from previous nodes (e.g., `steps.api_login.response.body.id`).
