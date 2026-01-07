# feature-scaffold

Clean Architecture 패턴에 맞는 새 기능의 전체 파일 구조를 자동 생성하는 스킬

## 목표
- 일관된 Clean Architecture 구조 유지
- 새 기능 개발 시간 단축
- 보일러플레이트 코드 자동화

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "새 기능 scaffold", "feature 생성" 요청
- `/scaffold [feature_name]` 명령어
- 새로운 도메인 개념 추가 시

## 프로젝트 구조 참조

```
lib/
├── core/                    # 공통 유틸리티
│   ├── constants/
│   ├── errors/              # Failure, Exception 정의
│   ├── config/
│   └── network/
│
├── domain/                  # 비즈니스 로직 (순수 Dart)
│   ├── entities/            # 도메인 엔티티
│   ├── repositories/        # Repository 인터페이스
│   └── usecases/            # UseCase 클래스
│
├── data/                    # 데이터 레이어
│   ├── repositories/        # Repository 구현체
│   ├── datasources/
│   │   ├── local/          # SQLite, SharedPreferences
│   │   └── remote/         # API 클라이언트
│   └── dto/                 # Data Transfer Objects
│
└── presentation/            # UI 레이어
    ├── providers/           # Riverpod Providers
    ├── screens/
    └── widgets/
```

## 생성 프로세스

### Step 1: 기능 정보 수집
1. 기능 이름 (snake_case): `notification`
2. 주요 액션: `send`, `get`, `schedule`
3. 데이터소스 유형: `local` / `remote` / `both`

### Step 2: Entity 생성
파일: `lib/domain/entities/{feature}.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

part '{feature}.g.dart';

/// {Feature} 엔티티
@JsonSerializable()
class {Feature} {
  final String id;
  // ... 필드 정의

  const {Feature}({
    required this.id,
    // ... 생성자 파라미터
  });

  {Feature} copyWith({
    String? id,
    // ... 파라미터
  }) {
    return {Feature}(
      id: id ?? this.id,
      // ... 복사
    );
  }

  factory {Feature}.fromJson(Map<String, dynamic> json) => _${Feature}FromJson(json);
  Map<String, dynamic> toJson() => _${Feature}ToJson(this);
}
```

### Step 3: Repository Interface 생성
파일: `lib/domain/repositories/{feature}_repository.dart`

```dart
import '../entities/{feature}.dart';

/// {Feature} 저장소 인터페이스 (Domain Layer)
abstract class {Feature}Repository {
  /// {Feature} 생성
  Future<{Feature}> create{Feature}(/* params */);

  /// {Feature} 조회
  Future<{Feature}?> get{Feature}ById(String id);

  /// 모든 {Feature} 조회
  Future<List<{Feature}>> getAll{Feature}s();

  /// {Feature} 삭제
  Future<void> delete{Feature}(String id);
}
```

### Step 4: UseCase 생성
파일: `lib/domain/usecases/{action}_{feature}_usecase.dart`

```dart
import '../entities/{feature}.dart';
import '../repositories/{feature}_repository.dart';
import '../../core/errors/failures.dart';

/// {Action} {Feature} 유스케이스
class {Action}{Feature}UseCase {
  final {Feature}Repository _repository;

  {Action}{Feature}UseCase(this._repository);

  /// {Action} 실행
  ///
  /// [params] 파라미터 설명
  ///
  /// 반환값: 결과 설명
  Future<{Feature}> execute(/* params */) async {
    try {
      // 입력 유효성 검사
      // 비즈니스 로직
      // Repository 호출
      return await _repository.someMethod(/* args */);
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw UnknownFailure(message: e.toString());
    }
  }
}
```

### Step 5: Repository Implementation 생성
파일: `lib/data/repositories/{feature}_repository_impl.dart`

```dart
import '../../domain/entities/{feature}.dart';
import '../../domain/repositories/{feature}_repository.dart';
import '../../core/errors/failures.dart';
import '../datasources/local/{feature}_local_datasource.dart';
// import '../datasources/remote/{feature}_remote_datasource.dart';

/// {Feature} Repository 구현체
class {Feature}RepositoryImpl implements {Feature}Repository {
  final {Feature}LocalDataSource _localDataSource;
  // final {Feature}RemoteDataSource _remoteDataSource;

  {Feature}RepositoryImpl({
    required {Feature}LocalDataSource localDataSource,
    // required {Feature}RemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource;
        // _remoteDataSource = remoteDataSource;

  @override
  Future<{Feature}> create{Feature}(/* params */) async {
    try {
      // 구현
      throw UnimplementedError();
    } catch (e) {
      throw CacheFailure(message: '{feature} 생성 실패: $e');
    }
  }

  // ... 기타 메서드 구현
}
```

### Step 6: Provider 등록
파일: `lib/presentation/providers/providers.dart` (업데이트)

```dart
// ============ {Feature} Providers ============

/// {Feature}Repository Provider
final {feature}RepositoryProvider = Provider<{Feature}Repository>((ref) {
  return {Feature}RepositoryImpl(
    localDataSource: ref.watch({feature}LocalDataSourceProvider),
  );
});

/// {Action}{Feature}UseCase Provider
final {action}{Feature}UseCaseProvider = Provider<{Action}{Feature}UseCase>((ref) {
  return {Action}{Feature}UseCase(ref.watch({feature}RepositoryProvider));
});
```

### Step 7: 테스트 템플릿 생성
파일: `test/domain/usecases/{action}_{feature}_usecase_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mindlog/domain/entities/{feature}.dart';
import 'package:mindlog/domain/repositories/{feature}_repository.dart';
import 'package:mindlog/domain/usecases/{action}_{feature}_usecase.dart';

class Mock{Feature}Repository implements {Feature}Repository {
  // Mock 구현
}

void main() {
  late {Action}{Feature}UseCase useCase;
  late Mock{Feature}Repository mockRepository;

  setUp(() {
    mockRepository = Mock{Feature}Repository();
    useCase = {Action}{Feature}UseCase(mockRepository);
  });

  group('{Action}{Feature}UseCase', () {
    // 테스트 케이스
  });
}
```

## 출력 형식

```
📁 생성된 파일 목록:

✅ lib/domain/entities/{feature}.dart
   └─ Entity 클래스 + JSON 직렬화

✅ lib/domain/repositories/{feature}_repository.dart
   └─ Repository 인터페이스 (추상 클래스)

✅ lib/domain/usecases/{action}_{feature}_usecase.dart
   └─ UseCase 클래스 + 유효성 검사

✅ lib/data/repositories/{feature}_repository_impl.dart
   └─ Repository 구현체

✅ test/domain/usecases/{action}_{feature}_usecase_test.dart
   └─ UseCase 테스트 템플릿

📝 수동 업데이트 필요:
   └─ lib/presentation/providers/providers.dart
      (Provider 등록 코드 추가)

🔧 추가 작업:
   └─ flutter pub run build_runner build
      (JSON 직렬화 코드 생성)
```

## 네이밍 규칙

| 항목 | 형식 | 예시 |
|------|------|------|
| 기능 이름 | snake_case | `notification`, `user_profile` |
| Entity 클래스 | PascalCase | `Notification`, `UserProfile` |
| Repository | `{Feature}Repository` | `NotificationRepository` |
| UseCase | `{Action}{Feature}UseCase` | `SendNotificationUseCase` |
| Provider | `{feature}{Type}Provider` | `notificationRepositoryProvider` |
| 테스트 파일 | `{usecase}_test.dart` | `send_notification_usecase_test.dart` |

## 레이어 의존성 규칙

```
presentation/ ─────┐
                   │
                   ▼
domain/ ◄────────────────── 의존성 없음 (순수 Dart)
   │
   ▼
data/ ─────────────┐
                   │
                   ▼
core/ ◄────────────────── 모든 레이어에서 참조 가능
```

**위반 금지:**
- ❌ domain/ → data/
- ❌ domain/ → presentation/
- ❌ data/ → presentation/

## 사용 예시

```
> "/scaffold reminder"

AI 응답:
1. 기능 정보 확인
   - 기능명: reminder
   - 주요 액션: create, get, delete
   - 데이터소스: local (SQLite)

2. 파일 생성:
   - lib/domain/entities/reminder.dart
   - lib/domain/repositories/reminder_repository.dart
   - lib/domain/usecases/create_reminder_usecase.dart
   - lib/data/repositories/reminder_repository_impl.dart
   - test/domain/usecases/create_reminder_usecase_test.dart

3. 다음 단계 안내:
   - providers.dart에 Provider 등록
   - build_runner 실행
   - DataSource 구현 (필요시)
```

## 확장 옵션

### 선택적 생성 파일
- `--with-screen`: Screen 위젯 템플릿 포함
- `--with-dto`: DTO 클래스 포함
- `--with-datasource`: DataSource 클래스 포함
- `--remote`: 원격 API 연동 구조 포함
