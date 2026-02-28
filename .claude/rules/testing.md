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
- `flutter_test` + `mocktail` for mocking
- No `mockito`, no `build_runner` generated mocks

## Mock Pattern
```dart
// mocktail (standard)
class MockXxxRepository extends Mock implements XxxRepository {}

// In test:
setUp(() {
  mockRepo = MockXxxRepository();
  when(() => mockRepo.someMethod(any())).thenAnswer((_) async => result);
});
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
