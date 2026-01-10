# Visual Workflow Editor Implementation Plan

Transition ApiLens from a linear collection runner to a powerful graph-based visual workflow editor, allowing modular API orchestration and precise data mapping.

## User Review Required

> [!IMPORTANT]
> This change introduces a graph-based data structure for collections. Existing linear collections will need a conversion logic to be viewed in the flow editor.

> [!NOTE]
> For the visual canvas, we will implement a custom graph UI using Flutter's `CustomPainter` and `GestureDetector` to ensure smooth performance and a premium feel.

## Proposed Changes

### 1. Data Model Refactor
- **[MODIFY] [api_collection_model.dart](file:///Users/youngwhankim/Project/api_tester/lib/models/api_collection_model.dart)**: 
  - Add `List<WorkflowNode> nodes` and `List<WorkflowEdge> edges`.
  - `WorkflowNode` will contain position (x, y), request reference, and port information.
  - `WorkflowEdge` will define connections between output ports and input ports.

### 2. Visual Flow Editor Component
- **[NEW] `lib/widgets/flow_editor/`**:
  - `workflow_canvas.dart`: The main interactive drawing area.
  - `api_node_widget.dart`: Visual representation of an API request with input/output ports.
  - `connection_painter.dart`: drawing Bezier curves between nodes.

### 3. Data Mapping UI (The "Entity" Feel)
- **[NEW] `lib/dialogs/data_mapping_dialog.dart`**:
  - A modal to define how response body fields (using JSONPath) map to the next request's headers, query params, or body.
  - Visual representation of fields, similar to an ER diagram connection.

### 4. Execution Engine Update
- **[MODIFY] `lib/services/batch_execution_service.dart`**:
  - Update from sequential iteration to a graph traversal execution.
  - Support branching logic (Success/Failure paths).

## Verification Plan

### Automated Tests
- Test graph traversal logic to ensure all reachable nodes are executed.
- Verify JSONPath extraction and variable injection.

### Manual Verification
- Create a login workflow where `token` is passed to a "Get Profile" API.
- Drag and move nodes to verify UI stability.
- Verify "If" logic by simulating a 401 Unauthorized response to trigger a "Failure" path.
