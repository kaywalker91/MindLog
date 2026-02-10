# Context Management Rules

**전역 규칙 참조**: `~/.claude/rules/context-auto-monitor.md`

## MindLog 프로젝트 전용 설정

### 비활성화된 MCP 서버
- Playwright (E2E 테스트 시에만 활성화)
  - 재활성화: `.claude/settings.json`에서 제거

### 세션 분리 권장
- 기능 구현 / 디버깅 / 리뷰 각각 별도 세션
- Context 70% 도달 시 `/compact` 또는 새 세션
