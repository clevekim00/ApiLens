# ApiLens (👁️) - AI Prompt Integration Guide

This document explains how to utilize AI prompts within ApiLens to generate API requests, configure workflows, and provides recommendations for AI models and their usage.

---

## 🤖 Recommended AI Models

To maximize natural language processing efficiency in ApiLens, we recommend the following models:

| Model | Key Features | Recommended Usage |
| :--- | :--- | :--- |
| **Claude 3.5 Sonnet** | Sophisticated JSON output & code understanding | Designing complex workflow chains and data mappings |
| **GPT-4o** | Versatile creativity and high accuracy | Immediate API request generation and validation |
| **Gemini 1.5 Pro** | Massive context window support | Analyzing large API specifications (Swagger/OpenAPI) and automation |
| **Ollama (Llama 3)** | Local execution (Data privacy) | Private API testing in security-sensitive enterprise environments |

---

## 🛠 Usage Guide

### 1. Prerequisites
To modify ApiLens configuration via AI, you must enforce the AI to return responses in **JSON** format. Include these rules in your System Prompt.

### 2. Request Generation Prompt
When asking the AI to create an API request for a specific feature, guide it to follow this schema:

**System Prompt Template:**
```text
You are an API Expert. Generate an API request in the following JSON format:
{
  "name": "Quick descriptive name",
  "method": "GET|POST|PUT|DELETE|PATCH",
  "url": "full URL",
  "headers": {"key": "value"},
  "body": "stringified body if any",
  "queryParams": {"key": "value"}
}
Only return the raw JSON.
```

**User Prompt Example:**
> "Create a GET request to fetch the post with ID 1 from JSONPlaceholder."

---

### 3. Visual Flow Setup Prompt
When designing complex workflows, you need to specify the relationships between Nodes and Edges.

**System Prompt Template:**
```text
Generate a workflow graph in JSON format:
{
  "nodes": [
    {"id": "node_1", "type": "api", "label": "Login", "requestId": "uuid_if_exists"},
    {"id": "node_2", "type": "if", "label": "Check Status", "config": {"condition": "status == 200"}}
  ],
  "edges": [
    {"id": "edge_1", "fromNodeId": "node_1", "toNodeId": "node_2"}
  ]
}
```

**User Prompt Example:**
> "Call the Login API first, and if it succeeds, set up a flow in the editor to fetch user information."

---

## 🚀 Future Roadmap

1.  **Native AI Prompt Input**: Add a dedicated input field within the app for direct prompt interaction.
2.  **API Context Awareness**: Inject currently loaded collection data into the AI for more accurate automation suggestions.
3.  **Local LLM Connector**: Provide plugins to directly connect local models like Ollama from the settings panel.

---
© 2026 clevekim. ApiLens Project.
