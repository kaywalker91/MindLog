# MindLog

AI 감정 일기 분석 앱 — Flutter + Clean Architecture + Riverpod

## Tech Stack

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter / Dart (fvm) | 3.38.9 / 3.10.8 |
| State | Riverpod | 2.6.1 |
| Database | SQLite (sqflite) | 2.3.3 |
| Firebase | Analytics, Crashlytics, FCM | 3.8.0+ |
| Routing | go_router | 17.0.1 |
| AI | Groq API | llama-3.3-70b-versatile |
| Chart | fl_chart | 0.68.0 |

## Project Structure

```
lib/
├── core/           # Errors, config, services, theme, utils
├── data/           # Repository impl, DataSources, DTOs
├── domain/         # Pure Dart: entities, repositories, usecases
├── presentation/   # Providers, Screens, Widgets
└── main.dart
```

Architecture: Clean Architecture (domain/data/presentation) + Riverpod state management

## Rules & Skills

- **Rules**: `.claude/rules/` — architecture, build, workflow, layer-specific constraints
- **Skills**: `.claude/skills/` — on-demand skill files (read when command is invoked)
- **Skill index**: `.claude/rules/skill-catalog.md`

## Debugging Rules
- IMPORTANT: 에러 수정 전 반드시 근본 원인(root cause)을 먼저 분석하고 설명할 것
- YOU MUST: 수정 전에 관련 테스트를 먼저 실행하여 현재 상태 확인
- YOU MUST: 에러 로그의 스택트레이스를 끝까지 추적 (표면 증상이 아닌 원인 파악)
- 추측 기반 수정 금지 — 증거 없으면 "/debug analyze" 사용

## Error Handling Pattern
- Failure: sealed class (`lib/core/errors/failures.dart`)
  - NetworkFailure, ApiFailure, CacheFailure, ServerFailure
  - DataNotFoundFailure, ValidationFailure, ImageProcessingFailure
  - SafetyBlockedFailure (절대 수정 금지 — 위기 감지)
  - UnknownFailure (catch-all)
- UseCase: try { repo } on Failure { rethrow } catch { UnknownFailure }

## Agent Teams (Experimental)
- 활성화: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` (`~/.claude/settings.json` 글로벌 설정)
- 가이드: `.claude/rules/parallel-agents.md`
- 팀원 간 직접 통신, 공유 태스크 리스트, delegate 모드 지원
- 주의: 세션 복원 불가, 팀당 1세션, 중첩 팀 불가

## Skill Triggers (Auto-invoke)
### P0 Safety (즉시 실행)
- SafetyBlockedFailure / 위기감지 코드 수정 → `/crisis-check validate-prompt`

### P1 Architecture Guards (즉시 실행)
- 레이어 간 import 변경 → `/arch-check`

### P2 Domain Safety (즉시 실행)
- 알림 서비스 코드 수정 → `/notification-audit`
- Provider 추가/변경 → `/provider-invalidation-audit`
- `_currentVersion` 증가 + `_onUpgrade` 수정 → `/db-migrate-validate`

### P3 Quality Enforcement (강하게 제안)
- 새 UseCase/Repository 클래스 생성 → `/test-unit-gen [파일]` 제안 (TDD RED phase)
- `Colors.*` 또는 `Color(0x...)` 하드코딩 감지 → `/color-migrate [파일]` 제안

### P4 Knowledge Capture (제안)
- 버그 해결 완료 → `/troubleshoot-save`
- 버그 해결 + 새 학습 포인트 → `/til-save [topic]` 추가 제안
- TIL 파일 생성 후 → `/til-index-sync --fix` (INDEX.md 동기화)
- context 70% → `/session-wrap` (v2: Step 5.5 MEMORY.md / Step 6.5 progress / Step 7.5 TIL INDEX 포함)
- 태스크 구현 완료 직후 → `/task-done [TASK-ID] [summary]` (docs/tasks.md 자동 업데이트)

### P5 Workflow Optimization (참고 제안)
- Play Store 배포 직전 → `/release-unified [type]` 사용 권장

## Known Issues
- Notification: 앱 시작 시 selfEncouragementProvider + userNameProvider 미전달 → 리마인더 취소 (v1.4.36 수정완료)
- 이름 개인화: `{name}` 패턴 제거 시 조사(님,의,은,을,이) + 후행 공백도 함께 제거 필요
- flutter_animate 위젯 테스트: pumpAndSettle() 절대 금지 → pump(500ms) x 4회
- A11y: Sprint 1+2 완료 (14개 화면 AccessibilityWrapper + theme-aware 색상) → Sprint 3 백로그: `memory/a11y-backlog.md`
