# memory-sync

`tasks/lessons.md` 신규 항목을 `MEMORY.md` 섹션에 의미론적으로 병합하는 스킬 (`/memory-sync`)

## 목적

세션 종료 시 `tasks/lessons.md`에 기록된 교훈을 `MEMORY.md` 관련 섹션에 자동 반영하여
세션 간 지식 손실을 방지한다.

## 사용법

```
/memory-sync                # 오늘 추가된 lessons 병합
/memory-sync --days 3       # 최근 3일 lessons 스캔
/memory-sync --dry-run      # 변경 내용 미리보기 (실제 적용 안 함)
```

## 파일 경로

- **lessons.md**: `tasks/lessons.md` (프로젝트 루트 기준)
- **MEMORY.md**: `~/.claude/projects/-Users-kaywalker-AndroidStudioProjects-mindlog/memory/MEMORY.md`
  - 절대 경로: `/Users/kaywalker/.claude/projects/-Users-kaywalker-AndroidStudioProjects-mindlog/memory/MEMORY.md`

## 프로세스

### Step 1: lessons.md 최근 항목 추출

```bash
# 오늘 날짜 기준 항목 확인
tail -50 tasks/lessons.md
```

오늘 날짜(`## [날짜]`) 기준으로 신규 항목을 식별한다.
`--days N` 옵션 시 최근 N일치 항목 스캔.

### Step 2: MEMORY.md 현재 내용 로드

MEMORY.md를 Read 도구로 로드하여:
- 현재 줄 수 확인 (200줄 제한)
- 각 섹션 구조 파악:
  - `## Critical Invariants`
  - `## Key UI Patterns`
  - `## Testing Patterns`
  - `## Notification ID Table`
  - `## Claude Code Skill 구조`
  - `## Accessibility 현황`
  - `## Misc Patterns`

### Step 3: 의미론적 섹션 매핑

각 lessons 항목을 MEMORY.md 섹션에 매핑:

| lessons 키워드 | MEMORY.md 섹션 |
|--------------|--------------|
| `테스트`, `widget test`, `pump`, `mock` | Testing Patterns |
| `위젯`, `UI`, `레이아웃`, `overflow` | Key UI Patterns |
| `알림`, `FCM`, `notification` | Notification ID Table |
| `Provider`, `Riverpod` | Misc Patterns |
| `아키텍처`, `import`, `레이어` | Critical Invariants |
| `접근성`, `a11y`, `Semantics` | Accessibility 현황 |
| 기타 | Misc Patterns |

### Step 4: 중복 여부 확인

lessons 항목의 **핵심 키워드**가 이미 MEMORY.md에 존재하는지 Grep으로 확인:
- 존재하면: `⏭️ 스킵됨` 출력
- 없으면: 해당 섹션에 1줄 요약 추가

### Step 5: MEMORY.md 업데이트

신규 패턴이면 Edit 도구로 해당 섹션 끝에 1줄 요약 추가:
- 형식: `- [핵심 내용] ([날짜] 추가)`
- 200줄 임박(180줄+) 시 경고 출력

### Step 6: 결과 보고

```
### 🔄 memory-sync 결과
✅ 병합됨: [패턴명] → [섹션명] 추가
⏭️ 스킵됨: [패턴명] — 이미 존재
⚠️ 200줄 임박: 현재 N줄 — 아카이빙 검토 필요
📏 MEMORY.md: N줄 / 200줄
🔵 변경 없음: 모든 항목 중복 또는 오늘 신규 lessons 없음
```

## 주의사항

- lessons.md에서 **날짜 헤더 `## YYYY-MM-DD`** 기준으로 신규 항목 식별
- 1줄 요약은 간결하게 (50자 이내)
- `--dry-run` 시 Edit 도구 호출 없이 예정 변경만 출력
- MEMORY.md 200줄 초과 시 즉시 중단 + `/memory-index-audit` 실행 제안

## 연관 스킬

- `/memory-index-audit` — memory/ 파일 ↔ Index 동기화 감사
- `/session-wrap` — Step 5.5에서 이 스킬의 로직 수행
- `/til-save` — TIL 생성 후 knowledge 보존

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | memory-management |
| Dependencies | tasks/lessons.md, MEMORY.md |
| Created | 2026-02-27 |
