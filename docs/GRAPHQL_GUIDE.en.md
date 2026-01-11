# GraphQL User Guide

## 1. Overview
ApiFlow Studio provides first-class support for **GraphQL**, alongside REST and WebSocket. In modern API environments with complex data requirements, GraphQL allows you to fetch exactly the data you need with a single request.

### REST vs. GraphQL
- **REST**: Often requires calling multiple endpoints (`/users`, `/posts`) to assemble the necessary data. This can lead to over-fetching (receiving more data than needed).
- **GraphQL**: Uses a single endpoint (`/graphql`) to request specific fields. You can retrieve all related data in one go.

With ApiFlow Studio's dedicated **GraphQL Client** and **Workflow Integration**, you can easily test and automate your GraphQL APIs.

---

## 2. Using the GraphQL Client
Navigate to the **Request Builder** screen and select the **`GraphQL` tab**.

### 1) Endpoint Configuration
- Enter the GraphQL API server URL (e.g., `https://rickandmortyapi.com/graphql`).
- Environment variables (e.g., `{{baseUrl}}`) are supported.

### 2) Headers / Auth
- **Headers**: Add headers like `Authorization` manually.
- **Auth**: Configure Bearer Token or Basic Auth to automatically inject headers.

### 3) Writing Queries
- **Query Editor**: Write your GraphQL operations in the top-left editor.
- Supports syntax highlighting for `query`, `mutation`, and `subscription`.

### 4) Defining Variables
- **Variables Editor**: Define variables in JSON format in the bottom-left editor.
- Map values to variables declared as `$variableName` in your query.

### 5) Execution & & Analysis
- Click the **Execute** button (▶) to send the request.
- **Response Viewer**: View the results in the right panel.
    - **JSON Pretty**: Formats the JSON response for readability.
    - **Data/Errors**: Clearly distinguishes between successful `data` and execution `errors`.

---

## 3. Example Queries

### Simple Query
Fetching character information from the Rick and Morty API.
```graphql
query GetCharacter {
  character(id: 1) {
    name
    status
    species
  }
}
```

### Using Variables
Fetching data dynamically using an ID variable.

**Query:**
```graphql
query GetCharacter($id: ID!) {
  character(id: $id) {
    name
    image
  }
}
```

**Variables (JSON):**
```json
{
  "id": "2"
}
```

### Mutation Example
Creating or updating data.
```graphql
mutation CreateUser($name: String!, $job: String!) {
  createUser(name: $name, job: $job) {
    id
    createdAt
  }
}
```

---

## 4. Using GraphQL in Workflows
You can automate GraphQL requests using the `gql_request` node in the **Visual Workflow Editor**.

### Adding & Configuring Nodes
1. Drag the **GraphQL Request** node from the palette to the canvas.
2. Select the node and configure it in the **Inspector Panel** on the right.

### Key Configuration Fields
- **Operation Mode**:
    - `Direct`: Enter the endpoint and query directly in the node.
    - `Config Reference`: Load and execute a saved GraphQL configuration.
- **Endpoint**: API URL (supports templates).
- **Query / Variables**: The operation and variables to execute.
- **Store As (Result Key)**: The key name to store the execution result (`data`) in the Context (e.g., `userData`).

### Example Flow: REST Login → GraphQL Request
1. **REST Request (Login)**: Call Login API → Receive Token.
2. **GraphQL Request (Fetch Profile)**:
    - **Endpoint**: `https://api.example.com/graphql`
    - **Header**: `Authorization: Bearer {{node.login.response.body.token}}`
    - **Query**: Fetch user profile.
3. **Condition**: Check `{{node.profile.response.data.me.isActive}} == true`.

---

## 5. Templating & Data Binding
ApiFlow Studio supports Handlebars syntax (`{{ ... }}`) to inject dynamic data into queries and variables.

### Environment Variables
```graphql
query {
  serverInfo(env: "{{env.environmentName}}") {
    version
  }
}
```

### Node References in Variables
Inject results from previous nodes (e.g., REST login token) into GraphQL variables.

**Variables (JSON):**
```json
{
  "userId": "{{node.loginSuccess.response.body.userId}}",
  "authToken": "{{node.auth.response.headers.x-auth-token}}"
}
```

---

## 6. Troubleshooting

### 400 Bad Request
- Check for syntax errors in your query or missing required variables.
- Review the `errors` field in the Response Viewer for details.

### Authentication Errors (401/403)
- Ensure the token is correctly configured in the Auth tab.
- For workflows, verify in the Debug Panel that the preceding Login node executed successfully.

### Variables JSON Error
- Ensure the content in the Variables Editor is valid JSON (check for missing quotes, commas, etc.).
