# test-unit-gen

UseCase/Repository 단위 테스트 자동 생성 (`/test-unit-gen [파일경로]`)

## 템플릿 (참조: `test/domain/usecases/analyze_diary_usecase_test.dart`)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';

/// Mock Repository
class MockXxxRepository implements XxxRepository {
  bool shouldThrowError = false;
  String? errorMessage;

  @override
  Future<Result> someMethod(Params params) async {
    if (shouldThrowError) throw Exception(errorMessage ?? 'Mock error');
    return MockResult();
  }
}

void main() {
  late XxxUseCase useCase;
  late MockXxxRepository mockRepository;

  setUp(() {
    mockRepository = MockXxxRepository();
    useCase = XxxUseCase(mockRepository);
  });

  group('XxxUseCase', () {
    group('입력 유효성 검사', () {
      test('빈 값은 ValidationFailure를 던져야 한다', () async {
        expect(() => useCase.execute(''), throwsA(isA<ValidationFailure>()));
      });
    });

    group('정상 케이스', () {
      test('정상 입력 시 올바른 결과를 반환해야 한다', () async {
        final result = await useCase.execute(validInput);
        expect(result, isNotNull);
      });
    });

    group('에러 처리', () {
      test('Repository 에러 시 Failure를 전파해야 한다', () async {
        mockRepository.shouldThrowError = true;
        await expectLater(useCase.execute(validInput), throwsA(isA<Failure>()));
      });
    });
  });
}
```

## 프로세스

1. **대상 분석**: UseCase/Repository 클래스, 의존성, public 메서드 파악
2. **Mock 생성**: `implements`로 Repository 구현, 상태 제어 변수 추가
3. **테스트 그룹**: 입력 유효성 / 정상 케이스 / 에러 처리
4. **작성 규칙**: 한국어 설명, AAA 패턴, `flutter_test`만 사용 (mockito 미사용)

## 출력
- 파일: `test/domain/usecases/[usecase_name]_test.dart`
- 네이밍: `{원본파일명}_test.dart`, 테스트 설명은 한국어 동사형
