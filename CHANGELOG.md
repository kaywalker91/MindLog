# Changelog

All notable changes to MindLog will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.4.42] - 2026-02-11

### Fixed
- **Provider 무효화 버그 수정**:
  - 일기 생성/분석 후 `diaryListControllerProvider` 무효화 누락 수정
  - 두 번째 일기 작성 시 목록에 즉시 표시되지 않던 버그 해결
  - `DiaryAnalysisController.analyzeDiary()` 완료 후 `statisticsProvider` + `diaryListController` 함께 invalidate
  - Provider 무효화 체인 패턴 확립: 생성은 invalidate, 삭제는 낙관적 업데이트
- **Lint 수정**:
  - `prefer_const_constructors` 8개 수정 (테스트 파일)
  - `unnecessary_const` 5개 수정 (lint fix 부작용)

### Changed
- **UI/UX 더보기 패턴 복원** (MEMORY.md 2026-02-05 패턴 적용):
  - 복잡한 인라인 펼치기/바텀시트 분리 방식 제거 → 단일 더보기 방식으로 UX 일관성 확보
  - `EmpathyMessage`: 3줄 축약 → 4줄 기본 표시 + 하단 "전체보기/접기" 토글 버튼 추가
  - `EmotionInsightCard`: 주석 정리 및 포맷팅 개선
  - InkWell ripple + "자세히 보기" 힌트 + chevron 아이콘 패턴 권장

### Removed
- **불필요한 파일 제거**:
  - `lib/presentation/widgets/result_card/analysis_detail_sheet.dart` 삭제 (370줄)
    - 바텀시트 분리 방식 제거로 더 이상 사용하지 않음

### Added
- **FCM 통합 테스트**:
  - `test/integration/fcm_notification_flow_test.dart` 추가 (포그라운드/백그라운드/killed 상태 시나리오)
  - Data-only payload 및 notification payload 처리 검증
  - 개인화 메시지 빌드 로직 테스트
- **위젯 테스트**:
  - `test/presentation/widgets/result_card/emotion_insight_card_test.dart` 추가
  - `test/presentation/widgets/result_card/empathy_message_test.dart` 추가 (펼치기/접기 토글 검증)
- **배포 검증 가이드**:
  - `.claude/deployment-validation-guide.md` 추가 (4-level 검증 프레임워크)
  - MindLog 특수 검증 항목 포함 (SafetyBlockedFailure 무결성, FCM 알림 ID 충돌 체크)
- **구현 로그**:
  - `.claude/implementation-log-view-all-restoration.md` 추가 (더보기 패턴 복원 과정 기록)

### Technical Details
- **Architecture**:
  - Provider Invalidation Chain 패턴 문서화 (MEMORY.md)
  - DiaryListController는 AsyncNotifier → invalidate 없으면 캐시된 오래된 리스트 유지
  - 테스트 전략: `identical()` 사용한 Provider rebuild 검증
- **Test Coverage**:
  - 총 1,505개 테스트 (전체 통과)
  - 커버리지 50.2% (domain/data 레이어 별도 검증 필요)

---

## [1.4.41] - 2026-02-10

### Added
- **DevTools 관측성 강화**:
  - `AppProviderObserver` 신규 추가 (`lib/core/observability/app_provider_observer.dart`)
  - 디버그 모드 전용 Provider 상태 전이 로깅 (생성/업데이트/폐기/실패)
  - `assert()` 기반 zero overhead 구현 (프로덕션 빌드에 완전히 제거됨)
  - main.dart에 `ProviderContainer.observers` 등록
- **알림 진단 UI 추가**:
  - `NotificationDiagnosticWidget` 신규 추가 (600줄, Material 3 기반)
  - 설정 화면에서 알림 예약 상태, 정확한 알람 권한, 배터리 최적화, 시간대 실시간 표시
  - 권한 문제 발견 시 해결 액션 버튼 제공 (정확한 알람 설정, 배터리 최적화 해제)
  - 접기/펼치기 토글, 새로고침 버튼, 요약 배너 (정상/경고 tone)
- **주간 인사이트 가이드 다이얼로그**:
  - `WeeklyInsightGuideDialog` 신규 추가 (269줄)
  - 주간 감정 리포트 기능 소개 (매주 일요일 밤 8시 알림 안내)
  - "나중에" / "통계 보기" 액션 제공
  - mindcareAccent 기반 브랜딩 적용
- **테스트 추가** (8개 파일):
  - `app_provider_observer_test.dart`: ProviderObserver 동작 검증
  - `notification_diagnostic_widget_test.dart`: 진단 위젯 UI 테스트
  - `weekly_insight_guide_dialog_test.dart`: 가이드 다이얼로그 테스트
  - `diary_image_gallery_cachewidth_test.dart`: 이미지 갤러리 cacheWidth 검증
  - `fullscreen_image_viewer_nocache_test.dart`: 전체화면 뷰어 cacheWidth=null 검증
  - `image_picker_section_cachewidth_test.dart`: 이미지 피커 섹션 cacheWidth 검증
  - `character_banner_cachewidth_test.dart`: 캐릭터 배너 cacheWidth 검증
  - `groq_remote_datasource_test.dart`: HTTP timeout 동작 검증 테스트 추가

### Changed
- **DevTools 성능 최적화**:
  - `GroqRemoteDataSource`: HTTP POST 요청에 30초 timeout 추가 (vision/text analysis 모두)
  - 기존 `TimeoutException` 핸들러 활용 (Network Failure로 매핑)
- **Image cacheWidth 최적화**:
  - `DiaryImageGallery`, `ImagePickerSection`, `CharacterBanner`: 표시크기 × 3 (DPR 대응)
  - `MediaQuery.size == 0` guard 추가 (테스트 환경 대응)
  - cacheWidth 적용으로 메모리 사용량 감소 (고해상도 이미지 다운샘플링)
- **위젯 리팩토링 및 성능 개선**:
  - `emotion_calendar/day_cell.dart`: AnimationController 제거 → StatefulWidget 단순화 (131줄 → 재구성)
    - `SingleTickerProviderStateMixin` 제거, `_isPressed` state 기반 탭 애니메이션으로 전환
    - const 생성자 + == 연산자 오버라이드로 불필요한 리빌드 방지
  - `mindcare_welcome_dialog.dart`: IntrinsicHeight accent stripe 패턴 제거 (307줄 리팩토링)
    - Row(stretch) + Container(4px) → Container(decoration: Border(left)) 패턴으로 전환
    - RenderFlex overflow 위험 제거, 동적 콘텐츠 대응 개선
  - `emotion_linked_prompt_card.dart`: IntrinsicHeight 제거 (107줄 리팩토링)
  - `message_input_dialog.dart`: IntrinsicHeight 제거 (347줄 리팩토링)
  - `ai_character_sheet.dart`: cacheWidth 적용
  - `notification_section.dart`: 303줄 → 간소화 (진단 위젯 통합)

### Fixed
- **테스트 환경 대응**:
  - `MediaQuery.size.width == 0` 테스트 환경에서 cacheWidth 계산 오류 방지
  - `rawSize > 0 ? rawSize : null` guard 적용

### Docs
- **DevTools 개선 패턴 문서화**: `.claude/RESTART-CHECKLIST.md`, `.claude/verification-updates.md` 추가
- **Performance Expert 스킬 강화**: `docs/skills/performance-expert.md` 업데이트 (121줄 추가)
  - HTTP timeout 자동 감사 기능 추가
  - Image cacheWidth 자동 감사 기능 추가
  - 성능 리포트 생성 기능 추가

---

## [1.4.40] - 2026-02-09

### Fixed
- **FCM 마음케어 중복 알림 근본 수정**: Android 백그라운드/killed 상태에서 OS 자동 표시 + 핸들러 표시로 인한 이중 알림 해결
  - 서버(`fcm.service.ts`): `notification` 필드 제거 → `data`에 title/body 이동 (data-only payload)
  - iOS 호환: `apns.payload.aps.alert`에 title/body 별도 추가
  - `sendToTopic()`도 동일하게 data-only 전환 + APNS 설정 추가
  - 미사용 `ANDROID_CHANNEL_ID` import 제거
- **빈 알림 방어 3-Layer Defense**:
  - Layer 1: `FCMService.buildPersonalizedMessage()` — 빈 title/body를 `'MindLog'`/`getRandomMindcareBody()`로 대체
  - Layer 2: `firebaseMessagingBackgroundHandler` fallback — catch 블록에서도 빈 메시지 방어
  - Layer 3: `NotificationService.showNotification()` — 최종 guard (`safeTitle`/`safeBody`)
- **Background Isolate FCM 초기화 누락 수정**: 백그라운드 핸들러 내 `NotificationService.initialize()` 호출 추가
  - 미초기화 시 `MissingPluginException` → Android OS가 빈 알림 표시하던 문제 해결
- **클라이언트 data-first 읽기**: `message.data['title'] ?? message.notification?.title` (구/신 서버 하위 호환)
- **고정 Notification ID**: FCM 알림에 `fcmMindcareId = 2001` 상수 ID 사용 → 핸들러 중복 실행 시 덮어쓰기
- **main.dart 재스케줄링 전략 변경**: "스마트 재스케줄링(이미 예약된 알림 스킵)" → "항상 재스케줄"
  - `PendingNotificationRequest`에 `scheduledDate` 필드 없음 → 설정과 실제 불일치 확인 불가
- **notification_section.dart**: 중복 `SettingsDivider` 1개 제거

### Added
- **NotificationDiagnosticService** (`notification_diagnostic_service.dart` 신규):
  - 알림 권한, 예약 상태, 정확한 알람 허용, 배터리 최적화, 시간대 정보 수집
  - `NotificationDiagnosticData` 데이터 클래스 + `hasAnyIssue` 판별
- **알림 진단 UI 위젯** (`_NotificationDiagnosticWidget`):
  - 설정 화면 리마인더 섹션 하단에 항상 표시
  - 예약 알림 개수, 정확한 알람 허용 여부, 배터리 최적화 상태, 시간대 표시
  - FutureBuilder 기반 비동기 로딩 + 새로고침 버튼
- **Analytics breadcrumb 강화**:
  - `AnalyticsService.logReminderScheduled()`에 `scheduleMode`, `timezoneName` 파라미터 추가
  - `NotificationSettingsService.applySettings()`에서 스케줄 모드/시간대 자동 기록
- **테스트 7개 추가**:
  - `fcm_service_test.dart`: 빈 문자열 title/body 방어 테스트 4개 (null, empty, title-only empty, body-only empty)
  - `notification_service_test.dart`: 빈 title/body showNotification 방어 테스트 3개
  - `notification_settings_service_test.dart`: timezone 초기화 `setUpAll` 추가

### Changed
- **서버-클라이언트 FCM 페이로드 구조**: `notification` + `data` 혼합 → `data`-only (Android) + `apns.alert` (iOS)
- **`NotificationService.showNotification()` 시그니처**: `id` optional 파라미터 추가 (기존: timestamp 기반 동적 ID)
- **claude-mem 메모리 수출 스크립트**: API 엔드포인트 `/api/observation` → `/api/memory/save` 변경, `PROJECT_NAME` 추가

### Docs
- claude-mem Phase 1~2 문서: 평가 보고서, 수출 스크립트 가이드, Phase 완료 보고서

---

## [1.4.39] - 2026-02-07

### Fixed
- **테스트 동기화**: Phase 2 프로덕션 코드 변경에 맞춰 테스트 3개 수정
  - `notification_service_test.dart`: payload type `test_mindcare` → `mindcare` 정정
  - `mindcare_welcome_dialog_test.dart`: 새 다이얼로그 UI 반영 (제목, 아이콘, CBT 텍스트, 뷰포트 800x1400 확장)
  - `settings_sections_test.dart`: Cheer Me/마음케어 섹션 라벨 텍스트 동기화

### Added
- **CI/CD 개선**:
  - `.github/workflows/test-health.yml`: 테스트 실패 자동 감지 워크플로우 추가
  - `scripts/test-health.sh`: 테스트 실패 패턴 분석 스크립트
  - `scripts/githooks/`: Git 훅 디렉토리 구조 추가
  - `scripts/setup-hooks.sh`: Git 훅 설정 자동화 스크립트
- **빌드 스크립트 강화**:
  - `scripts/run.sh`: `build-appbundle`, `quality-gate` 명령어 개선
  - 환경별 빌드 파라미터 자동 주입 (`GROQ_API_KEY`, `ENVIRONMENT`)

### Changed
- **CD 워크플로우 개선**: `cd.yml`에 API 키 주입 검증 및 환경 변수 처리 강화

---

## [1.4.38] - 2026-02-07

### Added

#### 알림 차별화 Phase 2 — 감정 인식 알림 시스템
- **주간 인사이트 알림**: 매주 일요일 20:00 한 주간의 감정 리뷰 알림 (`NotificationService.scheduleWeeklyInsight()`)
  - `isWeeklyInsightEnabled` 설정 토글 (`NotificationSettings`, `PreferencesLocalDatasource`)
  - 4종 제목 + 4종 본문 랜덤 조합 (`NotificationMessages.getRandomWeeklyInsightMessage()`)
  - 알림 ID: 2002, 채널: `mindlog_mindcare`
- **인지 패턴 CBT 알림**: 일기 분석 시 인지 왜곡 감지 → 다음 날 08:00 인지 재구조화 메시지 전송
  - 4패턴(흑백사고/과일반화/감정적추론/당위적사고) × 3메시지 = 12개 CBT 풀
  - `NotificationService.scheduleNextMorning()` — 패턴 이름 기반 동적 ID (3001+)
  - `NotificationMessages.getCognitivePatternMessage()` — null-safe 패턴 매칭
- **EmotionAware 메시지 로테이션 모드**: `MessageRotationMode.emotionAware` 추가
  - 감정 점수 거리 기반 가중치: ≤1.0→3x, ≤3.0→2x, else→1x
  - `recentEmotionScore` 파라미터를 `applySettings()`/`selectMessage()`에 전파
  - `_selectEmotionAwareMessage()` — 누적 가중치 랜덤 선택 알고리즘
  - `PreferencesLocalDatasource` 직렬화/역직렬화 지원 (알 수 없는 문자열 → `random` 폴백)
- **감정 트렌드 서비스** (신규 파일):
  - `EmotionTrendService.analyzeTrend()` — gap/steady/recovering/declining 4종 분석 (264줄)
  - `EmotionTrendNotificationService.notifyTrend()` — 트렌드 기반 알림 전송 (159줄)
- **Safety Followup 서비스** (신규 파일):
  - `SafetyFollowupService.scheduleFollowup()` — 위기 감지 24h 후 안부 확인 (241줄)
  - 알림 ID: 2004, `SafetyBlockedFailure` 읽기 전용 (기존 위기 감지 로직 무수정)
- **Emotion Linked Prompt Card** (신규 파일):
  - 감정 연동 프롬프트 카드 위젯 (132줄, `result_card/emotion_linked_prompt_card.dart`)
- **1회성 예약 알림 API**: `NotificationService.scheduleOneTimeNotification()` / `cancelNotification()`
- **분석 후 알림 트리거**: `DiaryAnalysisNotifier._triggerPostAnalysisNotifications()` — `unawaited`로 비블로킹
- **주간 인사이트 설정 UI**: `notification_section.dart` 토글 + `NotificationSettingsController.updateWeeklyInsightEnabled()`
- **메시지 로테이션 모드 시트**: emotionAware 옵션 추가

#### 테스트 (33개+ 추가)
- 인지 패턴 CBT 메시지 테스트 12개 (패턴별 유효성, 빈 패턴, Mock Random, 불변성, 글자 수 제한)
- EmotionAware 가중치 테스트 11개 (거리별 가중치, 경계값 1.0/3.0, null 처리, 1-10 범위, 단일 메시지)
- 메시지 로테이션 모드 직렬화 테스트 8개 (random/sequential/emotionAware 왕복, 알 수 없는 모드 폴백)
- 주간 인사이트 설정 테스트 2개 (enabled/disabled Analytics 기록)
- EmotionTrend 서비스 테스트 (신규 파일)
- EmotionTrendNotification 서비스 테스트 (신규 파일)
- SafetyFollowup 서비스 테스트 (신규 파일)

#### 인프라/문서
- `CONTRIBUTING.md` — 기여 가이드 추가
- `LICENSE` 추가
- `README.ko.md` — 한국어 README 추가
- `.github/workflows/readme-sync.yml` — README 동기화 워크플로우
- `.github/scripts/` — CI 스크립트 디렉토리
- Skill 문서: `notification-enum-gen.md`, `settings-card-gen.md`, `test-agent-consolidate.md`, `troubleshoot-save.md`
- Skill catalog: `/crisis-check`, `/emotion-analyze`, `/troubleshoot-save`, `/suppress-pattern`, `/periodic-timer` 추가

### Changed
- GitHub Pages 스크린샷 경로 마이그레이션: `docs/assets/images/` → `assets/screenshots/v3/`
- `docs/index.html` 이미지 src 경로 8개 업데이트
- `NotificationSettingsService.applySettings()` 시그니처에 `recentEmotionScore` 파라미터 추가
- `NotificationSettingsService.selectMessage()`에 `recentEmotionScore` named 파라미터 추가
- `MessageRotationMode` enum에 `emotionAware` 값 추가 (기존 `random`, `sequential` 유지)
- `NotificationSettings`에 `isWeeklyInsightEnabled` 필드 추가 (기본값 `true`)
- 기존 테스트: `hasLength` 단언 → `greaterThanOrEqualTo` 완화 (주간 인사이트 로그 추가 대응)
- `result_card.dart`에 `EmotionLinkedPromptCard` import 추가
- `docs/index.html` CSS 캐시 버스팅 파라미터 유지

### Removed
- `docs/assets/images/` 중복 이미지 15개 삭제 (screenshots/v3로 통합)

---

## [1.4.37] - 2026-02-06

### Added
- **Cheer Me 알림 제목 개인화**: 기존 하드코딩 "Cheer Me" → 8개 제목 템플릿 풀 + `{name}` 치환
  - `_cheerMeTitles`: `'{name}님의 응원 메시지'`, `'오늘의 응원 한마디'` 등 8종
  - `getCheerMeTitle(userName)`: 랜덤 선택 + 이름 개인화 적용
  - 62.5% `{name}` 포함 → 이름 등록 사용자에게 따뜻한 경험 제공
- **알림 본문 이름 개인화**: `NotificationSettingsService.applySettings()`에 `userName` 파라미터 추가
  - 메시지 본문에 `applyNamePersonalization()` 적용
  - `{name}님, 힘내세요!` → `지수님, 힘내세요!` 변환
- **이름 변경 → 알림 자동 재스케줄링**: `UserNameController.setUserName()` 호출 시 `rescheduleWithMessages()` 자동 트리거
  - try-catch로 감싸 재스케줄링 실패가 이름 저장을 방해하지 않음
- **FCM getUserName DI**: `FCMService.initialize(getUserName:)` 콜백 주입
  - Riverpod 컨테이너에서 이름을 읽는 콜백을 main.dart에서 전달
  - null이면 SharedPreferences fallback 사용 (백그라운드 isolate 호환)
- **앱 시작 시 메시지+이름 전달**: `_rescheduleNotificationsIfNeeded()`에서 `selfEncouragementProvider.future` + `userNameProvider.future` 읽기
  - 미전달 시 빈 리스트 → 리마인더 취소되는 버그 수정

### Changed
- **MessageCard → ConsumerStatefulWidget**: `ref.watch(userNameProvider)`로 실시간 이름 반영
  - 메시지 본문에 `applyNamePersonalization()` 적용하여 `{name}` 치환 표시
- **NotificationPreviewWidget**: `previewTitle` 파라미터 추가
  - 미리보기에 `getCheerMeTitle()` 결과 표시 (기존: 하드코딩 `'Cheer Me'`)
- **SelfEncouragementScreen**: 미리보기 메시지/제목 모두 이름 개인화 적용

### Added (Tests — 22+개)
- **NotificationMessages 테스트 7개**: `cheerMeTitles` 목록 검증, `getCheerMeTitle()` 이름 치환/제거, 결정론적 선택, `{name}` 비율 검증, 전체 풀 개인화 검증
- **FCMService 테스트 3개**: `getUserName` DI 콜백 호출 확인, SharedPreferences fallback, `resetForTesting` 초기화
- **NotificationSettingsService 테스트 8개**: `userName` 본문 개인화 5개 + `cheerMeTitle` 제목 개인화 3개
- **UserNameController 테스트 4개**: 이름 변경 시 reschedule 트리거, 메시지 없을 때 skip, reschedule 실패 시 이름 저장 유지, 이름 삭제 시 reschedule
- **신규 테스트 파일 2개**:
  - `test/integration/name_propagation_test.dart` (244줄): 이름 전파 통합 테스트
  - `test/presentation/widgets/self_encouragement/message_card_test.dart` (225줄): MessageCard 위젯 테스트

---

## [1.4.36] - 2026-02-06

### Fixed
- **[C-1] 마음케어알림 Critical 수정**: FCM 백그라운드 핸들러 개인화 실패 시 Crashlytics 로깅 + 이중 try-catch 폴백 처리
- **[P1-1~P1-4] 알림 시스템 방어 코드 강화**:
  - `reminderHour`/`reminderMinute` 값에 `.clamp(0, 23)` / `.clamp(0, 59)` 방어 (`PreferencesLocalDataSource`)
  - `selectMessage()` 인덱스 경계값 방어 (`NotificationMessages`)
  - FCM 백그라운드 핸들러 Crashlytics 에러 로깅 추가 (`FCMService`)
- **이름 개인화 정규식 확장**: `{name}님을`, `{name}님이` 등 한글 조사(을/이) 패턴 매칭 추가
  - 정규식: `\{name\}님[,의은]?` → `\{name\}님[,의은을이]?`

### Refactored
- **[P2-4] NotificationSettingsService 메서드 추출**:
  - `_checkPermissions()`: 권한 확인 로직 분리 (platform channel 실패 시 안전한 기본값)
  - `_manageFcmTopics()`: FCM 토픽 구독/해제 로직 분리
  - `applySettings()` 메서드 복잡도 감소 (모듈화)
- **NotificationSettings 엔티티**: `adjustIndexAfterDeletion()` 코멘트 개선 (playlist-style wrap-around 설명)

### Added (Tests — 80개 이상)
- **NotificationSettingsService 테스트 48개**: applySettings 16개 + selectMessage 16개 + 엔티티 인덱스 15개 + 기타
- **SelfEncouragementController 테스트 32개**: CRUD, 순서 변경, 순차 재생, 인덱스 보정, 에러 전파
- **NotificationMessages 테스트 확장 6개**: 한글 조사(을/이) + 에지 케이스(한 글자, 이모지, {name} 포함 이름)
- **SelfEncouragementController 에러 전파 테스트 2개**: addMessage/deleteMessage repository 에러 전파
- **DB Recovery Service 테스트**: `db_recovery_service_test.dart` 신규
- **Validators 테스트**: `validators_test.dart` 신규
- **SOS Card 위젯 테스트**: `sos_card_test.dart` 신규

### Added (Docs & Tooling)
- **README 재구성**: 빅테크 스타일 751줄 → 177줄 압축
- **Superpowers 패턴 문서**: 디버깅, 브레인스토밍, 2단계 리뷰, TDD 워크플로우
- **마음케어알림 점검 보고서**: 85/100점 평가 + 이슈 트래킹
- **Flutter 공식 문서 가이드**: Context7 연동 스킬 (`c7-flutter.md`)
- **신규 스킬**: `feature-pipeline-v2.md`, `openspec-review.md`, `responsive-overflow-fix.md`, `test-quality-review.md`
- **OpenSpec 템플릿**: `docs/templates/` 디렉토리 추가
- **테스트 품질 리뷰 에이전트**: `.claude/agents/test-quality-review/`

### Dependencies
- `url_launcher_platform_interface: ^2.3.0` dev dependency 추가 (위젯 테스트 URL 런처 모킹용)

---

## [1.4.35]
### Added
- **Cheer Me - 나만의 응원 메시지 기능:**
  - SelfEncouragementMessage 엔티티 (최대 10개, 각 100자)
  - 메시지 로테이션 모드: random(무작위) / sequential(순차)
  - 응원 메시지 관리 화면: CRUD 작업 및 미리보기
  - NotificationSettings 확장: `rotationMode`, `lastDisplayedIndex`

### Improved
- **공감 메시지(EmpathyMessage) UI:**
  - 인라인 확장 패턴: AnimatedCrossFade로 부드러운 확장
  - TextPainter 기반 오버플로우 감지
  - 햅틱 피드백 적용
- **분석 결과 카드:**
  - EmotionInsightCard: 더보기 힌트 + chevron 아이콘
  - ResultCard InkWell ripple 효과
- **설정 화면 구조:**
  - Cheer Me / 마음 케어 알림 카드 분리
  - Provider select() 최적화

---

## [1.4.34]
### Added
- **시간대별 알림 메시지 시스템:**
  - TimeSlot enum: morning/afternoon/evening/night 4단계
  - 시간대별 메시지 풀 (제목 5개 + 본문 6개)
  - 이름 개인화 API: `applyNamePersonalization()`
  - 감정 레벨 기반 메시지 분기

### Improved
- **CI/CD 파이프라인:**
  - pub cache, generated code 캐싱
  - Setup Job 분리로 병렬 실행 효율화
  - GitHub Reporter 적용
- **코드 품질:** 209개 파일 린트 및 포매팅 정리

---

## [1.4.33]
### Added
- **최초 사용자 온보딩:**
  - 3단계 PageView 기반 OnboardingScreen
  - smooth_page_indicator 적용
  - Analytics 이벤트 추적

### Improved
- **SOS 카드 소프트 랜딩:**
  - 빨간색 → 따뜻한 amber 톤으로 변경
  - 순차적 페이드인 애니메이션
  - 공감 메시지 우선 표시
- **분석 대기 메시지 로테이션:** 2초 간격 안심 메시지 전환
- **공감적 에러 메시지:** 부드러운 톤의 에러 안내

---

## [1.4.32]
### Fixed
- **일기 삭제 기능 안정화:**
  - deleteImmediately() 즉시 삭제 구현
  - confirmDelete() 에러 복구 시 정렬 유지
  - DeleteDiaryDialog 리팩토링 (9줄 → 2줄)

### Improved
- **Statistics Layer:**
  - 미사용 메서드 제거: `getKeywordFrequency()`
  - endDate 정규화로 당일 통계 반영
- **테스트:** DiaryListController 테스트 456줄 추가

---

## [1.4.31]
### Added
- **인앱 업데이트 시스템:**
  - Google Play In-App Update (Flexible/Immediate)
  - 1시간 주기 자동 체크
  - 업데이트 해제 상태 저장

### Improved
- **설정 화면 위젯 분해:** 600줄 → 5개 파일
  - AppInfoSection, NotificationSection, EmotionCareSection 등
- **대형 위젯 분해:** 3개 위젯 → 14개 파일
- **SOS 긴급 전화번호:** 109 자살예방 통합번호 적용
- **테스트:** 28개 신규, 전체 903개 통과

---

## [1.4.30]
### Added
- **홈 화면 헤더 UX:**
  - 시간대별 인사말 ('좋은 아침이에요' 등)
  - HomeHeaderTitle 위젯

### Improved
- **뒤로가기 UX:** PopScope 적용, 앱 종료 확인 다이얼로그
- **go_router:** go() → push() 마이그레이션
- **DB 복구:** Provider 무효화 강화

---

## [1.4.29]
### Improved
- **통계 화면 위젯 분해:** 501줄 삭감, 4개 독립 위젯
- **알림 스케줄링:** Android 14+ Graceful 실패 처리
- **go_router:** Navigator.pop → context.pop() 마이그레이션
- **테스트:** app_router_test.dart 신규

---

## [1.4.28]
### Fixed
- **CI/CD:** Concurrency 설정으로 중복 배포 방지
- **Fastlane:** GROQ_API_KEY 환경변수 전달
- **Firebase Functions:** timeSlot 파라미터 추가, 데드 코드 제거

---

## [1.4.27]
### Added
- **저녁 마음케어 알림:** 아침 9시 + 저녁 9시 2회 알림
- **스크린샷 v3:** 9개 스크린샷 시맨틱 네이밍

### Improved
- **KST 시간대 버그 수정:** 명시적 KST 변환
- **CI/CD:** Fastlane 통합 배포

---

## [1.4.26]
### Improved
- **아키텍처:**
  - DI 계층 분리: `infra_providers.dart` → `core/di/`
  - main.dart 리팩토링: MaterialApp.router 전환
  - 15초 안전 타임아웃 적용
- **FCMService:** force unwrap 제거, APNS 재시도 3회
- **하드코딩 색상 중앙화:** AppColors에 16개 신규 상수

---

## [1.4.25]
### Added
- **DiaryListScreen 분해:** TappableCard, WriteFab, ExpandableText
- **DiaryDisplayExtension:** Entity 표시 로직 Extension 분리
- **Soft Delete & Undo 패턴:** 5초 Timer 후 실제 삭제

### Improved
- **go_router:** 레거시 Navigator.push 전면 교체
- **테마 색상:** 하드코딩 제거
- **한국어 텍스트 필터:** 4단계 NLP 파이프라인

---

## [1.4.24]
### Added
- **Isolate 기반 이미지 처리:** UI 스레드 블로킹 방지
- **RepaintBoundary:** 차트, 히트맵 리페인트 방지

### Improved
- **위젯 모듈화:**
  - SettingsScreen: 1,224줄 → 200줄 + 9개 서브 컴포넌트
  - ResultCard: 791줄 → 100줄 + 7개 서브 컴포넌트
  - EmotionCalendar: 414줄 → 100줄 + 3개 서브 컴포넌트
- **Provider 중앙화:** ui_state_providers.dart

---

## [1.4.23]
### Changed
- **Google Play 정책 준수:** READ_MEDIA_IMAGES 권한 제거
- **Android Photo Picker:** API 33+ 시스템 Photo Picker 사용
- **image_picker:** ^1.0.7 → ^1.2.1

---

## [1.4.22]
### Added
- **이미지 첨부 기능:**
  - 최대 5개 이미지 첨부
  - Groq Vision API 통합
  - 4MB 초과 시 자동 압축
- **새 위젯:** ImageService, ImagePickerSection, DiaryImageGallery

---

## [1.4.21]
### Added
- **감정 달력(EmotionCalendar):**
  - 월간 캘린더 UI (PageView 기반)
  - 식물 성장 이모지 시각화
  - 마이크로 인터랙션

### Improved
- **시간대별 푸시 알림:** 아침/저녁 메시지 분리
- **테마 색상:** gardenWarm1~5, gardenGlow, todayGlow

---

## [1.4.20]
### Improved
- **테스트 커버리지 92.5%:** 665개 테스트
- **core/theme 완전 테스트:** 0% → 95.7%

---

## [1.4.19]
### Improved
- **테스트 커버리지 확대:** 608개 → 665개

---

## [1.4.18]
### Added
- **알림 메시지 다양화:** 8x8 랜덤 조합
- **기본 알림 시간:** 21:00 → 19:00 (연구 기반)
- **DB 복구 시스템:** forceReconnect(), DbRecoveryService

---

## [1.4.17]
### Added
- **감정 정원(Emotion Garden):** 이모지 기반 시각화

---

## [1.4.16]
### Fixed
- **P0 Critical:** Circuit Breaker 레이스 컨디션, SQLite 파싱 안전성
- **P1 High:** Rate Limit 429 핸들링

### Improved
- **P3 Optimization:** 시스템 프롬프트 캐싱, SQLite 복합 인덱스

---

## [1.4.15]
### Added
- **감정 이모지 동적 애니메이션:** 감정별 차별화된 효과
- **UI 마이크로 인터랙션:** stagger 애니메이션, 카드 탭 피드백

### Improved
- **접근성:** Reduced Motion 지원 (WCAG 2.1 AA)

---

## [1.4.14]
### Added
- **유저 이름 기반 개인화:** AI가 이름을 불러줌
- **UserNameController:** Riverpod AsyncNotifier 기반

---

## [1.4.13]
### Improved
- **GitHub Pages:** 앱 테마와 색상 통일
- **스킬 문서 77% 압축**

---

## [1.4.12]
### Added
- **마음 케어 알림:**
  - 설정 토글, 환영 다이얼로그
  - Cloud Functions: 매일 오전 9시 자동 발송
  - FCM 토픽 발송 서비스

---

## [1.4.11]
### Added
- **트러블슈팅 문서 시스템:** GitHub Pages 게시판
- **알림 안정성:** Proguard keep 규칙

---

## [1.4.10]
### Changed
- **광고 ID 권한 제거**
- **Analytics:** 광고 ID 수집 비활성화

---

## [1.4.9]
### Added
- **알림 리마인더:** 시간 설정, 테스트 알림, 재부팅 복구
- **Firebase:** Analytics, Crashlytics, FCM

---

## [1.4.8]
### Added
- **AI 분석 고도화:**
  - 1차/2차 감정 분류
  - 에너지 레벨 측정
  - 단계별 행동 지침

### Improved
- **분석 결과 카드:** 감정 온도계, 미션 체크박스

---

## [1.4.7]
### Added
- **일기 개별/스와이프 삭제**
- **삭제 확인 다이얼로그**

---

## [1.4.6]
### Fixed
- **분석 안정성:** 실패/차단 상태 처리
- **로딩 애니메이션:** dispose 이후 오류 방지

### Added
- **서킷 브레이커:** 네트워크 보호 로직

---

## [1.4.5]
### Added
- **원격 변경사항 연동:** GitHub Pages JSON
- **이전 버전 변경사항:** 접이식 표시

---

## [1.4.4]
### Added
- **AI 캐릭터 이름:**
  - 온이 (따뜻한 상담사)
  - 콕이 (현실적 코치)
  - 웃음이 (유쾌한 친구)

---

## [1.4.3]
### Added
- **AI 캐릭터:** 3종 선택 가능
- **캐릭터별 응답 스타일**
- **일기별 캐릭터 고정 기록**

---

## [1.4.2]
### Improved
- **성능 최적화:**
  - KeyedSubtree + ValueKey로 60fps 유지
  - 히트맵 O(n²) → O(n)
  - DB 복합 인덱스
  - 통계 4-pass → 1-pass
  - autoDispose 메모리 관리

---

## [1.4.1]
### Added
- **앱 버전/변경사항 화면**
- **업데이트 확인 기능**
- **원격 업데이트 JSON 연동**

### Improved
- **로딩 온보딩:** 테마 컬러 기반 인디케이터
- **앱 크롬:** 그라데이션 AppBar
- **통계 화면:** '마음 달력' 섹션
- **스플래시:** 파스텔 그라데이션

---

## [1.4.0]
### Added
- **AI 감정 분석 고도화:**
  - 시간대별 맞춤 추천
  - 12가지 Few-shot 예시
  - 다국어 필터링
- **인앱 웹뷰**

### Improved
- **감정 분석 리포트:** 감정 온도계, 미션 체크박스
- **메인 화면:** Pull-to-refresh
- **애니메이션:** flutter_animate 적용

---

## [1.3.1]
### Changed
- **앱 아이콘 리뉴얼**
- **반응형 UI:** ResponsiveUtils, 가로모드/태블릿 개선
- **AI 프롬프트:** 8종 카테고리 세분화

---

## [1.3.0]
### Fixed
- **RenderFlex 오버플로우**
- **터치 타겟 44dp 보장**

### Added
- **활동 히트맵:** 월~일 전체 7일 표시
- **UI 가이드라인 문서**

---

## [1.2.0]
### Added
- **통계 화면 전면 개편:**
  - GitHub 스타일 활동 히트맵
  - 감정 추이 라인 차트
  - 키워드 태그 애니메이션
- **한글 필터링:** KoreanTextFilter

---

## [1.1.0]
### Added
- **통계 기능:** 감정 대시보드, 히트맵, 키워드 클라우드
- **새 화면:** 메인, 설정, 통계
- **테스트:** 핵심 로직 단위 테스트

---

## [1.0.1]
### Changed
- **AI 모델:** Groq (llama-3.3-70b-versatile)
- **보안:** API Key dart-define 주입
