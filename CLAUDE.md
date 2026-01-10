# MindLog - Claude Code Instructions

## 빌드 및 배포 주의사항

### Groq API Key 주입 (중요)
- Flutter에서 환경 변수는 `--dart-define` 플래그로 빌드 타임에 주입해야 함
- `.env` 파일은 Flutter 빌드에서 자동으로 읽히지 않음

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

### 관련 파일
- `lib/core/config/env_config.dart` - API Key 정의
- `scripts/run.sh` - 로컬 빌드 스크립트
- `.github/workflows/cd.yml` - CI/CD 워크플로우

## 프로젝트 구조
- Clean Architecture + Riverpod 기반
- AI 분석: Groq API (llama-3.3-70b-versatile)

---

## Claude Skills

### P0 - 핵심 개발 스킬 (자동 로드)
@docs/skills/test-unit-gen.md
@docs/skills/feature-scaffold.md
@docs/skills/groq-expert.md
@docs/skills/database-expert.md
@docs/skills/resilience-expert.md

### P1/P2 - 온디맨드 스킬 (필요 시 `docs/skills/[파일].md` 참조)

| 카테고리 | 명령어 | 설명 |
|----------|--------|------|
| **릴리스** | `/version-bump [type]` | 버전 업데이트 (patch/minor/major) |
| | `/changelog` | CHANGELOG.md 자동 업데이트 |
| | `/release-notes` | 릴리스 노트 생성 |
| **코드품질** | `/lint-fix` | 린트 위반 자동 수정 |
| | `/pre-commit` | Git pre-commit 훅 설정 |
| | `/coverage` | 테스트 커버리지 리포트 |
| **생산성** | `/usecase [name]` | UseCase 클래스 생성 |
| | `/mock [repo]` | Mock Repository 생성 |
| | `/analytics-event [name]` | Firebase Analytics 이벤트 추가 |
| **전문가** | `/firebase [action]` | Firebase 통합 관리 |
| | `/performance [action]` | 성능 분석/최적화 |
| | `/integration-test [flow]` | E2E 통합 테스트 생성 |
| **테스트** | `/widget-test [file]` | 위젯 테스트 생성 |
| **문서** | `/api-doc` | API 문서 생성 |
| | `/architecture-doc` | 아키텍처 문서 생성 |
| **Firebase** | `/crashlytics-setup` | Crashlytics 설정 |
| | `/fcm-setup` | FCM 푸시 알림 설정 |
| **보안** | `/review [file]` | 코드 리뷰 |
| | `/security [action]` | 보안 점검 |

---

## 스킬 의존성 그래프

```
기능 개발:  /scaffold → /usecase → /mock → /test-unit-gen → /coverage
릴리스:    /lint-fix → /review → /version-bump → /changelog → /release-notes
전문가:    /groq ↔ /resilience, /db → /test-unit-gen
Firebase:  /firebase → /crashlytics-setup, /fcm-setup, /analytics-event
```

## 주요 시나리오

**새 기능 추가:** `/scaffold [name]` → `/usecase` → `/mock` → `/test-unit-gen` → `/coverage`

**릴리스 준비:** `/lint-fix` → `/review` → `/version-bump patch` → `/changelog` → `/release-notes`

**AI 개선:** `/groq analyze-prompt` → `/groq optimize-tokens` → `/resilience add-failure`

**DB 변경:** `/db add-column [name]` → `/db schema-report` → `/test-unit-gen`
