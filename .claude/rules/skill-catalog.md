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
| `/version-bump [type]` | `version-bump.md` | Version update (patch/minor/major) |
| `/changelog` | `changelog-update.md` | CHANGELOG.md update |
| `/lint-fix` | `lint-fix.md` | Auto-fix lint violations |
| `/coverage` | `test-coverage-report.md` | Test coverage report |
| `/review [file]` | `code-reviewer.md` | Code review |
| `/widget-test [file]` | `widget-test-gen.md` | Widget test generation |

## Quality & Refactoring Commands

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/arch-check` | `arch-check.md` | Clean Architecture 의존성 위반 검사 |
| `/widget-decompose [file]` | `widget-decompose.md` | 대형 위젯 분해 자동화 |
| `/provider-centralize` | `provider-centralize.md` | Provider 중복/분산 분석 및 중앙화 |
| `/refactor-plan [scope]` | `refactor-plan.md` | 리팩토링 계획서 생성 |
| `/session-wrap` | `session-wrap.md` | 세션 마무리 자동화 |
| `/til-save [topic]` | `til-save.md` | TIL 문서 메모리 저장 |

## CI/CD Commands

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/cd-diagnose [run_id]` | `cd-diagnose.md` | CD 워크플로우 실패 근본 원인 분석 |
| `/fastlane-audit` | `fastlane-audit.md` | Fastlane 설정 사전 검증 |

## Swarm Orchestration Commands

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/swarm-review [path]` | `swarm-review.md` | 보안·성능·아키텍처 3명 병렬 리뷰 |
| `/feature-pipeline [name]` | `feature-pipeline.md` | Research→Plan→Scaffold→Test→Review 자동 파이프라인 |
| `/swarm-refactor [scope] [strategy]` | `swarm-refactor.md` | 대규모 리팩토링 병렬 에이전트 분담 |

## Workflows
- **New feature**: `/scaffold` -> `/usecase` -> `/test-unit-gen` -> `/coverage`
- **New feature (auto)**: `/feature-pipeline [name]` (위 워크플로우 자동화)
- **Release**: `/lint-fix` -> `/review` -> `/version-bump` -> `/changelog`
- **AI improvement**: `/groq analyze-prompt` -> `/groq optimize-tokens`
- **DB change**: `/db add-column` -> `/db schema-report` -> `/test-unit-gen`
- **Refactoring**: `/arch-check` -> `/provider-centralize` -> `/refactor-plan` -> `/widget-decompose`
- **Refactoring (swarm)**: `/refactor-plan` -> `/swarm-refactor [scope] [strategy]`
- **Deep review**: `/swarm-review [path]` (보안+성능+아키텍처 병렬)
- **CD troubleshoot**: `/fastlane-audit` -> `/cd-diagnose [run_id]` -> 수정 -> 재배포
- **Session end**: `/session-wrap` -> `/til-save [topic]` (TIL 메모리화)
