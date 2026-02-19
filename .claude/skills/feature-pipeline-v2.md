# feature-pipeline-v2

AI 에이전트 팀 기반 9단계 기능 개발 파이프라인 (`/feature-pipeline-v2 [feature-name]`)

## 목표
- Phase 1-9 완전 자동화 개발 워크플로우
- SSOT 원칙에 따른 OpenSpec 문서 기반 소통
- Task 의존성 기반 순차/병렬 실행
- Human Review 포인트 명확화

## 기존 `/feature-pipeline`과의 차이점

| 항목 | `/feature-pipeline` (기존) | `/feature-pipeline-v2` (신규) |
|------|---------------------------|------------------------------|
| 단계 수 | 5단계 | 9단계 |
| 스펙 설계 | 없음 | OpenSpec 기반 |
| 스펙 검증 | 없음 | 3명 병렬 리뷰 |
| PR 생성 | 없음 | 자동 생성 |
| 추적성 | 커밋 로그 | Issue → Spec → PR 연결 |

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/feature-pipeline-v2 [feature-name]` 명령어
- "9단계 파이프라인", "전체 개발 플로우" 요청
- 완전 자동화 기능 개발 필요 시

## 전체 파이프라인 구조

```
Phase 1: Issue       ─────┐
                          ▼
Phase 2: Plan        ─────┐  (blockedBy: Phase 1)
                          ▼
Phase 3: Spec Design ─────┐  (blockedBy: Phase 2)
                          ▼
Phase 4: Spec Review ─────┐  (blockedBy: Phase 3)
                          ▼
Phase 5: Implement   ─────┐  (blockedBy: Phase 4)
                          ▼
Phase 6: Code Review ─────┐  (blockedBy: Phase 5)
                          ▼
Phase 7: Test        ─────┐  (blockedBy: Phase 6)
                          ▼
Phase 8: PR Create   ─────┐  (blockedBy: Phase 7)
                          ▼
Phase 9: Final       ─────   (blockedBy: Phase 8, Human)
```

## 프로세스

### Phase 1: Issue 확인 (Ticket Verification)
```
목적: 개발 대상 이슈 확인 및 컨텍스트 로드

실행 내용:
1. GitHub Issue 확인 (--issue 옵션 또는 자동 탐색)
   - gh issue view #{number}
   - 이슈 제목, 본문, 라벨 파싱
2. 이슈가 없으면 사용자 입력 기반 진행
3. 이슈 ID를 SSOT 식별자로 사용

출력:
- 이슈 요약
- 요구사항 목록
- 제약사항 (있을 경우)
```

### Phase 2: Plan 고도화 (Plan & Discovery)
```
목적: 기획 고도화 및 설계 방향 확정

실행 내용:
1. Plan Mode 활성화 (또는 동등한 분석)
2. 기존 코드베이스 분석
   - 관련 파일 탐색
   - 유사 패턴 확인
   - 의존성 파악
3. 초안 계획 수립
4. 사용자 확인 (Human Checkpoint #1)

출력:
- 구현 방향 요약
- 영향 받는 파일 목록
- 기술적 결정 사항
```

### Phase 3: Spec Design (스펙 설계)
```
목적: OpenSpec 표준 설계서 생성

실행 내용:
1. /openspec-design [feature-name] 호출
2. 문서 생성:
   - docs/specs/{feature}/proposal.md
   - docs/specs/{feature}/spec.md
   - docs/specs/{feature}/tasks.md
   - docs/specs/{feature}/references/plan.md

출력:
- OpenSpec 문서 세트
- 설계 요약
```

### Phase 4: Spec Review (스펙 검증)
```
목적: 설계 품질 검증 (PASS까지 반복)

실행 내용:
1. /openspec-review 호출
2. 3명 병렬 리뷰어 실행:
   - Security Reviewer
   - Architecture Reviewer
   - Business Logic Reviewer
3. FAIL 시 자가 교정 (최대 10회)
4. PASS 획득 시 진행

출력:
- 리뷰 결과 (PASS/FAIL)
- 발견 사항 목록
- reviews/ 폴더에 결과 저장
```

### Phase 5: Implement (코드 구현)
```
목적: 승인된 스펙 기반 코드 작성

실행 내용:
1. /scaffold [feature-name] 호출 (기본 구조)
2. tasks.md 기준 순차 구현:
   - Domain Layer (Entity, Repository, UseCase)
   - Data Layer (DataSource, Repository Impl)
   - Presentation Layer (Provider, Screen, Widget)
3. 라우팅 및 DI 설정
4. 컴파일 확인

출력:
- 생성/수정 파일 목록
- 구현 완료 체크리스트
```

### Phase 6: Code Review (코드 리뷰)
```
목적: 구현 코드가 스펙과 일치하는지 검증

실행 내용:
1. /swarm-review [feature-directory] 호출
2. 3명 병렬 리뷰어:
   - Security Reviewer (코드)
   - Performance Reviewer
   - Architecture Reviewer
3. 스펙(spec.md)과 코드 대조
4. FAIL 시 수정 → 재검증

출력:
- 코드 리뷰 결과
- Critical/Major/Minor 이슈 목록
```

### Phase 7: Test (자동화 테스트)
```
목적: 코드 동작 검증

실행 내용:
1. /test-unit-gen [feature-files] 호출
2. flutter test 실행
   - 새 테스트 통과
   - 기존 테스트 회귀 확인
3. /coverage 실행 (선택)
4. flutter analyze 실행

출력:
- 테스트 결과 (통과/실패)
- 커버리지 리포트
- 린트 결과
```

### Phase 8: PR Create (풀 리퀘스트 생성)
```
목적: 코드 제출 준비

실행 내용:
1. 브랜치 확인/생성
   - feature/{feature-name}
2. 변경 사항 커밋
3. GitHub PR 생성 (gh pr create)
   - 제목: feat({feature}): {description}
   - 본문: OpenSpec 요약 + 테스트 결과
4. Issue 연결 (--issue 있을 경우)

출력:
- PR URL
- PR 본문 요약
```

### Phase 9: Final Review (최종 승인)
```
목적: Human 최종 검토 및 머지

실행 내용:
1. PR 리뷰 대기 상태 안내
2. 체크리스트 제공:
   - [ ] 비즈니스 로직 확인
   - [ ] UI/UX 확인
   - [ ] 테스트 시나리오 확인
3. 사용자 승인 후 머지

Human Checkpoint #2:
- 코드 최종 검토
- PR 승인 및 머지
```

## 출력 형식

### 파이프라인 진행 상태
```
═══════════════════════════════════════════════════════════
         Feature Pipeline v2: diary-export
═══════════════════════════════════════════════════════════

Pipeline Status:
├── [✓] Phase 1: Issue           #123 로드 완료
├── [✓] Phase 2: Plan            설계 방향 확정
├── [✓] Phase 3: Spec Design     OpenSpec 생성 완료
├── [✓] Phase 4: Spec Review     PASS (Iteration 2)
├── [>] Phase 5: Implement       Domain Layer 구현 중...
├── [ ] Phase 6: Code Review     대기 (blocked)
├── [ ] Phase 7: Test            대기 (blocked)
├── [ ] Phase 8: PR Create       대기 (blocked)
└── [ ] Phase 9: Final           대기 (Human Required)

Current: Phase 5 - UseCase 구현 중

Human Checkpoints:
├── Phase 2: ✓ 설계 방향 승인됨
└── Phase 9: 대기 중

═══════════════════════════════════════════════════════════
```

### 최종 리포트
```
═══════════════════════════════════════════════════════════
      Feature Pipeline v2 Complete: diary-export
═══════════════════════════════════════════════════════════

결과 요약
├── Issue: #123 (있을 경우)
├── OpenSpec: docs/specs/diary-export/
├── 생성 파일: 12개
├── 수정 파일: 4개
├── 테스트: 18개 (전체 통과)
├── 커버리지: 87%
├── Code Review: PASS (Minor 2)
└── PR: https://github.com/user/repo/pull/456

OpenSpec 문서
├── proposal.md - 배경 및 목표
├── spec.md - 기술 스펙 (Entity 3, UseCase 4)
├── tasks.md - 25개 태스크
└── reviews/ - 리뷰 결과 2회

생성된 파일
├── lib/domain/entities/diary_export.dart
├── lib/domain/repositories/diary_export_repository.dart
├── lib/domain/usecases/export_diary.dart
├── lib/domain/usecases/get_export_formats.dart
├── lib/data/repositories/diary_export_repository_impl.dart
├── lib/data/datasources/diary_export_data_source.dart
├── lib/presentation/providers/diary_export_provider.dart
├── lib/presentation/screens/diary_export_screen.dart
├── test/domain/usecases/export_diary_test.dart
├── test/domain/usecases/get_export_formats_test.dart
├── test/data/repositories/diary_export_repository_impl_test.dart
└── test/presentation/diary_export_screen_test.dart

다음 단계
├── PR 리뷰 및 승인: https://github.com/user/repo/pull/456
├── 머지 후 Issue #123 자동 클로즈
└── 배포 파이프라인 (CI/CD)

═══════════════════════════════════════════════════════════
```

## 사용 예시

### 기본 사용
```
> "/feature-pipeline-v2 diary-export"

AI 응답:
1. Phase 1: Issue 없음 - 새 기능으로 진행
2. Phase 2: Plan Mode - 사용자 확인 요청
3. [사용자 승인 후]
4. Phase 3: OpenSpec 생성 (4개 문서)
5. Phase 4: Spec Review - PASS (Iteration 1)
6. Phase 5: 12개 파일 생성
7. Phase 6: Code Review - PASS
8. Phase 7: 18개 테스트 통과
9. Phase 8: PR #456 생성
10. Phase 9: 사용자 리뷰 대기 안내
```

### GitHub Issue 연계
```
> "/feature-pipeline-v2 diary-export --issue 123"

AI 응답:
1. Phase 1: Issue #123 로드
   - 제목: "일기 내보내기 기능 추가"
   - 요구사항: PDF, CSV 형식 지원
2. [이후 동일]
```

### 중단 후 재개
```
> [Phase 5에서 중단됨]
> "/feature-pipeline-v2 diary-export --resume"

AI 응답:
기존 진행 상태 로드:
- Phase 1-4: 완료
- Phase 5: 진행 중 (Task 3.2)

Phase 5 재개: Screen 구현 계속...
```

## Human Checkpoint 정책

| Checkpoint | Phase | 필수 여부 | 스킵 방법 |
|------------|-------|----------|----------|
| 설계 승인 | 2 | 필수 | 없음 |
| 최종 승인 | 9 | 필수 | 없음 |

## 연관 스킬
- `/openspec-design` - Phase 3에서 호출
- `/openspec-review` - Phase 4에서 호출
- `/scaffold` - Phase 5에서 호출
- `/test-unit-gen` - Phase 7에서 호출
- `/swarm-review` - Phase 6에서 호출
- `/feature-pipeline` - 기존 5단계 버전

## 주의사항
- Human Checkpoint 2회는 스킵 불가
- Phase 4 (Spec Review) 10회 실패 시 수동 검토 필요
- SafetyBlockedFailure 관련 기능은 특별 검증 강화
- OpenSpec 문서는 `docs/specs/` 에 영구 보존
- PR 생성 시 Issue 연결로 추적성 확보

## SSOT 원칙 적용

```
┌────────────────────────────────────────────────────────┐
│                    Information Flow                     │
│                                                        │
│  GitHub Issue (#123)                                   │
│       ↓                                                │
│  OpenSpec (docs/specs/{feature}/)                      │
│       ↓                                                │
│  Source Code (lib/, test/)                             │
│       ↓                                                │
│  Pull Request (PR #456) → Links to Issue               │
│       ↓                                                │
│  Merge → Issue Auto-Close                              │
│                                                        │
│  * 에이전트 간 직접 소통 없음                           │
│  * 문서와 코드만으로 정보 전달                          │
│  * 모든 산출물이 Issue ID로 추적 가능                   │
└────────────────────────────────────────────────────────┘
```

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P0 |
| Category | workflow |
| Dependencies | openspec-design, openspec-review, feature-scaffold, test-unit-gen, swarm-review |
| Created | 2026-02-04 |
| Updated | 2026-02-04 |
