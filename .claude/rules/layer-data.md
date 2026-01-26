---
paths: ["lib/data/**"]
---
# Data Layer Rules

## Repository Implementation
```dart
class MyRepositoryImpl with RepositoryFailureHandler implements MyRepository {
  Future<Data> getData() => guardFailure('operation description', () async {
    return await dataSource.fetchData();
  });
}
```
- Use `RepositoryFailureHandler` mixin for consistent error mapping
- `guardFailure` catches exceptions and maps to Failure types

## DataSource Pattern
- Throws `Exception` (never `Failure`)
- Local: `SqliteLocalDatasource` for DB operations
- Remote: `GroqRemoteDatasource` for API calls

## Groq API Settings
- URL: `https://api.groq.com/openai/v1/chat/completions`
- Model: `llama-3.3-70b-versatile`
- Temperature: 0.7, Max Tokens: 1024
- Retry: 3 attempts, initial delay 1s, backoff 2.0x
- Circuit Breaker: threshold 5, reset 30s, success threshold 2

## DTO/Parser Rules
- `AnalysisResponseDto` maps JSON fields to typed Dart
- `AnalysisResponseParser` handles malformed/partial JSON gracefully
- Always validate `is_emergency` field presence
