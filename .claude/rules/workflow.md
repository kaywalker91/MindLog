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
