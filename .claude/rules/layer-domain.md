---
paths: ["lib/domain/**"]
---
# Domain Layer Rules

## Constraints
- Pure Dart only — no Flutter imports, no external packages
- No dependency on `data/` or `presentation/` layers

## Entity Pattern
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

## UseCase Pattern
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

## Repository Interface
- Abstract class with CRUD methods
- Return types: `Future<Entity>`, `Future<List<Entity>>`, `Future<void>`
- Never throw — UseCase handles errors
