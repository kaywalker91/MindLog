# openspec-design

OpenSpec 표준 설계서 자동 생성 스킬 (`/openspec-design [feature-name]`)

## 목표
- 확정된 Plan을 OpenSpec 표준 규격 문서로 변환
- SSOT 원칙에 따른 추적 가능한 설계 산출물 생성
- 에이전트 간 소통을 위한 명확한 스펙 문서화
- **소크라틱 대화를 통한 요구사항 정제** (Phase 0)

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/openspec-design [feature-name]` 명령어
- "스펙 설계해줘", "OpenSpec 생성" 요청
- Plan Mode 완료 후 상세 설계 필요 시

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `docs/templates/openspec/proposal.md.template` | 제안 개요 템플릿 |
| `docs/templates/openspec/spec.md.template` | 상세 기술 스펙 템플릿 |
| `docs/templates/openspec/tasks.md.template` | 단계별 태스크 리스트 템플릿 |

## 출력 구조
```
docs/specs/{feature-name}/
├── proposal.md          # 제안 개요 및 배경
├── spec.md              # 상세 기술 스펙 및 비즈니스 로직
├── tasks.md             # 구현 단계별 태스크 리스트
├── references/
│   └── plan.md          # 추적성을 위한 원본 플랜 저장
└── reviews/             # 리뷰 결과 저장 디렉토리
```

## 프로세스

### Phase 0: Brainstorming (소크라틱 대화)

**목표**: 구현 전 요구사항 명확화 및 설계 정제

```
1. 초기 이해 확인
   - "이 기능의 핵심 목표는 무엇인가요?"
   - 한 번에 하나의 질문만 진행
   - 200-300단어 단위로 응답 검증

2. 접근법 제시 (2-3개)
   - 각 접근법의 장단점 명시
   - 트레이드오프 분석:
     - 개발 복잡도 vs 사용자 경험
     - 성능 vs 유지보수성
     - 시간 vs 완성도

3. 엣지 케이스 탐색
   - "~한 경우는 어떻게 처리할까요?"
   - "기존 [기능명]과의 상호작용은?"
   - 사용자가 명확한 답변을 제공할 때까지 반복

4. 설계 확정
   - 합의된 접근법 요약
   - 명확한 범위 경계 (In/Out scope)
   - 다음 Phase로 진행 동의 확인
```

**Brainstorming 규칙**:
- ✓ 질문 하나씩 순차 진행 (한 번에 여러 질문 금지)
- ✓ 사용자 응답을 요약하여 이해 확인
- ✓ 가정하지 말고 물어보기
- ✗ 200단어 이상의 긴 설명 회피
- ✗ 사용자 동의 없이 다음 단계 진행 금지

**Phase 0 완료 조건**:
```
□ 핵심 목표 명확화 완료
□ 접근법 선택 완료
□ 범위 경계 합의 완료
□ 사용자 "진행" 승인
```

---

### Step 1: 입력 분석
```
입력: /openspec-design [feature-name]
- feature-name: 기능명 (영문, kebab-case)
- 선행 조건: Plan Mode 결과 또는 GitHub Issue 내용 또는 Phase 0 완료

분석 내용:
1. 기존 Plan 문서 또는 대화 컨텍스트 확인
2. 관련 GitHub Issue 내용 확인 (있을 경우)
3. 기존 코드베이스 패턴 파악
4. Phase 0 brainstorming 결과 반영
```

### Step 2: proposal.md 생성
제안 개요 문서 작성:
```markdown
# [Feature Name] Proposal

## 배경
- 문제 상황 또는 요구사항

## 목표
- 달성하고자 하는 구체적 목표

## 범위
- In-scope: 포함 범위
- Out-of-scope: 제외 범위

## 성공 지표
- 측정 가능한 성공 기준

## 관련 이슈
- GitHub Issue: #xxx (있을 경우)
- 의존성: 선행 기능 또는 시스템
```

### Step 3: spec.md 생성
상세 기술 스펙 작성:
```markdown
# [Feature Name] Technical Specification

## 아키텍처 설계

### Domain Layer
- Entity 정의
- Repository 인터페이스
- UseCase 정의

### Data Layer
- DataSource 설계
- Repository 구현체
- DTO/Model 정의

### Presentation Layer
- Provider 설계
- Screen/Widget 설계
- 상태 관리 전략

## API 설계 (해당 시)
- Endpoint 정의
- Request/Response 스키마

## 데이터베이스 스키마 (해당 시)
- 테이블/컬럼 정의
- 마이그레이션 전략

## 에러 처리
- Failure 케이스 정의
- 사용자 대면 에러 메시지

## 보안 고려사항
- 인증/인가
- 데이터 보호
- 입력 검증

## 비즈니스 로직
- 핵심 로직 플로우
- 엣지 케이스 처리
```

### Step 4: tasks.md 생성
구현 태스크 리스트 작성:
```markdown
# [Feature Name] Implementation Tasks

## Phase 1: Domain Layer
- [ ] Task 1.1: Entity 생성
- [ ] Task 1.2: Repository 인터페이스 정의
- [ ] Task 1.3: UseCase 구현

## Phase 2: Data Layer
- [ ] Task 2.1: DataSource 구현
- [ ] Task 2.2: Repository 구현체 작성
- [ ] Task 2.3: DTO/Model 작성

## Phase 3: Presentation Layer
- [ ] Task 3.1: Provider 구현
- [ ] Task 3.2: Screen 구현
- [ ] Task 3.3: Widget 구현

## Phase 4: Integration
- [ ] Task 4.1: 라우팅 설정
- [ ] Task 4.2: DI 등록

## Phase 5: Testing
- [ ] Task 5.1: Unit 테스트
- [ ] Task 5.2: Widget 테스트
- [ ] Task 5.3: Integration 테스트 (선택)

## 완료 기준
- 모든 Task 체크 완료
- 테스트 통과
- 린트 경고 없음
```

### Step 5: references/plan.md 생성
원본 Plan 저장 (추적성 확보):
```markdown
# Original Plan

## 생성일시
YYYY-MM-DD HH:MM

## Plan 내용
[Plan Mode에서 확정된 내용 그대로 저장]

## 변경 이력
| 날짜 | 변경 내용 | 사유 |
|------|----------|------|
```

## 출력 형식

```
═══════════════════════════════════════════════════════════
              OpenSpec Design: {feature-name}
═══════════════════════════════════════════════════════════

생성된 문서:
├── docs/specs/{feature-name}/proposal.md      ✓
├── docs/specs/{feature-name}/spec.md          ✓
├── docs/specs/{feature-name}/tasks.md         ✓
├── docs/specs/{feature-name}/references/plan.md ✓
└── docs/specs/{feature-name}/reviews/         ✓ (디렉토리)

요약:
├── Domain: Entity 2개, UseCase 3개
├── Data: Repository 1개, DataSource 1개
├── Presentation: Provider 2개, Screen 1개
└── Tasks: 총 15개

다음 단계:
├── /openspec-review docs/specs/{feature-name}/
├── 스펙 검토 후 수정
└── 승인 후 /feature-pipeline 실행

═══════════════════════════════════════════════════════════
```

## 네이밍 규칙

| 항목 | 형식 | 예시 |
|------|------|------|
| 디렉토리 | `docs/specs/{feature-name}/` | `docs/specs/diary-export/` |
| 파일명 | `kebab-case.md` | `proposal.md`, `spec.md` |
| Feature Name | `kebab-case` | `diary-export`, `emotion-analysis` |

## 사용 예시

### 기본 사용 (Brainstorming 포함)
```
> "/openspec-design diary-export"

AI 응답 (Phase 0):
Q1: "일기 내보내기의 핵심 목표는 무엇인가요? 백업, 공유, 마이그레이션 중 어떤 용도인가요?"

사용자: "백업 목적이에요"

Q2: "백업 형식으로 다음 옵션이 있습니다:
- JSON: 복원 용이, 사람이 읽기 어려움
- Markdown: 읽기 쉬움, 메타데이터 손실 가능
- ZIP (JSON + 첨부파일): 완전한 백업, 용량 큼
어떤 형식이 좋을까요?"

사용자: "ZIP으로 할게요"

Q3: "범위 확인: 분석 결과도 포함할까요, 일기 텍스트만 포함할까요?"

사용자: "분석 결과도 포함"

AI 응답: "이해했습니다. 설계를 진행할까요?"

사용자: "네"

AI 응답 (Step 1~5):
1. Plan 컨텍스트 분석 + Phase 0 결과 반영
2. proposal.md 생성 - 배경 및 목표 정의
3. spec.md 생성 - 3-레이어 아키텍처 설계
4. tasks.md 생성 - 15개 태스크 정의
5. references/plan.md 생성 - 원본 저장
6. OpenSpec 설계 완료 리포트 출력
```

### 빠른 사용 (Brainstorming 스킵)
```
> "/openspec-design diary-export --skip-brainstorm"

AI 응답:
1. Plan 컨텍스트 분석 (Phase 0 스킵)
2. proposal.md 생성
3. spec.md 생성
4. tasks.md 생성
5. references/plan.md 생성
6. OpenSpec 설계 완료 리포트 출력

주의: 요구사항이 명확한 경우에만 사용
```

### Plan Mode 연계
```
> [Plan Mode에서 설계 확정 후]
> "/openspec-design diary-export"

AI 응답:
1. Plan Mode 결과 자동 인식
2. 설계 내용을 OpenSpec 형식으로 변환
3. 문서 세트 생성
```

### GitHub Issue 연계
```
> "/openspec-design diary-export --issue 123"

AI 응답:
1. GitHub Issue #123 내용 로드
2. Issue 기반 proposal.md 생성
3. 기술 스펙 및 태스크 도출
```

## 연관 스킬
- `/openspec-review` - 생성된 스펙 검증
- `/feature-pipeline` - 전체 개발 파이프라인
- `/scaffold` - 코드 스캐폴딩
- `/refactor-plan` - 리팩토링 계획 (유사 용도)

## 주의사항
- Plan Mode 또는 충분한 컨텍스트 없이 실행 시 경고
- 기존 스펙이 있으면 덮어쓰기 전 확인 요청
- SafetyBlockedFailure, is_emergency 관련 기능은 spec.md에 보안 섹션 필수
- MindLog Clean Architecture 규칙 준수 (domain → data → presentation)

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | workflow |
| Dependencies | - |
| Created | 2026-02-04 |
| Updated | 2026-02-04 |
