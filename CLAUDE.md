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

## Claude Skills

프로젝트 맞춤형 스킬 참조:

### P0 - 핵심 개발 스킬
@docs/skills/test-unit-gen.md
@docs/skills/feature-scaffold.md

### P1 - 릴리스 자동화
@docs/skills/version-bump.md
@docs/skills/changelog-update.md
@docs/skills/release-notes.md

### P1 - 코드 품질
@docs/skills/lint-fix.md
@docs/skills/pre-commit-setup.md
@docs/skills/test-coverage-report.md

### P1 - 개발 생산성
@docs/skills/usecase-gen.md
@docs/skills/mock-gen.md
@docs/skills/analytics-event-add.md
