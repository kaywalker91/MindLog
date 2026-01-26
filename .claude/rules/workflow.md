# Workflow & Conventions

## Build/Test Commands
- `flutter pub get` — install dependencies
- `flutter run` — launch app
- `flutter test` — run all tests
- `flutter analyze` — static analysis
- `dart format .` — format code
- `flutter build apk` / `flutter build appbundle` — release build

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
