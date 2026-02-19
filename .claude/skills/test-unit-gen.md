# test-unit-gen

UseCase/Repository 단위 테스트 자동 생성 (`/test-unit-gen [파일경로]`)

## TDD 정책 (Domain/Data Layer 필수)

### 필수 TDD 대상
| 레이어 | 대상 | TDD 요구 |
|--------|------|----------|
| **Domain** | UseCase, Entity | **필수** |
| **Data** | Repository Impl, DataSource | **필수** |
| **Presentation** | Provider, Widget | 권장 (자유) |

### RED-GREEN-REFACTOR 사이클

```
┌─────────────────────────────────────────────────────────┐
│  1. RED: 실패하는 테스트 먼저 작성                        │
│     - 테스트 실행하여 실패 확인 (필수!)                   │
│     - 실패 메시지가 의미있는지 확인                       │
├─────────────────────────────────────────────────────────┤
│  2. GREEN: 테스트 통과하는 최소 코드 작성                 │
│     - "최소"가 핵심 - 추가 로직 금지                      │
│     - 테스트 통과 확인                                   │
├─────────────────────────────────────────────────────────┤
│  3. REFACTOR: 코드 개선                                  │
│     - 중복 제거                                          │
│     - 가독성 개선                                        │
│     - 테스트 재실행하여 여전히 통과 확인                  │
└─────────────────────────────────────────────────────────┘
```

### TDD 강제 조건
- Domain UseCase 신규 작성 시 → 반드시 테스트 먼저
- Repository 메서드 추가 시 → Mock 테스트 선행
- **테스트 실패 미확인 시 경고**: "RED 단계 미완료 - 테스트 실패를 먼저 확인하세요"

### TDD 예외 허용 (Presentation Layer)
```
다음 경우 TDD 선택적:
- Widget 레이아웃 변경
- Provider 단순 상태 변경
- UI 스타일 조정
- 애니메이션 구현
```

---

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

## TDD 워크플로우 예시

### UseCase 신규 작성 (TDD 필수)
```
1. 테스트 파일 먼저 생성
   > /test-unit-gen lib/domain/usecases/export_diary_usecase.dart

2. 테스트 실행 → 컴파일 에러 (RED)
   > flutter test test/domain/usecases/export_diary_usecase_test.dart
   Error: Target of URI doesn't exist: 'export_diary_usecase.dart'

3. UseCase 스켈레톤 작성 (GREEN 준비)
   - 빈 클래스만 생성

4. 테스트 실행 → 로직 실패 (RED)
   Expected: <ExportResult>
   Actual: <null>

5. 로직 구현 (GREEN)
   - 테스트 통과하는 최소 코드

6. 리팩토링 (REFACTOR)
   - 중복 제거, 가독성 개선
   - 테스트 재실행
```

### Repository 메서드 추가 (TDD 필수)
```
1. Mock에 메서드 스텁 추가
2. 테스트 케이스 작성
3. 테스트 실행 → 실패 확인 (RED)
4. Repository Impl 구현 (GREEN)
5. 테스트 통과 확인
6. 리팩토링 (REFACTOR)
```

## 주의사항
- **Domain/Data 레이어**: TDD 필수 - 테스트 없이 코드 작성 시 경고
- **Presentation 레이어**: TDD 권장 - 복잡한 비즈니스 로직 있을 경우 적용
- 테스트 실패(RED)를 확인하지 않고 GREEN으로 넘어가면 경고 표시
- 기존 테스트 수정 시 기존 테스트가 통과하는지 먼저 확인

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | testing |
| Dependencies | - |
| Created | 2026-01-20 |
| Updated | 2026-02-05 |
