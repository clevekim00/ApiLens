import '../domain/models/workflow.dart';
import '../domain/models/workflow_node.dart';
import '../domain/models/workflow_edge.dart';
import '../domain/models/node_config.dart';

// Helper to create basic nodes for samples
WorkflowNode _createStart(String id, double x, double y) {
  return WorkflowNode(
    id: id, type: 'start', x: x, y: y,
    inputPortKeys: [], outputPortKeys: ['out']
  );
}

WorkflowNode _createEnd(String id, String label, double x, double y) {
  return WorkflowNode(
    id: id, type: 'end', x: x, y: y,
    data: {'name': label},
    inputPortKeys: ['in'], outputPortKeys: []
  );
}

class SampleWorkflows {
  static final List<Workflow> samples = [
    _authFlow,
    _failureRoutingFlow,
  ];

  static final Workflow _authFlow = Workflow(
    id: 'sample-auth-001',
    name: 'Sample: Auth & Branching',
    nodes: [
      _createStart('start', 100, 200),
      WorkflowNode(
        id: 'login', type: 'api', x: 300, y: 200,
        data: {
          'name': 'Login API',
          ...HttpNodeConfig(
            method: 'POST',
            url: 'https://jsonplaceholder.typicode.com/posts',
            body: '{"username": "demo", "password": "123"}',
          ).toJson(),
        },
      ),
      WorkflowNode(
        id: 'getUser', type: 'api', x: 550, y: 200,
        data: {
          'name': 'Get User Info',
          ...HttpNodeConfig(
            method: 'GET',
            url: 'https://jsonplaceholder.typicode.com/users/1',
            headers: {'Authorization': 'Bearer {{node.login.response.body.id}}'},
          ).toJson(),
        },
      ),
      WorkflowNode(
        id: 'checkId', type: 'condition', x: 800, y: 200,
        data: {
          'name': 'Check ID > 0',
          ...ConditionNodeConfig(
            expression: '{{node.getUser.response.body.id}} > 0',
          ).toJson(),
        },
      ),
      _createEnd('endSuccess', 'End (Success)', 1050, 150),
      _createEnd('endFail', 'End (Fail)', 1050, 250),
      _createEnd('apiFail', 'End (API Error)', 550, 350),
    ],
    edges: [
      WorkflowEdge(sourceNodeId: 'start', targetNodeId: 'login', sourcePort: 'out', targetPort: 'in'),
      WorkflowEdge(sourceNodeId: 'login', targetNodeId: 'getUser', sourcePort: 'success', targetPort: 'in'),
      WorkflowEdge(sourceNodeId: 'getUser', targetNodeId: 'checkId', sourcePort: 'success', targetPort: 'in'),
      WorkflowEdge(sourceNodeId: 'checkId', targetNodeId: 'endSuccess', sourcePort: 'true', targetPort: 'in'),
      WorkflowEdge(sourceNodeId: 'checkId', targetNodeId: 'endFail', sourcePort: 'false', targetPort: 'in'),
      
      WorkflowEdge(sourceNodeId: 'login', targetNodeId: 'apiFail', sourcePort: 'failure', targetPort: 'in'),
      WorkflowEdge(sourceNodeId: 'getUser', targetNodeId: 'apiFail', sourcePort: 'failure', targetPort: 'in'),
    ],
  );

  static final Workflow _failureRoutingFlow = Workflow(
    id: 'sample-fail-002',
    name: 'Sample: Failure Routing',
    nodes: [
      _createStart('start', 100, 200),
      WorkflowNode(
        id: 'badRequest', type: 'api', x: 300, y: 200,
        data: {
          'name': 'Bad Request (404)',
          ...HttpNodeConfig(
            method: 'GET',
            url: 'https://jsonplaceholder.typicode.com/invalid-endpoint-404',
          ).toJson(),
        },
      ),
      _createEnd('endOk', 'End (OK)', 550, 150),
      _createEnd('endError', 'End (Error)', 550, 250),
    ],
    edges: [
      WorkflowEdge(sourceNodeId: 'start', targetNodeId: 'badRequest', sourcePort: 'out', targetPort: 'in'),
      WorkflowEdge(sourceNodeId: 'badRequest', targetNodeId: 'endOk', sourcePort: 'success', targetPort: 'in'),
      WorkflowEdge(sourceNodeId: 'badRequest', targetNodeId: 'endError', sourcePort: 'failure', targetPort: 'in'),
    ],
  );
}
