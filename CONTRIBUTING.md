# Contributing to MindLog

Thank you for your interest in contributing to MindLog! This guide will help you get started.

> **Note:** When modifying `README.md`, please update `README.ko.md` accordingly (and vice versa).

## How to Contribute

1. **Bug Reports** — Open an [issue](https://github.com/kaywalker91/MindLog/issues) with reproduction steps
2. **Feature Requests** — Open an issue describing the use case and expected behavior
3. **Pull Requests** — Fork the repo, create a branch, and submit a PR

## Development Setup

```bash
# Prerequisites: Flutter 3.38.x, Dart 3.10.x

# 1. Clone
git clone https://github.com/kaywalker91/MindLog.git
cd MindLog

# 2. Install dependencies
flutter pub get

# 3. Generate code
dart run build_runner build --delete-conflicting-outputs

# 4. Get a Groq API key from https://console.groq.com/

# 5. Run
flutter run --dart-define=GROQ_API_KEY=your_key
```

## Quality Gates

Before submitting a PR, please ensure:

```bash
# Run all quality checks (lint + format + test)
./scripts/run.sh quality

# Or individually:
flutter analyze --fatal-infos
dart format --output=none --set-exit-if-changed .
flutter test
```

## Commit Convention

We follow [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Usage |
|--------|-------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation only |
| `refactor:` | Code restructuring |
| `test:` | Adding/updating tests |
| `chore:` | Build, CI, tooling |
| `ci:` | CI/CD changes |

## PR Process

1. Create a feature branch from `main`
2. Make your changes with clear, focused commits
3. Ensure all quality gates pass
4. Submit a PR with a description of what and why
5. Respond to review feedback

## Architecture

MindLog uses Clean Architecture with three layers:

- **domain/** — Entities, repository interfaces, use cases (pure Dart)
- **data/** — Repository implementations, data sources, DTOs
- **presentation/** — Providers (Riverpod), screens, widgets

**Layer rules:** `presentation → domain ← data` (domain has no dependencies)

## Code Style

- 2-space indent, trailing commas for multiline widgets
- `const` wherever possible, no `dynamic`
- Files: `snake_case.dart` / Types: `PascalCase` / Variables: `lowerCamelCase`

---

# MindLog 기여 가이드

MindLog에 관심을 가져주셔서 감사합니다!

## 기여 방법

1. **버그 리포트** — [이슈](https://github.com/kaywalker91/MindLog/issues)에 재현 방법과 함께 등록해 주세요
2. **기능 제안** — 이슈에 사용 사례와 기대 동작을 설명해 주세요
3. **Pull Request** — 저장소를 포크하고, 브랜치를 만든 후 PR을 제출해 주세요

## 개발 환경 설정

```bash
# 사전 요구: Flutter 3.38.x, Dart 3.10.x

# 1. 클론
git clone https://github.com/kaywalker91/MindLog.git
cd MindLog

# 2. 의존성 설치
flutter pub get

# 3. 코드 생성
dart run build_runner build --delete-conflicting-outputs

# 4. Groq API 키 발급: https://console.groq.com/

# 5. 실행
flutter run --dart-define=GROQ_API_KEY=your_key
```

## 커밋 컨벤션

[Conventional Commits](https://www.conventionalcommits.org/) 규칙을 따릅니다.

| 접두사 | 용도 |
|--------|------|
| `feat:` | 새 기능 |
| `fix:` | 버그 수정 |
| `docs:` | 문서 변경 |
| `refactor:` | 코드 구조 개선 |
| `test:` | 테스트 추가/수정 |
| `chore:` | 빌드, CI, 도구 |

## 주의사항

- `README.md`를 수정할 때는 `README.ko.md`도 함께 업데이트해 주세요 (반대도 동일)
- `SafetyBlockedFailure`는 절대 수정하지 마세요 (위기 감지 기능)
- PR 제출 전 `./scripts/run.sh quality`를 반드시 실행해 주세요
