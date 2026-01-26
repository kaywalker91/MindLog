# Clean Architecture 위반 수정 TIL

**작성일**: 2026-01-26
**프로젝트**: MindLog
**난이도**: 중급
**소요시간**: 10분

---

## 1. 문제 상황

### 발견된 위반
```
lib/presentation/providers/update_state_provider.dart:5
import '../../data/datasources/preferences_local_data_source.dart';
```

**위반 유형**: P0 Critical - presentation → data 직접 의존

### 왜 문제인가?

| 문제 | 영향 |
|------|------|
| 의존성 역전(DIP) 위반 | data 레이어 변경 시 presentation 영향 |
| 테스트 어려움 | Mock 주입 불가, 실제 SharedPreferences 필요 |
| 결합도 증가 | DataSource 구현 세부사항 노출 |

---

## 2. 해결 전략

### Step 1: Repository 인터페이스 확장

```dart
// lib/domain/repositories/settings_repository.dart
abstract class SettingsRepository {
  // 기존 메서드 유지...

  // 추가
  Future<String?> getDismissedUpdateVersion();
  Future<void> setDismissedUpdateVersion(String version);
  Future<void> clearDismissedUpdateVersion();
}
```

### Step 2: Repository 구현체에 추가

```dart
// lib/data/repositories/settings_repository_impl.dart
@override
Future<String?> getDismissedUpdateVersion() async {
  return _localDataSource.getDismissedUpdateVersion();
}

@override
Future<void> setDismissedUpdateVersion(String version) async {
  await _localDataSource.setDismissedUpdateVersion(version);
}
```

### Step 3: Provider에서 DI로 변경

```dart
// Before ❌
import '../../data/datasources/preferences_local_data_source.dart';

class UpdateStateNotifier extends StateNotifier<UpdateState> {
  final PreferencesLocalDataSource _prefs;
  // ...
}

// After ✅
import '../../domain/repositories/settings_repository.dart';

class UpdateStateNotifier extends StateNotifier<UpdateState> {
  final SettingsRepository _settingsRepository;
  // ...
}
```

---

## 3. 검증 방법

```bash
# 위반 검사 (결과 없어야 함)
grep -rn "import.*data/datasources" lib/presentation/ --include="*.dart"

# 테스트 통과 확인
flutter test

# 정적 분석
flutter analyze
```

---

## 4. 핵심 교훈

### Do ✅
- **인터페이스 확장**: 새 파일 생성보다 기존 Repository 확장
- **DI 활용**: Provider에서 Repository 주입받아 사용
- **점진적 수정**: 한 파일씩 수정 후 테스트

### Don't ❌
- DataSource 직접 import (Provider에서)
- 새 Repository 생성 (기존 확장으로 충분할 때)
- 여러 파일 동시 수정 (롤백 어려움)

---

## 5. 관련 리소스

| 리소스 | 용도 |
|--------|------|
| `/arch-check` | 위반 자동 탐지 스킬 |
| `/refactor-plan` | 수정 계획 수립 스킬 |
| `.claude/rules/architecture.md` | 레이어 의존성 규칙 |

---

## Metadata

| 속성 | 값 |
|------|-----|
| 카테고리 | Architecture |
| 태그 | Clean Architecture, DIP, Refactoring |
| 관련 파일 | `update_state_provider.dart`, `settings_repository.dart` |
