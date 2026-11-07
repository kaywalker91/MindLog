# Context Management Rules

**전역 규칙 참조**: `~/.claude/rules/context-auto-monitor.md`

## MindLog 프로젝트 전용 설정

### 비활성화된 MCP 서버
- Playwright (E2E 테스트 시에만 활성화)
  - 재활성화: 전역에서 플러그인이 꺼져 있으므로 `.claude/settings.local.json`의 `enabledPlugins`에 `"playwright@claude-plugins-official": true`를 넣고 새 세션 시작 (이 절차는 미검증)

### 세션 분리 권장
- 기능 구현 / 디버깅 / 리뷰 각각 별도 세션
- Context 70% 도달 시 `/compact` 또는 새 세션
