# test-unit-gen

UseCase/Repository에 대한 단위 테스트를 프로젝트 패턴에 맞게 자동 생성하는 스킬

## 목표
- 테스트 커버리지 향상
- 일관된 테스트 패턴 유지
- 개발자 생산성 증대

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "테스트 작성해줘", "unit test 생성" 요청
- 새 UseCase/Repository 생성 후
- 테스트 커버리지 분석 시 미커버 파일 감지
- `/test-unit-gen [파일경로]` 명령어

## 참조 템플릿

### UseCase 테스트 패턴
참조: `test/domain/usecases/analyze_diary_usecase_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/core/errors/failures.dart';
import 'package:mindlog/domain/entities/[entity].dart';
import 'package:mindlog/domain/repositories/[repository].dart';
import 'package:mindlog/domain/usecases/[usecase].dart';

/// Mock Repository for testing
class MockXxxRepository implements XxxRepository {
  // Mock 상태 변수
  bool shouldThrowError = false;
  String? errorMessage;

  @override
  Future<Result> someMethod(Params params) async {
    if (shouldThrowError) {
      throw Exception(errorMessage ?? 'Mock error');
    }
    return MockResult();
  }

  // ... 모든 인터페이스 메서드 구현
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
        expect(
          () => useCase.execute(''),
          throwsA(isA<ValidationFailure>()),
        );
      });

      test('null 값 처리 테스트', () async {
        // null safety 검증
      });
    });

    group('정상 케이스', () {
      test('정상 입력 시 올바른 결과를 반환해야 한다', () async {
        final result = await useCase.execute(validInput);
        expect(result, isNotNull);
        expect(result.someProperty, expectedValue);
      });

      test('경계값 테스트', () async {
        // 최소/최대 길이 등
      });
    });

    group('에러 처리', () {
      test('Repository 에러 시 Failure를 전파해야 한다', () async {
        mockRepository.shouldThrowError = true;
        mockRepository.errorMessage = 'API Error';

        await expectLater(
          useCase.execute(validInput),
          throwsA(isA<Failure>()),
        );
      });
    });
  });
}
```

## 프로세스

### Step 1: 대상 파일 분석
1. UseCase/Repository 클래스 읽기
2. 의존성 식별 (생성자 파라미터)
3. public 메서드 및 파라미터 분석
4. 사용하는 Entity/DTO 확인

### Step 2: Mock 클래스 생성
1. Repository interface를 `implements`로 구현
2. 상태 제어 변수 추가 (`shouldThrowError` 등)
3. 모든 인터페이스 메서드 stub 구현
4. 테스트용 반환값 설정 로직

### Step 3: 테스트 그룹 구성
1. **입력 유효성 검사**
   - 빈 값, null, 경계값
   - ValidationFailure 검증
2. **정상 케이스**
   - 성공 시나리오
   - 반환값 검증
3. **에러 처리**
   - Repository 에러 전파
   - Failure 타입 검증

### Step 4: 테스트 작성
1. 한국어 테스트 설명 사용
2. AAA 패턴 (Arrange-Act-Assert)
3. 독립적인 테스트 케이스
4. setUp/tearDown 활용

## 출력 형식

생성 파일: `test/domain/usecases/[usecase_name]_test.dart`

```
test/
└── domain/
    └── usecases/
        └── [usecase_name]_test.dart  ← 생성
```

## 네이밍 규칙
- 테스트 파일: `{원본파일명}_test.dart`
- 테스트 그룹: `{클래스명}`
- 테스트 설명: 한국어, 동사형 (~해야 한다)

## 주의사항
- `flutter_test` 패키지만 사용 (mockito 미사용)
- Mock 클래스는 테스트 파일 내 정의
- 비동기 테스트는 `async/await` 사용
- `expect` + `throwsA` 조합으로 예외 검증

## 사용 예시

```
> "GetStatisticsUseCase에 대한 단위 테스트 작성해줘"

AI 응답:
1. lib/domain/usecases/get_statistics_usecase.dart 분석
2. StatisticsRepository 의존성 확인
3. Mock 클래스 생성
4. 테스트 케이스 작성:
   - 입력 유효성 (날짜 범위 검증)
   - 정상 케이스 (통계 반환)
   - 에러 케이스 (Repository 에러)
5. test/domain/usecases/get_statistics_usecase_test.dart 생성
```
