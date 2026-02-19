# Parallel Agents

## 자동 트리거 조건
파일 수 > 3개 / 독립 작업 > 2개 / 리팩토링 범위 > 1 디렉토리 → 병렬 에이전트 사용

## 적합도
- **높음**: 코드 리뷰(보안/성능/아키텍처), 탐색, 테스트 작성, 파일별 리팩토링
- **중간**: 독립 모듈 구현, 복수 원인 버그 조사
- **낮음(순차)**: 의존성 체인, DB 마이그레이션, 단일 파일

## 주요 스킬
`/swarm-review`, `/parallel-dev`, `/swarm-refactor`, `/feature-pipeline`

## Agent Teams
토론/협업 필요 시: `~/.claude/rules/agent-teams-guide.md` 참조
