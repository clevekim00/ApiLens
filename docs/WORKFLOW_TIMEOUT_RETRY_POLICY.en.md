# Workflow Timeout/Retry Policy

Date: 2026-05-07

## Overview

ApiLens Workflow applies a shared `execution` policy to executable nodes. The policy keeps workflows predictable when an API is slow, a server returns a temporary error, or a WebSocket response does not arrive in time.

Applies to:

- HTTP/API nodes
- GraphQL Request nodes
- WebSocket Connect nodes
- WebSocket Send nodes
- WebSocket Wait nodes

## Policy Shape

```json
{
  "execution": {
    "timeoutMs": 10000,
    "retry": {
      "maxAttempts": 2,
      "backoffMs": 500,
      "retryOnStatusCodes": [408, 429, 500, 502, 503, 504],
      "retryOnTimeout": true
    }
  }
}
```

- `timeoutMs`: Time limit for one execution attempt. `null` or values below 1 disable the limit.
- `retry.maxAttempts`: Extra attempts after the first run. Default is `0`, so existing workflows do not retry automatically.
- `retry.backoffMs`: Delay before the next attempt.
- `retry.retryOnStatusCodes`: HTTP/GraphQL status codes that should trigger a retry.
- `retry.retryOnTimeout`: Whether timeout failures should be retried.

## Runtime Rules

- `timeoutMs` applies per attempt, not to the entire node lifetime across all retries.
- HTTP and GraphQL retry on exceptions and configured status codes.
- WebSocket nodes retry on exceptions and timeouts.
- If all attempts fail, the node result becomes `failure` and the workflow follows the `failure` port when connected.
- If an attempt succeeds, remaining retries are skipped and the workflow follows the `success` port.

## Example Policies

Standard API call:

```json
{
  "execution": {
    "timeoutMs": 10000,
    "retry": {
      "maxAttempts": 2,
      "backoffMs": 500
    }
  }
}
```

Fast failure for error-path validation:

```json
{
  "execution": {
    "timeoutMs": 3000,
    "retry": {
      "maxAttempts": 1,
      "backoffMs": 300
    }
  }
}
```

WebSocket wait:

```json
{
  "type": "ws_wait",
  "sessionKey": "mainWs",
  "timeoutMs": 5000,
  "match": {
    "type": "containsText",
    "value": "pong"
  },
  "execution": {
    "timeoutMs": 5000,
    "retry": {
      "maxAttempts": 1,
      "backoffMs": 500
    }
  }
}
```

## Test Coverage

`test/execution_engine_test.dart` covers:

- HTTP retry after a configured status code, then success routing
- Timeout with retries exhausted, then failure routing
- Existing HTTP, Condition, WebSocket, and GraphQL execution paths
