import 'package:uuid/uuid.dart';
import '../../workflow_editor/domain/models/workflow.dart';
import '../../workflow_editor/domain/models/workflow_node.dart';
import '../../workflow_editor/domain/models/workflow_edge.dart';
import '../../workflow_editor/domain/models/node_config.dart';
import '../domain/models/openapi_operation_model.dart';
import 'swagger_parser_service.dart';

class SwaggerWorkflowGenerator {
  final SwaggerParserService _parserService;

  SwaggerWorkflowGenerator({SwaggerParserService? parserService})
      : _parserService = parserService ?? SwaggerParserService();

  Workflow generateWorkflow(
    List<OpenApiOperation> operations,
    String name,
    String? groupId,
    ImportOptions options,
    String baseUrl,
  ) {
    final nodes = <WorkflowNode>[];
    final edges = <WorkflowEdge>[];

    final startNodeId = const Uuid().v4();
    nodes.add(WorkflowNode(
      id: startNodeId,
      type: 'start',
      x: 100,
      y: 200,
    ));

    String previousNodeId = startNodeId;
    String previousOutputPort = 'output';
    
    // Grid layout parameters
    const double startX = 100;
    const double startY = 200;
    const double horizontalSpacing = 300;
    const double verticalSpacing = 200;
    const int nodesPerRow = 4;

    for (int i = 0; i < operations.length; i++) {
      final op = operations[i];
      final requestModel =
          _parserService.convertOperationToRequest(op, options, baseUrl);

      final headersMap = <String, String>{};
      for (final h in requestModel.headers) {
        if (h.isEnabled && h.key.isNotEmpty) {
          headersMap[h.key] = h.value;
        }
      }

      final config = HttpNodeConfig(
        url: requestModel.url.isEmpty ? baseUrl + op.path : requestModel.url,
        method: requestModel.method.isEmpty ? 'GET' : requestModel.method,
        headers: headersMap.isNotEmpty ? headersMap : null,
        body: requestModel.body,
      );

      final nodeId = const Uuid().v4();
      final double x = startX + ((i + 1) % nodesPerRow) * horizontalSpacing;
      final double y = startY + ((i + 1) ~/ nodesPerRow) * verticalSpacing;

      nodes.add(WorkflowNode(
        id: nodeId,
        type: 'api',
        x: x,
        y: y,
        data: config.toJson(),
      ));

      edges.add(WorkflowEdge(
        id: const Uuid().v4(),
        sourceNodeId: previousNodeId,
        sourcePort: previousOutputPort,
        targetNodeId: nodeId,
        targetPort: 'input',
      ));

      previousNodeId = nodeId;
      previousOutputPort = 'success';
    }

    final endNodeId = const Uuid().v4();
    final int totalNodes = operations.length + 1;
    final double endX = startX + (totalNodes % nodesPerRow) * horizontalSpacing;
    final double endY = startY + (totalNodes ~/ nodesPerRow) * verticalSpacing;

    nodes.add(WorkflowNode(
      id: endNodeId,
      type: 'end',
      x: endX,
      y: endY,
    ));

    edges.add(WorkflowEdge(
      id: const Uuid().v4(),
      sourceNodeId: previousNodeId,
      sourcePort: previousOutputPort,
      targetNodeId: endNodeId,
      targetPort: 'input',
    ));

    final now = DateTime.now();
    return Workflow(
      id: const Uuid().v4(),
      name: name.isNotEmpty ? name : 'Imported Workflow',
      groupId: groupId,
      nodes: nodes,
      edges: edges,
      createdAt: now,
      updatedAt: now,
    );
  }
}
