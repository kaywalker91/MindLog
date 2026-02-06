# openspec-review

OpenSpec 설계서 병렬 검증 스킬 (`/openspec-review [spec-path]`)

## 목표
- 3명의 전문 리뷰어가 동시에 스펙 문서 검증
- 보안 / 아키텍처 / 비즈니스 로직 관점의 종합 리뷰
- 최대 10회 자가 교정 루프를 통한 품질 확보
- PASS 획득 시까지 반복 검증

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/openspec-review [spec-path]` 명령어
- "스펙 검증해줘", "OpenSpec 리뷰" 요청
- `/openspec-design` 완료 후 자동 제안

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `docs/specs/{feature}/spec.md` | 검증 대상 스펙 문서 |
| `docs/specs/{feature}/tasks.md` | 태스크 정합성 확인 |
| `docs/specs/{feature}/reviews/` | 리뷰 결과 저장 |

## 리뷰어 구성

### 1. Security Reviewer
**검증 항목:**
- API 키/시크릿 노출 위험
- 입력 검증 누락
- 인증/인가 설계 적절성
- 데이터 보호 (암호화, 마스킹)
- MindLog 특수: SafetyBlockedFailure 처리 적절성
- OWASP Top 10 관련 위험

### 2. Architecture Reviewer
**검증 항목:**
- Clean Architecture 레이어 분리 준수
- Domain Layer 순수성 (외부 의존 없음)
- Repository 패턴 올바른 적용
- Failure 처리 완전성
- Provider 설계 적절성
- 파일 구조 및 네이밍 규칙

### 3. Business Logic Reviewer
**검증 항목:**
- 요구사항 완전성 (proposal vs spec 일치)
- 엣지 케이스 처리
- 데이터 흐름 일관성
- 상태 전이 완전성
- 에러 시나리오 커버리지
- tasks.md와 spec.md 정합성

## 프로세스

### Step 1: 대상 스펙 로드
```
입력: /openspec-review [spec-path]
- spec-path: docs/specs/{feature}/ 경로
- 미지정 시: 최근 생성된 스펙 자동 선택

로드 파일:
1. proposal.md - 배경 및 목표
2. spec.md - 상세 기술 스펙
3. tasks.md - 구현 태스크
4. references/plan.md - 원본 Plan
```

### Step 2: 3개 리뷰어 병렬 실행
**반드시 Task 도구로 3개를 동시에 실행합니다:**

```
Task 1: security-spec-reviewer
  - subagent_type: general-purpose
  - 분석: 보안 취약점, 인증/인가, 데이터 보호
  - 출력: PASS / FAIL + 발견 사항

Task 2: architecture-spec-reviewer
  - subagent_type: general-purpose
  - 분석: 레이어 분리, 패턴 준수, Failure 처리
  - 출력: PASS / FAIL + 발견 사항

Task 3: business-logic-reviewer
  - subagent_type: general-purpose
  - 분석: 요구사항 일치, 엣지 케이스, 정합성
  - 출력: PASS / FAIL + 발견 사항
```

### Step 3: 결과 통합 및 판정
```
판정 기준:
- ALL PASS: 스펙 승인, 다음 단계 진행 가능
- ANY FAIL: 수정 필요 항목 목록화

심각도 분류:
1. Critical (FAIL 유발): 보안 취약점, 아키텍처 원칙 위반
2. Major (FAIL 유발): 요구사항 누락, 엣지 케이스 미처리
3. Minor (PASS 가능): 개선 권장 사항
4. Info (PASS 가능): 참고 정보
```

### Step 4: 자가 교정 루프 (FAIL 시)
```
교정 프로세스:
1. FAIL 항목 분석
2. spec.md 또는 tasks.md 수정 제안
3. 수정 적용 (사용자 확인)
4. 재검증 (Step 2로 복귀)

최대 10회까지 반복
10회 초과 시: 수동 검토 요청
```

### Step 5: 리뷰 결과 저장
```
reviews/ 디렉토리에 저장:
├── review-{timestamp}.md     # 리뷰 결과 전체
├── security-review.md        # 보안 리뷰 상세
├── architecture-review.md    # 아키텍처 리뷰 상세
└── business-review.md        # 비즈니스 로직 리뷰 상세
```

## 출력 형식

### 진행 중 상태
```
═══════════════════════════════════════════════════════════
              OpenSpec Review: diary-export
═══════════════════════════════════════════════════════════

Review Status (Iteration 1/10):
├── [>] Security Reviewer       분석 중...
├── [>] Architecture Reviewer   분석 중...
└── [>] Business Logic Reviewer 분석 중...

대상 문서: docs/specs/diary-export/
```

### 최종 결과 (PASS)
```
═══════════════════════════════════════════════════════════
              OpenSpec Review: diary-export
═══════════════════════════════════════════════════════════

Review Result: ✅ PASS (Iteration 2/10)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 요약
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| 리뷰어 | 결과 | Critical | Major | Minor |
|--------|------|----------|-------|-------|
| Security | PASS | 0 | 0 | 1 |
| Architecture | PASS | 0 | 0 | 0 |
| Business Logic | PASS | 0 | 0 | 2 |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Minor Issues (참고)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[SEC-M01] 로깅 민감정보
  위치: spec.md L45
  내용: 에러 로깅 시 사용자 ID 마스킹 권장
  상태: INFO (구현 시 고려)

[BIZ-M01] 대용량 처리
  위치: spec.md L78
  내용: 1000건 초과 내보내기 시 배치 처리 고려
  상태: INFO (향후 개선)

[BIZ-M02] 오프라인 지원
  위치: tasks.md L23
  내용: 오프라인 내보내기 시나리오 미정의
  상태: INFO (범위 외 확인 필요)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

리뷰 결과 저장: docs/specs/diary-export/reviews/review-20260204.md

다음 단계:
├── ✅ 스펙 승인 완료
├── /feature-pipeline diary-export 실행 가능
└── 또는 /scaffold diary-export로 직접 구현 시작

═══════════════════════════════════════════════════════════
```

### 최종 결과 (FAIL)
```
═══════════════════════════════════════════════════════════
              OpenSpec Review: diary-export
═══════════════════════════════════════════════════════════

Review Result: ❌ FAIL (Iteration 1/10)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Critical Issues (즉시 수정 필요)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[SEC-C01] 인증 누락
  위치: spec.md L23
  내용: 파일 내보내기 API에 인증 검증 미정의
  수정: Authentication 섹션 추가 필요

[ARCH-C01] 레이어 위반
  위치: spec.md L56
  내용: Domain Entity에서 Flutter 패키지 의존
  수정: Pure Dart로 Entity 재설계

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Major Issues (수정 권장)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[BIZ-M01] 엣지 케이스 누락
  위치: spec.md L89
  내용: 빈 일기 목록 내보내기 시 동작 미정의
  수정: Empty state 처리 로직 추가

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

자가 교정 시작...
수정 적용 후 재검증을 진행합니다.

═══════════════════════════════════════════════════════════
```

## 사용 예시

### 기본 사용
```
> "/openspec-review docs/specs/diary-export/"

AI 응답:
1. 스펙 문서 로드 (proposal, spec, tasks)
2. 3개 리뷰어 병렬 실행
3. 결과 통합: Critical 2, Major 1 → FAIL
4. 자가 교정 제안 → 수정 적용
5. 재검증 (Iteration 2) → PASS
6. 리뷰 결과 저장
```

### openspec-design 연계
```
> [/openspec-design diary-export 완료 후]
> "/openspec-review docs/specs/diary-export/"

AI 응답:
1. 직전 생성된 스펙 자동 로드
2. 검증 실행
```

### 강제 PASS (위험)
```
> "/openspec-review docs/specs/diary-export/ --force-pass"

AI 응답:
⚠️ 경고: Critical/Major 이슈가 있어도 PASS 처리됩니다.
리뷰 결과는 기록되며, 구현 시 리스크가 있습니다.
계속하시겠습니까? (Y/N)
```

## 기존 `/swarm-review`와의 차이점

| 항목 | `/swarm-review` | `/openspec-review` |
|------|-----------------|-------------------|
| 대상 | 소스 코드 | 설계 문서 (스펙) |
| 시점 | 구현 후 | 구현 전 |
| 목적 | 코드 품질 검증 | 설계 품질 검증 |
| 자가 교정 | 없음 | 최대 10회 |
| 리뷰어 | 보안/성능/아키텍처 | 보안/아키텍처/비즈니스 |

## 연관 스킬
- `/openspec-design` - 스펙 설계 (선행)
- `/swarm-review` - 코드 리뷰 (후행)
- `/feature-pipeline` - 전체 파이프라인
- `/arch-check` - 아키텍처 검증 (단독)

## 주의사항
- 스펙 문서가 없으면 실행 불가 → `/openspec-design` 먼저 실행
- 10회 자가 교정 실패 시 수동 검토 필요
- SafetyBlockedFailure 관련 스펙은 Security Reviewer가 특별 검증
- 리뷰 결과는 항상 reviews/ 디렉토리에 저장됨

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | quality |
| Dependencies | openspec-design |
| Created | 2026-02-04 |
| Updated | 2026-02-04 |
