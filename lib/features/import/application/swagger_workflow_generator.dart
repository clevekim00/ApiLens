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
    double currentX = 400;

    for (final op in operations) {
      final requestModel =
          _parserService.convertOperationToRequest(op, options, baseUrl);

      final headersMap = <String, String>{};
      for (final h in requestModel.headers) {
        if (h.isEnabled && h.key.isNotEmpty) {
          headersMap[h.key] = h.value;
        }
      }

      final config = HttpNodeConfig(
        url: requestModel.url,
        method: requestModel.method,
        headers: headersMap.isNotEmpty ? headersMap : null,
        body: requestModel.body,
      );

      final nodeId = const Uuid().v4();
      nodes.add(WorkflowNode(
        id: nodeId,
        type: 'api',
        x: currentX,
        y: 200,
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
      currentX += 300;
    }

    final endNodeId = const Uuid().v4();
    nodes.add(WorkflowNode(
      id: endNodeId,
      type: 'end',
      x: currentX,
      y: 200,
    ));

    edges.add(WorkflowEdge(
      id: const Uuid().v4(),
      sourceNodeId: previousNodeId,
      sourcePort: previousOutputPort,
      targetNodeId: endNodeId,
      targetPort: 'input',
    ));

    return Workflow(
      id: const Uuid().v4(),
      name: name,
      groupId: groupId,
      nodes: nodes,
      edges: edges,
      lastModified: DateTime.now(),
    );
  }
}
