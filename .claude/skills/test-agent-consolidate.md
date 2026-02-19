# test-agent-consolidate

병렬 테스트 에이전트 완료 후 검증·수정·리포트를 원커맨드로 자동화

## 목표
- 병렬 에이전트 작업 후 반복되는 lint + test + progress 업데이트 자동화
- 자동 수정 가능한 린트를 안전하게 배치 적용 (특정 lint code만)
- 신규 테스트 실패와 기존 실패를 구분하여 리포트
- `.claude/progress/current.md` 자동 업데이트

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/test-agent-consolidate` 명령어
- 병렬 에이전트(Task 도구) 완료 후 통합 검증 필요 시
- "에이전트 결과 정리", "테스트 통합 검증" 요청
- swarm/parallel-dev 작업 완료 직후

## 참조 파일
| 파일 | 역할 |
|------|------|
| `.claude/progress/current.md` | 세션 진행 상황 추적 |
| `scripts/run.sh` | 프로젝트 빌드/테스트 스크립트 |

## 프로세스

### Step 1: 정적 분석 실행
```bash
flutter analyze --fatal-infos 2>&1
```
- 전체 이슈 카운트 수집
- info / warning / error 분류
- 자동 수정 가능 lint code 식별 (prefer_single_quotes, unnecessary_this 등)

### Step 2: 안전한 배치 린트 수정
**핵심**: `dart fix --apply --code=<specific_lint>` 로 특정 린트만 수정 (전체 `dart fix --apply` 보다 안전)

```bash
# 안전한 자동 수정 대상 (의미 변경 없음)
dart fix --apply --code=prefer_single_quotes
dart fix --apply --code=unnecessary_this
dart fix --apply --code=unnecessary_new
dart fix --apply --code=prefer_collection_literals
dart fix --apply --code=unnecessary_const
dart fix --apply --code=unnecessary_string_interpolations
```

**절대 자동 수정하지 않는 린트**:
- `prefer_final_locals` — 의도적 mutable 변수 가능
- `avoid_dynamic_calls` — 타입 변환 필요
- `deprecated_member_use` — 대체 API 확인 필요

수정 후 재분석:
```bash
flutter analyze --fatal-infos 2>&1
```

### Step 3: 전체 테스트 실행
```bash
flutter test 2>&1
```
- 총 테스트 수, 통과, 실패, 스킵 수집
- 실패 테스트 목록 추출
- 가능하면 이전 실행 결과와 비교하여 신규 실패 구분

### Step 4: Progress 파일 업데이트
`.claude/progress/current.md` 에 다음 정보 추가:
```markdown
## 에이전트 통합 검증 결과
- 날짜: YYYY-MM-DD HH:MM
- 린트: X issues (자동수정 Y개 적용)
- 테스트: 통과 A / 실패 B / 스킵 C (총 D개)
- 상태: PASS / NEEDS_ATTENTION
```

### Step 5: 결과 요약 리포트 출력

## 출력 형식

```
═══════════════════════════════════════════════════════════
           Agent Consolidation Report
═══════════════════════════════════════════════════════════

Step 1: Static Analysis
├── Before fix: 15 issues (3 error, 5 warning, 7 info)
├── Auto-fixed: 7 issues (prefer_single_quotes: 5, unnecessary_this: 2)
└── After fix:  8 issues (3 error, 5 warning, 0 info)

Step 2: Test Results
├── Total:   142 tests
├── Passed:  140
├── Failed:  2
├── Skipped: 0
└── New failures: 2 (vs previous run)
    - test/core/services/emotion_trend_service_test.dart: 'should detect gap'
    - test/presentation/providers/diary_analysis_test.dart: 'should trigger CBT'

Step 3: Progress Updated
└── .claude/progress/current.md ✓

Overall: ⚠️ NEEDS_ATTENTION (2 test failures)

다음 단계:
├── 실패 테스트 수정 필요
├── /debug analyze — 실패 원인 분석
└── /test-lint-pipeline — 수정 후 재검증
═══════════════════════════════════════════════════════════
```

## 사용 예시

### 기본 사용
```
> "/test-agent-consolidate"

AI 응답:
1. flutter analyze 실행 → 15 issues 발견
2. dart fix --apply --code=prefer_single_quotes 등 배치 적용 → 7개 수정
3. flutter test 실행 → 140/142 통과
4. progress 파일 업데이트
5. 결과 리포트 출력
```

### 병렬 에이전트 후 사용
```
> "/parallel-dev implement notification feature"
> (에이전트 3개 완료)
> "/test-agent-consolidate"

AI 응답:
1. 3개 에이전트 작업물 통합 검증
2. 린트 자동 수정 → 0 remaining issues
3. 전체 테스트 통과 → PASS
4. progress 업데이트 완료
```

## 연관 스킬
- `/test-lint-pipeline` - 커밋 전 품질 게이트 (이 스킬의 경량 버전)
- `/parallel-dev` - 병렬 개발 (이 스킬의 선행 작업)
- `/lint-fix` - 린트 수동 수정
- `/coverage` - 커버리지 상세 리포트
- `/session-wrap` - 세션 마무리 (이 스킬 → session-wrap 순서)

## 주의사항
- `dart fix --apply --code=<lint>` 는 특정 린트만 수정 — 전체 `dart fix --apply`는 사용 금지
- 의미 변경 가능한 린트(prefer_final_locals 등)는 절대 자동 수정하지 않음
- 테스트 실패 시 자동 수정하지 않고 리포트만 출력 (수동 확인 필요)
- progress 파일이 없으면 새로 생성

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | testing, quality |
| Dependencies | - |
| Created | 2026-02-06 |
| Updated | 2026-02-06 |
