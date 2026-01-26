---
paths: ["lib/presentation/**"]
---
# Presentation Layer Rules

## Riverpod Patterns
- Use `StateNotifier` + `StateNotifierProvider` for stateful logic
- `ref.watch()` in build methods, `ref.read()` in callbacks
- Use `.select()` to minimize rebuilds
- Dispose resources in `StateNotifier.dispose()`

## Widget Rules
- Use `const` constructors wherever possible
- Extract widgets >50 lines into separate classes
- Use `RepaintBoundary` for expensive subtrees
- Trailing commas for multiline widget trees

## Navigation
- `go_router` for all routing
- Define routes as constants
- Use `context.go()` / `context.push()` (not Navigator)

## Failure Display
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
