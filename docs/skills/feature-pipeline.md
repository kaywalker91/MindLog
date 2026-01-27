# feature-pipeline

자동화된 기능 개발 파이프라인 스킬 (`/feature-pipeline [feature-name]`)

## 목표
- Research → Plan → Scaffold → Test → Review 단계 자동 체인
- Task 의존성 기반 순차 실행
- 기존 스킬들을 파이프라인으로 연결
- 수동 단계 전환 없이 자동 진행

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- `/feature-pipeline [feature-name]` 명령어
- "기능 파이프라인 실행해줘" 요청
- 새 기능 개발 시 전체 워크플로우 자동화 필요 시

## 프로세스

### 전체 파이프라인 구조
```
Task 1: Research ─────┐
                      ▼
Task 2: Plan ─────────┐  (blocked by Task 1)
                      ▼
Task 3: Scaffold ─────┐  (blocked by Task 2)
                      ▼
Task 4: Test ─────────┐  (blocked by Task 3)
                      ▼
Task 5: Review ───────   (blocked by Task 4)
```

### Step 1: 파이프라인 초기화
```
입력: /feature-pipeline [feature-name]
- feature-name: 구현할 기능명 (영문, kebab-case)
- 예: /feature-pipeline diary-export
```

5개 Task를 생성하고 의존성을 설정합니다:
```
TaskCreate: "Research: [feature-name]"
TaskCreate: "Plan: [feature-name]"        → blockedBy: [Task 1]
TaskCreate: "Scaffold: [feature-name]"    → blockedBy: [Task 2]
TaskCreate: "Test: [feature-name]"        → blockedBy: [Task 3]
TaskCreate: "Review: [feature-name]"      → blockedBy: [Task 4]
```

### Step 2: Research (Task 1)
기존 코드베이스 탐색 및 패턴 분석

```
실행 내용:
1. 관련 기존 코드 탐색 (Serena 도구 활용)
   - 유사 기능 구현체 검색
   - 사용 패턴 파악 (Entity, Repository, UseCase)
2. 의존성 파악
   - 연관 Entity/Repository/UseCase 식별
   - 필요한 데이터 소스 확인
3. MindLog 아키텍처 규칙 확인
   - .claude/rules/architecture.md 준수 사항
   - 레이어별 제약사항

출력:
- 관련 코드 목록
- 구현에 필요한 기존 컴포넌트 식별
- 제약사항 목록
```

### Step 3: Plan (Task 2)
구현 설계 — Plan Mode 활용

```
실행 내용:
1. Clean Architecture 기반 설계
   - Entity 설계 (domain/entities/)
   - Repository 인터페이스 (domain/repositories/)
   - UseCase 정의 (domain/usecases/)
   - DataSource 설계 (data/datasources/)
   - Provider 설계 (presentation/providers/)
   - Screen/Widget 설계 (presentation/screens/)
2. 파일 생성 목록 작성
3. 수정 필요 파일 목록 작성

출력:
- 구현 계획서 (파일 목록 + 설계)
- 사용자 확인 요청
```

### Step 4: Scaffold (Task 3)
코드 생성 — 기존 `/scaffold` 스킬 활용

```
실행 내용:
1. /scaffold [feature-name] 실행
   - Entity 생성
   - Repository interface + impl 생성
   - UseCase 생성
   - Provider 생성
   - Screen 생성
2. 추가 코드 작성
   - DataSource 메서드 추가
   - 라우팅 설정 (go_router)
   - DI 등록 (Provider)

출력:
- 생성된 파일 목록
- 수정된 파일 목록
```

### Step 5: Test (Task 4)
테스트 생성 및 실행 — 기존 `/test-unit-gen` + `/coverage` 활용

```
실행 내용:
1. /test-unit-gen [feature-files] 실행
   - UseCase 단위 테스트
   - Repository 단위 테스트
2. flutter test 실행
   - 새 테스트 통과 확인
   - 기존 테스트 회귀 확인
3. /coverage 실행 (선택적)
   - 커버리지 확인

출력:
- 테스트 결과
- 커버리지 리포트 (선택적)
```

### Step 6: Review (Task 5)
코드 리뷰 — `/swarm-review` 또는 `/review` 활용

```
실행 내용:
1. /swarm-review [feature-directory] 실행
   - 보안 검증
   - 성능 검증
   - 아키텍처 검증
2. flutter analyze 실행
3. 최종 리포트

출력:
- 리뷰 리포트
- 수정 필요 항목 (있을 경우)
```

## 출력 형식

### 파이프라인 진행 상태
```
═══════════════════════════════════════════════════════════
              Feature Pipeline: diary-export
═══════════════════════════════════════════════════════════

Pipeline Status:
├── [v] Task 1: Research          완료
├── [v] Task 2: Plan              완료
├── [>] Task 3: Scaffold          진행 중...
├── [ ] Task 4: Test              대기 (blocked by Task 3)
└── [ ] Task 5: Review            대기 (blocked by Task 4)

Current: Scaffold 단계 — 파일 생성 중
```

### 최종 리포트
```
═══════════════════════════════════════════════════════════
          Feature Pipeline Complete: diary-export
═══════════════════════════════════════════════════════════

결과 요약
├── 생성 파일: 8개
├── 수정 파일: 3개
├── 테스트: 12개 (전체 통과)
├── 커버리지: 85%
└── 리뷰: Major 0, Minor 2

생성된 파일
├── lib/domain/entities/diary_export.dart
├── lib/domain/repositories/diary_export_repository.dart
├── lib/domain/usecases/export_diary.dart
├── lib/data/repositories/diary_export_repository_impl.dart
├── lib/presentation/providers/diary_export_provider.dart
├── lib/presentation/screens/diary_export_screen.dart
├── test/domain/usecases/export_diary_test.dart
└── test/data/repositories/diary_export_repository_impl_test.dart

다음 단계
├── Minor 이슈 2건 수정 (선택적)
├── Widget 테스트 추가 권장
└── git commit 준비 완료
═══════════════════════════════════════════════════════════
```

## 사용 예시

```
> "/feature-pipeline diary-export"

AI 응답:
1. 파이프라인 초기화: 5개 Task 생성
2. Research: 기존 diary 관련 코드 탐색
3. Plan: Clean Architecture 기반 설계 → 사용자 확인
4. Scaffold: 8개 파일 생성
5. Test: 12개 테스트 작성 및 실행 (전체 통과)
6. Review: swarm-review 실행 → Minor 2건
7. 파이프라인 완료 리포트 출력
```

## 중단 및 재개
- 각 Task는 독립적으로 완료 표시됨
- Plan 단계에서 사용자 확인 후 진행 (자동 스킵 불가)
- 테스트 실패 시 파이프라인 일시 중단 → 수정 후 재개
- `TaskList`로 현재 진행 상태 확인 가능

## 연관 스킬
- `/scaffold` - 코드 스캐폴딩 (Step 3에서 호출)
- `/test-unit-gen` - 테스트 생성 (Step 4에서 호출)
- `/coverage` - 커버리지 확인 (Step 4에서 호출)
- `/swarm-review` - 병렬 리뷰 (Step 5에서 호출)
- `/review` - 단일 리뷰 (Step 5 대안)

## 주의사항
- Plan 단계에서 반드시 사용자 확인 필요
- 테스트 실패 시 자동으로 다음 단계 진행하지 않음
- 대규모 기능은 하위 기능으로 분할 후 각각 파이프라인 실행 권장
- SafetyBlockedFailure, is_emergency 관련 기능은 추가 주의

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | workflow |
| Dependencies | feature-scaffold, test-unit-gen, test-coverage-report, swarm-review |
| Created | 2026-01-27 |
| Updated | 2026-01-27 |
