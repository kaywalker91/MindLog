# test-quality-review

테스트 코드 품질 검증 Swarm 스킬 (`/test-quality-review [path]`)

## 목표
- 3명의 전문 리뷰어가 동시에 테스트 코드 분석
- 커버리지 / 코드 품질 / 시나리오 완전성 관점의 종합 리뷰
- 최대 5회 자가 교정 루프를 통한 품질 확보
- PASS 획득 시까지 반복 검증

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/test-quality-review [테스트경로]` 명령어
- "테스트 품질 검증", "test quality review" 요청
- 테스트 코드 작성 후 품질 확인 필요 시
- PR 전 테스트 코드 검증 필요 시

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `.claude/agents/test-quality-review/coverage-reviewer.md` | 커버리지 리뷰어 에이전트 |
| `.claude/agents/test-quality-review/quality-reviewer.md` | 코드 품질 리뷰어 에이전트 |
| `.claude/agents/test-quality-review/scenario-reviewer.md` | 시나리오 완전성 리뷰어 에이전트 |

## 리뷰어 구성

### 1. Coverage Reviewer - 커버리지 전문가

| 검사 항목 | 기준 |
|----------|------|
| Domain Layer 커버리지 | >= 80% |
| Data Layer 커버리지 | >= 70% |
| Presentation Layer 커버리지 | >= 50% |
| SafetyBlockedFailure 관련 | 100% 필수 |
| Critical Path 테스트 존재 | AnalyzeDiaryUseCase 등 |

### 2. Test Quality Reviewer - 코드 품질 전문가

| 검사 항목 | 기준 |
|----------|------|
| AAA 패턴 (Arrange-Act-Assert) | 필수 |
| group() 구조화 | 입력 유효성/정상/에러 3그룹 |
| Mock: implements 사용 | not extends |
| Mock: reset() 메서드 | 필수 |
| setUp/tearDown | container.dispose() 등 |
| 한국어 테스트 설명 | 프로젝트 규칙 |

### 3. Scenario Completeness Reviewer - 시나리오 전문가

| 검사 항목 | 기준 |
|----------|------|
| Happy Path 테스트 | 필수 |
| Edge Cases (빈 값, null, 경계값) | 필수 |
| Failure 타입별 에러 테스트 | 필수 |
| **SafetyBlockedFailure 시나리오** | **Critical 필수** |
| **is_emergency true/false 케이스** | **필수** |
| 위기 키워드 감지 테스트 | 필수 |
| DiaryStatus 상태 전이 | 필수 |

## 프로세스

### Step 1: 대상 파일 수집
```
입력: /test-quality-review [path]
- 파일 경로: 해당 테스트 파일만 분석
- 디렉토리: 하위 모든 _test.dart 파일 수집
- 미지정 시: test/ 전체 (경고 표시)

수집 파일:
1. *_test.dart 파일 목록
2. 대응하는 lib/ 소스 파일 매핑
```

### Step 2: 3개 리뷰어 병렬 실행
**반드시 Task 도구로 3개를 동시에 실행합니다:**

```
Task 1: coverage-reviewer
  - subagent_type: general-purpose
  - 프롬프트: coverage-reviewer.md 내용 + 대상 파일 목록
  - 분석: 커버리지 비율, 미커버 경로, Critical Path 확인
  - 출력: PASS / FAIL + 발견 사항

Task 2: quality-reviewer
  - subagent_type: general-purpose
  - 프롬프트: quality-reviewer.md 내용 + 대상 파일 목록
  - 분석: AAA 패턴, Mock 패턴, setUp/tearDown, 한국어 설명
  - 출력: PASS / FAIL + 발견 사항

Task 3: scenario-reviewer
  - subagent_type: general-purpose
  - 프롬프트: scenario-reviewer.md 내용 + 대상 파일 목록
  - 분석: Happy Path, Edge Cases, Failure 타입, Safety 시나리오
  - 출력: PASS / FAIL + 발견 사항
```

### Step 3: 결과 통합 및 판정
```
판정 기준:
- ALL PASS: 테스트 품질 승인
- ANY FAIL: 수정 필요 항목 목록화

심각도 분류:
1. Critical (FAIL 유발): SafetyBlockedFailure 테스트 누락, is_emergency 미검증
2. Major (FAIL 유발): AAA 패턴 미준수, Mock 패턴 위반, 주요 시나리오 누락
3. Minor (PASS 가능): 개선 권장 사항
4. Info (PASS 가능): 참고 정보
```

### Step 4: 자가 교정 루프 (FAIL 시)
```
교정 프로세스:
1. FAIL 항목 분석
2. 테스트 코드 수정 제안 또는 자동 생성
3. 수정 적용 (사용자 확인)
4. 재검증 (Step 2로 복귀)

최대 5회까지 반복
5회 초과 시: 수동 검토 요청
```

### Step 5: 결과 출력
리뷰 결과를 통합 리포트 형식으로 출력

## 출력 형식

### 진행 중 상태
```
═══════════════════════════════════════════════════════════
              Test Quality Review
═══════════════════════════════════════════════════════════

Review Status (Iteration 1/5):
├── [>] Coverage Reviewer       분석 중...
├── [>] Quality Reviewer        분석 중...
└── [>] Scenario Reviewer       분석 중...

대상: test/domain/usecases/
테스트 파일: 7개
```

### 최종 결과 (PASS)
```
═══════════════════════════════════════════════════════════
                 Test Quality Review Report
═══════════════════════════════════════════════════════════

대상: test/domain/usecases/
테스트 파일: 7개

| 리뷰어 | 결과 | Critical | Major | Minor |
|--------|------|----------|-------|-------|
| Coverage | PASS | 0 | 1 | 2 |
| Quality | PASS | 0 | 0 | 3 |
| Scenario | PASS | 0 | 0 | 1 |

Overall: ✅ PASS

Minor Issues (참고):
[COV-M01] Data Layer 커버리지 72% (권장 80%)
  파일: test/data/repositories/
  권장: diary_repository_impl_test.dart 추가

[QUAL-M01] tearDown 누락
  파일: test/domain/usecases/get_diaries_usecase_test.dart
  권장: tearDown에서 mockRepository.reset() 호출

다음 단계:
├── ✅ 테스트 품질 검증 완료
├── Minor 이슈는 선택적 개선
└── /coverage로 상세 커버리지 리포트 확인
═══════════════════════════════════════════════════════════
```

### 최종 결과 (FAIL)
```
═══════════════════════════════════════════════════════════
                 Test Quality Review Report
═══════════════════════════════════════════════════════════

대상: test/domain/usecases/
테스트 파일: 7개

| 리뷰어 | 결과 | Critical | Major | Minor |
|--------|------|----------|-------|-------|
| Coverage | PASS | 0 | 1 | 2 |
| Quality | PASS | 0 | 0 | 3 |
| Scenario | FAIL | 1 | 2 | 1 |

Overall: ❌ NEEDS ATTENTION (1 FAIL)

Critical Issues (즉시 수정 필요):
[SCEN-C01] SafetyBlockedFailure 시나리오 테스트 누락
  파일: analyze_diary_usecase_test.dart
  내용: "자살+자해" 복합 키워드 테스트 없음
  수정: 복합 위기 키워드 테스트 케이스 추가 필요

Major Issues (수정 권장):
[SCEN-M01] is_emergency false 케이스 미검증
  파일: analyze_diary_usecase_test.dart
  내용: 정상 일기에서 isEmergency가 false인지 검증 없음

[SCEN-M02] DiaryStatus 상태 전이 테스트 불완전
  파일: update_diary_usecase_test.dart
  내용: pending -> analyzed 전이만 테스트, 다른 전이 누락

자가 교정 시작...
수정 제안을 생성합니다.

다음 단계:
├── Critical: 즉시 테스트 추가 필요
├── /test-unit-gen [file]: 미커버 파일 테스트 생성
└── /riverpod-widget-test-gen: Provider 테스트 추가
═══════════════════════════════════════════════════════════
```

## 사용 예시

### 기본 사용
```
> "/test-quality-review test/domain/usecases/"

AI 응답:
1. 7개 테스트 파일 수집
2. 3개 리뷰어 병렬 실행
3. 결과 통합: Critical 1, Major 2 → FAIL
4. 자가 교정 제안 → 수정 적용
5. 재검증 (Iteration 2) → PASS
```

### 단일 파일 리뷰
```
> "/test-quality-review test/domain/usecases/analyze_diary_usecase_test.dart"

AI 응답:
1. 1개 파일 대상
2. 3개 리뷰어 병렬 실행
3. 결과 집중 리포트 출력
```

### 전체 테스트 리뷰
```
> "/test-quality-review test/"

AI 응답:
⚠️ 경고: 전체 테스트 디렉토리 대상 (대규모 분석)
1. 전체 test/ 파일 수집
2. 3개 리뷰어 병렬 실행
3. 종합 리포트 출력
```

## 기존 스킬과의 차이점

| 항목 | `/swarm-review` | `/test-quality-review` |
|------|-----------------|------------------------|
| 대상 | 소스 코드 (lib/) | 테스트 코드 (test/) |
| 리뷰어 | 보안/성능/아키텍처 | 커버리지/품질/시나리오 |
| 자가 교정 | 없음 | 최대 5회 |
| 목적 | 프로덕션 코드 품질 | 테스트 코드 품질 |

| 항목 | `/openspec-review` | `/test-quality-review` |
|------|-------------------|------------------------|
| 대상 | 설계 문서 | 테스트 코드 |
| 시점 | 구현 전 | 구현 후 |
| 자가 교정 | 최대 10회 | 최대 5회 |
| 리뷰어 | 보안/아키텍처/비즈니스 | 커버리지/품질/시나리오 |

## Feature Pipeline v2 통합

```
Phase 7: Test (확장)
  ├── /test-unit-gen [feature-files]      # 테스트 생성
  ├── flutter test                         # 테스트 실행
  ├── /test-quality-review [test-path]    # 테스트 품질 검증 (NEW)
  └── /coverage                            # 커버리지 리포트
```

## 연관 스킬
- `/test-unit-gen` - 단위 테스트 생성
- `/riverpod-widget-test-gen` - Riverpod 위젯 테스트 생성
- `/coverage` - 커버리지 리포트
- `/swarm-review` - 소스 코드 리뷰 (lib/)
- `/lint-fix` - 린트 자동 수정

## 주의사항
- 3개 병렬 에이전트는 토큰을 많이 사용하므로 범위를 적절히 제한
- test/ 전체 대상 시 경고 표시
- SafetyBlockedFailure 관련 테스트는 항상 Critical 취급
- is_emergency 필드 검증은 필수 시나리오
- 기존 `/swarm-review`를 대체하지 않음 (용도가 다름)

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | testing, quality |
| Dependencies | - |
| Created | 2026-02-04 |
| Updated | 2026-02-04 |
