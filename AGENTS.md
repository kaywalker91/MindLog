# MindLog — Agent entry (Codex / multi-agent)

> Canonical rules: [`docs/ai-guidelines.md`](docs/ai-guidelines.md)
> Claude-oriented notes: [`CLAUDE.md`](CLAUDE.md)
> Layer rules: `.claude/rules/`

## Quick verify

```bash
./scripts/run.sh quality
# or
./scripts/run.sh lint && ./scripts/run.sh test
```

## Hard rules

- Do not modify/delete `SafetyBlockedFailure`.
- Domain stays pure Dart; no presentation→data shortcuts.
- Do not delete protected `docs/` Pages files or CI workflows.
- Do not `git push` without explicit user approval.
- Do not claim done on analyze timeout / environment failure.

## Before coding

1. Read `docs/ai-guidelines.md`.
2. Skim `tasks/lessons.md` recent items when present.
3. Use fvm/`./scripts/run.sh` for project-standard commands.
