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
- **Skill triggers (P0~P5)**: See `.claude/rules/skill-workflows.md` (Auto-invoke Triggers section)
- **Agent Teams**: See `.claude/rules/parallel-agents.md`
- **Debugging & Error Handling**: See `.claude/rules/architecture.md`
- **Model strategy**: See `~/.claude/rules/model-selection-strategy.md`

## Known Issues
- Notification: 앱 시작 시 selfEncouragementProvider + userNameProvider 미전달 → 리마인더 취소 (v1.4.36 수정완료)
- 이름 개인화: `{name}` 패턴 제거 시 조사(님,의,은,을,이) + 후행 공백도 함께 제거 필요
- flutter_animate 위젯 테스트: pumpAndSettle() 절대 금지 → pump(500ms) x 4회
- A11y: Sprint 1+2 완료 (14개 화면 AccessibilityWrapper + theme-aware 색상) → Sprint 3 백로그: `memory/a11y-backlog.md`
