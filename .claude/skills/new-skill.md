# /new-skill - 스킬 스캐폴딩 자동화

## Purpose
새 Claude Code 커스텀 스킬의 `.claude/skills/<name>.md` + `.claude/commands/<name>.md` 두 파일을 동시 생성.
commands 파일 누락으로 인한 "Unknown skill" 오류를 사전 방지.

## Usage
```
/new-skill <name> "<description>" [--tools <tools>] [--agents <n>]
```

## Arguments
- `name` (필수) — 스킬 이름 (kebab-case, 예: `a11y-audit`, `perf-report`)
- `description` (필수) — 한 줄 설명 (commands frontmatter에 사용)
- `--tools` — allowed-tools 목록 (기본값: `Read, Grep, Glob`)
- `--agents <n>` — 병렬 에이전트 수 (기본값: 0, 없음)

## 동작

### Step 1: 입력 파싱
```
name = "a11y-audit"
description = "WCAG 접근성 종합 감사"
tools = "Read, Grep, Glob"
agents = 2
```

### Step 2: `.claude/commands/<name>.md` 생성
```markdown
---
allowed-tools: <tools>
description: <description>
---

Read `.claude/skills/<name>.md` and execute it.

대상: $ARGUMENTS
```

### Step 3: `.claude/skills/<name>.md` 생성 (스켈레톤)
```markdown
# /<name> - <description>

## Purpose
[TODO: 스킬 목적 설명]

## Usage
```
/<name> [action]    ← [TODO: 액션 목록]
```

## 트리거 조건
- [TODO: 언제 이 스킬을 사용하는지]

---

## 실행 방식
[에이전트 수에 따라 단일/병렬 섹션 생성]

## 출력 형식
```markdown
# <Name> Report
## Summary
| 항목 | 상태 |
|------|------|
```

## 관련 스킬
- [TODO: 연관 스킬 링크]
```

### Step 4: `.claude/rules/skill-catalog.md` 업데이트
```
| `/<name> [action]` | <name>.md |
```
를 목록 마지막에 추가.

### Step 5: 완료 보고
```
✅ /new-skill 생성 완료
  .claude/commands/<name>.md   ← 슬래시 커맨드 등록
  .claude/skills/<name>.md     ← 상세 지침 스켈레톤
  skill-catalog.md             ← 목록 업데이트

다음 단계: .claude/skills/<name>.md를 작성하세요.
```

## 유효성 검사
- 이름 형식: kebab-case만 허용 (`a-z`, `-` 허용, 공백/대문자 불가)
- 중복 체크: `.claude/commands/<name>.md` 이미 존재하면 경고 후 중단
  ```
  ⚠️ /a11y-audit 이미 존재합니다 (.claude/commands/a11y-audit.md)
  덮어쓰려면: /new-skill a11y-audit --force
  ```
- description 미입력 시 경고: `⚠️ description 없음 — frontmatter에 "[TODO]" 사용`

## 예시
```
/new-skill perf-report "Flutter 성능 리포트 생성"
/new-skill db-audit "SQLite 스키마 감사" --tools "Read, Grep, Glob, Bash(flutter*)" --agents 2
/new-skill changelog-gen "CHANGELOG.md 자동 생성" --tools "Read, Bash(git*)"
```
