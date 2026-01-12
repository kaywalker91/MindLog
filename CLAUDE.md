# MindLog - Claude Code Instructions

## 빌드 및 배포 주의사항

### Groq API Key 주입 (중요)

**우선순위**: `GROQ_API_KEY` > `DEV_GROQ_API_KEY` (debug only)

| 환경 | 변수 | 사용법 |
|------|------|--------|
| Production | `GROQ_API_KEY` | `--dart-define=GROQ_API_KEY=xxx` |
| Development | `DEV_GROQ_API_KEY` | debug 모드에서만 폴백 적용 |

**로컬 빌드:**
```bash
GROQ_API_KEY=your_key ./scripts/run.sh build-appbundle
```

**CI/CD 빌드 (cd.yml):**
```yaml
flutter build appbundle --release \
  --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }} \
  --dart-define=ENVIRONMENT=production
```

### CI/CD 파이프라인

| 워크플로우 | 트리거 | 단계 |
|-----------|--------|------|
| `ci.yml` | PR to main/develop | analyze → test → build-check |
| `cd.yml` | push to main | test → build-appbundle → Play Store (internal) |

**필수 GitHub Secrets:**
- `GROQ_API_KEY`, `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`
- `KEY_PASSWORD`, `KEY_ALIAS`, `PLAY_STORE_SERVICE_ACCOUNT_JSON`

### 관련 파일
| 파일 | 역할 |
|------|------|
| `lib/core/config/env_config.dart` | API Key 설정 및 폴백 로직 |
| `scripts/run.sh` | 로컬 빌드 스크립트 |
| `.github/workflows/ci.yml` | PR 검증 파이프라인 |
| `.github/workflows/cd.yml` | 배포 파이프라인 |

---

## 기술 스택

| 카테고리 | 기술 | 버전 |
|----------|------|------|
| Framework | Flutter / Dart | 3.38.x / ^3.10.1 |
| State | Riverpod | 2.6.1 |
| Database | SQLite (sqflite) | 2.3.3 |
| Firebase | Analytics, Crashlytics, FCM | 3.8.0+ |
| Routing | go_router | 17.0.1 |
| AI | Groq API | llama-3.3-70b-versatile |
| Chart | fl_chart | 0.68.0 |
| Animation | flutter_animate | 4.5.1 |

---

## 프로젝트 구조

```
lib/
├── core/           # 공통 (errors, config, services, theme, utils)
├── data/           # Repository 구현, DataSources, DTOs
├── domain/         # 순수 Dart (entities, repositories, usecases)
├── presentation/   # Riverpod Providers, Screens, Widgets
├── l10n/           # 다국어 지원 (ko, en)
└── main.dart
```

- **아키텍처**: Clean Architecture + Riverpod
- **AI 분석**: Groq API (llama-3.3-70b-versatile)
- **로컬 DB**: SQLite (스키마 버전 3)

---

## Claude Skills

### P0 - 핵심 개발 스킬 (자동 로드)
@docs/skills/test-unit-gen.md
@docs/skills/feature-scaffold.md
@docs/skills/groq-expert.md
@docs/skills/database-expert.md
@docs/skills/resilience-expert.md

### P1 - 주요 스킬

| 카테고리 | 명령어 | 설명 |
|----------|--------|------|
| **릴리스** | `/version-bump [type]` | 버전 업데이트 (patch/minor/major) |
| | `/changelog` | CHANGELOG.md 자동 업데이트 |
| | `/release-notes` | 릴리스 노트 생성 |
| **코드품질** | `/lint-fix` | 린트 위반 자동 수정 |
| | `/pre-commit` | Git pre-commit 훅 설정 |
| | `/coverage` | 테스트 커버리지 리포트 |
| | `/review [file\|PR]` | 코드 리뷰 |
| **생성** | `/usecase [action_entity]` | UseCase 클래스 생성 |
| | `/mock [repo]` | Mock Repository 생성 |
| **테스트** | `/widget-test [file]` | 위젯 테스트 생성 |
| | `/integration-test [flow]` | E2E 통합 테스트 생성 |
| **전문가** | `/firebase [action]` | Firebase 통합 관리 |
| | `/performance [action]` | 성능 분석/최적화 |
| | `/security [action]` | 보안 점검 |

### P2 - 보조 스킬

| 카테고리 | 명령어 | 설명 |
|----------|--------|------|
| **Firebase** | `/analytics-event [name]` | Firebase Analytics 이벤트 추가 |
| | `/crashlytics-setup` | Crashlytics 설정 |
| | `/fcm-setup` | FCM 푸시 알림 설정 |
| **문서** | `/api-doc` | API 문서 생성 |
| | `/architecture-doc` | 아키텍처 문서 생성 |

---

## 스킬 의존성 그래프

```
기능 개발:  /scaffold → /usecase → /test-unit-gen → /mock → /coverage
            └── /widget-test

릴리스:    /lint-fix → /review → /version-bump → /changelog → /release-notes

Firebase:  /firebase → /analytics-event, /crashlytics-setup, /fcm-setup

전문가:    /groq ↔ /resilience, /db → /test-unit-gen
```

---

## 주요 시나리오

**새 기능 추가:**
`/scaffold [name]` → `/usecase [action_entity]` → `/test-unit-gen` → `/mock` → `/coverage`

**릴리스 준비:**
`/lint-fix` → `/review` → `/version-bump patch` → `/changelog` → `/release-notes`

**AI 개선:**
`/groq analyze-prompt` → `/groq optimize-tokens` → `/resilience add-failure`

**DB 변경:**
`/db add-column [name]` → `/db schema-report` → `/test-unit-gen`

**Firebase 설정:**
`/firebase debug-firebase` → `/analytics-event [name]` → `/crashlytics-setup`

---

## 테스트 전략

| 유형 | 도구 | 목표 | 현황 |
|------|------|------|------|
| 단위 | flutter_test | ≥80% | 18개 파일 |
| 위젯 | flutter_test | 주요 화면 | 2개 파일 |
| 통합 | integration_test | 핵심 플로우 | 미구현 |

```bash
flutter test                    # 전체 테스트
flutter test --coverage         # 커버리지 수집
```
