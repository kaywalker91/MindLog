# Workflow & Conventions

## Build/Test Commands
- `./scripts/run.sh quality` — full quality gates (lint + format + test)
- `./scripts/run.sh test` — run all tests with coverage
- `./scripts/run.sh lint` — static analysis
- `./scripts/run.sh format` — format code
- `flutter pub get` — install dependencies
- `flutter build appbundle` — release build

## Progress File Pattern
세션 간 연속성: `.claude/progress/current.md`

**세션 시작**: `cat .claude/progress/current.md`
**세션 중**: 작업 완료 시 업데이트, 컨텍스트 70% → `/session-wrap`
**세션 종료**: 다음 세션 TODO 기록, 미완료 → GitHub Issue

**파일 구조**: 현재 작업 / 완료된 항목 / 다음 단계 / 주의사항 / 마지막 업데이트(날짜+세션ID)

## Custom Skill 생성 규칙

신규 스킬 추가 시 **반드시 두 파일** 작성:

| 파일 | 역할 | 위치 |
|------|------|------|
| `<name>.md` | 상세 실행 지침 (에이전트/절차/출력형식) | `.claude/skills/` |
| `<name>.md` | 슬래시 커맨드 등록 (YAML frontmatter 필수) | `.claude/commands/` |

```markdown
# .claude/commands/<name>.md 최소 템플릿
---
allowed-tools: Read, Grep, Glob
description: 한 줄 설명
---

Read `.claude/skills/<name>.md` and execute it.

대상: $ARGUMENTS
```

commands 파일 없으면 `/name Unknown skill` 오류. 스캐폴딩: `/new-skill <name>`

## Commit Convention
Conventional Commits: `feat:`, `fix:`, `docs:`, `ci:`, `refactor:`, `test:`, `chore:`

## Coding Style
- 2-space indent, trailing commas for multiline widgets, `const` where possible
- Files: `snake_case.dart` / Types: `PascalCase` / Variables: `lowerCamelCase`
- Follow `flutter_lints` (`analysis_options.yaml`)
- Keep widgets small and reusable

## Configuration & Secrets
- API keys via `--dart-define` or `scripts/run.sh`; `.env` is NOT loaded
- Never commit secrets to git

## Session Completion Checklist
1. File issues for remaining work
2. Run quality gates (if code changed): `flutter analyze && flutter test`
3. Update issue status
4. Push to remote: `git pull --rebase && git push`
5. Clean up stashes, prune branches
6. Verify `git status` shows "up to date with origin"
7. Hand off context for next session

**Critical**: Work is NOT complete until `git push` succeeds.

## Work Type Detection (작업 시작 시 체크)

작업 시작 시 아래 패턴을 확인하고 관련 스킬을 활성화한다.

| 작업 유형 감지 | 자동 확인/제안 |
|-------------|-------------|
| `lib/presentation/` 파일 수정 | `/ui-dark-mode` 필요 여부 확인, `/responsive-overflow-fix` 오버플로우 감지 |
| "감정 분석" / `emotion` 관련 코드 | `/emotion-analyze` 관련성 확인 |
| "Firebase" 설정 변경 | `/firebase-expert` 관련성 확인 |
| "성능 이슈" / "느림" / "jank" 언급 | `/perf [action]` 자동 제안 |
| 동일 테스트 실패 3회 이상 | `/debug analyze` 강제 제안 (추측 기반 수정 중단) |
| 린트 오류 발생 | `/lint-fix` 즉시 제안 |
| 새 알림 타입 추가 | `/notification-enum-gen` → `/settings-card-gen` 체인 제안 |
| "배포" / "릴리스" / "Play Store" 키워드 | `/version-bump` → `/changelog` → `/release-unified` 체인 제안 |
