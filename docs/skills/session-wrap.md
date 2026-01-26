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

### Step 5: 다음 액션 제안
- 푸시 필요 시: "git push를 실행할까요?"
- 미완료 작업 시: GitHub Issue 생성 제안
- 문서화 필요 시: TIL 파일 생성 제안

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
| Updated | 2026-01-26 |
