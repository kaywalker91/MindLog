---
paths: ["lib/core/**", "lib/data/**", "lib/domain/**", "lib/presentation/**"]
---
# Layer-Specific Architecture Rules

## Core Layer (`lib/core/**`)

### Failure Hierarchy (sealed class)
```
Failure
├── NetworkFailure
├── ApiFailure
├── CacheFailure
├── ServerFailure
├── DataNotFoundFailure
├── ValidationFailure
├── SafetyBlockedFailure  ← NEVER modify
└── UnknownFailure
```

### FailureMapper (Exception -> Failure)
- `SafetyBlockException` -> `SafetyBlockedFailure`
- `DataNotFoundException` -> `DataNotFoundFailure`
- `CacheException` -> `CacheFailure`
- `NetworkException`/`TimeoutException` -> `NetworkFailure`
- `ApiException`/`FormatException` -> `ApiFailure`
- `CircuitBreakerOpenException` -> `ServerFailure`
- Others -> `UnknownFailure`

### Service Initialization Order
Firebase -> Crashlytics -> Analytics -> NotificationService

### Circuit Breaker Settings
- `failureThreshold`: 5
- `resetTimeout`: 30s
- `successThreshold`: 2

### AI Characters
| Character | Style |
|-----------|-------|
| warmCounselor | Warm counselor (3-sentence empathy) |
| realisticCoach | Realistic coach (measurable actions) |
| cheerfulFriend | Cheerful friend (bright tone) |

### env_config.dart
- `GROQ_API_KEY` from `--dart-define` (production & local dev)

---

## Data Layer (`lib/data/**`)

### Repository Implementation
```dart
class MyRepositoryImpl with RepositoryFailureHandler implements MyRepository {
  Future<Data> getData() => guardFailure('operation description', () async {
    return await dataSource.fetchData();
  });
}
```
- Use `RepositoryFailureHandler` mixin for consistent error mapping
- `guardFailure` catches exceptions and maps to Failure types

### DataSource Pattern
- Throws `Exception` (never `Failure`)
- Local: `SqliteLocalDatasource` for DB operations
- Remote: `GroqRemoteDatasource` for API calls

### Groq API Settings
- URL: `https://api.groq.com/openai/v1/chat/completions`
- Model: `llama-3.3-70b-versatile`
- Temperature: 0.7, Max Tokens: 1024
- Retry: 3 attempts, initial delay 1s, backoff 2.0x
- Circuit Breaker: threshold 5, reset 30s, success threshold 2

### DTO/Parser Rules
- `AnalysisResponseDto` maps JSON fields to typed Dart
- `AnalysisResponseParser` handles malformed/partial JSON gracefully
- Always validate `is_emergency` field presence

---

## Domain Layer (`lib/domain/**`)

### Constraints
- Pure Dart only — no Flutter imports, no external packages
- No dependency on `data/` or `presentation/` layers

### Entity Pattern
```dart
class {Feature} {
  final String id;
  const {Feature}({required this.id});
  {Feature} copyWith({String? id}) => {Feature}(id: id ?? this.id);
  factory {Feature}.fromJson(Map<String, dynamic> json) => ...;
  Map<String, dynamic> toJson() => ...;
}
```
- Immutable (all fields `final`)
- Must have `copyWith`, `fromJson`, `toJson`

### UseCase Pattern
```dart
class {Action}{Feature}UseCase {
  final {Feature}Repository _repository;
  {Action}{Feature}UseCase(this._repository);
  Future<Result> execute(params) async {
    // Validate -> throw ValidationFailure
    // Call repository
    // Catch Exception, rethrow Failure, wrap unknown as UnknownFailure
  }
}
```

### Repository Interface
- Abstract class with CRUD methods
- Return types: `Future<Entity>`, `Future<List<Entity>>`, `Future<void>`
- Never throw — UseCase handles errors

---

## Presentation Layer (`lib/presentation/**`)

### Riverpod Patterns
- Use `StateNotifier` + `StateNotifierProvider` for stateful logic
- `ref.watch()` in build methods, `ref.read()` in callbacks
- Use `.select()` to minimize rebuilds
- Dispose resources in `StateNotifier.dispose()`

### Widget Rules
- Use `const` constructors wherever possible
- Extract widgets >50 lines into separate classes
- Use `RepaintBoundary` for expensive subtrees
- Trailing commas for multiline widget trees

### Navigation
- `go_router` for all routing
- Define routes as constants
- Use `context.go()` / `context.push()` (not Navigator)

### Failure Display
```dart
// Pattern for showing failures to user
state.when(
  data: (data) => ...,
  loading: () => ...,
  error: (failure, _) => FailureWidget(failure: failure),
);
```
- Map `Failure.displayMessage` to user-visible text
- Show retry option for `NetworkFailure` / `ServerFailure`
