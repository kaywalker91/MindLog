<p align="center">
  <a href="README.ko.md">🇰🇷 한국어</a>
</p>

<p align="center">
  <img src="assets/icons/icon_mind_log.png" width="100" alt="MindLog"/>
</p>

<h1 align="center">MindLog</h1>
<p align="center">
  <strong>AI-powered emotional diary that understands and comforts you</strong>
</p>

<p align="center">
  <a href="https://github.com/kaywalker91/MindLog/actions/workflows/ci.yml">
    <img src="https://github.com/kaywalker91/MindLog/actions/workflows/ci.yml/badge.svg" alt="CI"/>
  </a>
  <a href="https://play.google.com/store/apps/details?id=com.mindlog.mindlog">
    <img src="https://img.shields.io/badge/Google%20Play-Download-green?logo=google-play" alt="Google Play"/>
  </a>
  <img src="https://img.shields.io/badge/Platform-Android-blue?logo=android" alt="Platform"/>
  <img src="https://img.shields.io/badge/Privacy-No%20Account-success" alt="Privacy"/>
  <img src="https://img.shields.io/badge/AI-Groq%20gpt--oss--120b-purple" alt="AI"/>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
  </a>
</p>

---

## Features

- 🧠 **AI Emotion Analysis** — Real-time emotion detection powered by Groq (gpt-oss-120b)
- 💬 **Empathetic AI Characters** — Personalized comfort messages from AI companions
- 🌱 **Emotion Calendar** — Visualize your emotional journey as growing plants
- 📊 **Statistics & Trends** — Emotion charts, keyword analysis, and weekly insights
- 📸 **Image Analysis** — Detect emotions in photos via Vision API
- 🔔 **Smart Notifications** — Morning encouragement & evening care across 2 channels
- 🔒 **Privacy-First** — No account, no cloud sync. Entries live on your device and go out only for the AI analysis itself.

---

## Recent Updates (v1.4.64)

- ✅ **1,814 tests** passing — the test suite is roughly the size of the production code
- 📝 **Diary auto-save** — in-progress entries and attached photos now survive backgrounding, back-press, and process death; restored via a banner, kept for 7 days
- ☎️ **Crisis hotline unified to 109** — Korea merged its suicide-prevention line in Jan 2024; all 6 call sites now match
- 🔐 **Removed unauthenticated admin endpoints** — 3 public Cloud Functions HTTP handlers deleted (they could push to every topic subscriber)
- 🖼️ **Groq Vision rate-limit handling** — one downscaled image per request, with text-only fallback when the token budget is exceeded

<details>
<summary>Previous Updates (v1.4.60 – v1.4.63)</summary>

- 🔒 **Privacy policy rewritten** — replaced a generic template with the app's actual data flow (Groq, Firebase, on-device storage)
- 🐛 **FCM `{name}` placeholder leak fixed** — traced past the client to the server-side message templates, where the real source was
- 🧪 **Non-vacuous regression tests** — new tests are now verified to fail against the pre-fix code before being accepted
- ♻️ **Health Check refactor** — 57 files restructured with no user-facing change
- 📏 **Repository-wide format cleanup** — 53 files realigned to the Dart 3.7+ tall-style formatter

</details>

---

## Screenshots

<p align="center">
  <img src="assets/screenshots/v3/02_diary_list.jpeg" width="200" alt="Diary List"/>
  <img src="assets/screenshots/v3/03_diary_write.jpeg" width="200" alt="Diary Write"/>
  <img src="assets/screenshots/v3/04_stats_calendar.jpeg" width="200" alt="Emotion Calendar"/>
  <img src="assets/screenshots/v3/08_ai_character.jpeg" width="200" alt="AI Character"/>
</p>

---

## Privacy

> **Your mind belongs to you.**

| Item | Policy |
|------|--------|
| Storage | Local SQLite on your device — no account, no cloud sync |
| AI Analysis | Your entry text, plus one attached photo, is sent to the Groq API (US) to be analyzed. No name, email, or account is attached. |
| Analytics | Firebase receives the emotion score, energy level, and the first 50 characters of the action suggestion — never the entry itself. |
| Deletion | Instant full deletion from Settings |

See [Privacy Policy](docs/legal/privacy-policy.md) for details.

---

## Tech Stack

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter / Dart | 3.38.x / ^3.10.1 |
| State | Riverpod | 2.6.1 |
| Database | SQLite (sqflite) | 2.3.3 |
| Firebase | Analytics, Crashlytics, FCM | 3.8.0+ |
| Routing | go_router | 17.0.1 |
| AI (text) | Groq API | openai/gpt-oss-120b |
| AI (vision) | Groq API | qwen/qwen3.6-27b |
| Charts | fl_chart | 0.68.0 |

---

## Architecture

```
┌──────────────────────────────────────────┐
│              Presentation                │
│     Providers (Riverpod) + Widgets       │
├────────────────────┬─────────────────────┤
│                    ▼                     │
│               Domain                     │
│    Entities, UseCases, Repo Interfaces   │
├────────────────────┬─────────────────────┤
│                    ▲                     │
│                Data                      │
│   Repo Impl, DataSources, DTOs          │
└──────────────────────────────────────────┘

Layer rules: presentation → domain ← data
(domain has zero external dependencies)
```

---

## Getting Started

### Prerequisites

- Flutter 3.38.x / Dart 3.10.x
- A [Groq API key](https://console.groq.com/)

### Setup

```bash
# Clone
git clone https://github.com/kaywalker91/MindLog.git
cd MindLog

# Install dependencies
flutter pub get

# Generate code (freezed, json_serializable, etc.)
dart run build_runner build --delete-conflicting-outputs

# Run
flutter run --dart-define=GROQ_API_KEY=your_key
```

### Build

```bash
# Release App Bundle
flutter build appbundle --release --dart-define=GROQ_API_KEY=your_key

# Release APK
flutter build apk --release --dart-define=GROQ_API_KEY=your_key
```

---

## Project Structure

```
lib/
├── core/           # Config, services, theme, constants, utilities
├── data/           # Repository implementations, DataSources, DTOs
├── domain/         # Pure Dart: entities, repository interfaces, use cases
├── presentation/   # Providers, Screens, Widgets
└── main.dart
```

### AI-assisted development, written down

This project is built with AI coding assistants, and the working agreement for that is
version-controlled rather than improvised per session. [`.claude/`](.claude/) holds the
architecture and testing rules the assistant must follow, the automation commands used for
recurring work, and the engineering notes written up after each non-obvious bug — including
why a regression test that passes can still be worthless.

---

## Testing

```bash
# Run all tests with coverage
./scripts/run.sh test

# Full quality gates (lint + format + test)
./scripts/run.sh quality
```

Coverage targets: unit ≥ 80%, widget ≥ 70%

---

## Contributing

Bug reports, feature requests, and pull requests are welcome!

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for full release notes.

---

## License

[MIT License](LICENSE) — Copyright (c) 2024 kaywalker91
