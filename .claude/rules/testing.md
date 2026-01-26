---
paths: ["test/**"]
---
# Testing Rules

## File Naming
- `{source_file}_test.dart` under `test/` mirroring `lib/` structure
- Test descriptions in Korean (verb form)

## Pattern: AAA (Arrange-Act-Assert)
```dart
test('정상 입력 시 올바른 결과를 반환해야 한다', () async {
  // Arrange
  final input = validInput;
  // Act
  final result = await useCase.execute(input);
  // Assert
  expect(result, isNotNull);
});
```

## Test Framework
- `flutter_test` only — NO mockito, NO build_runner mocks
- Manual mock classes using `implements`

## Mock Pattern
```dart
class MockXxxRepository implements XxxRepository {
  bool shouldThrowError = false;
  String? errorMessage;

  @override
  Future<Result> someMethod(Params params) async {
    if (shouldThrowError) throw Exception(errorMessage ?? 'Mock error');
    return MockResult();
  }
}
```

## Test Group Structure
```dart
group('XxxUseCase', () {
  group('input validation', () { ... });
  group('normal cases', () { ... });
  group('error handling', () { ... });
});
```

## Coverage Targets
- Unit tests: >= 80%
- Widget tests: major screens
- Run: `flutter test --coverage`
