# MindLog

AI 감정 일기 분석 앱 — Flutter + Clean Architecture + Riverpod

## Tech Stack

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter / Dart | 3.38.x / ^3.10.1 |
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
- **Skills**: `docs/skills/` — on-demand skill files (read when command is invoked)
- **Skill index**: `.claude/rules/skill-catalog.md`
