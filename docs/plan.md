# MindLog 아키텍처 결정 기록 (plan.md)

**버전**: v1.4 (현재 구현 기준)
**최종 업데이트**: 2026-02-24

> 이 파일은 MindLog의 핵심 아키텍처 결정과 그 배경을 기록합니다.
> 신규 기여자 온보딩 및 미래 기술 결정 시 참조하세요.

---

## 1. Clean Architecture 채택

### 결정
Presentation → Domain ← Data 3레이어 분리

### 이유
- 단일 개발자 프로젝트지만 AI 분석 로직(Domain)과 Groq API 구현(Data)의 테스트 독립성 확보
- Domain 레이어: 순수 Dart (Flutter 의존성 없음) → 빠른 단위 테스트
- 향후 Groq → 다른 AI 모델 교체 시 Data 레이어만 수정

### 레이어 경계 규칙
```
lib/
├── domain/    # Pure Dart (Flutter import 금지)
│   ├── entities/          # Diary, AnalysisResult, SelfEncouragementMessage
│   ├── repositories/      # Abstract interfaces
│   └── usecases/         # Business logic
├── data/      # Repository 구현, DataSources, DTOs
│   ├── datasources/       # SQLite, Groq API, SharedPreferences
│   ├── dtos/              # JSON/DB 변환 객체
│   └── repositories/      # Domain interface 구현
├── presentation/ # Flutter UI + Riverpod providers
│   ├── providers/
│   ├── screens/
│   └── widgets/
└── core/      # 공유 인프라 (errors, services, theme, utils)
    ├── errors/            # Failure sealed class
    ├── services/          # NotificationService, etc.
    ├── config/            # EnvConfig (API Key)
    └── theme/             # AppColors, AppTextStyles
```

### Port/Adapter 패턴 (domain ← core)
- Domain interface: `domain/repositories/notification_scheduler.dart`
- 구현: `core/services/notification_settings_service.dart`
- Provider 등록: `presentation/providers/infra_providers.dart`
- **중요**: Controller에서 infra_providers.dart 직접 import 금지 → `providers.dart` 경유

---

## 2. SQLite 선택 (Isar 마이그레이션 배경)

### 결정
`sqflite` (SQLite 2.3.3) 사용

### 배경
- 초기 PRD에 Isar 명시되어 있었으나 **빌드 복잡성 및 안정성 이슈로 SQLite로 전환**
- Isar: NoSQL, Full-text Search 지원이지만 Flutter 생태계에서 빌드 설정 복잡
- SQLite: 성숙한 생태계, 간단한 마이그레이션 전략, Android/iOS 내장 지원

### 스키마 관리
- 현재 버전: Schema v3
- 마이그레이션: `_onUpgrade()` → `ALTER TABLE` (DROP 금지, 하위 호환성 유지)
- `_onCreate`와 `_onUpgrade` 항상 동기화 유지

### 데이터 모델
```sql
-- 핵심 테이블
diaries (id, content, created_at, status, analysis_result_json, is_pinned, image_paths_json, is_secret)
self_encouragement_messages (id, content, created_at, display_order, category, written_emotion_score)
notification_settings (key-value store via shared_preferences)
secret_pin (flutter_secure_storage)
```

---

## 3. Riverpod 상태관리 패턴

### 결정
Riverpod 2.6.1 + Code Generation (riverpod_generator)

### Provider 계층
```
infra_providers.dart (core services)
    ↓
providers.dart (domain, data, usecase)
    ↓
feature_providers.dart (presentation)
```

### Controller 패턴
```dart
// AsyncNotifier 사용
@riverpod
class DiaryAnalysisController extends _$DiaryAnalysisController {
  @override
  FutureOr<AnalysisResult?> build() => null;

  Future<void> analyze(String content) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(analyzeDiaryUseCaseProvider).execute(content));
  }
}
```

### Provider 사용 규칙
- `ref.watch()`: build() 내부에서만
- `ref.read()`: 콜백/이벤트 핸들러에서만
- `.select()`: 최소 리빌드를 위해 적극 활용

### Provider Invalidation Chain
- 일기 생성/분석 완료 시: `statisticsProvider` + `diaryListControllerProvider` 동시 invalidate 필수
- 적용 위치: `diary_analysis_controller.dart:92-94`

---

## 4. SafetyBlockedFailure 불변 정책

### 결정
`SafetyBlockedFailure`는 코드에서 절대 수정/제거 불가

### 이유
- 위기 감지(자해/자살 암시) 핵심 로직
- 사용자 안전과 직결: 이 Failure가 누락되면 SOS 카드가 표시되지 않음
- Play Store/App Store 정책 준수: 정신건강 앱의 안전망 필수

### 관련 코드
```dart
// lib/core/errors/failures.dart
sealed class Failure { ... }
// ...
class SafetyBlockedFailure extends Failure { ... }  // 절대 수정 금지

// DiaryStatus.safetyBlocked → SOS 카드 렌더링 (분기 절대 제거 금지)
```

---

## 5. 알림 아키텍처

### 결정
FCM (data-only) + 로컬 알림(flutter_local_notifications) 혼합

### 알림 ID 할당
| ID | 알림 유형 | 방식 |
|----|----------|------|
| 1001 | CheerMe (일기 리마인더) | 로컬 |
| 2001 | FCM Mindcare | FCM data-only |
| 2002 | WeeklyInsight | 로컬 |
| 2004 | SafetyFollowup | 로컬 |
| 3001+ | 동적 CBT 알림 | 로컬 |

### FCM data-only 선택 이유
- FCM notification payload: OS가 직접 표시 → 개인화(`{name}`) 불가
- data-only: 앱이 직접 표시 처리 → 개인화 메시지 삽입 가능
- 배포 순서: 클라이언트 먼저 배포 → 서버 payload 형식 변경

### Background Isolate 처리
- FCM 백그라운드 핸들러에서 `NotificationService.initialize()` 필수 호출
- 미호출 시: MissingPluginException 발생

---

## 6. AI 분석 아키텍처

### Groq API 선택 이유
- Llama 3.3 70B: 한국어 이해 우수, JSON Mode 지원
- 비용 효율: 무료 티어 + 빠른 응답 속도 (< 3초)
- OpenAI 호환 API: 향후 모델 교체 용이

### 멀티모달 분석 (이미지 첨부)
- 이미지 있음: Groq Vision API (이미지 + 텍스트 분석)
- 이미지 없음: 텍스트 전용 분석
- 이미지는 base64 인코딩 후 전송 (Android Photo Picker TIL 참조)

### EmotionAware 메시지 선택 알고리즘
```
execute(settings, currentEmotionScore):
  if emotionAware mode:
    bucket = score≤3 → low, ≤6 → medium, >6 → high
    filtered = messages where writtenEmotionScore in bucket
    if filtered.isEmpty → fallback to all messages (random)
  else:
    return by rotation mode (random/sequential)
```

---

## 7. 테스트 전략

### 레이어별 TDD 요구사항
| 레이어 | TDD | 근거 |
|--------|-----|------|
| Domain (UseCase, Entity) | 필수 | 핵심 비즈니스 로직 |
| Data (Repository, DataSource) | 필수 | 데이터 무결성 |
| Presentation (Provider, Widget) | 권장 | UI 변경 빈번 |

### 알려진 테스트 패턴
- `flutter_animate` 위젯 테스트: `pump(500ms) × 4회` (pumpAndSettle 금지)
- timezone 테스트: 기대값도 `tz.TZDateTime.from(dt, tz.local)` 감쌈 (UTC CI 호환)
- Static Service 모킹: `@visibleForTesting static Function? override` + `resetForTesting()` (tearDown 필수)
- 개인화 테스트: 기대값도 `applyNamePersonalization(expected, null)` 적용

### 커버리지 목표
- Domain + Data: >= 80%
- Widget: >= 70%
- 생성 코드 제외 (*.g.dart)

---

## 8. 보안 아키텍처

### 비밀 일기 PIN
- 저장소: `flutter_secure_storage` (iOS Keychain / Android Keystore)
- PIN은 절대 SharedPreferences/SQLite에 저장하지 않음

### API Key 관리
- `--dart-define=GROQ_API_KEY=xxx` 빌드 타임 주입
- `lib/core/config/env_config.dart`: 런타임 접근 + fallback
- `.env` 파일 방식 미사용 (flutter_dotenv 미도입)

---

## 9. UI/UX 향상 전략 (2026-02-24 추가)

> **참조 REQ**: REQ-090 ~ REQ-096
> **원칙**: 한 번에 1개 화면씩 점진적 개선 / 테스트 커버리지 유지 / Clean Architecture 미침범

### 핵심 문제 진단

| 문제 | 심각도 | 영향 범위 |
|------|--------|---------|
| `AppTextStyles` 하드코딩 색상 → 다크 모드 텍스트 불가시 | 🔴 Critical | 전체 화면 |
| `darkTheme`에 `textTheme` 미정의 → Material3 기본값 폴백 | 🔴 Critical | 전체 화면 |
| 4개 분리된 컬러 시스템 (AppColors, Stats, Healing, CheerMe) | 🟡 High | 유지보수성 |
| 하드코딩 `Colors.white/black/grey` 잔존 | 🟡 High | 다크 모드 |
| DiaryListScreen 빈 상태(empty state) 없음 | 🟡 High | 첫 사용자 UX |
| 글자 수 카운터 없음 (DiaryScreen) | 🟢 Medium | 작성 UX |
| 로딩 상태 단순 CircularProgressIndicator | 🟢 Medium | 분석 대기 UX |

### 개선 전략 (4단계 Phase)

#### Phase 1: 테마 시스템 수복 (Foundation) — TASK-UI-001 ~ 003
**목표**: 다크 모드 렌더링 버그 수정. 모든 후속 개선의 기반.

- `darkTheme`에 완전한 `textTheme` 정의 추가
- `AppTextStyles`를 `static TextStyle Function(BuildContext)` 팩토리 패턴으로 교체 OR
  `ThemeData.textTheme`을 통해 접근하도록 가이드라인 업데이트
- 참조 패턴: `StatisticsThemeTokens`의 `ThemeExtension` 방식 (이미 올바름)

**결정**: `AppTextStyles`는 const 유지, `darkTheme`에 동등한 `textTheme` 정의.
색상은 `colorScheme.onSurface` / `colorScheme.onSurfaceVariant`로 오버라이드.

#### Phase 2: 하드코딩 색상 마이그레이션 (Consistency) — TASK-UI-004 ~ 005
**목표**: `Colors.white/black/grey` → theme-aware 값으로 전환.

- Grep으로 잔존 하드코딩 색상 목록 생성
- `.claude/rules/patterns-theme-colors.md` 매핑 테이블 기준 일괄 변환
- 우선순위: 다이얼로그 → 카드 → 배경 순

#### Phase 3: 핵심 화면 UX 개선 (Impact) — TASK-UI-006 ~ 009
**목표**: 사용자가 체감하는 주요 개선.

1. **DiaryListScreen**: 빈 상태 UI 구현 (Semantics 포함)
2. **DiaryScreen**: 글자 수 카운터 + 키보드 인셋 처리 개선
3. **DiaryScreen**: 분석 진행 단계 메시지 ("저장 중..." → "AI 분석 중..." → "완료")
4. **공통**: 접근성 Semantics 레이블 핵심 위젯에 추가

#### Phase 4: 마이크로인터랙션 (Polish) — TASK-UI-010 ~ 012
**목표**: 앱의 완성도/고급감 향상.

- `AppDurations` 상수 클래스 도입 (fast/normal/slow)
- 햅틱 피드백 일관화 (저장, 삭제, PIN 입력)
- Pull-to-refresh 색상 테마 일관성

### 테스트 전략
- Phase 1~2: `flutter analyze` + 다크 모드 스크린샷 비교 (Golden test)
- Phase 3: 위젯 테스트 — empty state, 글자수 카운터, 로딩 단계
- Phase 4: 단위 테스트 없음 (시각/햅틱은 통합 확인)

---

## 11. 비밀일기 아키텍처 (v1.4.44, 2026-02-19)

> 구현 상세: `memory/secret-diary-plan-2026-02-19.md`

### 핵심 설계 결정

**PIN 해싱 전략**
- 알고리즘: `SHA-256(rawPin + salt)` (4자리 숫자 PIN)
- salt: `Random.secure()` 32바이트 base64 → `flutter_secure_storage`에 별도 저장 (hash/salt 분리 키)
- 저장소: iOS Keychain / Android Keystore 전용 — SQLite·SharedPreferences 절대 금지

**격리 네비게이션**
- 라우팅 가드: Router-level redirect 미사용 → `SecretDiaryListScreen` 내부 `ref.listen(secretAuthProvider, ...)` 처리
- 세션 인증: in-memory only (앱 재시작/프로세스 종료 시 자동 잠금)
- 진입점: `DiaryListScreen` AppBar → `/secret-diary/` 라우트 계층 분리 (설정 화면 아님)

**통계 완전 제외**
- `getAllDiaries()` + `getAnalyzedDiariesInRange()` 모두 `WHERE is_secret = 0` 필터 적용

**DB 마이그레이션**
- Schema v6 → v7: `diaries.is_secret INTEGER DEFAULT 0` (ALTER TABLE)
- `idx_diaries_is_secret` 인덱스 추가

### 관련 파일 (핵심)

```
domain/usecases/secret/           # 6개 UseCase
data/datasources/local/secure_storage_datasource.dart
data/repositories/secret_pin_repository_impl.dart
presentation/providers/secret_auth_provider.dart    # in-memory 인증 상태
presentation/providers/secret_diary_providers.dart
```

---

## 10. 향후 기술 결정 필요 사항

| 결정 사항 | 현재 상태 | 검토 시점 |
|----------|----------|---------|
| 클라우드 동기화 방식 | 미결정 | 사용자 요청 발생 시 |
| iOS 배포 | 미구현 (Android 전용) | 수요 확인 후 |
| 다국어 지원 | 한국어 전용 | 해외 사용자 발생 시 |
| 인앱 결제 | 없음 | 지속 가능 모델 검토 시 |
