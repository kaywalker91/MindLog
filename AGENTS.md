# Repository Guidelines

## Project Structure & Module Organization
- `lib/` contains the Flutter app code, organized with Clean Architecture: `core/`, `data/`, `domain/`, `presentation/` (providers, screens, widgets).
- `test/` holds unit and widget tests, generally mirroring `lib/` (e.g., `test/domain/`, `test/widget_test.dart`).
- `assets/` stores images and static files; update `pubspec.yaml` when adding new assets.
- Platform targets live in `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/`.
- `docs/` includes design and workflow references.

## Build, Test, and Development Commands
- `flutter pub get` installs dependencies.
- `flutter run` launches the app on a device or emulator.
- `flutter test` runs all tests under `test/`.
- `flutter analyze` runs static analysis using `analysis_options.yaml`.
- `dart format .` formats Dart source.
- `flutter build apk` (or `flutter build ios`) creates a release build.

## Coding Style & Naming Conventions
- Use Dart defaults: 2-space indentation, trailing commas for multiline widgets, and `const` where possible.
- File names use `snake_case.dart`; types use `PascalCase`; variables and functions use `lowerCamelCase`.
- Follow `flutter_lints` (see `analysis_options.yaml`) and keep widgets small and reusable.

## Testing Guidelines
- Use the standard Flutter test framework (`flutter_test`).
- Name tests `*_test.dart` and place them under `test/` to mirror the feature area in `lib/`.
- Add unit tests for `domain/` and widget tests for `presentation/` when behavior changes.

## Commit & Pull Request Guidelines
- Match the existing Conventional Commit style: `feat: ...`, `docs: ...`, `ci: ...`, etc.
- PRs should include a brief summary, linked issue (if any), and screenshots for UI changes.
- Note the tests you ran (e.g., `flutter test`, `flutter analyze`).

## Configuration & Secrets
- Use `--dart-define` or `scripts/run.sh` to inject the Groq API key; `.env` is not loaded.
- Never commit secrets to git.

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
