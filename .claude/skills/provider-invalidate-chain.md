# provider-invalidate-chain

Provider 무효화 체인 분석 및 코드 생성 자동화 스킬

## 목표
- Provider 간 의존성 맵 자동 분석
- 데이터 소스 변경 시 무효화해야 할 Provider 목록 도출
- 무효화 코드 스니펫 자동 생성
- Cross-layer 무효화 누락 방지

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/provider-invalidate-chain [trigger]` 명령어
- `/provider-invalidate-chain --validate` 기존 체인 검증
- "Provider 무효화 체인 분석해줘" 요청
- DB 복원, 로그아웃, 계정 전환 등 데이터 소스 변경 구현 시

## 참조 파일
```
lib/core/di/infra_providers.dart       # Core layer providers
lib/presentation/providers/*.dart       # Presentation layer providers
lib/main.dart                           # Composition Root
```

## 프로세스

### Step 1: 트리거 이벤트 식별
무효화가 필요한 트리거 이벤트 확인:
- `db-recovery`: DB 복원 감지 시
- `logout`: 사용자 로그아웃 시
- `account-switch`: 계정 전환 시
- `cache-clear`: 캐시 수동 삭제 시

### Step 2: Provider 의존성 분석
```bash
# Core layer Provider 스캔
grep -rn "Provider" lib/core/di/ --include="*.dart"

# Presentation layer Provider 스캔
grep -rn "Provider" lib/presentation/providers/ --include="*.dart"

# 의존성 추출 (ref.watch, ref.read 패턴)
grep -rn "ref\.\(watch\|read\)" lib/presentation/providers/ --include="*.dart"
```

### Step 3: 무효화 체인 맵 생성
```
[Trigger: db-recovery]
├── Core Layer (infra_providers.dart)
│   ├── sqliteLocalDataSourceProvider
│   ├── diaryRepositoryProvider
│   ├── statisticsRepositoryProvider
│   ├── getStatisticsUseCaseProvider
│   └── analyzeDiaryUseCaseProvider
└── Presentation Layer (main.dart에서 무효화)
    ├── statisticsProvider
    ├── topKeywordsProvider
    └── diaryListControllerProvider
```

### Step 4: 코드 스니펫 생성
```dart
// 생성되는 코드 예시
void invalidateAllDataProviders(ProviderContainer container) {
  // Core layer
  invalidateDataProviders(container);

  // Presentation layer
  container.invalidate(statisticsProvider);
  container.invalidate(topKeywordsProvider);
  container.invalidate(diaryListControllerProvider);
}
```

### Step 5: 검증 체크리스트 출력
- [ ] 모든 `ref.read()` 의존성 포함 확인
- [ ] `autoDispose` Provider 명시적 무효화 확인
- [ ] Cross-layer import 아키텍처 위반 없음

### Step 6 (--validate 플래그): 기존 체인 검증
`--validate` 플래그 사용 시 기존 무효화 코드를 검증합니다:

```bash
# 현재 무효화 코드 위치 검색
grep -rn "invalidate\(" lib/ --include="*.dart"
grep -rn "invalidateDataProviders" lib/ --include="*.dart"
```

검증 항목:
1. **ref.watch() 의존성 추적 확인**: Provider body 내 ref.read() 사용 여부
2. **체인 완전성**: 무효화 시작점 → 최종 UI Provider까지 연결 확인
3. **누락 Provider 검출**: watch하지만 무효화 대상에 없는 Provider

```
검증 결과 예시:
═══════════════════════════════════════════════════════════
           🔍 Provider 무효화 체인 검증 결과
═══════════════════════════════════════════════════════════

체인 완전성: ✅ PASS
├── sqliteLocalDataSourceProvider
│   └── [watch] statisticsRepositoryProvider
│       └── [watch] getStatisticsUseCaseProvider
│           └── [watch] statisticsProvider ← UI

ref.read() 사용 검출: ⚠️ 2개 발견
├── lib/core/di/infra_providers.dart:57 - diaryRepositoryProvider
└── lib/core/di/infra_providers.dart:72 - statisticsRepositoryProvider

권장 조치:
└── /provider-ref-fix lib/core/di 실행
```

## 출력 형식

```
═══════════════════════════════════════════════════════════
           🔗 Provider 무효화 체인 분석 완료
═══════════════════════════════════════════════════════════

트리거: {trigger-event}

의존성 맵:
├── Core Layer (N개)
│   ├── provider1
│   └── provider2
└── Presentation Layer (M개)
    ├── provider3
    └── provider4

생성 코드:
```dart
// 복사해서 사용
container.invalidate(provider1);
container.invalidate(provider2);
```

권장 위치: {main.dart / 해당 서비스 파일}

검증 체크리스트:
├── [ ] ref.read() 의존성 포함
├── [ ] autoDispose Provider 포함
└── [ ] 아키텍처 위반 없음
```

## 사용 예시

```
> "/provider-invalidate-chain db-recovery"

AI 응답:
1. 트리거 식별: DB 복원 감지
2. Provider 의존성 분석 (Grep)
3. 무효화 체인 맵 생성
4. 코드 스니펫 생성
5. 검증 체크리스트 출력

> "/provider-invalidate-chain logout"

AI 응답:
1. 트리거 식별: 사용자 로그아웃
2. 인증 관련 Provider 추가 분석
3. 전체 데이터 Provider 무효화 체인 생성
4. 코드 스니펫 생성 (auth + data providers)
```

## 연관 스킬
- `/provider-centralize` - Provider 중복/분산 분석
- `/arch-check` - Clean Architecture 의존성 검사
- `/til-save` - 학습 내용 메모리화

## 주의사항
- Composition Root(main.dart) 외 위치에서 cross-layer import 금지
- `invalidate()`는 idempotent → 중복 포함해도 무해
- `autoDispose` Provider는 반드시 명시적 무효화 포함
- `ref.watch()` 의존성은 자동 추적되므로 선택적 포함

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | quality |
| Dependencies | arch-check |
| Created | 2026-02-02 |
| Updated | 2026-02-02 |
