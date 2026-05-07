# Workflow Timeout/Retry 정책

작성일: 2026-05-07

## 개요

ApiLens Workflow 실행 엔진은 실행형 노드에 공통 `execution` 정책을 적용합니다. 이 정책은 네트워크 지연, 일시적인 서버 오류, WebSocket 응답 지연 같은 상황에서 워크플로가 예측 가능하게 실패하거나 재시도하도록 돕습니다.

적용 대상:

- HTTP/API 노드
- GraphQL Request 노드
- WebSocket Connect 노드
- WebSocket Send 노드
- WebSocket Wait 노드

## 정책 필드

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

- `timeoutMs`: 실행 시도 1회당 제한 시간입니다. `null` 또는 0 이하이면 제한을 적용하지 않습니다.
- `retry.maxAttempts`: 최초 실행 이후 추가 재시도 횟수입니다. 기본값은 `0`이라 기존 워크플로는 자동 재시도하지 않습니다.
- `retry.backoffMs`: 재시도 전 대기 시간입니다.
- `retry.retryOnStatusCodes`: HTTP/GraphQL 응답 상태 코드가 이 목록에 포함되면 재시도합니다.
- `retry.retryOnTimeout`: timeout 발생 시 재시도할지 결정합니다.

## 실행 규칙

- `timeoutMs`는 전체 노드 시간이 아니라 각 attempt에 적용됩니다.
- HTTP와 GraphQL은 예외뿐 아니라 `retryOnStatusCodes`에 포함된 상태 코드도 재시도 대상으로 봅니다.
- WebSocket 계열 노드는 connect/send/wait 중 발생한 예외와 timeout을 재시도할 수 있습니다.
- 모든 재시도가 실패하면 노드 결과는 `failure`가 되고, `failure` 포트가 연결되어 있으면 그 경로로 이동합니다.
- 성공 응답을 받으면 남은 재시도는 실행하지 않고 즉시 `success` 포트로 이동합니다.

## 샘플 정책

일반 API 호출:

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

빠르게 실패시켜 에러 경로를 검증하는 호출:

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

WebSocket 응답 대기:

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

## 테스트 커버리지

`test/execution_engine_test.dart`에 다음 회귀 테스트가 포함되어 있습니다.

- HTTP 500 응답 이후 설정된 상태 코드 기준으로 재시도하고 성공 포트로 이동
- timeout 이후 재시도를 소진하면 실패 결과를 내고 failure 포트로 이동
- 기존 HTTP, Condition, WebSocket, GraphQL 실행 경로 유지
