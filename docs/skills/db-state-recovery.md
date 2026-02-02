# db-state-recovery

DB 상태 복원 시나리오 테스트 및 검증 자동화 스킬

## 목표
- 앱 재설치/복원 시나리오 자동화 테스트 생성
- DB 복원 감지 로직 단위 테스트 생성
- Provider 무효화 검증 테스트 생성
- 수동 테스트 체크리스트 자동 생성

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/db-state-recovery [action]` 명령어
- "DB 복원 테스트 생성해줘" 요청
- DB 복원 관련 버그 수정 후 테스트 필요 시

## 참조 파일
```
lib/core/services/db_recovery_service.dart  # 복원 감지 로직
lib/main.dart                                # 복원 처리 로직
test/core/services/                          # 테스트 위치
```

## 프로세스

### Step 1: 액션 파라미터 확인
| Action | 설명 |
|--------|------|
| `test-gen` | DB 복원 감지 단위 테스트 생성 |
| `checklist` | 수동 테스트 체크리스트 출력 |
| `verify` | 현재 구현 상태 검증 |

### Step 2: 테스트 생성 (test-gen)
```dart
// test/core/services/db_recovery_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('DbRecoveryService', () {
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
    });

    test('should detect recovery when prefs is null and db exists', () async {
      // Arrange
      when(() => mockPrefs.getString('session_id')).thenReturn(null);
      // DB exists 시뮬레이션

      // Act
      final wasRecovered = await checkAndRecoverIfNeeded();

      // Assert
      expect(wasRecovered, true);
    });

    test('should not detect recovery on normal launch', () async {
      // Arrange
      when(() => mockPrefs.getString('session_id')).thenReturn('abc123');

      // Act
      final wasRecovered = await checkAndRecoverIfNeeded();

      // Assert
      expect(wasRecovered, false);
    });

    test('should invalidate presentation providers on recovery', () async {
      // Arrange
      final container = ProviderContainer();
      await container.read(statisticsProvider.future);

      // Act
      simulateDbRecovery(container);

      // Assert
      // Provider가 무효화되어 exists가 false이거나 재생성됨
      verify(() => container.invalidate(statisticsProvider)).called(1);
    });
  });
}
```

### Step 3: 수동 테스트 체크리스트 (checklist)
```markdown
## DB 복원 수동 테스트 체크리스트

### 사전 조건
- [ ] 에뮬레이터/실기기 준비
- [ ] Android 백업 활성화 확인 (설정 > 백업)

### 테스트 단계
1. [ ] 앱에서 일기 3개 이상 작성 (분석 완료 상태)
2. [ ] 통계 화면에서 데이터 표시 확인 (baseline)
3. [ ] 앱 삭제
4. [ ] 앱 재설치 (동일 APK)
5. [ ] 앱 실행

### 검증 포인트
- [ ] 일기 목록 화면: 복원된 일기 표시 확인
- [ ] **통계 화면: 데이터 표시 확인** (핵심)
- [ ] 기간 필터 변경: 정상 동작 확인

### 디버그 로그 확인
```
[DbRecoveryService] Prefs session: null
[DbRecoveryService] DB session: abc123...
[DbRecoveryService] Prefs cleared, DB restored - recovery triggered
[Main] DB recovery detected, all data providers invalidated
```

### 결과
- [ ] PASS: 모든 검증 포인트 통과
- [ ] FAIL: 실패 항목 기록
```

### Step 4: 구현 검증 (verify)
현재 코드 상태 확인:
1. `DbRecoveryService.checkAndRecoverIfNeeded()` 존재 여부
2. main.dart 복원 처리 로직 존재 여부
3. presentation layer Provider 무효화 포함 여부

## 출력 형식

```
═══════════════════════════════════════════════════════════
           💾 DB 상태 복원 테스트 생성 완료
═══════════════════════════════════════════════════════════

생성된 파일:
├── test/core/services/db_recovery_service_test.dart
└── docs/test-checklists/db-recovery-manual.md

테스트 케이스:
├── [Unit] should detect recovery when prefs is null and db exists
├── [Unit] should not detect recovery on normal launch
└── [Unit] should invalidate presentation providers on recovery

다음 단계:
└── flutter test test/core/services/db_recovery_service_test.dart
```

## 네이밍 규칙

| 항목 | 형식 | 예시 |
|------|------|------|
| 테스트 파일 | `{service}_test.dart` | `db_recovery_service_test.dart` |
| 테스트 그룹 | `{ServiceName}` | `DbRecoveryService` |
| 테스트 케이스 | `should {action} when {condition}` | `should detect recovery when prefs is null` |

## 사용 예시

```
> "/db-state-recovery test-gen"

AI 응답:
1. DbRecoveryService 분석
2. 테스트 케이스 설계
3. 테스트 파일 생성
4. 실행 명령어 출력

> "/db-state-recovery checklist"

AI 응답:
1. 수동 테스트 체크리스트 생성
2. Markdown 형식 출력
3. 클립보드 복사 안내

> "/db-state-recovery verify"

AI 응답:
1. 현재 구현 상태 스캔
2. 누락된 부분 식별
3. 권장 수정 사항 출력
```

## 연관 스킬
- `/provider-invalidate-chain` - Provider 무효화 체인 분석
- `/test-unit-gen` - 단위 테스트 생성
- `/integration-test-gen` - 통합 테스트 생성

## 주의사항
- 수동 테스트는 실제 기기/에뮬레이터 필요 (자동화 한계)
- Android 백업 동작은 기기/OS 버전에 따라 다를 수 있음
- SharedPreferences Mock 시 실제 동작과 차이 있을 수 있음
- 통합 테스트는 별도 스킬 사용 권장

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | testing |
| Dependencies | test-unit-gen |
| Created | 2026-02-02 |
| Updated | 2026-02-02 |
