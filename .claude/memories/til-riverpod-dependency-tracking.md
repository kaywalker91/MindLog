# TIL: Riverpod 의존성 추적 패턴

> 날짜: 2026-02-02
> 세션: db-recovery-statistics-fix
> 태그: #riverpod #provider #dependency-tracking #indexedstack

## 핵심 학습

### 1. ref.read() vs ref.watch() 의존성 추적

**문제**: Provider body 내에서 `ref.read()` 사용 시 의존성 추적이 되지 않음

```dart
// ❌ 문제 코드 - 의존성 추적 안 됨
final statisticsRepositoryProvider = Provider((ref) {
  return StatisticsRepositoryImpl(
    localDataSource: ref.read(sqliteLocalDataSourceProvider),
  );
});
```

**결과**: `sqliteLocalDataSourceProvider`가 무효화되어도 `statisticsRepositoryProvider`는 자동 재생성되지 않음

**해결**:
```dart
// ✅ 올바른 코드 - 의존성 추적됨
final statisticsRepositoryProvider = Provider((ref) {
  return StatisticsRepositoryImpl(
    localDataSource: ref.watch(sqliteLocalDataSourceProvider),
  );
});
```

**규칙**:
| 컨텍스트 | 올바른 선택 |
|----------|-------------|
| Provider body 내 의존성 | `ref.watch()` |
| Widget build 메서드 | `ref.watch()` |
| onPressed/onTap 콜백 | `ref.read()` |
| Timer/Stream 콜백 | `ref.read()` |
| container.read() | `ref.read()` (유일한 방법) |

### 2. IndexedStack 즉시 빌드 특성

**문제**: `IndexedStack`은 **모든 자식을 앱 시작 시 즉시 빌드**함 (Lazy 아님)

```dart
// main_screen.dart
body: IndexedStack(
  index: selectedIndex,
  children: const [
    DiaryListScreen(),      // ← 즉시 빌드
    StatisticsScreen(),     // ← 즉시 빌드 (선택 안 해도!)
    SettingsScreen(),       // ← 즉시 빌드
  ],
),
```

**결과**: 앱 초기화 완료 전에 `StatisticsScreen`이 빌드되어 Provider를 watch → Provider 무효화 전에 이미 캐시됨

**비교**:
| 위젯 | 빌드 시점 | Lazy |
|------|----------|------|
| `IndexedStack` | 모든 자식 즉시 | ❌ |
| `TabBarView` | 보이는 것만 | ✅ |
| `PageView` | 보이는 것 + 인접 | ✅ |

### 3. 방어적 코딩: forceReconnect()

타이밍 경합 조건에 대비한 방어적 코드:

```dart
if (wasRecovered) {
  // 1. Provider 무효화
  invalidateDataProviders(appContainer);

  // 2. Presentation Provider 무효화
  appContainer.invalidate(statisticsProvider);

  // 3. DB 연결 강제 리셋 (안전장치)
  await SqliteLocalDataSource.forceReconnect();
}
```

**원리**: Provider 캐시와 DB 연결 캐시가 별개일 수 있으므로, 둘 다 초기화

## 실제 적용

### 수정 파일
- `lib/core/di/infra_providers.dart`: 10개 ref.read() → ref.watch() 변환
- `lib/main.dart`: forceReconnect() 안전장치 추가

### 검증 결과
- 정적 분석: 통과
- 테스트: 883개 모두 통과

## 관련 Skills
- `/provider-ref-fix` - Provider ref.read() 자동 검사/변환
- `/provider-invalidate-chain` - 무효화 체인 분석
- `/defensive-recovery-gen` - 방어적 복원 코드 생성

## 참고 자료
- [Riverpod 공식 문서 - ref.watch vs ref.read](https://riverpod.dev/docs/concepts/reading)
- [Flutter IndexedStack 문서](https://api.flutter.dev/flutter/widgets/IndexedStack-class.html)
