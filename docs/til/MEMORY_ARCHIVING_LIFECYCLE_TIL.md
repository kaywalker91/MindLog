# Claude 세션 메모리 아카이빙 수명주기 패턴

**분류**: Claude Code / Memory Management / Workflow
**난이도**: 초급
**예상 소요**: 10분
**최종 업데이트**: 2026-02-27

---

## 배경

Claude Code 세션에서 메모리는 7개 레이어로 구성되며, 레이어별로 수명(lifecycle)이 다르다.
파일이 폭증하거나 MEMORY.md가 200줄 제한에 도달하면 중요 정보가 truncation으로 손실된다.
이 TIL은 MindLog 프로젝트에서 설계된 7레이어 구조와 아카이빙 정책을 기록한다.

---

## 7레이어 메모리 구조

```
레이어 1: CLAUDE.md (정적 정체성)
   └─ 역할: 아키텍처 원칙, 기술 스택, 트리거 규칙
   └─ 수명: 영구 (세션 간 공유, git 추적)

레이어 2: rules/ (범용/조건부)
   └─ 역할: 언어별/도메인별 규칙 (flutter, testing, CI/CD)
   └─ 수명: 영구 (git 추적)

레이어 3: MEMORY.md (프로젝트 허브) ← 200줄 제한
   └─ 역할: Critical Invariants, 패턴, Memory Index
   └─ 수명: 장기 (세션 시작 시 자동 로드)

레이어 4: memory/ 보조 파일들 (주제별)
   └─ 역할: 세부 백로그, 감사 결과, 설계 결정
   └─ 수명: 중기 (MEMORY.md에서 참조, 90일 아카이빙)

레이어 5: tasks/lessons.md (교훈 누적)
   └─ 역할: 세션 중 발견된 패턴, 안티패턴, 버그 교훈
   └─ 수명: 중기 (session-wrap Step 5에서 업데이트)

레이어 6: docs/tasks.md (태스크 추적)
   └─ 역할: SDD 태스크 ID 매핑, 진행 상태
   └─ 수명: 장기 (git 추적)

레이어 7: .claude/progress/current.md (세션 연속성)
   └─ 역할: 현재 작업, 다음 단계, 마지막 세션 요약
   └─ 수명: 단기 (session-wrap Step 6.5에서 덮어씀)
```

---

## 아카이빙 3원칙

### 즉시 아카이빙 (archived-YYYY-MM.md에 병합 후 삭제)
| 조건 | 예시 |
|------|------|
| `SUPERSEDED` 마킹 + 3세션 이상 경과 | `claude-mem-critical-patterns.md` |
| 날짜 기반 스냅샷 + 90일 경과 | `notification-audit-2026-02-06.md` (90일 후) |
| MEMORY.md Index 미참조 (고아) | 등록 또는 삭제 |

### 절대 아카이빙 금지 (영구 보존)
- Critical Invariants 섹션 (SafetyBlockedFailure 포함)
- `a11y-backlog.md` — 진행 중 백로그
- `archiving-policy.md` — 이 정책 자체
- `debugging-strategy.md` — 세션마다 사용

### MEMORY.md 200줄 관리
- 180줄+: 아카이빙 후보 자동 출력 (경고)
- 200줄+: 즉시 아카이빙 필수
- 정책: `memory/archiving-policy.md` 참조

---

## session-wrap 자동화 통합

`/session-wrap` Step 5.5가 매 세션 종료 시 아카이빙 체크를 자동 수행:

```
Step 5.5 체크:
1. MEMORY.md 줄 수 확인
   ├── 180줄 이상 → 아카이빙 후보 출력
   └── 200줄 이상 → 즉시 아카이빙 (경고)
2. memory/ 파일 스캔
   ├── SUPERSEDED 파일 → 아카이빙 제안
   ├── 90일 초과 파일 → 아카이빙 후보
   └── Index 미등록 파일 → 등록 또는 삭제 제안
```

수동 감사: `/memory-index-audit` 스킬 사용

---

## 교훈

1. **MEMORY.md는 노트북이 아니다** — 200줄 제한은 실제로 truncation을 유발한다
2. **레이어 5 → 레이어 3 전파가 누락되기 쉽다** — lessons.md에 기록해도 MEMORY.md에 전파 안 되면 손실 (session-wrap G-2 갭)
3. **SUPERSEDED 마킹 즉시 아카이빙 안 해도 된다** — 3세션 유예기간 후 처리 (갑작스런 삭제 방지)

---

## 참조 파일

- `memory/archiving-policy.md` — 아카이빙 정책 상세
- `.claude/skills/session-wrap.md` — Step 5.5 구현
- `.claude/skills/memory-index-audit.md` — 감사 스킬
- `.claude/skills/memory-sync.md` — lessons → MEMORY.md 병합 스킬
