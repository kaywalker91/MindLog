# TIL: Provider Invalidation Chain — Troubleshoot, Performance & Testing

**Date**: 2026-02-02
**Session**: statistics-restoration-bugfix
**Split from**: til-provider-invalidation-chain-pattern.md (Part 3/3)

---

## 문제 해결 가이드

### 문제 1: invalidate했는데 업데이트 안됨

```
의심 순서:
1. ref.watch() 사용 중인가?
   → ref.read()로 변경되어 있나?

2. 구독 중인 Provider가 있나?
   → autoDispose면 명시적 invalidate?

3. 의존성 체인이 끊어졌나?
   → Repository에서 DataSource를 watch?

4. 타이밍 이슈?
   → Provider warm-up 필요?
```

### 문제 2: 일부 화면만 업데이트됨

```
진단:
- Home화면: 업데이트 ✓
- Statistics: 업데이트 ✗

원인: statisticsProvider가 ref.read() 사용
해결: ref.watch()로 변경
```

### 문제 3: 앱 시작 시 데이터 안 보임

```
진단: DB 복원 직후 통계 화면 비어있음

체크:
1. invalidate 호출됨? ✓
2. warm-up 필요? (autoDispose)
3. timeout 발생? (async 작업 중단)

해결:
container.invalidate(sqliteLocalDataSourceProvider);
container.invalidate(statisticsProvider);  // 명시적
await container.read(statisticsProvider.future).timeout(5s);
```

---

## 성능 최적화

### 1. 불필요한 invalidate 피하기

```dart
// ❌ DON'T: 모든 Provider invalidate
void invalidateAll(ProviderContainer container) {
  container.invalidate(authProvider);
  container.invalidate(settingsProvider);
  container.invalidate(themeProvider);
  container.invalidate(notificationProvider);
  container.invalidate(statisticsProvider);  // 관계없는데 invalidate
  // ... 50개 이상
}

// ✅ DO: 영향받는 것만
void invalidateOnDbRecovery(ProviderContainer container) {
  container.invalidate(sqliteLocalDataSourceProvider);
  // 관련된 것들 자동 전파
  // - statisticsProvider
  // - diaryListProvider
  // 관계없는 것들은 유지
  // - authProvider
  // - themeProvider
}
```

### 2. 배치 invalidation

```dart
// ❌ 순차 호출 (느림)
container.invalidate(provider1);
container.invalidate(provider2);
container.invalidate(provider3);

// ✅ 함수로 관리
void invalidateDataLayer(ProviderContainer container) {
  // 한 번에
  container.invalidate(sqliteLocalDataSourceProvider);
}
```

### 3. Selective watch

```dart
// ❌ 모든 Repository watch (불필요)
final myProvider = FutureProvider.autoDispose((ref) async {
  await ref.watch(diaryRepositoryProvider).getDiaries();
  await ref.watch(statisticsRepositoryProvider).getStats();
  await ref.watch(settingsRepositoryProvider).getSettings();
  // 3개 모두 watch = 3개 중 하나 변경되면 전체 재계산
});

// ✅ 필요한 것만 watch
final myProvider = FutureProvider.autoDispose((ref) async {
  return await ref.watch(diaryRepositoryProvider).getDiaries();
  // settings 변경되어도 영향 없음
});
```

---

## 테스트 전략

### 단위 테스트 예제

```dart
group('Provider Invalidation Chain', () {
  test('DataSource invalidation should propagate to UseCase', () async {
    final container = ProviderContainer();

    // Arrange: 초기 로드
    final useCase1 = container.read(getDiaryUseCaseProvider);

    // Act: DataSource invalidate
    container.invalidate(sqliteLocalDataSourceProvider);

    // Assert: UseCase가 재생성됨 (watch 덕분)
    final useCase2 = container.read(getDiaryUseCaseProvider);
    expect(identical(useCase1, useCase2), false);  // 다른 instance
  });

  test('autoDispose Provider should be invalidated explicitly', () async {
    final container = ProviderContainer();

    // Arrange
    await container.read(diaryListProvider.future);

    // Act: DataSource invalidate (자동 전파 안됨)
    container.invalidate(sqliteLocalDataSourceProvider);

    // Assert: 명시적 invalidate 필요
    expect(container.exists(diaryListProvider), true);  // 여전히 캐시됨

    // Fix: 명시적 invalidate
    container.invalidate(diaryListProvider);
    expect(container.exists(diaryListProvider), false);  // 제거됨
  });
});
```

---

## 결론

### 무효화 체인의 3가지 원칙

1. **Bottom-up watch**: 모든 의존성을 watch로 연결
2. **Explicit invalidate at root**: DataSource invalidate로 시작
3. **Handle autoDispose**: 화면에 표시되는 Provider는 명시적 invalidate

### 체크리스트 (모든 새 Provider)

- [ ] 이 Provider는 다른 Provider를 의존하나?
  - [ ] Yes → `ref.watch()` 사용 (read 금지)
  - [ ] No → OK

- [ ] 이 Provider는 autoDispose?
  - [ ] Yes → invalidate 호출 시 명시적으로 invalidate
  - [ ] No → OK (자동 전파)

- [ ] 데이터 소스 변경 지점?
  - [ ] Yes → 모든 관련 Provider invalidate
  - [ ] No → OK

### 다음 개선

- [ ] Provider 의존성 문서 자동화
- [ ] invalidation chain 검증 도구 개발
- [ ] 성능 모니터링 (invalidation 횟수)
