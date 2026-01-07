# mock-gen

Repository 인터페이스 기반 Mock 클래스를 자동 생성하는 스킬

## 목표
- 테스트용 Mock 클래스 자동화
- 일관된 Mock 패턴 유지
- 테스트 코드 작성 시간 단축

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "Mock 생성", "mock 만들어줘" 요청
- `/mock [repository_name]` 명령어
- UseCase 테스트 작성 시

## 참조 템플릿
참조: `test/domain/usecases/analyze_diary_usecase_test.dart`

```dart
/// Mock DiaryRepository for testing
class MockDiaryRepository implements DiaryRepository {
  // ====== Mock 상태 변수 ======
  bool shouldThrowError = false;
  String? errorMessage;
  Exception? customException;

  // ====== Mock 데이터 ======
  final List<Diary> mockDiaries = [];
  AnalysisResult? mockAnalysisResult;

  // ====== 호출 추적 ======
  final List<Diary> savedDiaries = [];
  final List<Diary> updatedDiaries = [];
  int getCallCount = 0;

  // ====== Reset ======
  void reset() {
    shouldThrowError = false;
    errorMessage = null;
    customException = null;
    mockDiaries.clear();
    savedDiaries.clear();
    updatedDiaries.clear();
    getCallCount = 0;
  }

  // ====== Interface 구현 ======
  @override
  Future<Diary?> getDiaryById(String id) async {
    getCallCount++;
    if (shouldThrowError) {
      throw customException ?? Exception(errorMessage ?? 'Mock error');
    }
    return mockDiaries.firstWhereOrNull((d) => d.id == id);
  }

  @override
  Future<List<Diary>> getAllDiaries() async {
    if (shouldThrowError) {
      throw customException ?? Exception(errorMessage ?? 'Mock error');
    }
    return mockDiaries;
  }

  @override
  Future<Diary> saveDiary(Diary diary) async {
    if (shouldThrowError) {
      throw customException ?? Exception(errorMessage ?? 'Mock error');
    }
    savedDiaries.add(diary);
    return diary;
  }

  @override
  Future<Diary> updateDiary(Diary diary) async {
    if (shouldThrowError) {
      throw customException ?? Exception(errorMessage ?? 'Mock error');
    }
    updatedDiaries.add(diary);
    return diary;
  }

  @override
  Future<void> deleteDiary(String id) async {
    if (shouldThrowError) {
      throw customException ?? Exception(errorMessage ?? 'Mock error');
    }
    mockDiaries.removeWhere((d) => d.id == id);
  }

  // ... 기타 메서드
}
```

## 프로세스

### Step 1: Repository 인터페이스 분석
```dart
// lib/domain/repositories/{repository_name}.dart 읽기
abstract class DiaryRepository {
  Future<Diary?> getDiaryById(String id);
  Future<List<Diary>> getAllDiaries();
  Future<Diary> saveDiary(Diary diary);
  // ...
}
```

### Step 2: Mock 클래스 구조 생성

| 섹션 | 용도 |
|------|------|
| 상태 변수 | 에러 시뮬레이션 제어 |
| Mock 데이터 | 반환할 테스트 데이터 |
| 호출 추적 | 메서드 호출 검증용 |
| reset() | 테스트 간 상태 초기화 |
| 인터페이스 구현 | 모든 메서드 stub |

### Step 3: Mock 파일 생성 또는 테스트 파일에 포함

**Option A: 별도 파일**
```
test/mocks/mock_{repository_name}.dart
```

**Option B: 테스트 파일 내 정의 (권장)**
```
test/domain/usecases/{usecase}_test.dart
```

## 출력 형식

```
🧪 Mock 클래스 생성 완료

✅ MockDiaryRepository
   └─ implements DiaryRepository

상태 변수:
├── shouldThrowError: bool
├── errorMessage: String?
└── customException: Exception?

Mock 데이터:
├── mockDiaries: List<Diary>
└── mockAnalysisResult: AnalysisResult?

호출 추적:
├── savedDiaries: List<Diary>
├── updatedDiaries: List<Diary>
└── getCallCount: int

메서드:
├── reset()
├── getDiaryById(String id)
├── getAllDiaries()
├── saveDiary(Diary diary)
├── updateDiary(Diary diary)
└── deleteDiary(String id)
```

## 사용 예시

```
> "/mock DiaryRepository"

AI 응답:
1. DiaryRepository 인터페이스 분석
   - 메서드 8개 발견

2. MockDiaryRepository 생성:
   - 상태 변수 (3개)
   - Mock 데이터 (2개)
   - 호출 추적 (3개)
   - 메서드 구현 (8개)

3. 테스트에서 사용:
   mockRepository.shouldThrowError = true;
   mockRepository.mockDiaries = [testDiary];
```

## Mock 사용 패턴

### 정상 케이스
```dart
test('정상 입력 시 결과를 반환해야 한다', () async {
  mockRepository.mockDiaries = [testDiary];

  final result = await useCase.execute('diary-1');

  expect(result, equals(testDiary));
  expect(mockRepository.getCallCount, equals(1));
});
```

### 에러 케이스
```dart
test('Repository 에러 시 Failure를 던져야 한다', () async {
  mockRepository.shouldThrowError = true;
  mockRepository.errorMessage = 'Network error';

  await expectLater(
    useCase.execute('diary-1'),
    throwsA(isA<UnknownFailure>()),
  );
});
```

### 호출 검증
```dart
test('저장 메서드가 호출되어야 한다', () async {
  await useCase.execute(newDiary);

  expect(mockRepository.savedDiaries.length, equals(1));
  expect(mockRepository.savedDiaries.first.content, equals('test'));
});
```

## 기존 Repository 목록
참조: `lib/domain/repositories/`

| Repository | 메서드 수 | Mock 상태 |
|------------|---------|----------|
| DiaryRepository | 8 | 생성됨 |
| SettingsRepository | 4 | 생성 필요 |
| StatisticsRepository | 3 | 생성 필요 |

## 연관 스킬
- `/test-unit-gen [파일]` - Mock을 사용하는 테스트 생성
- `/usecase [name]` - UseCase 생성 (Mock 필요)

## 주의사항
- mockito 사용 안 함 (flutter_test만 사용)
- Mock 클래스는 테스트 파일 내 정의 권장
- reset() 메서드로 setUp에서 상태 초기화
- 호출 추적은 검증이 필요한 경우에만 추가
