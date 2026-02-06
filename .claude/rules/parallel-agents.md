# Parallel Agents Guide

Peter의 AI 코딩 원칙 5: "여러 에이전트를 병렬로 돌리세요"

## 핵심 원칙
- 단일 에이전트보다 2-3개 병렬 에이전트가 더 빠르고 창의적
- 독립적인 작업은 항상 병렬로 분할
- 결과 통합 단계에서 품질 향상

## 병렬화 적합 작업

### 높은 적합도 (항상 병렬화)
| 작업 유형 | 병렬 분할 방법 |
|-----------|---------------|
| 코드 리뷰 | 보안 / 성능 / 아키텍처 3명 |
| 탐색 작업 | 영역별 탐색 분할 |
| 테스트 작성 | 레이어별 (unit / widget / integration) |
| 리팩토링 | 파일별 독립 수정 |

### 중간 적합도 (상황에 따라)
| 작업 유형 | 조건 |
|-----------|------|
| 기능 구현 | 독립 모듈인 경우 |
| 버그 조사 | 원인 후보가 여러 개인 경우 |
| 문서화 | API / 아키텍처 / 사용법 분리 가능 시 |

### 낮은 적합도 (순차 실행)
| 작업 유형 | 이유 |
|-----------|------|
| 의존성 체인 수정 | 결과가 다음 작업에 영향 |
| DB 마이그레이션 | 순서 보장 필요 |
| 단일 파일 수정 | 충돌 위험 |

## 일상 작업 병렬화 패턴

### 1. 탐색 + 분석 병렬
```
목표: 버그 원인 찾기
├── Agent 1: 관련 코드 탐색
├── Agent 2: 로그/에러 패턴 분석
└── Agent 3: 유사 이슈 검색
→ 결과 통합: 원인 후보 우선순위 정렬
```

### 2. 구현 + 테스트 병렬
```
목표: 기능 완성
├── Agent 1: 메인 로직 구현
├── Agent 2: 단위 테스트 템플릿 작성
└── Agent 3: 관련 문서 준비
→ 결과 통합: 테스트에 실제 로직 연결
```

### 3. 리뷰 병렬 (swarm-review)
```
목표: 종합 코드 리뷰
├── Security Reviewer
├── Performance Reviewer
└── Architecture Reviewer
→ 결과 통합: 심각도별 정렬된 리포트
```

## 자동 트리거 조건

다음 상황에서 병렬 에이전트 사용 권장:
- 파일 수 > 3개
- 독립적 작업 > 2개
- 리팩토링 범위 > 1 디렉토리
- 탐색 대상 > 2 영역

## 병렬 실행 명령어

| 명령 | 용도 | 에이전트 수 |
|------|------|------------|
| `/swarm-review [path]` | 종합 리뷰 | 3 |
| `/swarm-refactor [scope] [strategy]` | 대규모 리팩토링 | 2-4 |
| `/parallel-dev [task]` | 일반 병렬 개발 | 2-3 |
| `/explore-creative [goal]` | 창의적 탐색 | 2-3 |

## 주의사항
- 병렬 에이전트는 토큰 사용량 증가 (2-3배)
- 충돌 방지: 각 에이전트에 명확한 범위 지정
- 통합 단계 필수: 결과 검증 및 정합성 확인

---

## Agent Teams (Experimental)

Agent Teams는 여러 Claude Code 인스턴스가 독립 컨텍스트에서 병렬 협업하는 기능이다.
기존 Subagent(Task 도구)와 달리 **팀원 간 직접 통신**, **공유 태스크 리스트**, **자율 태스크 할당**을 지원한다.

### Agent Teams vs Subagent 선택 기준

| 항목 | Subagent (Task 도구) | Agent Teams |
|------|---------------------|-------------|
| 컨텍스트 | 독립, 결과만 반환 | 독립, 완전 자율 |
| 통신 | 메인 에이전트에만 보고 | **팀원끼리 직접 메시지** |
| 조율 | 메인이 모든 작업 관리 | **공유 태스크 리스트 + 자율 할당** |
| 적합 | 결과만 필요한 집중 작업 | 토론/협업이 필요한 복합 작업 |
| 토큰 | 낮음 (요약 반환) | 높음 (각 인스턴스 별도 과금) |

### Agent Teams 사용 (팀원 간 토론/협업 필요)
- 코드 리뷰: 보안/성능/아키텍처 리뷰어가 서로 발견사항 공유/반박
- 버그 디버깅: 경쟁 가설 테스트, 서로의 이론 반증
- 크로스레이어 기능: Frontend/Backend/Test 각각 소유, 직접 조율
- 대규모 리팩토링: 모듈별 소유자가 변경 사항 공유

### Subagent 유지 (결과만 필요한 집중 작업)
- 단순 코드 탐색/검색
- 독립적인 테스트 생성
- 문서 생성
- 단일 결과만 필요한 분석

### Agent Teams 프롬프트 템플릿

#### 병렬 코드 리뷰
```
Create an agent team to review [path]. Spawn three reviewers:
- Security: API키 노출, SQL injection, 입력 검증, SafetyBlockedFailure 무결성
- Performance: 불필요한 리빌드, 메모리 릭, async 패턴
- Architecture: Clean Architecture 위반, Provider 패턴, 레이어 의존성
Have them challenge each other's findings.
```

#### 경쟁 가설 디버깅
```
[에러 설명]. Spawn 3 teammates to investigate:
- Hypothesis A: [가설1]
- Hypothesis B: [가설2]
- Hypothesis C: [가설3]
Have them debate and disprove each other's theories.
```

#### 크로스레이어 기능 구현
```
Implement [feature]. Create a team:
- Domain: UseCase + Entity + Repository interface
- Data: Repository impl + DataSource + DTO
- Presentation: Provider + Screen + Widget
Require plan approval before implementation.
```

### 토큰 비용 관리
1. **팀원 수 최소화**: 3명 이하 권장 (명확한 역할 분리 시에만 추가)
2. **모델 차등**: 팀원에게 Sonnet 지정하여 비용 절감
3. **단순 작업은 Subagent**: 결과만 필요한 탐색/분석은 기존 Task 도구 사용
4. **delegate 모드**: Shift+Tab으로 리드를 조율 전용으로 설정

### 알려진 제약사항
| 제약 | 대응 |
|------|------|
| 세션 복원 불가 (`/resume`, `/rewind`) | 작업 완료 후 정리, 새 팀 생성 |
| 팀당 1세션, 중첩 팀 불가 | 현재 팀 정리 후 새 팀 |
| Split-pane: VS Code 터미널 미지원 | iTerm2 또는 독립 터미널 사용 |
| 태스크 상태 지연 | 수동 확인 또는 리드에게 nudge 요청 |
