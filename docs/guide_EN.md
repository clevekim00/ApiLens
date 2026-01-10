# ApiLens (👁️) - Usage Guide

**"Focus on the API, not the noise."**

ApiLens is a high-performance REST API testing tool built with Flutter. It offers an intuitive UI, powerful workflow orchestration, and visually rich response analysis features.

---

## 🎨 New Branding: ApiLens
The application has been fully rebranded from 'API Tester' to **ApiLens**.
- **Premium Dark Mode**: Utilizing a Deep Blue and Cyan color palette, providing a focused environment that's easy on the eyes.
- **New Icon**: A modern, professional app icon has been applied to represent our developer-focused tool.

![ApiLens App Icon](../assets/apilens_app_icon.png)

---

## 🚀 Core Features

### 1. Collection Management & Auto-save
- **Auto-Sync**: All collections and request data are saved locally in real-time and automatically loaded on startup. Your work is preserved without the need for manual imports or exports.
- **Inline Editing**: Click on collection names to rename them instantly, or use the ✏️ button to quickly update request names.

### 2. Visual Workflow Editor (Flow Editor)
Go beyond simple list-based execution and design complex API sequences as a graph.

- **Interactive Nodes**: Drag and drop API requests and logic nodes (If/Else, Log) onto the canvas.
- **Result Segments**: Once a node completes execution, 'Header' and 'Body' segments appear at the bottom of the card. Click them to inspect results immediately in a popup.
- **Logic Branching**: Support for If/Else nodes that control execution flow based on response status codes or data fields.

![Visual Workflow Editor](node_results.png)
*Exploring node result segments and detailed popup*

---

## 📊 Professional Response Analysis

ApiLens provides the ultimate tools for deep and intuitive analysis of your response data.

### 1. Interactive JSON Tree View
Responses with `application/json` content-types are automatically rendered as interactive trees. Effortlessly expand or collapse large JSON datasets to find exactly what you need.

### 2. Clean Header Table
Complex HTTP header information is presented in a sorted key-value table format, ensuring maximum readability compared to plain text.

### 3. Status Metric Badges
HTTP status codes, response times (ms), and content sizes (B/KB) are displayed as color-coded badges, allowing you to gauge request health at a glance.

![Professional Response View](response_headers.png)
*Cleanly organized header table and metric info*

---

## 🔗 Batch Execution & Result Tabs
Experience powerful result analysis when running entire collections in List Mode.

- **Tabbed Interface**: Running multiple requests generates individual tabs for each request in the right panel.
- **Independent Result Preservation**: Each tab utilizes the professional JSON tree and header table views, allowing you to switch between and compare multiple request results in real-time.

![Batch Results View](batch_results.png)
*Detailed per-request results separated by tabs after batch execution*

---

## 📟 Integrated Console & Logs
Monitor all workflow events and custom logs in real-time via the integrated console at the bottom.
- **Variable Substitution**: Use patterns like `{{response.body.id}}` to output dynamic data in your logs.

---

## 📦 Build & Launch
ApiLens supports macOS, Windows, and Web environments.

- **macOS Build**: `flutter build macos --release`
- **Web Serving**: `python3 -m http.server 8080 --directory build/web`

---

## ✅ Developer Info
- **GitHub**: [https://github.com/clevekim00/ApiLens](https://github.com/clevekim00/ApiLens)
- **Copyright**: © 2026 clevekim. MIT License.
