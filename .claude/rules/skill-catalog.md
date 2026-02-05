# Skill Catalog

Skills are in `docs/skills/`. Read the relevant file on-demand when a command is invoked.

## Commands

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/scaffold [name]` | `feature-scaffold.md` | Clean Architecture scaffolding |
| `/test-unit-gen [file]` | `test-unit-gen.md` | Unit test generation (TDD 강화) |
| `/debug [action]` | `systematic-debugging.md` | 4단계 체계적 디버깅 (NEW) |
| `/groq [action]` | `groq-expert.md` | AI prompt optimization |
| `/db [action]` | `database-expert.md` | SQLite schema management |
| `/resilience [action]` | `resilience-expert.md` | Error handling patterns |
| `/version-bump [type]` | `version-bump.md` | Version update (patch/minor/major) |
| `/changelog` | `changelog-update.md` | CHANGELOG.md update |
| `/lint-fix` | `lint-fix.md` | Auto-fix lint violations |
| `/coverage` | `test-coverage-report.md` | Test coverage report |
| `/review [file]` | `code-reviewer.md` | Code review |
| `/widget-test [file]` | `widget-test-gen.md` | Widget test generation |
| `/suppress-pattern [entity] [duration]` | `suppress-pattern.md` | Time-based suppression (24h, 7d, etc) |
| `/periodic-timer [name] [interval]` | `periodic-timer.md` | Periodic background task with cleanup |

## Mental Health & Safety Commands (NEW)

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/crisis-check [action]` | `crisis-detection.md` | 위기 감지 및 안전 개입 프로토콜 (P0 Critical) |
| `/emotion-analyze [action]` | `emotion-analyze.md` | 감정 분석 심화 및 Mental Health 패턴 |

## Flutter Advanced Commands (NEW)

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/flutter-advanced [action]` | `flutter-advanced.md` | Riverpod 심화 패턴 및 성능 최적화 |
| `/ui-dark-mode [action]` | `ui-dark-mode.md` | Dark Theme 최적화 및 디자인 시스템 |
| `/c7-flutter [topic]` | `c7-flutter.md` | Context7 Flutter/Riverpod 공식 문서 조회 |

## AI & Optimization Commands (NEW)

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/prompt-opt [action]` | `prompt-optimization.md` | LLM 프롬프트 체계적 최적화 |
| `/db-migrate-validate [action]` | `db-migration-validator.md` | SQLite 마이그레이션 검증 자동화 |

## Quality & Refactoring Commands

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/arch-check` | `arch-check.md` | Clean Architecture 의존성 위반 검사 |
| `/widget-decompose [file]` | `widget-decompose.md` | 대형 위젯 분해 자동화 |
| `/responsive-overflow-fix [file]` | `responsive-overflow-fix.md` | Column 오버플로우 → 반응형 UI 변환 |
| `/barrel-export-gen [dir]` | `barrel-export-gen.md` | 배럴 export 파일 자동 생성 |
| `/color-migrate [file]` | `color-migrate.md` | 하드코딩 색상 → theme-aware 마이그레이션 |
| `/provider-centralize` | `provider-centralize.md` | Provider 중복/분산 분석 및 중앙화 |
| `/provider-invalidate-chain [trigger]` | `provider-invalidate-chain.md` | Provider 무효화 체인 분석 및 코드 생성 |
| `/provider-invalidate-chain --validate` | `provider-invalidate-chain.md` | 기존 무효화 체인 검증 |
| `/provider-ref-fix [path]` | `provider-ref-fix.md` | Provider 정의 내 ref.read() → ref.watch() 자동 변환 |
| `/defensive-recovery-gen [trigger]` | `defensive-recovery-gen.md` | DB 복원 방어적 코드 패턴 생성 |
| `/provider-invalidation-audit` | `provider-invalidation-audit.md` | Provider 무효화 누락 정적 분석 |
| `/refactor-plan [scope]` | `refactor-plan.md` | 리팩토링 계획서 생성 |
| `/session-wrap` | `session-wrap.md` | 세션 마무리 자동화 |
| `/til-save [topic]` | `til-save.md` | TIL 문서 메모리 저장 |

## Testing & Recovery Commands

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/test-quality-review [path]` | `test-quality-review.md` | 테스트 품질 3명 병렬 리뷰 (커버리지/품질/시나리오) |
| `/riverpod-widget-test-gen [file]` | `riverpod-widget-test-gen.md` | Riverpod 위젯 테스트 자동 생성 |
| `/db-state-recovery [action]` | `db-state-recovery.md` | DB 복원 시나리오 테스트 자동화 |

## CI/CD Commands

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/cd-diagnose [run_id]` | `cd-diagnose.md` | CD 워크플로우 실패 근본 원인 분석 |
| `/fastlane-audit` | `fastlane-audit.md` | Fastlane 설정 사전 검증 |

## OpenSpec & SSOT Commands (NEW)

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/openspec-design [feature]` | `openspec-design.md` | OpenSpec 표준 설계서 자동 생성 (Phase 3) |
| `/openspec-review [spec-path]` | `openspec-review.md` | 스펙 검증 3명 병렬 리뷰 + 자가 교정 (Phase 4) |

## Swarm Orchestration Commands

| Command | Skill File | Purpose |
|---------|-----------|---------|
| `/swarm-review [path]` | `swarm-review.md` | 보안·성능·아키텍처 3명 병렬 리뷰 |
| `/feature-pipeline [name]` | `feature-pipeline.md` | Research→Plan→Scaffold→Test→Review 5단계 파이프라인 |
| `/feature-pipeline-v2 [name]` | `feature-pipeline-v2.md` | Issue→Spec→Implement→PR 9단계 SSOT 파이프라인 (NEW) |
| `/swarm-refactor [scope] [strategy]` | `swarm-refactor.md` | 대규모 리팩토링 병렬 에이전트 분담 |
| `/parallel-dev [task]` | `parallel-dev.md` | 일상 작업 병렬화 (탐색+구현+검증) |
| `/explore-creative [goal]` | `explore-creative.md` | 모호한 목표로 창의적 해결책 탐색 |

## Workflows
- **New feature**: `/scaffold` -> `/usecase` -> `/test-unit-gen` -> `/coverage`
- **New feature (auto)**: `/feature-pipeline [name]` (위 워크플로우 자동화)
- **New feature (SSOT)**: `/feature-pipeline-v2 [name]` (9단계 OpenSpec 기반 파이프라인)
- **Spec design**: `/openspec-design [feature]` -> `/openspec-review` -> `/feature-pipeline-v2`
- **Release**: `/lint-fix` -> `/review` -> `/version-bump` -> `/changelog`
- **AI improvement**: `/groq analyze-prompt` -> `/groq optimize-tokens`
- **AI prompt optimization (NEW)**: `/prompt-opt analyze` -> `/prompt-opt compress` -> `/prompt-opt validate`
- **DB change**: `/db add-column` -> `/db schema-report` -> `/test-unit-gen`
- **DB migration (NEW)**: `/db-migrate-validate validate` -> `/db-migrate-validate dry-run` -> `flutter test`
- **Refactoring**: `/arch-check` -> `/provider-centralize` -> `/refactor-plan` -> `/widget-decompose`
- **Refactoring (swarm)**: `/refactor-plan` -> `/swarm-refactor [scope] [strategy]`
- **Widget decompose**: `/widget-decompose [file]` -> `/barrel-export-gen [dir]` -> `/riverpod-widget-test-gen [file]`
- **Overflow fix**: `/responsive-overflow-fix [file]` -> `flutter analyze` -> 디바이스 테스트
- **Color migration**: `/color-migrate [file]` -> `/lint-fix` -> `flutter test`
- **Dark mode audit (NEW)**: `/ui-dark-mode audit-theme` -> `/ui-dark-mode migrate-colors` -> `flutter test`
- **Provider audit**: `/provider-invalidation-audit` -> `/provider-invalidate-chain [trigger]` -> 코드 적용
- **Provider optimization (NEW)**: `/flutter-advanced audit-providers` -> `/flutter-advanced optimize-rebuilds`
- **Provider ref fix**: `/provider-ref-fix --dry-run` -> `/provider-ref-fix [path]` -> `flutter test`
- **DB recovery defense**: `/defensive-recovery-gen [trigger]` -> 코드 적용 -> 디바이스 테스트
- **DB recovery test**: `/db-state-recovery verify` -> `/db-state-recovery test-gen` -> `/db-state-recovery checklist`
- **Deep review**: `/swarm-review [path]` (보안+성능+아키텍처 병렬)
- **Safety audit (NEW)**: `/crisis-check audit` -> `/crisis-check validate-prompt` -> `/crisis-check test-scenarios`
- **Emotion analysis (NEW)**: `/emotion-analyze audit-accuracy` -> `/emotion-analyze enhance-categories` -> `/emotion-analyze test-sentiment`
- **CD troubleshoot**: `/fastlane-audit` -> `/cd-diagnose [run_id]` -> 수정 -> 재배포
- **Session end**: `/session-wrap` -> `/til-save [topic]` (TIL 메모리화)
- **Parallel development**: `/parallel-dev [task]` (탐색+구현+검증 병렬)
- **Creative exploration**: `/explore-creative [goal]` -> 선택 -> `/parallel-dev` 또는 `/feature-pipeline`
- **Test Quality Audit**: `/test-quality-review [path]` -> 수정 -> 재검증
- **PR Pre-check**: `/swarm-review [lib/]` + `/test-quality-review [test/]`
- **Feature Complete**: `/test-unit-gen` -> `/test-quality-review` -> `/coverage`
- **Systematic debugging**: `/debug analyze` -> 4단계 프로세스 -> 실패 테스트 작성 -> 수정
- **TDD workflow**: 테스트 작성 (RED) -> `/test-unit-gen` -> 구현 (GREEN) -> 리팩토링
- **Official docs lookup**: `/c7-flutter [topic]` -> 공식 패턴 확인 -> memories 참조
- **New pattern learning**: `/c7-flutter [topic]` -> 코드 적용 -> `/til-save [topic]`
