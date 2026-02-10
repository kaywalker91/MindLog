# Skill Workflows

스킬 조합 워크플로우 참조. 특정 작업에 맞는 스킬 체인을 확인하세요.

## Feature Development
- **New feature**: `/scaffold` -> `/usecase` -> `/test-unit-gen` -> `/coverage`
- **New feature (auto)**: `/feature-pipeline [name]`
- **New feature (SSOT)**: `/feature-pipeline-v2 [name]`
- **Spec design**: `/openspec-design [feature]` -> `/openspec-review` -> `/feature-pipeline-v2`

## Release & Quality
- **Release**: `/lint-fix` -> `/review` -> `/version-bump` -> `/changelog`
- **PR Pre-check**: `/swarm-review [lib/]` + `/test-quality-review [test/]`
- **Feature Complete**: `/test-unit-gen` -> `/test-quality-review` -> `/coverage`
- **Deep review**: `/swarm-review [path]`

## Refactoring
- **Refactoring**: `/arch-check` -> `/provider-centralize` -> `/refactor-plan` -> `/widget-decompose`
- **Refactoring (swarm)**: `/refactor-plan` -> `/swarm-refactor [scope] [strategy]`
- **Widget decompose**: `/widget-decompose [file]` -> `/barrel-export-gen [dir]` -> `/riverpod-widget-test-gen [file]`
- **Color migration**: `/color-migrate [file]` -> `/lint-fix` -> `flutter test`
- **Overflow fix**: `/responsive-overflow-fix [file]` -> `flutter analyze` -> 디바이스 테스트

## Database
- **DB change**: `/db add-column` -> `/db schema-report` -> `/test-unit-gen`
- **DB migration**: `/db-migrate-validate validate` -> `/db-migrate-validate dry-run` -> `flutter test`
- **DB recovery defense**: `/defensive-recovery-gen [trigger]` -> 코드 적용 -> 디바이스 테스트
- **DB recovery test**: `/db-state-recovery verify` -> `/db-state-recovery test-gen` -> `/db-state-recovery checklist`

## Provider Optimization
- **Provider audit**: `/provider-invalidation-audit` -> `/provider-invalidate-chain [trigger]` -> 코드 적용
- **Provider optimization**: `/flutter-advanced audit-providers` -> `/flutter-advanced optimize-rebuilds`
- **Provider ref fix**: `/provider-ref-fix --dry-run` -> `/provider-ref-fix [path]` -> `flutter test`

## AI & Prompts
- **AI improvement**: `/groq analyze-prompt` -> `/groq optimize-tokens`
- **AI prompt optimization**: `/prompt-opt analyze` -> `/prompt-opt compress` -> `/prompt-opt validate`

## Performance & UI
- **Performance audit**: `/perf audit-http-timeouts` + `/perf audit-image-cache` -> `/perf performance-report`
- **Dark mode audit**: `/ui-dark-mode audit-theme` -> `/ui-dark-mode migrate-colors` -> `flutter test`
- **Notification categorization**: `/notification-enum-gen [feature]` -> `/settings-card-gen [type]` -> `/test-unit-gen`

## Testing
- **Test Quality Audit**: `/test-quality-review [path]` -> 수정 -> 재검증
- **TDD workflow**: 테스트 작성 (RED) -> `/test-unit-gen` -> 구현 (GREEN) -> 리팩토링

## Debugging
- **Systematic debugging**: `/debug analyze` -> 4단계 프로세스 -> 실패 테스트 작성 -> 수정
- **Parallel debugging**: `/debug [issue]`
- **Bug→Memory pipeline**: `/debug` -> 해결 -> `/troubleshoot-save [id]`
- **Troubleshoot search**: `/debug` Stage 1 시작 → `troubleshooting.json` 자동 검색 → 유사 이슈 참조

## CI/CD
- **CD troubleshoot**: `/fastlane-audit` -> `/cd-diagnose [run_id]` -> 수정 -> 재배포

## Parallel Development
- **Parallel development**: `/parallel-dev [task]`
- **Creative exploration**: `/explore-creative [goal]` -> 선택 -> `/parallel-dev` 또는 `/feature-pipeline`

## Mental Health (MindLog 전용)
- **Safety audit**: `/crisis-check audit` -> `/crisis-check validate-prompt` -> `/crisis-check test-scenarios`
- **Emotion analysis**: `/emotion-analyze audit-accuracy` -> `/emotion-analyze enhance-categories` -> `/emotion-analyze test-sentiment`

## Session Management
- **Session end**: `/session-wrap` -> `/til-save [topic]` + `/troubleshoot-save [id]`
- **Official docs lookup**: `/c7-flutter [topic]` -> 공식 패턴 확인 -> memories 참조
- **New pattern learning**: `/c7-flutter [topic]` -> 코드 적용 -> `/til-save [topic]`
