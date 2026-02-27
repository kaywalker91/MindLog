# TIL: 리빙 문서 아카이브 패턴 (Rolling Window + Append-Only Archive)

**날짜**: 2026-02-27
**분류**: Workflow / Document Management
**관련 파일**: `docs/tasks.md`, `docs/tasks/history.md`, `.claude/skills/task-done.md`, `.claude/skills/session-wrap.md`

---

## 문제

SDD(Specification-Driven Development) 워크플로우에서 `docs/tasks.md`처럼 지속적으로 갱신되는 "리빙 문서"는 완료 항목이 누적되면서 무한 성장한다.

**MindLog 실측**:
- 249줄 / 12.75K — 3개월 운영 후
- 평균 10 task/버전 × 5줄/task × 버전 2주당 릴리스 → **연간 ~500줄 증가**
- 매 세션 `system-reminder`로 전체 파일이 컨텍스트에 로드됨 → AI 컨텍스트 소비 증가

---

## 패턴: Rolling Window + Append-Only Archive

### 핵심 아이디어

문서의 역할을 두 레이어로 분리:

| 레이어 | 파일 | 내용 | 크기 제한 |
|--------|------|------|-----------|
| **활성 작업판** | `docs/tasks.md` | In Progress + Pending + Future | ≤150줄 |
| **이력 아카이브** | `docs/tasks/history.md` | 완료 태스크 (버전별 섹션) | 무제한 |

```
tasks.md (활성, 작은 크기)     history.md (아카이브, 계속 추가)
┌─────────────────────┐         ┌──────────────────────────────┐
│ ## 진행 중           │         │ ## v1.4.48 (2026-02-27)      │
│ _없음_              │  ──→    │ - [x] TASK-A11Y-001 ...      │
│ ## 백로그           │         │ ## v1.4.47 (2026-02-24)      │
│ - [ ] TASK-XXX ...  │         │ - [x] TASK-UI-001 ...        │
└─────────────────────┘         └──────────────────────────────┘
```

### 아카이브 트리거 기준

| 조건 | 수준 | 액션 |
|------|------|------|
| `[x]` 태스크 ≥ 5개 | ⚠️ 경고 | `/session-wrap` 권장 |
| `[x]` 태스크 ≥ 10개 | 🔴 즉시 | 아카이브 제안 |
| tasks.md ≥ 150줄 | 🔴 즉시 | 자동 아카이브 실행 |

### 아카이브 절차

```bash
# 1. 현재 버전 + 날짜로 섹션 헤더
## v{VERSION} ({DATE}) — {Sprint/Feature 이름}

# 2. tasks.md의 [x] 블록을 history.md 상단에 prepend (최신 먼저)
# 3. tasks.md에서 해당 블록 삭제
# 4. tasks.md 헤더 최종 업데이트 날짜 갱신
```

---

## 자동화 통합

### `/task-done` Step 8 (완료 처리 후 카운트)

```bash
grep -c '^\- \[x\]' docs/tasks.md
# ≥5 → 경고, ≥10 → 즉시 아카이브 제안
```

### `/session-wrap` Step 6.1 (세션 마무리 시 점검)

```bash
wc -l docs/tasks.md           # 150줄 상한
grep -c '^\- \[x\]' docs/tasks.md  # 5개 상한
```

조건 충족 시 아카이브 자동 실행 후 보고:
```
🗄️ tasks.md 아카이브
✅ 아카이브 완료: N개 완료 태스크 → docs/tasks/history.md
   └─ tasks.md: {BEFORE}줄 → {AFTER}줄
```

---

## 결과

| 지표 | 이전 | 이후 |
|------|------|------|
| tasks.md 줄 수 | 249줄 | 44줄 |
| 컨텍스트 로드 크기 | 12.75K | ~2K |
| 완료 태스크 추적 | tasks.md 내 | history.md (전체 보존) |
| 연간 성장률 | ~500줄/년 | 0줄 (자동 이동) |

---

## 다른 문서에 적용 가능한 경우

이 패턴은 다음 유형의 문서에 범용 적용 가능:
- **백로그 파일** (`tasks.md`, `backlog.md`)
- **변경 이력 파일** (`CHANGELOG.md` — 버전 단위로 archive/)
- **학습 노트** (`lessons.md` — 월 단위로 archived-YYYY-MM.md)
- **회의 메모** (월 단위 롤링)

**핵심 원칙**: "활성 뷰(active view)"는 작게 유지, "이력(history)"은 append-only로 무제한 보존.

---

## 거부된 대안

| 대안 | 거부 이유 |
|------|----------|
| 버전별 파일 (`completed-v1.4.48.md`) | 파일 파편화, 검색 불편 |
| 페이즈별 분할 (`completed-ui.md`) | 시간순 추적 불가 |
| 단일 ARCHIVE 섹션 in tasks.md | tasks.md와 구조 중복, 관리 지점 2개 |
| DB/SQLite 기반 | 오버엔지니어링, 마크다운 가독성 손실 |

---

## 참고

- 구현 PR: `chore(docs): implement tasks.md rolling window archive system`
- 관련 스킬: `.claude/skills/task-done.md` (Step 8), `.claude/skills/session-wrap.md` (Step 6.1)
- 기존 유사 패턴: `memory/archiving-policy.md` (MEMORY.md 7레이어 아카이브)
