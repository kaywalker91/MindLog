# MindLog — AI Agent Guidelines (canonical)

모델별 진입점(`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`)은 이 문서를 짧은 포인터로 참조한다.
세션 상태·PR 번호·일시적 이력은 여기 두지 않는다 (메모리/`tasks/` 사용).

## Build / Verify

```bash
# Prefer fvm
./scripts/run.sh quality   # lint + format + test (PR gate)
./scripts/run.sh lint
./scripts/run.sh test
./scripts/run.sh format
fvm dart run build_runner build --delete-conflicting-outputs
```

`GROQ_API_KEY` 등은 `--dart-define` 주입 (`.env` 미사용). 완료 선언 전 quality gate 통과.

## Architecture boundaries

- Clean Architecture: `presentation → domain`, `data → domain` only
- `domain`: pure Dart (no Flutter imports)
- UseCase: `execute()` single method; catch Exception → rethrow Failure
- **Never modify/delete `SafetyBlockedFailure`** (crisis detection)

## Database

- Schema change: bump `_currentVersion`, keep `_onUpgrade` + `_onCreate` in sync
- No DROP of user data tables in migrations

## Protected areas

- `docs/` GitHub Pages site files (index, troubleshooting, style, json indexes)
- `.github/workflows/*` CI/CD pipelines

## Git / release

- `git push` 사용자 명시 승인 후에만
- 완료 전 예상 밖 변경 없음 확인

## Feedback

- 반복 실수: `tasks/lessons.md`
- 상세 규칙: `.claude/rules/`, skills: `.claude/skills/`
