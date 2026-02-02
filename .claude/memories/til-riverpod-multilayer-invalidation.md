# TIL: Riverpod 다층 Provider 무효화

**Date**: 2026-02-02
**Session**: db-recovery-statistics-fix
**Commit**: (pending) feat → DB 복원 시 presentation layer Provider 무효화 추가

---

## 버그/문제 분석

### 문제 현상
- **예상**: 앱 재설치 후 복원된 DB 데이터가 통계 화면에 표시
- **실제**: 일기 목록은 보이지만 통계 화면은 빈 상태로 표시

### 근본 원인
`invalidateDataProviders()`가 core layer Provider만 무효화하고, presentation layer Provider는 캐시를 유지함

```dart
// 문제가 된 코드 (infra_providers.dart)
void invalidateDataProviders(ProviderContainer container) {
  container.invalidate(sqliteLocalDataSourceProvider);
  container.invalidate(diaryRepositoryProvider);
  container.invalidate(statisticsRepositoryProvider);
  container.invalidate(getStatisticsUseCaseProvider);
  // ❌ statisticsProvider 누락
  // ❌ topKeywordsProvider 누락
}
```

**왜 발생했는가?**

1. `statisticsProvider`는 `FutureProvider.autoDispose` → 화면 진입 전까지 생성 안됨
2. UseCase Provider들이 `ref.read()`로 의존성 참조 → Riverpod 자동 의존성 추적 불가
3. 아키텍처 제약: `infra_providers.dart`(core)에서 `statistics_providers.dart`(presentation) import 불가

---

## 해결책

main.dart (Composition Root)에서 presentation layer Provider 명시적 무효화 추가:

```dart
// lib/main.dart
if (wasRecovered) {
  // 1. Core layer Provider 무효화 (DataSource, Repository, UseCase)
  invalidateDataProviders(appContainer);

  // 2. Presentation layer Provider 무효화 (복원된 DB 데이터 재로드)
  appContainer.invalidate(statisticsProvider);
  appContainer.invalidate(topKeywordsProvider);
  appContainer.invalidate(diaryListControllerProvider);

  if (kDebugMode) {
    debugPrint('[Main] DB recovery detected, all data providers invalidated');
  }
}
```

### 왜 이 방식이 나은가?

| 항목 | 대안 1: infra에 직접 추가 | 대안 2: Event Bus | **선택: Composition Root** |
|------|-------------------------|------------------|---------------------------|
| 아키텍처 | ❌ core → presentation 위반 | ✓ 준수 | ✓ 준수 |
| 변경량 | 1 파일 | 3+ 파일 | **1 파일 (6줄)** |
| 복잡도 | 낮음 | 높음 | **낮음** |
| 명시성 | 암묵적 | 이벤트 기반 | **명시적** |

---

## Best Practices

### ✅ DO
- Composition Root(main.dart)에서 모든 layer Provider 접근 가능
- `invalidate()`는 idempotent → 중복 호출 무해
- DB 상태 변경 시 연관된 모든 Provider 명시적 무효화

### ❌ DON'T
- core layer에서 presentation layer import 금지
- `ref.read()`로만 참조하면 자동 의존성 추적 안됨에 주의
- autoDispose Provider는 upstream 무효화만으로 부족할 수 있음

---

## 유사 버그 패턴 및 방지법

### 패턴: "캐시 불일치"
```
데이터 소스 변경 (DB 복원, 로그아웃, 계정 전환)
  ↓
Core layer Provider 무효화
  ↓
Presentation layer Provider 캐시 유지 ← 문제 발생
  ↓
UI에 stale 데이터 표시
```

### 방지법
1. 데이터 소스 변경 이벤트 발생 지점에서 **모든 관련 Provider** 무효화
2. Provider 의존성 맵 문서화 (어떤 Provider가 어떤 데이터에 의존하는지)
3. `ref.watch()` 사용 권장 → 자동 의존성 추적

---

## 테스트 전략

### 수동 테스트 (필수)
1. 에뮬레이터에서 일기 3개 이상 작성 (분석 완료 상태)
2. 앱 삭제 후 재설치
3. 일기 목록 화면 → 복원된 일기 표시 확인
4. **통계 화면 → 데이터 표시 확인** ← 핵심 검증 포인트

### 단위 테스트 (권장)
```dart
test('DB recovery should invalidate presentation providers', () async {
  final container = ProviderContainer();

  // Arrange: 초기 데이터 로드
  await container.read(statisticsProvider.future);

  // Act: DB 복원 시뮬레이션
  simulateDbRecovery(container);

  // Assert: Provider 재생성 확인
  expect(container.exists(statisticsProvider), false);
});
```

---

## 결론

### 핵심 교훈
1. **`ref.read()` vs `ref.watch()`**: read는 의존성 추적이 안되므로, upstream 무효화만으로 downstream이 자동 갱신되지 않음
2. **Composition Root 패턴**: main.dart는 모든 layer에 접근 가능하므로, cross-layer 무효화의 적합한 위치
3. **명시적 무효화**: autoDispose Provider도 명시적으로 invalidate하면 다음 구독 시 재생성됨

### 관련 Provider 체인
```
[Core Layer]
sqliteLocalDataSourceProvider
  ↓
diaryRepositoryProvider / statisticsRepositoryProvider
  ↓
getStatisticsUseCaseProvider

[Presentation Layer - 명시적 무효화 필요]
statisticsProvider ← getStatisticsUseCaseProvider 참조 (ref.read)
topKeywordsProvider ← getStatisticsUseCaseProvider 참조 (ref.read)
diaryListControllerProvider ← diaryRepositoryProvider 참조 (ref.read)
```

### 다음 세션 체크리스트
- [ ] 수동 테스트 완료 (앱 삭제 → 재설치 → 통계 확인)
- [ ] DB 복원 감지 단위 테스트 추가
- [ ] Provider 무효화 체인 자동화 스킬 검토
