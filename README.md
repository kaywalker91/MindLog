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
  <a href="https://play.google.com/store/apps/details?id=com.mindlog.app">
    <img src="https://img.shields.io/badge/Google%20Play-Download-green?logo=google-play" alt="Google Play"/>
  </a>
  <img src="https://img.shields.io/badge/Platform-Android-blue?logo=android" alt="Platform"/>
  <img src="https://img.shields.io/badge/Privacy-Local%20Only-success" alt="Privacy"/>
  <img src="https://img.shields.io/badge/AI-Groq%20Llama%203.3-purple" alt="AI"/>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
  </a>
</p>

---

## Features

- 🧠 **AI Emotion Analysis** — Real-time emotion detection powered by Groq Llama 3.3
- 💬 **Empathetic AI Characters** — Personalized comfort messages from AI companions
- 🌱 **Emotion Calendar** — Visualize your emotional journey as growing plants
- 📊 **Statistics & Trends** — Emotion charts, keyword analysis, and weekly insights
- 📸 **Image Analysis** — Detect emotions in photos via Vision API
- 🔔 **Smart Notifications** — Morning encouragement & evening care across 2 channels
- 🔒 **Privacy-First** — 100% local storage, no cloud sync, no server uploads

---

## Recent Updates (v1.4.39)

- ✅ **1,384 tests** all passing — comprehensive test coverage ensuring stability
- 🔧 **Enhanced CI/CD** — automated test health monitoring and quality gates
- 📊 **Pre-deployment audit system** — 7-gate validation before every release
- 🛠️ **Improved build scripts** — streamlined environment-specific builds

<details>
<summary>Previous Updates (v1.4.38)</summary>

- 📬 **Weekly Insights** — Every Sunday evening, receive a summary of your emotional week
- 🧠 **Cognitive Pattern Detection** — AI detects cognitive distortions and sends CBT messages
- 🎯 **Emotion-Aware Messages** — Notifications prioritize messages matching your recent emotional state
- 💙 **Safety Follow-up** — 24-hour check-in after crisis detection
- 📈 **Emotion Trend Analysis** — Automatic insights when mood patterns change

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
| Storage | Local SQLite only — never leaves your device |
| AI Analysis | Anonymous text sent to Groq API, no personal data |
| Cloud Sync | None — no accounts, no servers |
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
| AI | Groq API | llama-3.3-70b-versatile |
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
