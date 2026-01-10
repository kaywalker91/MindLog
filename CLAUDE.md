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
@docs/skills/groq-expert.md
@docs/skills/database-expert.md
@docs/skills/resilience-expert.md

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

### P1 - 전문가 스킬
@docs/skills/firebase-expert.md
@docs/skills/performance-expert.md
@docs/skills/integration-test-gen.md

### P2 - Testing
@docs/skills/widget-test-gen.md

### P2 - Documentation
@docs/skills/api-doc-gen.md
@docs/skills/architecture-doc-gen.md

### P2 - Firebase
@docs/skills/crashlytics-setup.md
@docs/skills/fcm-setup.md

### P2 - Code Quality & Security
@docs/skills/code-reviewer.md
@docs/skills/flutter-security-expert.md

---

## 스킬 의존성 그래프

스킬 간의 연관 관계 및 추천 실행 순서:

```
┌─────────────────────────────────────────────────────────────────┐
│                    기능 개발 워크플로우                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  /scaffold ──────┬──────> /usecase ──────> /mock                │
│      │           │            │              │                   │
│      │           │            ▼              ▼                   │
│      │           └──────> /test-unit-gen <───┘                  │
│      │                        │                                  │
│      ▼                        ▼                                  │
│  /widget-test ◄────────── /coverage                             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    릴리스 워크플로우                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  /lint-fix ───> /review ───> /security ───> /pre-commit        │
│      │                           │              │                │
│      ▼                           ▼              ▼                │
│  /version-bump ───> /changelog ───> /release-notes              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    전문가 스킬 (독립 실행)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  /groq ─────────────────┬─────────────────> /resilience         │
│    │                    │                       │                │
│    ▼                    ▼                       ▼                │
│  AI 분석 최적화      /db 스키마 변경        에러 처리 강화        │
│                         │                                        │
│                         ▼                                        │
│  /firebase ◄──────── /analytics-event                           │
│      │                                                           │
│      ├───> /crashlytics-setup                                   │
│      └───> /fcm-setup                                           │
│                                                                  │
│  /performance ─────────────────────────────> 성능 최적화         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 의존성 관계

| 스킬 | 선행 스킬 | 후속 스킬 |
|------|----------|----------|
| `/scaffold` | - | `/usecase`, `/test-unit-gen`, `/widget-test` |
| `/usecase` | `/scaffold` | `/mock`, `/test-unit-gen` |
| `/test-unit-gen` | `/usecase`, `/mock` | `/coverage` |
| `/lint-fix` | - | `/review`, `/pre-commit` |
| `/review` | `/lint-fix` | `/security` |
| `/version-bump` | `/lint-fix`, `/review` | `/changelog` |
| `/changelog` | `/version-bump` | `/release-notes` |
| `/groq` | - | `/resilience` |
| `/db` | - | `/test-unit-gen` |
| `/firebase` | - | `/crashlytics-setup`, `/fcm-setup`, `/analytics-event` |

---

## 사용 시나리오

### 시나리오 1: 새 기능 추가 (전체 플로우)

```bash
# 1. 기능 스캐폴딩
> /scaffold notification

# 2. UseCase 생성 (필요시 추가)
> /usecase schedule_notification

# 3. Mock 클래스 생성
> /mock NotificationRepository

# 4. 단위 테스트 생성
> /test-unit-gen lib/domain/usecases/schedule_notification_usecase.dart

# 5. 커버리지 확인
> /coverage

# 6. 코드 리뷰
> /review lib/domain/usecases/schedule_notification_usecase.dart
```

### 시나리오 2: AI 분석 기능 개선

```bash
# 1. 현재 프롬프트 분석
> /groq analyze-prompt

# 2. 토큰 최적화
> /groq optimize-tokens

# 3. 새 기능 추가 (예: 인지 왜곡 감지)
> /groq add-feature cognitive_distortion

# 4. 에러 처리 강화
> /resilience add-failure analysis_timeout

# 5. 파서 테스트 생성
> /test-unit-gen lib/data/dto/analysis_response_parser.dart
```

### 시나리오 3: DB 스키마 변경

```bash
# 1. 컬럼 추가
> /db add-column is_favorite

# 2. 마이그레이션 검증
> /db schema-report

# 3. 쿼리 최적화
> /db optimize-query getDiariesByDateRange

# 4. 테스트 생성
> /test-unit-gen lib/data/datasources/local/sqlite_local_datasource.dart
```

### 시나리오 4: 릴리스 준비

```bash
# 1. 린트 수정
> /lint-fix

# 2. 코드 리뷰
> /review --pr 123

# 3. 보안 점검
> /security audit

# 4. pre-commit 설정 확인
> /pre-commit

# 5. 버전 업데이트
> /version-bump patch

# 6. 체인지로그 업데이트
> /changelog

# 7. 릴리스 노트 생성
> /release-notes
```

### 시나리오 5: Firebase 서비스 설정

```bash
# 1. Analytics 이벤트 추가
> /analytics-event diary_shared

# 2. Crashlytics 에러 기록 최적화
> /firebase configure-crashlytics

# 3. FCM 토픽 구독 설정
> /firebase configure-fcm --topic=announcements
```

### 시나리오 6: 성능 최적화

```bash
# 1. 렌더링 분석
> /performance analyze-rendering

# 2. 빌드 최적화
> /performance optimize-build

# 3. 메모리 분석
> /performance analyze-memory

# 4. 리스트 최적화
> /performance optimize-list

# 5. 종합 리포트
> /performance performance-report
```

---

## 스킬 트리거 명령어 요약

### P0 - 핵심 개발
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/scaffold [name]` | Clean Architecture 기능 생성 | `/scaffold notification` |
| `/test-unit-gen [file]` | 단위 테스트 생성 | `/test-unit-gen lib/domain/usecases/analyze_diary_usecase.dart` |
| `/groq [action]` | AI 프롬프트 최적화 | `/groq analyze-prompt` |
| `/db [action]` | DB 스키마 관리 | `/db add-column is_favorite` |
| `/resilience [action]` | 에러 처리 강화 | `/resilience add-failure rate_limit` |

### P1 - 릴리스 자동화
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/version-bump [type]` | 버전 업데이트 | `/version-bump patch` |
| `/changelog` | CHANGELOG 업데이트 | `/changelog` |
| `/release-notes` | 릴리스 노트 생성 | `/release-notes` |

### P1 - 코드 품질
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/lint-fix` | 린트 자동 수정 | `/lint-fix` |
| `/pre-commit` | pre-commit 훅 설정 | `/pre-commit` |
| `/coverage` | 테스트 커버리지 리포트 | `/coverage` |

### P1 - 개발 생산성
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/usecase [name]` | UseCase 생성 | `/usecase get_diary` |
| `/mock [repository]` | Mock 클래스 생성 | `/mock DiaryRepository` |
| `/analytics-event [name]` | Analytics 이벤트 추가 | `/analytics-event diary_shared` |

### P1 - 전문가 스킬
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/firebase [action]` | Firebase 서비스 관리 | `/firebase add-analytics-event diary_deleted` |
| `/performance [action]` | 성능 분석/최적화 | `/performance analyze-rendering` |
| `/integration-test [flow]` | 통합 테스트 생성 | `/integration-test diary_flow` |

### P2 - Testing & Documentation
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/widget-test [file]` | 위젯 테스트 생성 | `/widget-test lib/presentation/screens/diary_screen.dart` |
| `/api-doc` | API 문서 생성 | `/api-doc` |
| `/architecture-doc` | 아키텍처 문서 생성 | `/architecture-doc` |

### P2 - Firebase 상세
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/crashlytics-setup` | Crashlytics 설정 | `/crashlytics-setup` |
| `/fcm-setup` | FCM 설정 | `/fcm-setup` |

### P2 - Code Quality & Security
| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/review [file\|PR]` | 코드 리뷰 | `/review lib/presentation/screens/diary_screen.dart` |
| `/security [action]` | 보안 점검 | `/security audit` |
