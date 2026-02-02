# provider-invalidation-audit

Provider 무효화 누락 정적 분석 및 리포트 생성 스킬

## 목표
- `ref.read()` 패턴 사용 Provider 자동 탐지
- `autoDispose` Provider 무효화 누락 검사
- Cross-layer 의존성 위반 검사
- 무효화 누락 리포트 생성

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/provider-invalidation-audit` 명령어
- "Provider 무효화 누락 검사해줘" 요청
- `/arch-check` 후 추가 검사 필요 시
- 새 Provider 추가 후 검증 필요 시

## 참조 패턴
```dart
// 위험 패턴: ref.read()는 의존성 추적 안됨
final data = ref.read(upstreamProvider);

// 권장 패턴: ref.watch()는 자동 추적
final data = ref.watch(upstreamProvider);

// autoDispose Provider 정의
final myProvider = FutureProvider.autoDispose((ref) => ...);
```

## 프로세스

### Step 1: Provider 정의 스캔
```bash
# 모든 Provider 정의 찾기
grep -rn "Provider" lib/ --include="*.dart" | grep -E "(final|const).*Provider"

# autoDispose Provider 찾기
grep -rn "autoDispose" lib/ --include="*.dart"
```

### Step 2: ref.read() 사용처 분석
```bash
# ref.read() 패턴 찾기
grep -rn "ref\.read(" lib/presentation/providers/ --include="*.dart"

# 의존성 맵 구축
# Provider A가 ref.read(Provider B)를 호출하면
# B 무효화 시 A도 명시적 무효화 필요
```

### Step 3: 무효화 함수 분석
```bash
# invalidate 호출 위치 찾기
grep -rn "invalidate(" lib/ --include="*.dart"

# invalidateDataProviders 함수 분석
cat lib/core/di/infra_providers.dart | grep -A 20 "invalidateDataProviders"
```

### Step 4: 누락 검사 실행
```
검사 항목:
1. ref.read()로 참조된 Provider가 무효화 체인에 포함되어 있는가?
2. autoDispose Provider가 명시적 무효화 대상에 있는가?
3. Composition Root 외 위치에서 cross-layer 무효화가 있는가?
```

### Step 5: 리포트 생성
```
Severity 레벨:
- 🔴 CRITICAL: ref.read() 의존성이 무효화 체인에 없음
- 🟠 WARNING: autoDispose Provider 명시적 무효화 누락 가능성
- 🟡 INFO: ref.watch() 권장 (현재 ref.read() 사용)
- ✅ PASS: 무효화 체인 완전
```

## 출력 형식

```
═══════════════════════════════════════════════════════════
           🔍 Provider 무효화 Audit 리포트
═══════════════════════════════════════════════════════════

스캔 범위: lib/presentation/providers/

발견된 Provider: N개
├── autoDispose: M개
├── ref.read() 의존: K개
└── ref.watch() 의존: L개

═══════════════════════════════════════════════════════════

🔴 CRITICAL (즉시 수정 필요)
───────────────────────────────────────────────────────────
[1] statisticsProvider
    위치: lib/presentation/providers/statistics_providers.dart:10
    문제: ref.read(getStatisticsUseCaseProvider) 사용
         → getStatisticsUseCase 무효화 시 statisticsProvider 캐시 유지
    해결: invalidateDataProviders() 호출 후
         container.invalidate(statisticsProvider) 추가

🟠 WARNING (검토 권장)
───────────────────────────────────────────────────────────
[2] topKeywordsProvider
    위치: lib/presentation/providers/statistics_providers.dart:18
    문제: autoDispose Provider, 명시적 무효화 권장

🟡 INFO (개선 권장)
───────────────────────────────────────────────────────────
[3] diaryListControllerProvider
    위치: lib/presentation/providers/diary_list_controller.dart:137
    권장: ref.read() → ref.watch() 변경 검토

✅ PASS
───────────────────────────────────────────────────────────
- 총 P개 Provider 무효화 체인 완전

═══════════════════════════════════════════════════════════

요약:
├── 🔴 CRITICAL: 1개
├── 🟠 WARNING: 1개
├── 🟡 INFO: 1개
└── ✅ PASS: P개

권장 조치:
1. CRITICAL 항목 즉시 수정
2. WARNING 항목 검토 후 필요 시 수정
3. /provider-invalidate-chain으로 무효화 코드 생성
```

## 네이밍 규칙

| 항목 | 형식 | 예시 |
|------|------|------|
| 리포트 파일 | `provider-audit-{date}.md` | `provider-audit-2026-02-02.md` |

## 사용 예시

```
> "/provider-invalidation-audit"

AI 응답:
1. Provider 정의 스캔 (Grep)
2. ref.read() 사용처 분석
3. 무효화 함수 분석
4. 누락 검사 실행
5. 리포트 생성 및 출력

> "/provider-invalidation-audit --save"

AI 응답:
1. (위와 동일)
5. 리포트 파일 저장: docs/audits/provider-audit-2026-02-02.md
```

## 연관 스킬
- `/provider-invalidate-chain` - 무효화 체인 코드 생성
- `/arch-check` - 아키텍처 의존성 검사
- `/provider-centralize` - Provider 중복/분산 분석

## 주의사항
- 정적 분석 한계: 동적 의존성은 탐지 불가
- False positive 가능: ref.read()가 항상 문제는 아님
  - 콜백 내 일회성 읽기는 무효화 불필요할 수 있음
- 최종 판단은 개발자가 컨텍스트 파악 후 결정

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | quality |
| Dependencies | arch-check, provider-centralize |
| Created | 2026-02-02 |
| Updated | 2026-02-02 |
