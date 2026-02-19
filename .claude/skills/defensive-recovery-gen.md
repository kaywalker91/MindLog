# defensive-recovery-gen

DB 복원/데이터 소스 변경 시 방어적 코드 패턴 자동 생성

## 목표
- DB 복원 감지 후 필요한 방어적 코드 패턴 생성
- 타이밍 경합 조건(Race Condition) 대비 안전장치 추가
- Provider 무효화 + 데이터 소스 재연결 코드 템플릿 제공

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/defensive-recovery-gen [trigger]` 명령어
- "DB 복원 방어 코드 생성해줘" 요청
- 데이터 소스 복원/전환 로직 구현 시

## 배경 지식

### 왜 방어적 코딩이 필요한가?

1. **타이밍 경합 조건**: Provider 무효화와 UI 빌드 사이의 시간차
2. **IndexedStack 즉시 빌드**: 모든 자식 위젯이 앱 시작 시 즉시 빌드됨
3. **DB 연결 캐싱**: SQLite 연결이 이전 상태를 유지할 수 있음

### 문제 시나리오
```
App Start
 ├─ _initializeApp() [비동기]
 │    ├─ DB 복원 감지
 │    └─ Provider 무효화  ← 여기서 무효화해도...
 │
 └─ MindLogApp [즉시 실행]
      └─ IndexedStack
           └─ StatisticsScreen
                └─ ref.watch(statisticsProvider)  ← 이미 빌드 완료
```

## 참조 파일
```
lib/main.dart                              # 복원 감지 및 처리 위치
lib/core/services/db_recovery_service.dart # 복원 감지 서비스
lib/data/datasources/local/sqlite_local_datasource.dart  # DB 연결 관리
```

## 프로세스

### Step 1: 트리거 이벤트 확인
지원하는 트리거 이벤트:
- `db-recovery`: OS에 의한 DB 복원 감지
- `logout`: 사용자 로그아웃
- `account-switch`: 계정 전환
- `cache-clear`: 캐시 수동 삭제
- `app-update`: 앱 업데이트 후 데이터 마이그레이션

### Step 2: 방어적 코드 패턴 생성

#### 패턴 A: Provider 무효화 + forceReconnect
```dart
if (wasRecovered) {
  // 1. Core layer Provider 무효화 (DataSource, Repository, UseCase)
  invalidateDataProviders(appContainer);

  // 2. Presentation layer Provider 무효화 (UI 상태)
  appContainer.invalidate(statisticsProvider);
  appContainer.invalidate(topKeywordsProvider);
  appContainer.invalidate(diaryListControllerProvider);

  // 3. DB 연결 최종 확인 (타이밍 경합 조건 안전장치)
  await SqliteLocalDataSource.forceReconnect();

  if (kDebugMode) {
    debugPrint('[Main] DB recovery detected, all data providers invalidated');
  }
}
```

#### 패턴 B: 지연 초기화 (Lazy Initialization)
```dart
// DB 복원 완료 신호 Provider
final dbRecoveryCompleteProvider = StateProvider<bool>((ref) => false);

// 통계 Provider가 복원 완료를 기다림
final statisticsProvider = FutureProvider.autoDispose<EmotionStatistics>((ref) async {
  // 복원 완료 대기
  final isReady = ref.watch(dbRecoveryCompleteProvider);
  if (!isReady) {
    throw StateError('DB recovery not complete');
  }

  final useCase = ref.watch(getStatisticsUseCaseProvider);
  return useCase.execute(ref.watch(selectedStatisticsPeriodProvider));
});
```

#### 패턴 C: 재시도 래퍼 (Retry Wrapper)
```dart
Future<T> withRetryOnRecovery<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration delay = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < maxRetries; i++) {
    try {
      return await operation();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(delay);
      await SqliteLocalDataSource.forceReconnect();
    }
  }
  throw StateError('Max retries exceeded');
}
```

### Step 3: forceReconnect 구현 확인
```dart
// SqliteLocalDataSource에 forceReconnect 메서드 필요
class SqliteLocalDataSource {
  static Database? _database;

  static Future<void> forceReconnect() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    // 다음 접근 시 자동 재연결
  }
}
```

### Step 4: 검증

검증 체크리스트:
- [ ] 모든 데이터 Provider 무효화 포함
- [ ] forceReconnect() 호출 위치 적절
- [ ] 디버그 로그 추가
- [ ] 에러 핸들링 포함

## 출력 형식

```
═══════════════════════════════════════════════════════════
           🛡️ 방어적 복원 코드 생성 완료
═══════════════════════════════════════════════════════════

트리거: {trigger-event}
권장 패턴: {A / B / C}

생성 코드:
```dart
// 복사해서 {위치}에 추가
{generated_code}
```

필요한 import:
```dart
import 'package:flutter/foundation.dart';
import 'package:mindlog/data/datasources/local/sqlite_local_datasource.dart';
```

검증 체크리스트:
├── [ ] invalidateDataProviders() 호출
├── [ ] Presentation Provider 무효화
├── [ ] forceReconnect() 호출
└── [ ] 디버그 로그 추가

다음 단계:
└── 실제 디바이스에서 복원 시나리오 테스트
```

## 사용 예시

```
> "/defensive-recovery-gen db-recovery"

AI 응답:
1. 트리거: DB 복원 감지
2. 패턴 A (Provider 무효화 + forceReconnect) 권장
3. 코드 생성
4. 적용 위치: lib/main.dart _initializeApp()
5. 검증 체크리스트 출력

> "/defensive-recovery-gen logout --pattern B"

AI 응답:
1. 트리거: 사용자 로그아웃
2. 패턴 B (지연 초기화) 적용
3. 코드 생성
4. 적용 위치: 로그아웃 핸들러
5. 검증 체크리스트 출력
```

## 연관 스킬
- `/provider-invalidate-chain` - Provider 무효화 체인 분석
- `/provider-ref-fix` - Provider ref.read() 검사
- `/db-state-recovery` - DB 복원 시나리오 테스트

## 주의사항
- forceReconnect()는 비용이 있음 → 필요한 경우에만 호출
- IndexedStack 사용 시 모든 자식이 즉시 빌드됨 고려
- 패턴 B (지연 초기화)는 UX에 영향 → Loading 상태 필요
- 실제 디바이스 테스트 필수 (에뮬레이터와 동작 다를 수 있음)

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | quality |
| Dependencies | provider-invalidate-chain, db-state-recovery |
| Created | 2026-02-02 |
| Updated | 2026-02-02 |
