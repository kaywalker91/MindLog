---
paths: [".claude/skills/**", ".claude/rules/**"]
---
# Skill Workflows

스킬 조합 워크플로우 참조. 특정 작업에 맞는 스킬 체인을 확인하세요.

## Feature Development
**When:** 새 기능 요청 + 2개 이상 레이어(domain/data/presentation) 변경 예상
- **New feature**: `/scaffold` -> `/usecase` -> `/test-unit-gen` -> `/coverage`
- **New feature (auto)**: `/feature-pipeline [name]`
- **New feature (SSOT)**: `/feature-pipeline-v2 [name]`
- **Spec design**: `/openspec-design [feature]` -> `/openspec-review` -> `/feature-pipeline-v2`

## Release & Quality
**When:** "배포", "릴리스", "Play Store", "PR" 키워드 또는 main 브랜치 머지 직전
- **Release**: `/lint-fix` -> `/review` -> `/version-bump` -> `/changelog` -> `/release-unified [type]`
- **PR Pre-check**: `/swarm-review [lib/]` + `/test-quality-review [test/]`
- **Feature Complete**: `/test-unit-gen` -> `/test-quality-review` -> `/coverage`
- **Deep review**: `/swarm-review [path]`

## Refactoring
**When:** 범위 > 3파일 또는 > 50줄 변경, 아키텍처 패턴 변경 포함
- **Refactoring**: `/arch-check` -> `/provider-centralize` -> `/refactor-plan` -> `/widget-decompose`
- **Refactoring (swarm)**: `/refactor-plan` -> `/swarm-refactor [scope] [strategy]`
- **Widget decompose**: `/widget-decompose [file]` -> `/barrel-export-gen [dir]` -> `/riverpod-widget-test-gen [file]`
- **Color migration**: `/color-migrate [file]` -> `/lint-fix` -> `flutter test`
- **Overflow fix**: `/responsive-overflow-fix [file]` -> `flutter analyze` -> 디바이스 테스트

## Database
**When:** `_currentVersion` 증가 또는 `ALTER TABLE` / 새 테이블 추가 감지
- **DB change**: `/db add-column` -> `/db schema-report` -> `/test-unit-gen`
- **DB migration**: `/db-migrate-validate validate` -> `/db-migrate-validate dry-run` -> `flutter test`
- **DB recovery defense**: `/defensive-recovery-gen [trigger]` -> 코드 적용 -> 디바이스 테스트
- **DB recovery test**: `/db-state-recovery verify` -> `/db-state-recovery test-gen` -> `/db-state-recovery checklist`

## Provider Optimization
**When:** Provider 추가/변경/삭제 또는 "리빌드 최적화", "성능" 언급
- **Provider audit**: `/provider-invalidation-audit` -> `/provider-invalidate-chain [trigger]` -> 코드 적용
- **Provider optimization**: `/flutter-advanced audit-providers` -> `/flutter-advanced optimize-rebuilds`
- **Provider ref fix**: `/provider-ref-fix --dry-run` -> `/provider-ref-fix [path]` -> `flutter test`

## AI & Prompts
**When:** AI 응답 품질 이슈 언급 또는 Groq API 토큰 비용 최적화 필요
- **AI improvement**: `/groq analyze-prompt` -> `/groq optimize-tokens`
- **AI prompt optimization**: `/prompt-opt analyze` -> `/prompt-opt compress` -> `/prompt-opt validate`

## Performance & UI
**When:** "성능 이슈", "느림", "오버플로우", UI 컴포넌트 수정 (`lib/presentation/` 파일)
- **Performance audit**: `/perf audit-http-timeouts` + `/perf audit-image-cache` -> `/perf performance-report`
- **Dark mode audit**: `/ui-dark-mode audit-theme` -> `/ui-dark-mode migrate-colors` -> `flutter test`
- **Notification categorization**: `/notification-enum-gen [feature]` -> `/settings-card-gen [type]` -> `/test-unit-gen`

## Testing
**When:** 테스트 커버리지 부족(< 80%) 또는 TDD RED phase 시작
- **Test Quality Audit**: `/test-quality-review [path]` -> 수정 -> 재검증
- **TDD workflow**: 테스트 작성 (RED) -> `/test-unit-gen` -> 구현 (GREEN) -> 리팩토링

## Debugging
**When:** 테스트 실패, 런타임 에러, 스택트레이스 발생 또는 동일 버그 3회+
- **Systematic debugging**: `/debug analyze` -> 4단계 프로세스 -> 실패 테스트 작성 -> 수정
- **Parallel debugging**: `/debug [issue]`
- **Bug→Memory pipeline**: `/debug` -> 해결 -> `/troubleshoot-save [id]` -> `/til-save [topic]`
- **Troubleshoot search**: `/debug` Stage 1 시작 → `troubleshooting.json` 자동 검색 → 유사 이슈 참조

## CI/CD
**When:** GitHub Actions 실패, Fastlane 오류, 배포 파이프라인 이슈
- **CD troubleshoot**: `/fastlane-audit` -> `/cd-diagnose [run_id]` -> 수정 -> 재배포

## Parallel Development
**When:** 독립 작업 2개 이상 병렬 가능, 파일 수 > 3개, 복잡도 >= 0.7
- **Parallel development**: `/parallel-dev [task]`
- **Creative exploration**: `/explore-creative [goal]` -> 선택 -> `/parallel-dev` 또는 `/feature-pipeline`

## Mental Health (MindLog 전용)
**When:** 위기감지 로직 수정, SafetyBlockedFailure 관련 코드, 감정분석 정확도 이슈
- **Safety audit**: `/crisis-check audit` -> `/crisis-check validate-prompt` -> `/crisis-check test-scenarios`
- **Emotion analysis**: `/emotion-analyze audit-accuracy` -> `/emotion-analyze enhance-categories` -> `/emotion-analyze test-sentiment`

## Session Management
**When:** Context 70% 도달, 세션 종료, 중요 버그 해결 직후
- **Session end**: `/session-wrap` -> `/til-save [topic]` + `/troubleshoot-save [id]`
- **Official docs lookup**: `/c7-flutter [topic]` -> 공식 패턴 확인 -> memories 참조
- **New pattern learning**: `/c7-flutter [topic]` -> 코드 적용 -> `/til-save [topic]`
