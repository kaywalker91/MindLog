# OpenSpec Templates

> SDD(Specification-Driven Development) 워크플로우용 문서 템플릿

## Templates

| 파일 | 역할 | 단계 |
|------|------|------|
| `proposal.md.template` | 기능 제안서 (배경, 목표, 범위, 리스크) | Step 0 — 기획 |
| `spec.md.template` | 기능 명세서 (요구사항 REQ-xxx, AC, 엣지케이스) | Step 1 — Specify |
| `tasks.md.template` | 구현 태스크 목록 (TASK-xxx → REQ 매핑) | Step 3 — Task |

## 사용 방법

### 스킬 사용 (권장)

```
/openspec-design [feature-name]
```

`/openspec-design` 스킬이 템플릿을 참조하여 `docs/spec.md`와 `docs/tasks.md`를 자동 생성합니다.

### 수동 사용

```bash
# 새 기능 기획 시작
cp docs/templates/openspec/proposal.md.template docs/proposal-[feature].md
cp docs/templates/openspec/spec.md.template docs/spec-[feature].md
cp docs/templates/openspec/tasks.md.template docs/tasks-[feature].md
```

`{{PLACEHOLDER}}` 형식의 모든 값을 실제 내용으로 교체합니다.

## SDD 워크플로우

```
proposal.md.template → spec.md (REQ-001~N) → tasks.md (TASK-001~M) → 코드
        ↓                    ↓                       ↓
  Step 0: 기획          Step 1: Specify          Step 3: Task
                        Step 2: Plan (plan.md)   Step 4: Implement
```

**규칙**: 코드보다 문서를 먼저. `spec.md → plan.md → tasks.md → 코드` 순서를 반드시 지킵니다.

## 관련 스킬

- [`/openspec-design [feature]`](../../.claude/skills/openspec-design.md) — spec.md 자동 생성
- [`/openspec-review [spec-path]`](../../.claude/skills/openspec-review.md) — 명세 품질 리뷰
- [`/scaffold [name]`](../../.claude/skills/feature-scaffold.md) — Clean Architecture 파일 생성
