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
| AI | Groq API | openai/gpt-oss-120b |
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

## Build Commands

```bash
# 품질 게이트 (lint + format + test) — PR 전 필수
./scripts/run.sh quality

# 개별 실행
./scripts/run.sh test          # 전체 테스트 + 커버리지
./scripts/run.sh lint          # flutter analyze
./scripts/run.sh format        # dart format

# 릴리스 빌드 (GROQ_API_KEY 필수)
GROQ_API_KEY=your_key ./scripts/run.sh build-appbundle

# 코드 생성 (freezed / riverpod_annotation 변경 후)
fvm dart run build_runner build --delete-conflicting-outputs
```

> `flutter` 대신 `fvm flutter` 사용. `GROQ_API_KEY`는 `--dart-define`으로 주입 (`.env` 미사용).

## Arch Constraints

- `presentation → domain` 참조만 허용 (data 직접 참조 금지)
- `domain`: 순수 Dart — Flutter import 금지
- `data → domain` 참조만 허용 (presentation 참조 금지)
- UseCase: `execute()` 단일 메서드, Exception 캐치 후 Failure rethrow
- `SafetyBlockedFailure` 절대 수정·삭제 금지 (위기 감지 핵심)
- DB 스키마 변경: `_currentVersion` +1, `_onUpgrade` + `_onCreate` 동기화, DROP 금지

## Protected Files (삭제 금지)

> ⚠️ 아래 파일들은 프로젝트 운영에 필수적이며 **절대 삭제하지 않는다**.
> 리팩토링, 정리, cleanup 작업 시에도 이 목록에 있는 파일은 제외한다.

### GitHub Pages 사이트 (`docs/`)

GitHub Pages 소스 디렉토리. `https://github.com/kaywalker91/mindlog` 레포의 `/docs` 폴더로 퍼블리시된다.

| 파일 | 역할 | 삭제 금지 이유 |
|------|------|--------------|
| `docs/index.html` | 메인 랜딩 페이지 (앱 소개, 기능, 스크린샷) | 공개 마케팅 사이트 진입점 |
| `docs/troubleshooting.html` | 트러블슈팅 가이드 페이지 | JSON 인덱스 기반 동적 이슈 가이드 |
| `docs/style.css` | 전체 페이지 통합 스타일시트 | index + troubleshooting 양쪽에서 사용 |
| `docs/troubleshooting.json` | 트러블슈팅 이슈 인덱스 데이터 | troubleshooting.html이 동적 로드 |
| `docs/update.json` | 버전별 업데이트 정보 | 앱 업데이트 히스토리 표시용 |

### GitHub Actions 워크플로우 (`.github/`)

CI/CD 파이프라인 및 자동화 스크립트. 삭제 시 PR 검증·배포·문서 동기화가 전부 중단된다.

| 파일 | 역할 | 삭제 금지 이유 |
|------|------|--------------|
| `.github/workflows/ci.yml` | PR 검증 파이프라인 (lint·test·build) | PR 머지 전 품질 게이트 |
| `.github/workflows/cd.yml` | Play Store 배포 자동화 | main 푸시 → Internal Track 자동 배포 |
| `.github/workflows/readme-sync.yml` | README 동기화 검증 | README.md ↔ README.ko.md 헤더 일치 보장 |
| `.github/workflows/test-health.yml` | 테스트 상태 모니터링 | 테스트 건강도 추적 |
| `.github/scripts/check-readme-sync.sh` | README 동기화 검증 셸 스크립트 | readme-sync.yml 워크플로우 의존 |

## Known Issues
- Notification: 앱 시작 시 selfEncouragementProvider + userNameProvider 미전달 → 리마인더 취소 (v1.4.36 수정완료)
- 이름 개인화: `{name}` 패턴 제거 시 조사(님,의,은,을,이) + 후행 공백도 함께 제거 필요
- flutter_animate 위젯 테스트: pumpAndSettle() 절대 금지 → pump(500ms) x 4회
- A11y: Sprint 1+2 완료 (14개 화면 AccessibilityWrapper + theme-aware 색상) → Sprint 3 백로그: `memory/a11y-backlog.md`
