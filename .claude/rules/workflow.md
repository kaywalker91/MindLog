# Workflow & Conventions

## Build/Test Commands
- `./scripts/run.sh quality` — full quality gates (lint + format + test)
- `./scripts/run.sh test` — run all tests with coverage
- `./scripts/run.sh lint` — static analysis
- `./scripts/run.sh format` — format code
- `flutter pub get` — install dependencies
- `flutter build appbundle` — release build

## Progress File Pattern (claude-progress.txt)
세션 간 연속성을 위해 `.claude/progress/current.md` 파일을 활용합니다.

**세션 시작 시:**
```bash
# progress 파일 확인
cat .claude/progress/current.md
```

**세션 중:**
- 작업 완료 시 progress 파일 업데이트
- 컨텍스트 70% 도달 시 `/session-wrap` 실행

**세션 종료 시:**
- progress 파일에 다음 세션 TODO 기록
- 미완료 작업은 GitHub Issue로 추적

**Progress 파일 구조:**
```markdown
# Current Progress

## 현재 작업
- [작업 내용]

## 완료된 항목
- [x] 항목 1
- [x] 항목 2

## 다음 단계
1. [TODO 1]
2. [TODO 2]

## 주의사항
- [컨텍스트 공유 필요 정보]

## 마지막 업데이트
- 날짜: YYYY-MM-DD HH:MM
- 세션: [세션 식별자]
```

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
