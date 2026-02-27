# session-wrap

세션 마무리 자동화 스킬 (`/session-wrap`)

## 목표
- 세션 작업 내용 체계적 요약
- CLAUDE.md 업데이트 후보 도출
- 자동화 가능 패턴 식별
- TIL(Today I Learned) 문서화
- 다음 세션 우선순위 정리

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "/session-wrap" 명령어
- "세션 마무리해줘" 요청
- 대규모 작업 완료 후
- 컨텍스트 한도 도달 전

### 자동 트리거 조건 (권장)
다음 조건에서 Claude는 `/session-wrap` 실행을 자동 제안합니다:
- **컨텍스트 70% 도달**: 대화가 길어질 때
- **커밋 10개 이상**: 단일 세션에서 많은 변경 발생 시
- **작업 시간 2시간 초과**: 장시간 작업 시
- **파일 20개 이상 수정**: 대규모 리팩토링 시

자동 제안 시 메시지:
```
💡 세션 정리 시점입니다. `/session-wrap`을 실행할까요?
- 컨텍스트: ~70% 사용
- 커밋: N개
- 수정 파일: N개
```

## 프로세스

### Step 1: 세션 변경 사항 수집
```bash
# Git 변경 내역
git log --oneline -20
git diff --stat HEAD~10

# 수정된 파일 목록
git status

# 커밋 요약
git log --pretty=format:"%h %s" --since="8 hours ago"
```

### Step 2: 4개 병렬 분석 에이전트 실행
동시에 4개 Task 에이전트 실행:

**1. doc-updater**: CLAUDE.md 업데이트 후보
```
- 새로 발견된 아키텍처 패턴
- 워크플로우 개선사항
- 프로젝트 구조 변경
```

**2. automation-scout**: 자동화 가능 패턴
```
- 반복된 수작업 패턴
- 스킬로 자동화 가능한 작업
- 워크플로우 최적화 기회
```

**3. learning-extractor**: TIL 문서 후보
```
- 기술적 발견사항
- 문제 해결 과정
- 재사용 가능한 지식
```

**4. followup-suggester**: 다음 세션 우선순위
```
- 미완료 작업
- 발견된 기술 부채
- 테스트 커버리지 갭
```

### Step 3: 결과 통합 및 보고서 생성

```markdown
# Session Wrap Report

## 📊 세션 요약
- 기간: YYYY-MM-DD HH:MM ~ HH:MM
- 커밋: N개
- 수정 파일: N개
- 신규 파일: N개

## 🔧 완료된 작업
1. [작업 1]
2. [작업 2]
...

## 📝 CLAUDE.md 업데이트 후보
- [업데이트 1]
- [업데이트 2]

## ⚡ 자동화 후보
| 패턴 | 스킬 이름 | 우선순위 |
|------|----------|----------|
| ... | /... | P1 |

## 📚 TIL 문서 후보
- [제목]: [요약]

## 🎯 다음 세션 우선순위
| 우선순위 | 작업 | 이유 |
|----------|------|------|
| High | ... | ... |
| Medium | ... | ... |
| Low | ... | ... |
```

### Step 4: Git 상태 확인
```bash
# 푸시 대기 커밋 확인
git log origin/main..HEAD --oneline

# Working tree 상태
git status --short
```

### Step 5: tasks/lessons.md 업데이트 확인 ← 필수 체크포인트

세션 중 발생한 수정 요청, 버그 수정, 패턴 발견을 `tasks/lessons.md`에 기록합니다:

```bash
# 현재 lessons.md 마지막 항목 확인
tail -20 tasks/lessons.md
```

**기록 체크리스트**:
- [ ] 세션 중 사용자 수정 요청이 있었는가? → 교훈 추가
- [ ] 새로 발견한 패턴/안티패턴이 있는가? → 교훈 추가
- [ ] 프로덕션에 영향하는 버그를 해결했는가? → `/troubleshoot-save [id]` 도 실행
- [ ] 재현 가능한 기술 패턴을 학습했는가? → TIL 후보로 추가

기록 형식:
```markdown
## [날짜] - [교훈 제목]
**무엇이 잘못됐나**: [설명]
**근본 원인**: [분석]
**해결책**: [솔루션]
**예방 규칙**: [다음 번에 어떻게 피할지]
```

### Step 5.5: MEMORY.md 업데이트 후보 추출 [G-2]

Step 5에서 `tasks/lessons.md`에 추가된 신규 항목을 스캔하여 `MEMORY.md`에 반영한다.

```bash
# MEMORY.md 현재 줄 수 확인 (200줄 제한)
wc -l ~/.claude/projects/-Users-kaywalker-AndroidStudioProjects-mindlog/memory/MEMORY.md
```

**처리 절차**:
1. `tasks/lessons.md` 최신 항목 (오늘 날짜 기준) 추출
2. `MEMORY.md` 기존 내용과 대조 → 중복 여부 판단
3. 신규 패턴이면: 해당 섹션에 1줄 요약 추가 (Write/Edit 도구로 직접 반영 또는 제안)
4. MEMORY.md가 180줄 이상이면: 아카이빙 후보 자동 식별 (가장 오래된 비필수 항목 목록 출력)

**보고 형식**:
```
### 🧠 MEMORY.md 동기화
✅ 신규 패턴 반영: [패턴명] → Testing Patterns 섹션 추가
⚠️ 200줄 임박 (현재 N줄): 아카이빙 후보 → [항목 목록]
🔵 변경 없음: 기존 메모리와 동일
```

### Step 6: Tasks.md 동기화 점검

최근 커밋에서 TASK-XXX 패턴을 추출해 `docs/tasks.md` 상태와 대조한다.

```bash
# 최근 20개 커밋 메시지 확인
git log --oneline -20

# 커밋 메시지에서 TASK-ID 패턴 추출 예시
git log --oneline -20 | grep -oE 'TASK-[A-Z]+-[0-9]+'
```

**동기화 절차**:
1. 커밋 메시지에서 `TASK-XXX` 패턴 추출
2. `docs/tasks.md`에서 해당 ID의 현재 상태 확인
3. `[ ]` 상태인데 커밋에 포함된 항목 → `/task-done TASK-ID` 실행 또는 직접 `[x]` 마킹
4. `[x]`인데 메타데이터(완료:, 파일:, 추가:) 없는 항목 → 보완 제안

**보고 형식**:
```
### 📋 Tasks.md 동기화
✅ 자동 업데이트됨: TASK-A11Y-001~005 (5건)
⚠️ 미완료 상태 감지:  TASK-UI-003 (커밋에 포함됐지만 [ ] 상태)
⚠️ 메타데이터 누락:   TASK-SD-001 (완료일 불명)
🔵 변경 없음: 나머지 태스크
```

### Step 6.5: progress/current.md 동기화 [G-3]

세션 종료 상태를 `.claude/progress/current.md`에 자동 반영한다.

**업데이트 내용**:
```markdown
## 현재 작업
없음 (세션 종료)

## 완료된 항목
[Step 3 보고서의 완료된 작업 목록 추가]

## 다음 단계
[followup-suggester 결과에서 Top 3 추출]

## 주의사항
[Step 5에서 발견된 신규 안티패턴/주의사항]

## 마지막 업데이트
[오늘 날짜] / 세션 [git log 최신 커밋 해시 7자]
```

**보고 형식**:
```
### 📍 progress/current.md 동기화
✅ 업데이트 완료: 다음 단계 3개 기록
📅 마지막 업데이트: YYYY-MM-DD / 세션 abc1234
```

### Step 7: 다음 액션 제안
- 푸시 필요 시: "git push를 실행할까요?"
- 미완료 작업 시: GitHub Issue 생성 제안
- 문서화 필요 시: TIL 파일 생성 제안

### Step 7.5: TIL INDEX 동기화 [G-4]

Step 3에서 TIL 후보가 확인된 경우에만 실행한다.

**조건부 실행**:
- TIL 파일이 실제로 생성된 경우: `docs/til/INDEX.md` 신규 항목 추가
- TIL 후보만 제안된 경우: `/til-index-sync --fix` 실행 제안 (선택적)
- TIL 변경 없는 경우: 이 스텝 skip

**처리 절차**:
1. `docs/til/` 디렉토리에서 INDEX.md에 없는 신규 파일 감지
2. 누락 항목이 있으면 INDEX.md 업데이트 (15-시나리오 테이블에 행 추가)
3. `--dry-run` 모드: 변경 예정 항목만 출력

**보고 형식**:
```
### 📚 TIL INDEX 동기화
✅ INDEX.md 업데이트: [파일명] → 시나리오 추가
🔵 변경 없음: TIL 신규 파일 없음 (skip)
```

## 출력 형식

```
═══════════════════════════════════════════════════════════
                    📋 Session Wrap Report
═══════════════════════════════════════════════════════════

📊 세션 요약
├── 기간: 2026-01-26 14:00 ~ 18:00
├── 커밋: 6개
├── 수정 파일: 21개
└── 신규 파일: 15개

🔧 완료된 작업
├── ✅ Phase 1: 아키텍처 위반 수정
├── ✅ Phase 2: Provider 정리
├── ✅ Phase 3: 위젯 분해
└── ✅ Phase 4: UI State 통합

📝 CLAUDE.md 업데이트 후보
┌─────────────────────────────────────────────────────────
│ 1. Widget Organization 섹션 추가
│    - widgets/ 하위 디렉토리 구조 설명
│    - 섹션 위젯 네이밍 컨벤션
│
│ 2. Provider Organization 섹션 추가
│    - ui_state_providers.dart 역할 설명
│    - Provider 배럴 파일 패턴
└─────────────────────────────────────────────────────────

⚡ 자동화 후보
┌─────────────────────────────────────────────────────────
│ | 패턴 | 스킬 | 우선순위 |
│ |------|------|----------|
│ | 대형 위젯 분해 | /widget-decompose | P1 |
│ | 아키텍처 검사 | /arch-check | P0 |
│ | Provider 정리 | /provider-centralize | P1 |
└─────────────────────────────────────────────────────────

📚 TIL 문서 후보
┌─────────────────────────────────────────────────────────
│ 1. FLUTTER_WIDGET_DECOMPOSITION_TIL.md
│    - 대형 위젯 분해 전략
│    - 섹션 위젯 추출 패턴
│
│ 2. CLEAN_ARCHITECTURE_VIOLATION_FIX_TIL.md
│    - presentation → data 위반 수정
│    - Repository 인터페이스 확장 패턴
└─────────────────────────────────────────────────────────

🎯 다음 세션 우선순위
┌─────────────────────────────────────────────────────────
│ | 우선순위 | 작업 | 이유 |
│ |----------|------|------|
│ | High | 분해된 위젯 테스트 | 테스트 커버리지 확보 |
│ | Medium | TIL 문서 작성 | 지식 보존 |
│ | Low | CLAUDE.md 업데이트 | 프로젝트 문서화 |
└─────────────────────────────────────────────────────────

🚀 Git 상태
├── 로컬 커밋: 6개 (origin/main 대비)
└── Working tree: clean

═══════════════════════════════════════════════════════════
git push를 실행할까요? (y/n)
```

## 네이밍 규칙

| 항목 | 형식 | 예시 |
|------|------|------|
| TIL 파일 | `{TOPIC}_TIL.md` | `FLUTTER_WIDGET_DECOMPOSITION_TIL.md` |
| 세션 로그 | `session-{date}.md` | `session-2026-01-26.md` |
| 계획 파일 | `{adjective}-{noun}.md` | `steady-purring-lobster.md` |

## 사용 예시

```
> "/session-wrap"

AI 응답:
1. Git 변경 내역 수집: 6 커밋, 21 파일
2. 4개 분석 에이전트 병렬 실행
3. 결과 통합
4. Session Wrap Report 출력
5. "git push를 실행할까요?" 질문
```

## 연관 스킬
- `/sc:git` - Git 작업 자동화
- `/refactor-plan` - 리팩토링 계획
- `/changelog` - CHANGELOG 업데이트

## 주의사항
- 대규모 변경 시 커밋 분리 확인
- 민감 정보 커밋 여부 검사
- 테스트 통과 확인 후 푸시 권장
- 미완료 작업은 Issue로 추적

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | workflow |
| Dependencies | - |
| Created | 2026-01-26 |
| Updated | 2026-02-27 |
