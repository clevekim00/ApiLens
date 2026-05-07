import '../domain/models/workflow.dart';
import '../domain/models/workflow_node.dart';
import '../domain/models/workflow_edge.dart';
import '../domain/models/node_config.dart';

const _standardHttpPolicy = ExecutionPolicy(
  timeoutMs: 10000,
  retry: RetryPolicy(maxAttempts: 2, backoffMs: 500),
);

const _fastFailHttpPolicy = ExecutionPolicy(
  timeoutMs: 3000,
  retry: RetryPolicy(maxAttempts: 1, backoffMs: 300),
);

const _graphQLPolicy = ExecutionPolicy(
  timeoutMs: 10000,
  retry: RetryPolicy(maxAttempts: 1, backoffMs: 500),
);

const _webSocketPolicy = ExecutionPolicy(
  timeoutMs: 5000,
  retry: RetryPolicy(maxAttempts: 1, backoffMs: 500),
);

// Helper to create basic nodes for samples
WorkflowNode _createStart(String id, double x, double y) {
  return WorkflowNode(
      id: id,
      type: 'start',
      x: x,
      y: y,
      inputPortKeys: [],
      outputPortKeys: ['out']);
}

WorkflowNode _createEnd(String id, String label, double x, double y) {
  return WorkflowNode(
      id: id,
      type: 'end',
      x: x,
      y: y,
      data: {'name': label},
      inputPortKeys: ['in'],
      outputPortKeys: []);
}

class SampleWorkflows {
  static final List<Workflow> samples = [
    _authFlow,
    _crudChainingFlow,
    _webSocketFlow,
    _graphqlFlow,
    _failureRoutingFlow,
  ];

  static final Workflow _authFlow = Workflow(
    id: 'sample-auth-001',
    name: 'Login & Data Fetch',
    nodes: [
      _createStart('start', 100, 200),
      WorkflowNode(
        id: 'login',
        type: 'api',
        x: 300,
        y: 200,
        data: {
          'name': 'Login API',
          ...HttpNodeConfig(
            method: 'POST',
            url: 'https://jsonplaceholder.typicode.com/posts',
            body: '{"username": "demo", "password": "123"}',
            executionPolicy: _standardHttpPolicy,
          ).toJson(),
        },
      ),
      WorkflowNode(
        id: 'getUser',
        type: 'api',
        x: 550,
        y: 200,
        data: {
          'name': 'Get User Profile',
          ...HttpNodeConfig(
            method: 'GET',
            url: 'https://jsonplaceholder.typicode.com/users/1',
            headers: {
              'Authorization': 'Bearer {{node.login.response.body.id}}'
            },
            executionPolicy: _standardHttpPolicy,
          ).toJson(),
        },
      ),
      WorkflowNode(
        id: 'checkId',
        type: 'condition',
        x: 800,
        y: 200,
        data: {
          'name': 'Verify Profile',
          ...ConditionNodeConfig(
            expression: '{{node.getUser.response.body.id}} > 0',
          ).toJson(),
        },
      ),
      _createEnd('endSuccess', 'Success', 1050, 150),
      _createEnd('endFail', 'Invalid Profile', 1050, 250),
    ],
    edges: [
      WorkflowEdge(
          id: 'e1',
          sourceNodeId: 'start',
          targetNodeId: 'login',
          sourcePort: 'out',
          targetPort: 'in'),
      WorkflowEdge(
          id: 'e2',
          sourceNodeId: 'login',
          targetNodeId: 'getUser',
          sourcePort: 'success',
          targetPort: 'in'),
      WorkflowEdge(
          id: 'e3',
          sourceNodeId: 'getUser',
          targetNodeId: 'checkId',
          sourcePort: 'success',
          targetPort: 'in'),
      WorkflowEdge(
          id: 'e4',
          sourceNodeId: 'checkId',
          targetNodeId: 'endSuccess',
          sourcePort: 'true',
          targetPort: 'in'),
      WorkflowEdge(
          id: 'e5',
          sourceNodeId: 'checkId',
          targetNodeId: 'endFail',
          sourcePort: 'false',
          targetPort: 'in'),
    ],
  );

  static final Workflow _crudChainingFlow = Workflow(
    id: 'sample-crud-003',
    name: 'CRUD: List & Delete',
    nodes: [
      _createStart('start', 100, 200),
      WorkflowNode(
        id: 'listPosts',
        type: 'api',
        x: 300,
        y: 200,
        data: {
          'name': 'Fetch All Posts',
          ...HttpNodeConfig(
                  method: 'GET',
                  url: 'https://jsonplaceholder.typicode.com/posts',
                  executionPolicy: _standardHttpPolicy)
              .toJson(),
        },
      ),
      WorkflowNode(
        id: 'deleteFirst',
        type: 'api',
        x: 550,
        y: 200,
        data: {
          'name': 'Delete First Item',
          ...HttpNodeConfig(
                  method: 'DELETE',
                  url:
                      'https://jsonplaceholder.typicode.com/posts/{{node.listPosts.response.body[0].id}}',
                  executionPolicy: _fastFailHttpPolicy)
              .toJson(),
        },
      ),
      _createEnd('done', 'Item Deleted', 800, 200),
    ],
    edges: [
      WorkflowEdge(
          id: 'c1',
          sourceNodeId: 'start',
          targetNodeId: 'listPosts',
          sourcePort: 'out',
          targetPort: 'in'),
      WorkflowEdge(
          id: 'c2',
          sourceNodeId: 'listPosts',
          targetNodeId: 'deleteFirst',
          sourcePort: 'success',
          targetPort: 'in'),
      WorkflowEdge(
          id: 'c3',
          sourceNodeId: 'deleteFirst',
          targetNodeId: 'done',
          sourcePort: 'success',
          targetPort: 'in'),
    ],
  );

  static final Workflow _webSocketFlow = Workflow(
    id: 'sample-ws-004',
    name: 'WS: Real-time Sync',
    nodes: [
      _createStart('start', 100, 200),
      WorkflowNode(
        id: 'wsConnect',
        type: 'ws_connect',
        x: 300,
        y: 200,
        data: {
          'name': 'Connect to Echo',
          ...WebSocketConnectNodeConfig(
                  url: 'wss://echo.websocket.org',
                  storeAs: 'echo_main',
                  executionPolicy: _webSocketPolicy)
              .toJson(),
        },
      ),
      WorkflowNode(
        id: 'wsSend',
        type: 'ws_send',
        x: 550,
        y: 200,
        data: {
          'name': 'Ping Server',
          ...WebSocketSendNodeConfig(
                  sessionKey: 'echo_main',
                  payload: '{"msg": "ping", "ts": {{timestamp}}}',
                  executionPolicy: _webSocketPolicy)
              .toJson(),
        },
      ),
      WorkflowNode(
        id: 'wsWait',
        type: 'ws_wait',
        x: 800,
        y: 200,
        data: {
          'name': 'Wait for Pong',
          ...WebSocketWaitNodeConfig(
                  sessionKey: 'echo_main',
                  match: {'type': 'containsText', 'value': 'ping'},
                  timeoutMs: 5000,
                  executionPolicy: _webSocketPolicy)
              .toJson(),
        },
      ),
      _createEnd('wsEnd', 'Sync Complete', 1050, 200),
    ],
    edges: [
      WorkflowEdge(
          id: 'w1',
          sourceNodeId: 'start',
          targetNodeId: 'wsConnect',
          sourcePort: 'out',
          targetPort: 'in'),
      WorkflowEdge(
          id: 'w2',
          sourceNodeId: 'wsConnect',
          targetNodeId: 'wsSend',
          sourcePort: 'success',
          targetPort: 'in'),
      WorkflowEdge(
          id: 'w3',
          sourceNodeId: 'wsSend',
          targetNodeId: 'wsWait',
          sourcePort: 'success',
          targetPort: 'in'),
      WorkflowEdge(
          id: 'w4',
          sourceNodeId: 'wsWait',
          targetNodeId: 'wsEnd',
          sourcePort: 'success',
          targetPort: 'in'),
    ],
  );

  static final Workflow _graphqlFlow = Workflow(
    id: 'sample-gql-005',
    name: 'GraphQL: Query Flow',
    nodes: [
      _createStart('start', 100, 200),
      WorkflowNode(
        id: 'gqlQuery',
        type: 'gql_request',
        x: 350,
        y: 200,
        data: {
          'name': 'Fetch Countries',
          ...GraphQLNodeConfig(
            endpoint: 'https://countries.trevorblades.com/',
            query: 'query { countries { code name emoji } }',
            variablesJson: '{}',
            storeAs: 'countriesResult',
            executionPolicy: _graphQLPolicy,
          ).toJson(),
        },
      ),
      _createEnd('gqlEnd', 'Data Loaded', 650, 200),
    ],
    edges: [
      WorkflowEdge(
          id: 'g1',
          sourceNodeId: 'start',
          targetNodeId: 'gqlQuery',
          sourcePort: 'out',
          targetPort: 'in'),
      WorkflowEdge(
          id: 'g2',
          sourceNodeId: 'gqlQuery',
          targetNodeId: 'gqlEnd',
          sourcePort: 'success',
          targetPort: 'in'),
    ],
  );

  static final Workflow _failureRoutingFlow = Workflow(
    id: 'sample-fail-002',
    name: 'Error Handling Pattern',
    nodes: [
      _createStart('start', 100, 200),
      WorkflowNode(
        id: 'badRequest',
        type: 'api',
        x: 350,
        y: 200,
        data: {
          'name': 'Unreliable API',
          ...HttpNodeConfig(
            method: 'GET',
            url: 'https://httpstat.us/500',
            executionPolicy: const ExecutionPolicy(
              timeoutMs: 3000,
              retry: RetryPolicy(
                maxAttempts: 2,
                backoffMs: 500,
                retryOnStatusCodes: [500],
              ),
            ),
          ).toJson(),
        },
      ),
      _createEnd('handleSuccess', 'Saved!', 650, 150),
      _createEnd('handleError', 'Error Logged', 650, 250),
    ],
    edges: [
      WorkflowEdge(
          id: 'f1',
          sourceNodeId: 'start',
          targetNodeId: 'badRequest',
          sourcePort: 'out',
          targetPort: 'in'),
      WorkflowEdge(
          id: 'f2',
          sourceNodeId: 'badRequest',
          targetNodeId: 'handleSuccess',
          sourcePort: 'success',
          targetPort: 'in'),
      WorkflowEdge(
          id: 'f3',
          sourceNodeId: 'badRequest',
          targetNodeId: 'handleError',
          sourcePort: 'failure',
          targetPort: 'in'),
    ],
  );
}
