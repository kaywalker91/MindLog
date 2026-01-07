# usecase-gen

Clean Architecture UseCase를 프로젝트 패턴에 맞게 자동 생성하는 스킬

## 목표
- 일관된 UseCase 구조 유지
- 보일러플레이트 코드 자동화
- 비즈니스 로직 표준화

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "유스케이스 생성", "usecase 만들어줘" 요청
- `/usecase [action]_[entity]` 명령어
- 새 비즈니스 로직 추가 시

## 참조 템플릿
참조: `lib/domain/usecases/analyze_diary_usecase.dart`

```dart
import '../../core/errors/failures.dart';
import '../entities/{entity}.dart';
import '../repositories/{entity}_repository.dart';

/// {Action} {Entity} 유스케이스
///
/// {설명}
class {Action}{Entity}UseCase {
  final {Entity}Repository _repository;

  {Action}{Entity}UseCase(this._repository);

  /// {Action} 실행
  ///
  /// [params] 파라미터 설명
  ///
  /// 반환값: 결과 설명
  ///
  /// Throws:
  /// - [ValidationFailure]: 입력 유효성 검사 실패
  /// - [UnknownFailure]: 예상치 못한 오류
  Future<{ReturnType}> execute({Params}) async {
    // 1. 입력 유효성 검사
    _validateInput({params});

    // 2. 비즈니스 로직
    try {
      return await _repository.{method}({args});
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw UnknownFailure(message: e.toString());
    }
  }

  void _validateInput({Params}) {
    // 유효성 검사 로직
    if (/* 조건 */) {
      throw ValidationFailure(message: '유효성 검사 실패 메시지');
    }
  }
}
```

## 프로세스

### Step 1: UseCase 정보 수집
1. 액션 (동사): `get`, `create`, `update`, `delete`, `analyze`
2. 엔티티: `diary`, `statistics`, `settings`
3. 파라미터: 타입, 필수 여부
4. 반환 타입: Entity, List, void

### Step 2: Repository 의존성 확인
```dart
// 필요한 Repository 인터페이스 확인
lib/domain/repositories/{entity}_repository.dart
```

### Step 3: UseCase 파일 생성
파일: `lib/domain/usecases/{action}_{entity}_usecase.dart`

### Step 4: Provider 등록 안내
```dart
// lib/presentation/providers/providers.dart에 추가 필요

/// {Action}{Entity}UseCase Provider
final {action}{Entity}UseCaseProvider = Provider<{Action}{Entity}UseCase>((ref) {
  return {Action}{Entity}UseCase(ref.watch({entity}RepositoryProvider));
});
```

## 출력 형식

```
📦 UseCase 생성 완료

✅ lib/domain/usecases/{action}_{entity}_usecase.dart
   └─ {Action}{Entity}UseCase 클래스
   └─ execute() 메서드
   └─ _validateInput() 메서드

📝 수동 업데이트 필요:
   └─ lib/presentation/providers/providers.dart
      (Provider 등록 코드 추가)

🧪 테스트 생성:
   └─ /test-unit-gen lib/domain/usecases/{action}_{entity}_usecase.dart
```

## 네이밍 규칙

| 항목 | 형식 | 예시 |
|------|------|------|
| 파일명 | snake_case | `get_statistics_usecase.dart` |
| 클래스명 | PascalCase | `GetStatisticsUseCase` |
| 메서드 | execute | `execute(StatisticsPeriod period)` |

## 사용 예시

```
> "/usecase get_diary"

AI 응답:
1. UseCase 정보:
   - 액션: get
   - 엔티티: diary
   - 파라미터: String id
   - 반환: Diary?

2. Repository 확인:
   - DiaryRepository.getDiaryById(String id)

3. 생성 파일:
   - lib/domain/usecases/get_diary_usecase.dart

4. Provider 등록 안내
```

## 기존 UseCase 목록
참조: `lib/domain/usecases/`

| UseCase | Repository | 설명 |
|---------|------------|------|
| AnalyzeDiaryUseCase | DiaryRepository | AI 일기 분석 |
| GetStatisticsUseCase | StatisticsRepository | 통계 조회 |
| GetSelectedAiCharacterUseCase | SettingsRepository | AI 캐릭터 조회 |
| SetSelectedAiCharacterUseCase | SettingsRepository | AI 캐릭터 설정 |
| GetNotificationSettingsUseCase | SettingsRepository | 알림 설정 조회 |
| SetNotificationSettingsUseCase | SettingsRepository | 알림 설정 변경 |

## 연관 스킬
- `/scaffold [feature]` - 전체 기능 스캐폴딩 (Entity, Repository, UseCase 포함)
- `/test-unit-gen [파일]` - UseCase 테스트 생성
- `/mock [repository]` - Mock Repository 생성

## 주의사항
- UseCase는 하나의 비즈니스 로직만 담당 (단일 책임)
- Domain 레이어는 순수 Dart (Flutter 의존성 없음)
- Failure는 core/errors에서 import
- 문서화 주석(///) 필수
