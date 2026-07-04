# Changelog

All notable changes to MindLog will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.4.57] - 2026-07-04

### Changed (Groq AI Model Migration)

- **텍스트 감정 분석 모델 교체**: `llama-3.3-70b-versatile` → `openai/gpt-oss-120b` (Production 등급, 비용 효율 ↑, 한국어 성능 유지)
- **비전(이미지 분석) 모델 교체**: `meta-llama/llama-4-scout-17b-16e-instruct` → `qwen/qwen3.6-27b` (폐기 모델 대체, 유일한 비전 지원 후보)
- Groq 요청 파라미터 대응 (reasoning 모델 특성 반영):
  - `max_tokens` → `max_completion_tokens: 2048` (텍스트/비전 모두)
  - 텍스트 요청에만 `reasoning_effort: "low"`, `include_reasoning: false` 추가 (JSON 응답 잘림 방지 + 방어)
- 관련 코드/테스트/문서 동기화:
  - `app_constants.dart`, `groq_remote_datasource.dart`
  - `image_service_test.dart`
  - CLAUDE.md, `.claude/rules/architecture-layers.md`, `.claude/skills/groq-expert.md`
- 실 API 검증 완료 (에뮬레이터 + 실제 키): 3개 캐릭터 분석, 위기 감지(`is_emergency`) 경로, JSON 스키마, 한국어 응답 품질, truncation 없음 확인
- deprecation 대응: 7/17(비전), 8/16(텍스트) 마감 전 조기 릴리스로 미업데이트 사용자 보호

### Notes
- 캐시 키, 프롬프트, 파서 등은 모델 독립적이라 변경 불필요 (자동 무효화됨)
- Phase 2 (원격 설정) 는 후속 작업 예정

## [1.4.56] - 2026-07-04

### Improved (P1 Notification Defense Completion - P1-3/P1-4)

**P1-3: 알림 ID 중앙화 및 충돌 방어 강화 (id-conflict-checker 관점)**

- `NotificationService`에 모든 고정 ID 중앙 상수화:
  - `weeklyInsightId = 2002`
  - `safetyFollowupId = 2004`
  - `cbtBaseId = 3001`, `cbtIdRange = 1000`
  - `generateCbtNotificationId(patternName)` 헬퍼 추가 (결정적 해시 기반 생성).
- `scheduleWeeklyInsight()` 내부 `const weeklyInsightId = 2002` 제거, 중앙 상수 참조로 변경.
- `SafetyFollowupService.notificationId = NotificationService.safetyFollowupId`로 중앙 참조.
- `scheduleNextMorning()` (CBT 동적 ID) 에 collision defense 추가:
  - `getPendingNotifications()` 로 현재 예약 상태 조회.
  - 고정 ID (daily, fcm, weekly, safety)와 pending ID와 충돌 시 범위 내 perturbation (최대 20회).
  - pending 조회 실패 시 fail-open (스케줄링 우선).
- 테스트: `notification_service_test.dart` 에 ID 상수 고정값 검증, generator 결정성 테스트 추가.

**P1-4: 시나리오 커버리지 + 추가 레질리언스 (scenario-tester + resilience)**

- `_applyCheerMeQueueDiff()` 강화:
  - cancel 루프와 schedule 루프를 per-item try/catch 로 변경.
  - 실패 시 해당 항목만 스킵, 나머지 계속 처리.
  - kDebugMode 디버그 로그 + analyticsLog null 시 `CrashlyticsService.recordError` (reason: 'cheerme_*_partial_failure').
  - success 플래그 집계 유지.
- 테스트 보강:
  - `fcm_service_test.dart`: mindcare 메시지 `{name}` 패턴 절대 미포함 검증, low(1.0)/high(10.0) 경계 커버 테스트.
  - `notification_settings_service_test.dart`: "일부 스케줄 실패 시에도 나머지 진행" resilience 테스트 (override로 2번째 실패 시뮬).
  - 기존 경계값(null, empty, 3.0/3.1/6.0/6.1) 및 static reset 패턴 보강.
- NotificationMessages: mindcare 경로는 applyNamePersonalization 호출 안 함 (CheerMe만 허용) 검증 강화.

### Testing
- P1-3/P1-4 관련 신규/보강 테스트 다수 추가. notification_*_test, fcm_service_test, safety_followup_service_test 등 전체 green.
- `flutter analyze --fatal-infos` clean, format check 통과.
- `scripts/run.sh quality` 핵심 게이트 (analyze + format + test) 통과 (design-audit 는 pre-existing presentation color 이슈).

### Docs
- CHANGELOG.md, tasks/lessons.md, docs/til/FCM_IDEMPOTENCY_LOCK.md 에 P1 교훈 및 변경사항 기록.
- update.json (사용자 릴리스 노트), docs/index.html (GitHub Pages) 업데이트.

---

## [1.4.55] - 2026-07-02

### Added
- **일기 작성 시 과거 날짜 선택 및 백필 지원** (`lib/presentation/screens/diary_screen.dart`, `lib/domain/usecases/analyze_diary_usecase.dart`, `lib/domain/repositories/diary_repository.dart`, `lib/data/repositories/diary_repository_impl.dart`):
  - 작성 화면에 날짜 선택 ActionChip 추가 (기본값 "오늘"). 탭 시 DatePicker 표시 (하한: 5년 전, 상한: 오늘, 미래 선택 불가).
  - 라벨 동적 표시: "오늘" / "어제 (7월 1일)" / "6월 15일 (17일 전)".
  - `AnalyzeDiaryUseCase.execute()`에 `entryDate` 파라미터 추가. 내부 `_resolveCreatedAt()`에서:
    - 미지정 또는 오늘 → 현재 시각
    - 과거 날짜 → 선택한 날짜 + 현재 시:분:초 병합 (동일 날짜의 여러 일기 작성 순서 보존)
    - 미래 날짜 → `ValidationFailure` (도메인 레벨 차단)
  - `DiaryRepository.createDiary(createdAt)` 파라미터 지원. Repository/DataSource 레이어에서 `now()` 하드코딩 제거.
  - `getTodayDiaries()`에 `< 내일 0시` 상한 방어 추가.
  - DB 스키마 변경 없음 (기존 `createdAt` 필드 활용).

- **KST 타임존 유틸리티** (`lib/core/utils/time_utils.dart`): `getCurrentKstTime()`, `utcToKst()`, `formatIso8601Kst()`. `timezone` 패키지 기반 정확한 한국 시간 처리. 전용 단위 테스트 6건 추가.

### Changed
- Diary 생성 전체 파이프라인에 `entryDate` 지원 전파 (UI → UseCase → Repository → LocalDataSource).
- `DiaryScreen` 상태 관리에 `_screenEntryDay` / `_selectedDate` 도입으로 자정 넘김 시에도 기준일 유지.

### Testing
- 신규 테스트 대거 추가 및 기존 테스트 보강:
  - UseCase 6건 (날짜 해결 로직, 미래 차단, createdAt 병합)
  - Widget 테스트 3건 (날짜 칩 렌더링, DatePicker 상호작용, 과거 선택 시 createdAt 전달)
  - `time_utils_test.dart` 6건
  - 다수 provider / repository 테스트 리팩토링
- `scripts/run.sh test-affected`로 12개 affected 테스트 + 전체 스위트 (1,711건) green 확인.

### Chore / Infrastructure
- **CI 안정화**: `scripts/run.sh` 상단에 fvm shim 추가 (`flutter()` → `fvm flutter`). pre-push hook이 사용자의 PATH flutter(3.41.4 user-branch) 대신 프로젝트 fvm pinned `stable` (3.38.9)을 사용하도록 보호. ink_sparkle.frag 셰이더 디코드 실패 같은 환경 드리프트 버그 차단. (CLAUDE.md "flutter 대신 fvm flutter" 규약 준수)
- 세션/프로젝트 관리: `tasks/lessons.md`에 mocktail 관련 교훈 기록, `.gitignore` (.claude/tmp/, harness runs/), `.serena/project.yml` 갱신.

---

## [1.4.54] - 2026-05-02

### Added
- **Firebase Performance 측정 인프라** (`lib/core/observability/performance_traces.dart`, `pubspec.yaml`): `firebase_performance: ^0.10.0+11` 의존성 추가. `PerformanceTraces.measure()` 헬퍼로 `TimelineTask` + Firebase Trace를 동시에 래핑하는 추상화 도입. 4개 trace 상수 정의 — `db.getAllDiaries`, `groq.analyze`, `notification.applySettings`, `first.diaryList.paint`. `FirebaseService`에서 prod 환경에만 collection enable, debug는 `dart:developer` Timeline로 폴백.
- **Groq 응답 SQLite 캐싱** (`lib/data/datasources/local/sqlite_local_datasource.dart`, `lib/data/datasources/local/groq_cache_key.dart`): DB schema v7 → v8 마이그레이션으로 `groq_analysis_cache` 테이블 + `last_used_at` 인덱스 신설. `GroqCacheKey`는 `model + content_normalized + character + userName + imageHashes + promptVersion`을 SHA-256으로 해싱하며 content는 공백 압축 정규화. LRU 1000건 임계 도달 시 `last_used_at` 오래된 순으로 eviction. `is_emergency=true` 응답은 캐시 미저장 (위기 감지 매번 재평가). `PromptConstants.version` 상수로 프롬프트 변경 시 캐시 일괄 무효화 가능.
- **알림 큐 diff 알고리즘** (`lib/core/services/notification_diff_planner.dart`): 신규 91줄 순수 함수 모듈. `getPendingNotifications()`로 추출한 현재 예약 상태와 새 plan을 비교하여 cancel/reschedule 변경분만 산출. 동일 plan 재적용 시 platform channel 호출 0건 달성. ID는 일기 ID/날짜 기반 결정적 생성으로 재계산마다 동일.
- **DiaryListController.addOrUpdateDiary** (`lib/presentation/providers/diary_list_controller.dart`): 분석 후 메모리 상태 직접 갱신용 메서드. `DiaryAnalysisController`의 `invalidate()` 풀스캔 호출을 `addOrUpdateDiary(diary)`로 교체하여 분석 후 SQLite 풀스캔 0건.

### Changed
- **Cheer Me 7일 알림 큐 재구축** (`lib/core/services/notification_settings_service.dart`, `lib/core/services/notification_service.dart`, `lib/main.dart`): 단일 시점 reminder를 7일치 일별 큐로 재설계 (+1176/-322 lines). `requiresCheerMeQueueRebuild()` 게이트, `getPendingNotifications()` 노출, `getRandomMindcareBody()` 폴백 로직 정비. 자가응원 메시지 변경/이름 변경/시간 변경 등 트리거에서 큐 전체를 멱등적으로 재생성.
- **applySettings diff 통합** (`lib/core/services/notification_settings_service.dart`): `notification_diff_planner.diffCheerMeQueue()` 결과만 cancel/schedule. diff 결과가 비어있으면 `reminder_unchanged` analytics 이벤트 발행으로 캐시 적중 모니터링. `PerformanceTraces.measure(notificationApplySettings)` trace로 응답성 측정.
- **DiaryRepositoryImpl 캐시 통합** (`lib/data/repositories/diary_repository_impl.dart`): `analyze()`에서 cache lookup → miss 시 remote 호출 → 응답 저장 흐름 도입. 캐시 read/write 실패는 분석 흐름을 막지 않고 graceful degrade.
- **AnalysisResponseParser top-level 함수 추출** (`lib/data/dto/analysis_response_parser.dart`, `lib/data/datasources/remote/groq_remote_datasource.dart`): `parseAnalysisResponseString` top-level 함수로 분리. `groq_remote_datasource`는 4KB+ 응답을 `compute()`로 isolate 오프로드하여 메인 isolate jank 방지. `compute()` 실패 시 메인 isolate fallback 안전장치.

### Fixed
- **Groq retry 복원력 회복** (`lib/data/datasources/remote/groq_remote_datasource.dart`): 이전 리팩토링 과정에서 누락된 retry 로직을 복원. 5xx/타임아웃에 대한 지수 백오프 재시도가 다시 활성화되어 일시 장애 내성 회복. 테스트 472줄 전면 재구성으로 retry 시나리오 검증 강화.

### Testing
- **신규 +41 / 회귀 보강 +다수** (`test/`): 1696/1696 그린.
  - `notification_diff_planner_test.dart` 8건 (동일 plan 재적용 0-call, 변경분만 reschedule)
  - `notification_settings_service_test.dart` P1-1 회귀 4건 + 기타 +454줄
  - `groq_analysis_cache_test.dart` 7건 (CRUD + LRU + emergency 제외)
  - `groq_cache_key_test.dart` 9건 (해시 결정성, 정규화, 컴포넌트 변경 시 키 분리)
  - `diary_repository_impl_test.dart` cache 7건 + 추가 254줄
  - `diary_analysis_controller_test.dart` invalidate → addOrUpdateDiary 동작 갱신
  - `analysis_response_parser_test.dart` 3건 (top-level 함수 + 빈 입력)

### Chore
- **DB 마이그레이션 ADD-only 준수** (`lib/data/datasources/local/sqlite_local_datasource.dart`): v7 → v8 ALTER만 사용, DROP 없음 (`CLAUDE.md` 규약 준수). `_onCreate`/`_onUpgrade` 동기화 유지.
- **CI/CD 게이트**: `flutter analyze` clean, marionette_flutter info만 잔존.

---

## [1.4.53] - 2026-04-05

### Fixed
- **Self-Encouragement timeAware 모드 실제 구현** (`lib/core/services/notification_settings_service.dart`): `MessageRotationMode.timeAware` 선택 시 `messages[Random().nextInt(messages.length)]`로 random과 동일하게 동작하던 버그 수정. morning(5-11h)/afternoon(12-17h)/evening(18-4h) 시간대별 `timeCategory` 필터링 로직 추가, 매칭 메시지 없을 때 전체 풀 폴백 안전장치 포함. `selectMessage()`에 `DateTime? now` 파라미터 추가로 테스트 주입 가능.
- **emotionAware 이중 로직 통일** (`lib/core/di/infra_providers.dart`): `GetNextSelfEncouragementMessageUseCase` + 테스트 (485줄) 전량 삭제. Service가 유일한 메시지 선택 경로로 통일되어 emotionAware/timeAware 로직 분기가 한 곳에서만 관리됨. Provider 등록(`infra_providers.dart`)도 함께 제거.
- **freezed `@JsonKey` invalid_annotation_target 경고 해소** (`analysis_options.yaml`): freezed constructor parameter에 `@JsonKey(includeIfNull: false)` 사용 시 발생하는 경고를 `invalid_annotation_target: ignore`로 처리 (freezed 공식 권장 패턴).

### Added
- **timeCategory 입력 UI** (`lib/presentation/widgets/self_encouragement/message_input_dialog.dart`): `MessageInputResult` record 타입 도입. ChoiceChip 4종(전체/아침/오후/저녁) UI 추가. 수정 모드에서 기존 timeCategory 프리로드 지원. `SelfEncouragementController.addMessage()`/`updateMessage()`에 `{String? timeCategory}` optional 파라미터 추가.
- **시간대 뱃지 표시** (`lib/presentation/widgets/self_encouragement/message_card.dart`): `_timeCategoryIcon()`/`_timeCategoryLabel()` 헬퍼로 메시지 카드에 시간대 아이콘+라벨 뱃지 렌더링.
- **RotationModeSheet timeAware 옵션** (`lib/presentation/widgets/settings/message_rotation_mode_sheet.dart`): 기존 3개(random/sequential/emotionAware) RadioListTile에 timeAware용 '시간대 맞춤 선택' 항목 추가.

### Testing
- **selectMessage() 단위 테스트 220줄** (`test/core/services/notification_settings_service_select_message_test.dart`): timeAware 시간대 필터링 (morning/evening 경계값), 매칭 없을 때 폴백, emotionAware 가중치(거리 ≤1→3x) 및 null writtenScore 균등 가중치 검증 6개 케이스.
- **MessageInputDialog 위젯 테스트 17건** (`test/presentation/widgets/self_encouragement/message_input_dialog_test.dart`): timeCategory ChoiceChip 선택/해제, 수정 모드 프리로드, `MessageInputResult` record 반환값 검증, 빈 입력 유효성 검사 등.

---

## [1.4.52] - 2026-03-23

### Fixed
- **공감 메시지 4줄 잘림 제거** (`lib/presentation/widgets/result_card/empathy_message.dart`): `ResultCard`는 `diary_screen`, `diary_detail_screen` 모두 `SingleChildScrollView` 안에 렌더링되므로 내부 truncation이 불필요했음. `maxLines: 4` + `TextOverflow.ellipsis` + `AnimatedCrossFade` + `TextPainter` 측정 + "전체보기/접기" 토글 로직 전체 제거. `StatefulWidget` → `StatelessWidget` 전환으로 코드 90줄 → 62줄 단순화.

---

## [1.4.51] - 2026-03-15

### Added
- **Accessibility Sprint 3 — L1 AppAccessibility 유틸 점진적 도입** (`lib/core/accessibility/app_accessibility.dart`): 기존 AppAccessibility 유틸 중 `diaryItemLabel`, `dateLabel` 2종 적용에 그쳤던 구조에서 L1 레벨 유틸을 코드베이스 전반에 점진적으로 도입 시작. Sprint 3 백로그 항목과 연계.

### Fixed
- **Fastlane `Dir.chdir("..")` 경로 오류** (`android/fastlane/Fastfile`): Fastfile CWD는 `android/fastlane/`이므로 `Dir.chdir("..")` → `android/` 이동 — `pubspec.yaml` 미발견으로 CD 파이프라인 실패. `PROJECT_ROOT = File.expand_path("../..", __dir__).freeze` 상수로 교체하고 4곳 `Dir.chdir` + 3곳 `aab:` 경로 모두 절대경로 기반으로 수정.

### Changed
- **도메인 엔티티 freezed 패턴 전환** (`lib/domain/entities/`): `Statistics`, `NotificationSettings`, `Diary`, `SelfEncouragementMessage` 4개 엔티티를 freezed 패턴으로 전환 완료 (Phase 3-1). `copyWith` 자동 생성, `==`/`hashCode` 일관성 보장.
- **mocktail `extends Mock` 전환** (`test/`): 수동 Mock 클래스에서 `extends Mock` 패턴으로 전환 (Phase 1+2). talker 기반 로깅 인프라 추가로 테스트 디버깅 가시성 향상.

### Chore
- **riverpod_annotation + riverpod_generator 추가** (`pubspec.yaml`): `riverpod_annotation: ^2.6.1`, `riverpod_generator: ^2.6.3` 의존성 추가 (Phase 3-3). 신규 코드 전용 코드젠 기반 Provider 작성 경로 확보.

---

## [1.4.50] - 2026-03-14

### Fixed
- **Cheer Me {name}님 플레이스홀더 미치환 (4개 복합 원인)** (`lib/core/constants/notification_messages.dart`, `lib/presentation/providers/user_name_controller.dart`, `lib/main.dart`):
  - Fix D: `_nameWithSuffixPattern` 정규식 `[,의은을이]?` → `(?:[,의은을이]|에게|께)?` — 2자 조사 `에게`/`께` 미커버로 `님에게`, `님께` 잔류 해소
  - Fix C: `getRandomReminderTitle()` / `getRandomReminderMessage()`에 optional `[String? userName]` 파라미터 추가 + `applyNamePersonalization()` 호출 — 개인화 미적용 경로 해소
  - Fix B: `setUserName()`에서 `selfEncouragementProvider.valueOrNull ?? []`(AsyncLoading=null → 스킵) → `await selfEncouragementProvider.future`로 교체 — 로딩 완료 전 reschedule 누락 해소
  - Fix A: `main.dart` `hasReminder` 조기반환에 `hasPlaceholder` 체크 추가 — 이전 버전에서 bake-in된 `{name}` 리터럴 알림을 강제 재스케줄로 덮어쓰기
- **KoreanTextFilter 중복 동사 패턴 오탐** (`lib/core/services/korean_text_filter.dart`): `~하고 하기` 패턴을 `hasIssue` 트리거에서 제외하고 경량 교정 브랜치에 이동 — `filterMessage` length guard가 정상 교정 결과를 차단하는 문제 해소

### Testing
- **알림 개인화 테스트 확장** (`test/core/constants/notification_messages_test.dart`): `에게`/`께` 조사 커버리지 9개 케이스, `getRandomReminderTitle` userName 파라미터 5개 케이스 추가; 테스트 기대값 `reminderTitles contains` → `{name} 미포함` 검증으로 변경
- **UserNameController reschedule 테스트 수정** (`test/presentation/providers/user_name_controller_test.dart`): 빈 메시지 목록에서 reschedule 스킵 → 1회 호출 검증으로 변경 (Fix B 반영)

### Chore
- **CLAUDE.md 보호 파일 섹션 추가**: GitHub Pages (`docs/`) + GitHub Actions (`.github/workflows/`) 삭제 금지 목록 명시
- **메모리 파일 분할 재구성** (`.claude/memories/`): 7개 대용량 TIL 파일 → 13개 포커스 파일로 분할 (MEMORY.md 200줄 제한 준수)
- **진행 아카이브 정리** (`.claude/progress/archive/`): 누적된 분석/요약 파일 정리 → `.gitkeep` 유지

---

## [1.4.49] - 2026-02-27

### Added
- **디자인 토큰 시스템 확립** (`lib/core/theme/app_colors.dart`): Primary 팔레트를 스카이 블루(#87CEEB)로 정의; 텍스트용 `primaryDark`(#4A90B8, WCAG AA 충족), theme 경유 `primaryColor`(#7EC8E3) 삼각형 토큰 체계 수립 — 분산된 하드코딩 색상을 단일 소스로 통합
- **스플래시 화면 리디자인** (`lib/presentation/screens/splash_screen.dart`): `_entranceController`(800ms one-shot, easeOutBack) + `_loopController`(2500ms repeat/reverse) 이중 컨트롤러 아키텍처 도입; `Listenable.merge()` 기반 `AnimatedBuilder` 연결로 상태 관리 단순화; 디자인 토큰 마이그레이션 완료
- **접근성 Sprint 1+2 완료** (`lib/presentation/`): 14개 화면 전체 `AccessibilityWrapper(screenTitle:)` 추가; `fullscreen_image_viewer`, `mindcare_welcome_dialog`, `activity_heatmap` 등 theme-aware 색상 매핑(`Colors.black87→scrim.withValues()`, `Colors.white→onSurface`) 완료

### Fixed
- **Stack 내부 Column 좌측 쏠림** (`lib/presentation/screens/splash_screen.dart`): `Stack` 내부에서 `loose constraints`가 전파되어 `Column`이 자식 너비로 수축하는 현상 수정; `SizedBox(width: double.infinity)` 추가로 부모 너비 명시적 상속 적용
- **Zone mismatch 오류** (`lib/main.dart`): `runZonedGuarded` + `runApp` 병용 시 `WidgetsFlutterBinding` 등 binding 초기화가 outer zone에서 실행되어 발생하는 불일치 수정; `bindingInitializer`를 `runZonedGuarded` 콜백 내부로 이동

### Testing
- **스카이 블루 팔레트 테스트 기대값 갱신** (`test/core/theme/app_colors_test.dart`): Primary 토큰 변경에 따라 테스트 expected 값 일괄 업데이트; 색상 시스템 회귀 방지
- **`withAlpha` → `withValues` 기대값 갱신** (`test/`): Flutter 3.x deprecation에 따른 diagnostic 위젯 테스트 기대값 업데이트

### Chore
- **세션 자동화 파이프라인 강화** (`.claude/`): session-wrap v2 (MEMORY.md / progress / TIL INDEX 자동화), task-done 스킬, model-strategy 규칙, MCP 설정, 메모리 파이프라인 P1+P2 개선

---

## [1.4.48] - 2026-02-27

### Added
- **`AppDurations`** (`lib/core/theme/app_durations.dart`): 애니메이션 지속 시간 토큰 클래스 도입; `fast(200ms)`, `normal(300ms)`, `slow(500ms)` 상수 추가 — 분산된 Duration 리터럴을 단일 소스로 통합
- **`darkTheme` textTheme 완성** (`lib/core/theme/app_theme.dart`): `displayLarge`→`labelSmall` 전 범위 textTheme 정의; 공백으로 남아있던 스타일 모두 채움
- **빈 상태 화면** (`lib/presentation/screens/diary_screen.dart`): 일기 미작성 시 빈 상태 안내 위젯 추가 (TASK-UI-006)
- **글자수 카운터** (`lib/presentation/screens/diary_screen.dart`): 일기 입력 중 실시간 글자수 카운터 표시 (TASK-UI-007)
- **분석 단계 UI** (`lib/presentation/screens/diary_screen.dart`): 분석 중 단계별 진행상황 표시 (TASK-UI-008~009)
- **에이전트 명세 3종** (`.claude/agents/`): `a11y-audit`, `l10n-manager`, `notification-tester` 에이전트 spec 추가

### Fixed
- **FCM 마음케어 중복 알림** (`functions/src/services/fcm.service.ts`): Firebase Functions retry + 부분 실패 시 3회 중복 발송되던 문제를 Firestore `create()` 원자적 잠금(pre-lock 패턴)으로 해결; `acquireSendLock` / `completeSendLock` / `releaseSendLockOnFailure` 3-함수 패턴 도입 — fail-open → fail-safe 전환
- **라이트 전용 그라디언트** (`lib/presentation/widgets/`): `Colors.white` 기반 그라디언트가 다크모드에서 깨지던 문제 수정 (TASK-UI-013)
- **`withAlpha` → `withValues` 마이그레이션** (`lib/`): Flutter 3.x deprecation에 따라 `withAlpha()` → `withValues(alpha:)` 전환

### Changed
- **하드코딩 색상 토큰화** (`lib/presentation/`): `Colors.*`, `Color(0x...)` 직접 사용 → `AppColors.*` 테마 토큰 교체 (TASK-UI-004~005); 다크/라이트 양 모드 자동 대응

### Testing
- **FCM 백그라운드 핸들러 테스트** (`test/core/services/`): `notification != null` guard 로직 검증, data-only 메시지 처리 조건 커버; guard log 개선

### Chore
- **Skill 커맨드 래퍼 69개** (`.claude/commands/`): 모든 스킬에 대한 슬래시 커맨드 명세 파일 추가
- **스킬 자동 트리거 시스템 강화** (`.claude/rules/`): P0~P5 우선순위 레이어 기반 트리거 조건 명확화

---

## [1.4.47] - 2026-02-24

### Added
- **`ApplyNotificationSettingsUseCase`** (`domain/usecases/`): 알림 설정 적용 로직을 Domain UseCase로 분리; `NotificationSettingsController`에서 Service 직접 호출 제거 → 의존성 역전 원칙 완성
- **`NotificationScheduler` 추상 인터페이스** (`domain/repositories/notification_scheduler.dart`): Port/Adapter 패턴으로 알림 스케줄러를 Domain 계층으로 편입; `NotificationSchedulerImpl`이 어댑터로 `NotificationSettingsService`를 감쌈
- **EmotionAware 메시지 선택** (`GetNextSelfEncouragementMessageUseCase`): 최근 감정 점수 기반 레벨 필터링 (low≤3, medium 4-6, high>6) + 매칭 메시지 없을 시 전체 풀 랜덤 폴백; `recentEmotionScore` 파라미터 추가
- **`cancelNotificationOverride` + `resetForTesting()`** (`NotificationService`): 미초기화 환경(테스트)에서 `LateInitializationError` 우회용 `@visibleForTesting static Function? override` 패턴 추가
- **SDD 문서 트리오** (`docs/spec.md`, `docs/plan.md`, `docs/tasks.md`): REQ-001~083 요구사항 명세, 아키텍처 결정 기록(ADR), REQ 매핑 태스크 백로그 신규 작성; `sdd-workflow.md` 규칙 활성화
- **알림 중복 방지** (`NotificationService`, `splash_screen.dart`): 앱 시작 시 리마인더(ID 1001)가 이미 pending이면 재스케줄 skip; FCM 백그라운드 핸들러에서 `notification` 필드 있을 시 early-return → OS 표시 1회만 보장
- **`dailyReminderId` 공개 상수** (`NotificationService`): pending 체크 외부 접근용으로 visibility 확대

### Testing
- **DiaryScreen 위젯 테스트** (`test/presentation/screens/diary_creation_flow_test.dart`, 9개):
  - `_FirebaseFreeNotifier`: Firebase 없이 `analyzeDiary` 오버라이드 — 순수 Widget 테스트 가능
  - `_ControllableMock(Completer)`: Loading 상태 지속 제어 패턴
  - `devicePixelRatio=1.0 + physicalSize(800×2000)`: 버튼 viewport 확보
  - flutter_animate `delay:600ms` Timer 정리: `pump(700ms)` 패턴 확립 (memory/timer leak 방지)
  - `SafetyBlocked` → followup 알림 예약 검증 (`SafetyFollowupService.scheduleOneTimeOverride` static override)
- **StatisticsScreen 위젯 테스트** (`test/presentation/screens/statistics_screen_test.dart`, 6개):
  - loading / data / error / retry / period-tab / empty-data 6개 상태 전환 커버
  - `AnalyticsService._instance()` Firebase 미초기화 방어 (`try-catch`) — 테스트 환경 안정화
- **NotificationSchedulerImpl 통합 테스트** (`test/core/services/notification_scheduler_impl_test.dart`, 9개):
  - `apply()` → `applySettings()` 위임 end-to-end 검증
  - `recentEmotionScore` emotionAware 전파: single-message 선택, no-score fallback, empty-list skip
  - sequential 모드 wrap-around 및 nextIndex 진행 검증
- **총 1,623 테스트 통과** (신규 16개: TASK-001/002/003 완료)

### Fixed
- **FCM 마음케어 이중 알림** (`fcm_service.dart`): background handler에서 OS 직접 표시 + `showNotification()` 중복 호출 방지
- **앱 재시작 시 리마인더 중복** (`splash_screen.dart`): pending alarm 존재 시 재스케줄 skip; 재부팅 후는 정상 재스케줄
- **`prefer_const_constructors` lint** (`notification_scheduler_impl_test.dart:90`): `final` → `const`
- **dart format** 테스트 파일 3개 자동 포맷 적용

---

## [1.4.46] - 2026-02-20

### Fixed
- **timezone 테스트 CI 호환성** (`test/core/services/safety_followup_service_test.dart`):
  - `safety_followup_service_test.dart` — 기대값 DateTime을 `tz.TZDateTime.from(dt, tz.local)`로 감싸도록 수정
  - CI 환경(TZ=UTC)에서 Seoul 로컬 타임존 기준 예약 시각이 다르게 계산되던 테스트 실패 해소
  - 원인: `DateTime(2026, 2, 6, 10, 0).add(Duration(hours: 24))`는 UTC plain DateTime이어서 TZDateTime 비교 시 불일치

### Added
- **`test-tz` 빌드 명령어** (`scripts/run.sh`):
  - `TZ=UTC flutter test` 래퍼 — CI(UTC 서버)와 동일한 타임존 환경에서 로컬 테스트 실행
  - 사용법: `./scripts/run.sh test-tz [test-path]` — `--coverage` 자동 적용
  - 타임존 민감 테스트(알림 예약 시각, KST 날짜 경계) 사전 검증 용도

### Chore
- **`.gitignore` 개행 정규화**: 파일 말미 누락된 `\n` 추가 (POSIX 호환)

---

## [1.4.45] - 2026-02-19

### Added
- **StatisticsThemeTokens** (`lib/core/theme/statistics_theme_tokens.dart`): 통계 탭 전용 디자인 토큰 시스템 신규 추가
  - `ThemeExtension<StatisticsThemeTokens>` 기반으로 Light/Dark 모드 완전 분리
  - 40여 개 명명된 토큰: 카드·페이지 배경, 텍스트 계층(Primary/Secondary/Tertiary), AppBar 그라데이션, 내비게이션 바, 감정 달력, 차트 툴팁 등 전 영역 커버
  - `StatisticsThemeTokens.of(context)` 헬퍼로 어느 위젯에서나 O(1) 조회
- **`MindlogAppBarVariant` enum**: `defaultStyle` / `statistics` 두 변형 추가
  - `statistics` 변형: 라이트/다크 모드에 따라 그라데이션 색상·버블 투명도·타이틀 색상 자동 전환
- **통계 스크린 다크모드 전면 지원**: 통계 화면 전체가 SystemUI 다크모드와 완벽히 연동

### Changed
- **`AppTheme`** (`lib/core/theme/app_theme.dart`):
  - `extensions` 필드에 `StatisticsThemeTokens.light` / `.dark` 주입 — ThemeExtension 패턴 도입
  - `primaryDark` 색상 `#3A7BC8 → #5BA4C9` 미세 조정 (채도·밝기 보정)
- **`AppColors`** (`lib/core/theme/app_colors.dart`):
  - `statsTextPrimary` `#2C3E50 → #1F2A37` (명도 대비 강화)
  - `statsTextSecondary` `#7F8C9A → #4B5F72` (가독성 향상)
  - `statsTextTertiary` `#A8B5C4 → #617488` (힌트 텍스트 최소 대비 충족)
- **`StatisticsScreen`**: `AppColors` 직접 참조 → `StatisticsThemeTokens` 전환, `MindlogAppBarVariant.statistics` 적용
- **`MainScreen` NavigationBar**: `AppColors` 하드코딩 → `StatisticsThemeTokens` (navGradientTop/Bottom, navBorder, navShadow, navSelected/Unselected, navIndicator)
- **통계 위젯 일괄 토큰화** — 아래 위젯 모두 `AppColors` → `StatisticsThemeTokens` 마이그레이션 완료:
  - `StatisticsHeatmapCard` — isDark 분기·카드 그림자 토큰화
  - `_SummaryCard` / `_StreakCard` — 카드 배경·텍스트·스트릭 컬러 전환
  - `ChartCard`, `KeywordCard` — 카드 스타일 토큰화
- **`PinKeypadWidget`** (비밀일기): 반응형 레이아웃 개선
  - `isCompact` 분기 (screenWidth < 360px): padding·spacing·dot 간격 동적 조정
  - 카드 컨테이너 추가 (`BoxDecoration` 그림자+테두리) — 시각적 강조
- **비밀일기 화면 UI 개선** (`SecretDiaryUnlockScreen`, `SecretPinSetupScreen`): 패딩·폰트 사이즈 미세 조정

### Refactored
- **Skills 문서 구조 개편**: `docs/skills/` (70여 개 MD) → `.claude/skills/` 이동, 경로 단순화
  - `CLAUDE.md`, `.claude/rules/skill-catalog.md`, `skill-workflows.md`, `parallel-agents.md`, `workflow.md` 경로 참조 업데이트
  - 중복 규칙 통합 및 token 최적화 (~20% 절감)

### Tests
- `test/core/theme/statistics_theme_tokens_test.dart` 신규 추가 — ThemeExtension 등록·of() 조회·Light/Dark 값 검증
- `test/presentation/screens/secret_pin_setup_screen_test.dart` 신규 추가 — 2단계 PIN 입력 플로우 위젯 테스트
- `test/presentation/widgets/statistics/statistics_visual_states_test.dart` 신규 추가 — 통계 카드 다크모드 시각 상태 테스트
- `statistics_dark_mode_sections_test.dart` 확장 — 토큰 기반 색상 검증

---

## [1.4.44] - 2026-02-19

### Added
- **비밀일기 기능**:
  - 4자리 PIN 설정/인증 (SHA-256 해시 + salt, flutter_secure_storage 저장)
  - 비밀일기 목록 화면 (SecretDiaryListScreen) — 인증 해제 시 자동 잠금
  - PIN 잠금 해제 화면 (SecretDiaryUnlockScreen) — 3회 실패 시 초기화 링크
  - PIN 설정 화면 (SecretPinSetupScreen) — 2단계 확인 플로우
  - PIN 키패드 위젯 (PinKeypadWidget) — 오류 시 sin 파형 shake 애니메이션
  - 일기 목록에서 롱프레스 → "비밀일기로 설정" / "비밀 해제" 메뉴
  - AppBar `_SecretDiaryEntryButton` — PIN 설정 여부 감시 (hasPinProvider)

### Changed
- **DB 마이그레이션 v7**: `diary` 테이블에 `is_secret` 컬럼 추가
- **통계 제외**: 비밀일기는 통계/히트맵에서 완전 제외
- **비밀 해제 버그 수정**: 비밀 해제 후 일반 목록에 즉시 반영 (`ref.invalidate(diaryListControllerProvider)`)

---

## [1.4.43] - 2026-02-13

### Added
- **Healing Color Schemes 시스템**:
  - `healing_color_schemes.dart` 신규 추가: `mutedTeal`, `pastelComfort` 2종 힐링 테마
  - `cheer_me_section_palette.dart` 신규 추가: Cheer Me 추천 영역 전용 팔레트 (13개 색상 역할 정의)
  - Light/Dark 모드 대응 완료
  - Material 3 ColorScheme 기반 설계
- **Cheer Me 프리셋 템플릿**:
  - 5개 카테고리 추가 (아침 다짐, 자기 위로, 감사 확인, 성장 인정, 과거의 나에게)
  - 각 카테고리당 4개 프리셋 메시지 (총 20개)
  - 가로 스크롤 카테고리 칩 UI
  - 선택 시 자동 입력 필드 채우기
  - 햅틱 피드백 및 애니메이션 전환
- **접근성 문서화**:
  - `CHEER_ME_SECTION_ACCESSIBILITY_CHECKLIST.md` 추가
  - WCAG 대비 요구사항 (4.5:1) 체크리스트
  - 뷰포트/텍스트 스케일 호환성 가이드
- **포트폴리오 문서**:
  - `PORTFOLIO.md` (한글), `PORTFOLIO_EN.md` (영문) 추가
  - 프로젝트 개요, 주요 기능, 아키텍처, 개발 하이라이트

### Changed
- **app_theme.dart**:
  - `healingColorScheme()` 메서드 추가 (Cheer Me 모달 전용 팔레트 반환)
  - `defaultHealingPaletteMode` 상수 추가 (`HealingPaletteMode.mutedTeal`)
- **message_input_dialog.dart** (대규모 리팩토링):
  - 프리셋 템플릿 UI 추가 (카테고리 칩 + 추천 카드)
  - Theme 통합: Light 모드에서 healing color scheme 자동 적용
  - 수정 모드에서는 프리셋 숨김 (입력 필드만 표시)
  - 스크롤 가능 영역 + 고정 버튼 레이아웃

### Added (Tests)
- `app_theme_test.dart`: Healing color scheme 메서드 검증 (+24줄)
- `cheer_me_section_palette_test.dart`: 팔레트 색상 무결성 테스트 (신규)
- `healing_color_schemes_test.dart`: ColorScheme 완전성 검증 (신규)
- `message_input_dialog_test.dart`: 프리셋 템플릿 위젯 테스트 (신규)

### Technical Details
- **Color System Architecture**:
  - 3-tier palette: Base theme → Healing schemes → Section palette
  - Context-aware theme switching (modal-scoped)
  - Material 3 semantic color roles 준수
- **UX Patterns**:
  - Chip selection: background + 1dp border + 6px blur shadow (alpha 0.10)
  - State differentiation: color + weight + shadow
  - Minimum touch target: 48dp (accessibility compliance)

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
