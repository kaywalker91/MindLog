# provider-ref-fix

Provider 정의 내 ref.read() → ref.watch() 자동 변환 스킬

## 목표
- Provider body 내부의 잘못된 ref.read() 사용 검출
- 의존성 추적이 필요한 위치만 선별적으로 ref.watch()로 변환
- 이벤트 핸들러/콜백의 올바른 ref.read()는 유지

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/provider-ref-fix [path]` 명령어
- "Provider ref.read 검사해줘" 요청
- Provider 무효화 체인 이슈 발생 시

## 배경 지식

### ref.read() vs ref.watch() 차이

| | ref.read() | ref.watch() |
|---|---|---|
| 의존성 추적 | ❌ 안 함 | ✅ 함 |
| 재구독 | ❌ 1회성 읽기 | ✅ 변경 시 재실행 |
| 사용 위치 | 콜백, 이벤트 핸들러 | Provider body, build 메서드 |

### 문제 상황
```dart
// ❌ 문제 - Provider body에서 ref.read() 사용
final statisticsRepositoryProvider = Provider((ref) {
  return StatisticsRepositoryImpl(
    localDataSource: ref.read(sqliteLocalDataSourceProvider),  // 의존성 추적 안 됨!
  );
});
```

`sqliteLocalDataSourceProvider`가 무효화되어도 `statisticsRepositoryProvider`는 자동 재생성되지 않음.

### 올바른 사용
```dart
// ✅ 올바름 - Provider body에서 ref.watch() 사용
final statisticsRepositoryProvider = Provider((ref) {
  return StatisticsRepositoryImpl(
    localDataSource: ref.watch(sqliteLocalDataSourceProvider),  // 의존성 추적됨
  );
});
```

## 참조 파일
```
lib/core/di/infra_providers.dart       # Core layer providers
lib/presentation/providers/*.dart       # Presentation layer providers
```

## 프로세스

### Step 1: 변환 대상 검출
Provider 정의 내부의 ref.read() 패턴 검색:

```bash
# Provider body 내 ref.read() 검색
grep -rn "Provider.*((ref)" lib/ --include="*.dart" -A 10 | grep "ref\.read"
```

검출 패턴:
- `Provider<T>((ref) { ... ref.read(...) ... })`
- `StateNotifierProvider<T>((ref) { ... ref.read(...) ... })`
- `FutureProvider<T>((ref) async { ... ref.read(...) ... })`

### Step 2: 제외 패턴 필터링
다음 패턴은 변환 **제외**:

```dart
// ❌ 변환 제외 - 이벤트 핸들러
onPressed: () {
  ref.read(someProvider.notifier).doSomething();
}

// ❌ 변환 제외 - main 초기화
final dataSource = container.read(sqliteLocalDataSourceProvider);

// ❌ 변환 제외 - Timer/Stream 콜백
Timer.periodic(duration, (_) {
  ref.read(counterProvider.notifier).increment();
});

// ❌ 변환 제외 - .notifier 접근 (상태 변경용)
ref.read(someProvider.notifier).setState(newState);
```

### Step 3: 변환 수행
검출된 패턴을 ref.watch()로 변환:

```dart
// 변환 전
localDataSource: ref.read(sqliteLocalDataSourceProvider),

// 변환 후
localDataSource: ref.watch(sqliteLocalDataSourceProvider),
```

### Step 4: 검증
```bash
# 정적 분석
flutter analyze

# 테스트 실행
flutter test
```

## 출력 형식

```
═══════════════════════════════════════════════════════════
           🔧 Provider ref.read() → ref.watch() 변환 완료
═══════════════════════════════════════════════════════════

검출된 파일: N개
변환된 위치: M개

변환 목록:
├── lib/core/di/infra_providers.dart
│   ├── Line 57: diaryRepositoryProvider
│   ├── Line 58: diaryRepositoryProvider
│   └── Line 72: statisticsRepositoryProvider
└── lib/presentation/providers/some_provider.dart
    └── Line 23: customProvider

제외된 위치 (올바른 사용): K개
├── lib/presentation/screens/home_screen.dart:45 (onPressed 콜백)
└── lib/main.dart:109 (container.read 초기화)

검증 결과:
├── [✓] flutter analyze: No issues found!
└── [✓] flutter test: All tests passed

다음 단계:
└── git diff로 변경사항 확인 후 커밋
```

## 변환 규칙 요약

| 컨텍스트 | ref.read() | ref.watch() |
|----------|------------|-------------|
| Provider body 내 의존성 주입 | ❌ 변환 | ✅ 사용 |
| Widget build 메서드 | ❌ 변환 | ✅ 사용 |
| onPressed/onTap 콜백 | ✅ 유지 | ❌ 사용금지 |
| Timer/Stream 콜백 | ✅ 유지 | ❌ 사용금지 |
| initState/dispose | ✅ 유지 | ❌ 사용금지 |
| container.read() | ✅ 유지 | N/A |
| .notifier 접근 | ✅ 유지 | 상황에 따라 |

## 사용 예시

```
> "/provider-ref-fix lib/core/di"

AI 응답:
1. lib/core/di/ 디렉토리 스캔
2. Provider body 내 ref.read() 10개 검출
3. 제외 패턴 0개 필터링
4. 10개 위치 ref.watch()로 변환
5. flutter analyze 통과
6. 완료

> "/provider-ref-fix --dry-run"

AI 응답:
1. 전체 프로젝트 스캔
2. 변환 대상 목록만 출력 (실제 변환 안 함)
3. 검토 후 --apply로 실행
```

## 연관 스킬
- `/provider-invalidate-chain` - Provider 무효화 체인 분석
- `/provider-invalidation-audit` - Provider 무효화 누락 정적 분석
- `/arch-check` - Clean Architecture 의존성 검사

## 주의사항
- **절대로 모든 ref.read()를 변환하지 않음** - 컨텍스트 분석 필수
- `.notifier` 접근은 대부분 ref.read()가 올바름 (상태 변경용)
- Provider body 외부의 ref.read()는 변환 대상 아님
- 변환 후 반드시 테스트 실행하여 부작용 확인

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | quality |
| Dependencies | provider-invalidate-chain |
| Created | 2026-02-02 |
| Updated | 2026-02-02 |
