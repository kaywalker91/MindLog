# swarm-review

2단계 병렬 코드 리뷰 Swarm 스킬 (`/swarm-review [path]`)

## 목표
- **Stage 1**: Spec Compliance 단독 리뷰 (설계 준수 검증)
- **Stage 2**: 보안 / 성능 / 아키텍처 3명 병렬 리뷰 (코드 품질 검증)
- 우선순위 정렬된 통합 리포트 생성

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/swarm-review [파일경로|디렉토리]` 명령어
- "종합 리뷰", "swarm review" 요청
- 대규모 변경 후 품질 검증 필요 시

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `.claude/agents/swarm-review/security-reviewer.md` | 보안 리뷰어 에이전트 |
| `.claude/agents/swarm-review/performance-reviewer.md` | 성능 리뷰어 에이전트 |
| `.claude/agents/swarm-review/architecture-reviewer.md` | 아키텍처 리뷰어 에이전트 |

## 프로세스

### Step 1: 대상 파일 수집
```
입력: /swarm-review [path]
- 파일 경로: 해당 파일만 분석
- 디렉토리: 하위 모든 .dart 파일 수집
- 미지정 시: lib/ 전체 (경고 표시)
- 옵션: --spec [spec-path] - OpenSpec 문서 경로 (Stage 1 필수)
```

### Step 2: Stage 1 - Spec Compliance Review (단독 실행)
**설계 준수 검증을 먼저 단독으로 실행합니다:**

```
Task: spec-compliance-reviewer
  - subagent_type: general-purpose
  - 실행: Stage 2 전에 단독 실행 (순차)
  - 입력:
    - 대상 파일 목록
    - OpenSpec 문서 (있을 경우)
    - 관련 GitHub Issue/PR

  - 검증 항목:
    1. 기능 요구사항 충족 여부
       - proposal.md 목표와 구현 매칭
       - spec.md 비즈니스 로직 준수
       - tasks.md 완료 기준 충족

    2. API 계약 준수
       - Repository 인터페이스 시그니처
       - UseCase 입출력 타입
       - DTO/Entity 필드 매칭

    3. 에러 처리 완전성
       - spec.md에 정의된 Failure 케이스 구현
       - 사용자 대면 에러 메시지 준수

    4. 범위 준수
       - In-scope 기능만 구현 (over-engineering 탐지)
       - Out-of-scope 침범 없음
```

**Stage 1 통과 조건**:
```
□ 기능 요구사항 100% 충족
□ API 계약 위반 없음
□ 정의된 Failure 케이스 모두 구현
□ 범위 이탈 없음
```

**Stage 1 실패 시**: Stage 2 진행하지 않고 피드백 반환

---

### Step 3: Stage 2 - Quality Review (3명 병렬 실행)
**Stage 1 통과 후, 코드 품질 검증을 병렬로 실행합니다:**

```
Task 1: security-reviewer
  - subagent_type: general-purpose
  - 프롬프트: security-reviewer.md 내용 + 대상 파일 목록
  - 분석: API 키 노출, SQL 인젝션, 입력 검증, 데이터 보호

Task 2: performance-reviewer
  - subagent_type: general-purpose
  - 프롬프트: performance-reviewer.md 내용 + 대상 파일 목록
  - 분석: 불필요한 rebuild, 메모리 누수, 리스트 최적화, 비동기 처리

Task 3: architecture-reviewer
  - subagent_type: general-purpose
  - 프롬프트: architecture-reviewer.md 내용 + 대상 파일 목록
  - 분석: 레이어 위반, 패턴 준수, 파일 위치, Failure 처리
```

### Step 4: 결과 통합
각 리뷰어의 결과를 수집하여 심각도 기준으로 통합 정렬:
1. **Spec Violation** (Stage 1 - 요구사항 미충족, API 계약 위반)
2. **Critical** (보안 취약점, 아키텍처 원칙 위반)
3. **Major** (성능 이슈, 패턴 위반)
4. **Minor** (최적화 권장, 코드 스타일)
5. **Info** (제안, 참고)

### Step 5: 통합 리포트 출력

## 출력 형식

```
═══════════════════════════════════════════════════════════
                    Swarm Review Report
═══════════════════════════════════════════════════════════

대상: lib/presentation/screens/
파일: 12개
리뷰어: Stage 1 (Spec) + Stage 2 (보안, 성능, 아키텍처)
Spec 문서: docs/specs/diary-export/spec.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Stage 1: Spec Compliance ✓ PASSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

기능 요구사항: 5/5 충족 ✓
API 계약: 위반 없음 ✓
Failure 케이스: 3/3 구현 ✓
범위 준수: In-scope only ✓

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Stage 2: Quality Review 요약
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

| 심각도 | 보안 | 성능 | 아키텍처 | 합계 |
|--------|------|------|----------|------|
| Critical | 0 | 0 | 1 | 1 |
| Major | 1 | 2 | 0 | 3 |
| Minor | 2 | 1 | 1 | 4 |
| Info | 0 | 1 | 0 | 1 |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Critical Issues
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[ARCH-001] 레이어 의존성 위반
  파일: lib/presentation/screens/settings_screen.dart:45
  내용: data 레이어 직접 참조 (presentation -> data)
  수정: Repository 인터페이스를 통해 접근

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Major Issues
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[SEC-001] 사용자 입력 미검증
  파일: lib/presentation/screens/diary_input_screen.dart:78
  내용: 일기 텍스트 길이 제한 없음
  수정: maxLength 검증 추가

[PERF-001] 불필요한 리빌드
  파일: lib/presentation/screens/home_screen.dart:32
  내용: Consumer가 전체 화면을 감싸고 있음
  수정: ref.watch(provider.select(...)) 사용

[PERF-002] dispose 누락
  파일: lib/presentation/screens/analysis_screen.dart:15
  내용: ScrollController dispose 미호출
  수정: dispose() override 추가

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 다음 단계
├── Critical: 즉시 수정 필요
├── Major: 다음 커밋 전 수정 권장
├── /lint-fix: 자동 수정 가능 항목 처리
└── /refactor-plan: 대규모 수정 필요 시

═══════════════════════════════════════════════════════════
```

## 사용 예시

### 디렉토리 리뷰 (2단계)
```
> "/swarm-review lib/presentation/screens/ --spec docs/specs/diary-export/"

AI 응답:
1. 12개 파일 수집
2. Stage 1: Spec Compliance 단독 실행 → PASSED
3. Stage 2: 3개 리뷰어 병렬 실행
4. 결과 통합: Critical 1, Major 3, Minor 4, Info 1
5. 통합 리포트 출력
```

### 단일 파일 리뷰
```
> "/swarm-review lib/data/repositories/diary_repository_impl.dart"

AI 응답:
1. 1개 파일 대상
2. 3개 리뷰어 병렬 실행
3. 결과 통합
4. 파일 집중 리포트 출력
```

### 전체 코드베이스 리뷰
```
> "/swarm-review lib/"

AI 응답:
1. 전체 lib/ 대상 (경고: 대규모 분석)
2. 3개 리뷰어 병렬 실행
3. 결과 통합
4. 종합 리포트 출력
```

## 기존 `/review`와의 차이점

| 항목 | `/review` | `/swarm-review` |
|------|-----------|-----------------|
| 리뷰어 수 | 1명 (범용) | 1명 (Spec) + 3명 (품질) |
| 실행 방식 | 순차 | Stage 1 순차 → Stage 2 병렬 |
| 분석 깊이 | 체크리스트 기반 | Spec 준수 + 전문 영역별 심층 |
| 적합 용도 | 단일 파일, 빠른 확인 | 디렉토리/모듈 단위 종합 검증 |
| Spec 검증 | 없음 | Stage 1에서 필수 검증 |

## 연관 스킬
- `/review` - 단일 파일 빠른 리뷰
- `/lint-fix` - 자동 수정 실행
- `/arch-check` - 아키텍처 전용 검사
- `/refactor-plan` - 리팩토링 계획 수립

## 주의사항
- Stage 1 + Stage 2 순차-병렬 구조로 토큰 사용량 고려
- lib/ 전체 대상 시 경고 표시
- **Stage 1 실패 시 Stage 2로 진행하지 않음** (설계 준수 우선)
- 각 리뷰어의 False positive는 통합 단계에서 필터링
- 기존 `/review`를 대체하지 않음 (용도가 다름)
- OpenSpec 문서 없이 실행 시 Stage 1은 일반 요구사항 추론으로 동작

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | quality |
| Dependencies | - |
| Created | 2026-01-27 |
| Updated | 2026-02-05 |
