# ApiLens 👁️
> **Focus on the API, not the noise.**

ApiLens is a modern, high-performance REST API testing tool built with Flutter. It focuses on developer productivity through a clean, distraction-free interface, powerful automation features, and seamless data persistence.

![ApiLens Banner](assets/logo_full.png)

## 🎥 Usage Guide
A quick guide to explore ApiLens' main features (Collection Management, Flow Editor, Integrated Console, etc.).

- **[Detailed Walkthrough](docs/guide_EN.md)**
- **[Demo Video (WebP)](docs/demo.webp)**

---

## 🚀 Design Direction
- **Minimalism**: Intuitive UI/UX for immediate API testing without complex configurations.
- **Visual Orchestration**: Graph-based visual workflows that go beyond traditional linear request chains.
- **Productivity**: Maximize debugging efficiency with Auto-save, Data Mapping, and Log analysis.
- **Aesthetics**: Premium Dark Mode design based on a Deep Blue & Cyan color palette that's easy on the eyes.

---

## ✨ Key Features

### 1. 🕸️ Visual Workflow Editor
Design complex sequences with a node-based graph editor, going beyond simple API call lists.
- **Graph Traversal**: Queue-based graph engine supporting conditional branching (If/Else) and recursive execution.
- **Logic Nodes**: Conditional execution via If/Else nodes and custom debugging messages using **Log nodes**.
- **Bezier Connections**: Define flows by intuitively connecting input/output ports with Bezier curves.
- **Data Mapping**: Map response data from previous nodes to variables for subsequent steps using JSONPath.

### 2. 📟 Integrated Console & Logs
A dedicated console area to monitor workflow execution in real-time.
- **Real-time Logging**: API execution results and Log node messages are output with timestamps.
- **Variable Substitution**: Full support for variable replacement (e.g., `{{response.body.id}}`) in log messages.
- **Execution History**: View a summary and results of all executed steps at a glance.

### 3. 📊 Professional Response Visualization
Significantly improved for deep and intuitive analysis of response data.
- **Interactive JSON Tree**: `application/json` responses are automatically rendered as trees, allowing efficient navigation of large datasets.
- **Header Table View**: Complex HTTP header information is presented in a clean, key-value table format.
- **Precision Metrics**: Color-coded status badges, response time in milliseconds (ms), and readable content size (KB/B).
- **Rich Error Details**: Instantly view error messages and detailed causes within the 'Body' tab on request failure.

### 4. 🔗 Batch Execution & Result Tabs
Run multiple requests in a collection at once and compare results.
- **Batch Running**: Process entire collections sequentially or in parallel (Workflow mode) from the List View.
- **Tabbed Results View**: Individual response results are provided in separate tabs, allowing seamless switching between request statuses.
- **Copy to Clipboard**: Copy response bodies to the clipboard with a single click for immediate use in other tools.

### 5. 🗄️ Persistence & UX
- **Auto-save & Auto-load**: All collections and request history are saved locally in real-time and restored upon app restart.
- **Split-View Layout**: Efficient layout allowing simultaneous work on request configuration and response results.
- **Inline Renaming**: Instantly edit collection and request names with a single click.

---

## 🏗 Architecture
This project follows a **Service-Oriented** structure with **Provider** pattern-based state management and a dedicated execution system for the graph engine.

- **Presentation Layer**: Premium UI components based on Flutter widgets (`WorkflowCanvas`, `ConsoleViewer`, etc.).
- **Business Logic Layer**: State synchronization via `CollectionProvider` and `RequestProvider`.
- **Core Engine**:
  - `BatchExecutionService`: Graph-based node traversal and execution engine.
  - `HttpService`: High-performance network request handling.
  - `VariableService`: Complex data binding and variable substitution engine.

---

## 🛠 Build & Installation

### Setup
```bash
git clone https://github.com/clevekim00/ApiLens.git
cd ApiLens
flutter pub get
```

### Build for macOS
```bash
flutter build macos --release
```

### Build for Windows
```bash
flutter build windows --release
```

### Build for Web & Serving
```bash
flutter build web --release
python3 -m http.server 8080 --directory build/web
```

---

## 📜 License
This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

Copyright © 2026 clevekim.
