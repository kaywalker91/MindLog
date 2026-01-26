# Skill Catalog

Skills are in `docs/skills/`. Read the relevant file on-demand when a command is invoked.

## Commands

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/scaffold [name]` | `feature-scaffold.md` | Clean Architecture scaffolding |
| `/test-unit-gen [file]` | `test-unit-gen.md` | Unit test generation |
| `/groq [action]` | `groq-expert.md` | AI prompt optimization |
| `/db [action]` | `database-expert.md` | SQLite schema management |
| `/resilience [action]` | `resilience-expert.md` | Error handling patterns |
| `/version-bump [type]` | — | Version update (patch/minor/major) |
| `/changelog` | — | CHANGELOG.md update |
| `/lint-fix` | — | Auto-fix lint violations |
| `/coverage` | — | Test coverage report |
| `/review [file]` | — | Code review |
| `/widget-test [file]` | — | Widget test generation |

## Workflows
- **New feature**: `/scaffold` -> `/usecase` -> `/test-unit-gen` -> `/coverage`
- **Release**: `/lint-fix` -> `/review` -> `/version-bump` -> `/changelog`
- **AI improvement**: `/groq analyze-prompt` -> `/groq optimize-tokens`
- **DB change**: `/db add-column` -> `/db schema-report` -> `/test-unit-gen`
