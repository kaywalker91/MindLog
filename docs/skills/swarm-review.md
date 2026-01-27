# swarm-review

병렬 코드 리뷰 Swarm 스킬 (`/swarm-review [path]`)

## 목표
- 3명의 전문 리뷰어가 동시에 코드 분석
- 보안 / 성능 / 아키텍처 관점의 종합 리뷰
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
```

### Step 2: 3개 리뷰어 병렬 실행
**반드시 Task 도구로 3개를 동시에 실행합니다:**

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

### Step 3: 결과 통합
각 리뷰어의 결과를 수집하여 심각도 기준으로 통합 정렬:
1. Critical (보안 취약점, 아키텍처 원칙 위반)
2. Major (성능 이슈, 패턴 위반)
3. Minor (최적화 권장, 코드 스타일)
4. Info (제안, 참고)

### Step 4: 통합 리포트 출력

## 출력 형식

```
═══════════════════════════════════════════════════════════
                    Swarm Review Report
═══════════════════════════════════════════════════════════

대상: lib/presentation/screens/
파일: 12개
리뷰어: 3명 (보안, 성능, 아키텍처)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 요약
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

### 디렉토리 리뷰
```
> "/swarm-review lib/presentation/screens/"

AI 응답:
1. 12개 파일 수집
2. 3개 리뷰어 병렬 실행
3. 결과 통합: Critical 1, Major 3, Minor 4, Info 1
4. 통합 리포트 출력
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
| 리뷰어 수 | 1명 (범용) | 3명 (전문) |
| 실행 방식 | 순차 | 병렬 |
| 분석 깊이 | 체크리스트 기반 | 전문 영역별 심층 |
| 적합 용도 | 단일 파일, 빠른 확인 | 디렉토리/모듈 단위 종합 검증 |

## 연관 스킬
- `/review` - 단일 파일 빠른 리뷰
- `/lint-fix` - 자동 수정 실행
- `/arch-check` - 아키텍처 전용 검사
- `/refactor-plan` - 리팩토링 계획 수립

## 주의사항
- 3개 병렬 에이전트는 토큰을 많이 사용하므로 범위를 적절히 제한
- lib/ 전체 대상 시 경고 표시
- 각 리뷰어의 False positive는 통합 단계에서 필터링
- 기존 `/review`를 대체하지 않음 (용도가 다름)

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | quality |
| Dependencies | - |
| Created | 2026-01-27 |
| Updated | 2026-01-27 |
