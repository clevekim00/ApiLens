# Workflow Orchestrator Implementation Plan

## Goal
Build an n8n-style API Workflow Orchestrator where users can visually chain API requests and logic nodes.

## Core Principles
- **UI**: Flutter Desktop/Web (Material 3).
- **State**: Riverpod.
- **Network**: Dio (reusing existing core).
- **Storage**: Hive (for Workflows).
- **Engine**: Pure Dart async/await execution with variable injection.

## Architecture

### 1. Data Models (`lib/features/workflow/models`)
- **Workflow**: `id`, `name`, `nodes` (List), `edges` (List).
- **WorkflowNode**:
    - `id`: Window unique ID.
    - `type`: `api`, `start`, `end`, `condition`.
    - `position`: `Offset` (x, y).
    - `data`: JSON Map (stores URL, method, headers, validation logic etc).
- **WorkflowEdge**: `sourceNodeId`, `targetNodeId`, `sourcePort`, `targetPort`.

### 2. Execution Engine (`lib/features/workflow/engine`)
- **WorkflowEngine**:
    - Accepts a `Workflow` and `initialContext`.
    - Topological sort or purely event-driven traversal (Node A completes -> Trigger Node B).
    - **Context Store**: A generic Map `Map<String, dynamic> executionContext`.
    - **Variable Resolver**:
        - Syntax: `{{node.nodeId.data.response.body.token}}`.
        - Logic: Regex parse `{{...}}` -> lookup in `executionContext`.

### 3. Canvas UI (`lib/features/workflow/ui`)
- **WorkflowCanvas**: 
    - `InteractiveViewer` (infinite pan/zoom).
    - `Stack` for Nodes.
    - `CustomPaint` for Edges (Bezier curves).
- **NodeWidget**: Draggable widget representing a step.
- **PropertiesPanel**: Sidebar to edit the currently selected node (e.g., configuring the API Request).

## Implementation Steps

### Phase 1: Models & Storage
- [ ] Add `hive` and `hive_flutter`.
- [ ] Create `Workflow`, `Node`, `Edge` models with Hive adapters.
- [ ] Create `WorkflowRepository`.

### Phase 2: Canvas UI (The "n8n" look)
- [ ] Implement `WorkflowCanvas` with `InteractiveViewer`.
- [ ] Implement Draggable Nodes.
- [ ] Implement Edge drawing (connecting nodes).

### Phase 3: Configuration & Logic
- [ ] Build `NodeConfigurationPanel` (reuse `RequestScreen` widgets for API nodes).
- [ ] Implement Condition logic editor.

### Phase 4: Execution Engine
- [ ] Build the `Runner`.
- [ ] Implement Variable Substitution logic.
- [ ] UI: "Run Workflow" button and execution visualization (highlight active node).

## User Review Required
> [!NOTE]
> We will use **Hive** for storing Workflows as requested, separate from the existing Isar DB used for History/Environments.
