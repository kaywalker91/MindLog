# memory-index-audit

`memory/` 폴더 파일 ↔ `MEMORY.md` Memory Index 테이블 동기화 감사 스킬 (`/memory-index-audit`)

## 목적

`memory/` 디렉토리의 실제 파일과 `MEMORY.md`의 `## Memory Index` 섹션을 비교하여
미등록 파일, 고아 항목, 아카이빙 후보를 탐지한다.

## 사용법

```
/memory-index-audit          # 감사만 (수정 없음)
/memory-index-audit --fix    # 미등록 파일 자동 Index 추가
/memory-index-audit --dry-run  # 변경 예정 항목만 출력
```

## 파일 경로

- **memory/ 폴더**: `/Users/kaywalker/.claude/projects/-Users-kaywalker-AndroidStudioProjects-mindlog/memory/`
- **MEMORY.md**: `/Users/kaywalker/.claude/projects/-Users-kaywalker-AndroidStudioProjects-mindlog/memory/MEMORY.md`

## 프로세스

### Step 1: memory/ 파일 목록 수집

```bash
ls -lt /Users/kaywalker/.claude/projects/-Users-kaywalker-AndroidStudioProjects-mindlog/memory/
```

또는 Glob 도구로: `pattern="*.md"`, `path="/Users/kaywalker/.claude/projects/-Users-kaywalker-AndroidStudioProjects-mindlog/memory/"`

MEMORY.md 자체는 감사 대상에서 제외.

### Step 2: MEMORY.md Memory Index 파싱

MEMORY.md를 Read하여 `## Memory Index` 섹션의 테이블에서 등록된 파일 이름 목록 추출.

형식 참조:
```
| 파일 | 내용 |
|------|------|
| `memory/a11y-backlog.md` | A11y Sprint 1~3 상세 백로그 |
| `memory/archiving-policy.md` | memory/ 파일 아카이빙 기준 |
```

### Step 3: 비교 분석

4가지 케이스 탐지:

**① 미등록 파일** (memory/에 존재 + Index에 없음):
→ `❌ 미등록: [파일명]` 출력
→ `--fix` 모드: Memory Index 테이블에 행 추가

**② 고아 항목** (Index에 있음 + memory/에 파일 없음):
→ `⚠️ 고아 항목: [파일명] — 파일 없음` 출력
→ `--fix` 모드: Index에서 해당 행 삭제 제안 (자동 삭제 안 함, 확인 필요)

**③ SUPERSEDED 마킹 파일**:
→ 파일 내용에서 `SUPERSEDED` 키워드 확인
→ `🗂️ 아카이빙 후보: [파일명] — SUPERSEDED`

**④ 날짜 기반 파일 (90일 초과)**:
→ 파일명에서 날짜 패턴 (`YYYY-MM-DD`) 추출
→ 현재 날짜 기준 90일 경과 확인
→ `🗂️ 아카이빙 후보: [파일명] — 날짜 기반 90일 초과`

### Step 4: MEMORY.md 줄 수 확인

```bash
wc -l /Users/kaywalker/.claude/projects/-Users-kaywalker-AndroidStudioProjects-mindlog/memory/MEMORY.md
```

- 180줄+: 아카이빙 검토 경고
- 200줄+: 즉시 아카이빙 필요 (강한 경고)

### Step 5: --fix 모드 실행 (옵션)

미등록 파일 발견 시:
1. MEMORY.md의 `## Memory Index` 테이블 끝에 새 행 추가:
   ```
   | `memory/[파일명]` | [설명 placeholder — 수동 입력 필요] |
   ```
2. Edit 도구로 직접 반영

### Step 6: 결과 보고

```
### 🔍 memory-index-audit 결과
❌ 미등록: [파일명] — Memory Index에 없음
⚠️ 고아 항목: [파일명] — memory/에 파일 없음
🗂️ 아카이빙 후보: [파일명] — SUPERSEDED
🗂️ 아카이빙 후보: [파일명] — 날짜 기반 90일 초과
✅ 동기화됨: 모든 파일 Index에 등록 확인
📏 MEMORY.md: N줄 / 200줄
```

## archiving-policy.md 참조

아카이빙 기준 상세는 `memory/archiving-policy.md` 참조:
- 절대 아카이빙 금지: Critical Invariants, SafetyBlockedFailure, a11y-backlog.md
- 조건부 아카이빙: 날짜 기반 90일, SUPERSEDED+3세션
- 영구 유지: debugging-strategy.md, MEMORY.md, archiving-policy.md

## 연관 스킬

- `/memory-sync` — lessons.md → MEMORY.md 병합
- `/session-wrap` — Step 5.5에서 이 스킬의 로직 수행

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | memory-management |
| Dependencies | memory/, MEMORY.md |
| Created | 2026-02-27 |
