# Current Progress

## 현재 작업
- 알림 기능 차별화 Phase 2 **완료** — 커밋 대기

## 완료된 항목 (2월 6일)

### 알림 기능 차별화 Phase 2 ✅ (전체 완료)

#### Wave 1 (독립 — 완료)
- [x] P2-1: EmotionTrendService — gap/steady/recovering/declining 감지
- [x] P2-3: 주간 감정 인사이트 알림 — scheduleWeeklyInsight (일요일 20:00)
- [x] P2-5: SafetyFollowupService — 24h 팔로업 (ID 2004, Critical)
- [x] P2-7: SelfEncouragementMessage 엔티티 확장 (category, writtenEmotionScore, emotionAware enum)

#### Wave 2 (의존성 — 완료)
- [x] P2-2: EmotionTrendNotificationService — 4가지 트렌드별 메시지 풀
- [x] P2-4: 인지 패턴 CBT 메시지 — 4패턴 x 3메시지 + scheduleNextMorning
- [x] P2-6: EmotionLinkedPromptCard UI — 감정 연동 자기대화 프롬프트
- [x] P2-8: emotionAware 메시지 선택 — 가중치 기반 (≤1→3x, ≤3→2x, else 1x)

#### 통합 (완료)
- [x] DiaryAnalysisNotifier: safetyBlocked→SafetyFollowup, cognitivePattern→CBT, analyzed→EmotionTrend
- [x] NotificationSettingsController: weeklyInsightEnabled toggle, recentEmotionScore 전달
- [x] Settings UI: 주간 인사이트 토글, 감정 맞춤 모드 라디오, ModeLabel 3종
- [x] ResultCard: EmotionLinkedPromptCard 통합
- [x] PreferencesLocalDataSource: emotionAware 직렬화

#### 테스트 (완료)
- [x] EmotionTrendService 테스트 — 33개 (gap/steady/recovering/declining + 우선순위 + 경계값)
- [x] SafetyFollowupService 테스트 — 22개 (스케줄링/중복방지/취소/메시지풀)
- [x] EmotionTrendNotificationService 테스트 — 28개 (트렌드별 알림/채널/메타데이터)
- [x] emotionAware + 주간 인사이트 + 인지 패턴 CBT 테스트 — 34개
- [x] NotificationMessages 확장 테스트 (인지 패턴, 가중치 분포)
- [x] 기존 테스트 수정 (mock updateWeeklyInsightEnabled, analyticsLog 유연화)

### 알림 기능 차별화 Phase 1 ✅ (커밋 완료)
- [x] 알림 채널 분리, UI accent, CBT 메시지 구조화, 프리셋 템플릿, Welcome 개선, 탭 라우팅

## 변경 파일 요약 (Phase 2)

### 신규 생성
- `lib/core/services/emotion_trend_service.dart`
- `lib/core/services/emotion_trend_notification_service.dart`
- `lib/core/services/safety_followup_service.dart`
- `lib/presentation/widgets/result_card/emotion_linked_prompt_card.dart`
- `test/core/services/emotion_trend_service_test.dart` (33 tests)
- `test/core/services/safety_followup_service_test.dart` (22 tests)
- `test/core/services/emotion_trend_notification_service_test.dart` (28 tests)

### 수정
- `lib/core/services/notification_service.dart` (공통 API 4개 추가)
- `lib/core/services/notification_settings_service.dart` (주간인사이트, emotionAware)
- `lib/core/constants/notification_messages.dart` (주간인사이트, 인지패턴 CBT)
- `lib/domain/entities/notification_settings.dart` (isWeeklyInsightEnabled)
- `lib/domain/entities/self_encouragement_message.dart` (category, writtenEmotionScore, emotionAware)
- `lib/data/datasources/local/preferences_local_datasource.dart` (직렬화 확장)
- `lib/presentation/providers/diary_analysis_controller.dart` (알림 트리거)
- `lib/presentation/providers/notification_settings_controller.dart` (주간인사이트, recentScore)
- `lib/presentation/widgets/settings/notification_section.dart` (주간인사이트 토글)
- `lib/presentation/widgets/settings/message_rotation_mode_sheet.dart` (감정맞춤 옵션)
- `lib/presentation/widgets/result_card.dart` (EmotionLinkedPromptCard)
- `lib/presentation/widgets/result_card/result_card.dart` (barrel export)
- `test/core/services/notification_settings_service_test.dart` (emotionAware + weekly insight tests)
- `test/core/constants/notification_messages_test.dart` (인지 패턴 CBT + 가중치 분포)
- `test/data/datasources/local/preferences_local_datasource_test.dart` (emotionAware 직렬화)

## 다음 단계
1. 커밋

## 보류
1. ARCH-001/002: splash_screen, onboarding_screen 레이어 위반
2. Phase 3: AI 자기대화 제안, AI 마음돌봄 레터, 타임캡슐

## 주의사항
- `SafetyBlockedFailure` 로직 절대 수정 금지 (Phase 2-5에서 읽기만)
- DB 마이그레이션 불필요 (SharedPreferences 사용)
- 기존 9개 테스트 실패는 Phase 2 이전부터 존재 (notification_service, mindcare_welcome, settings_sections)

## 마지막 업데이트
- 날짜: 2026-02-06
- 세션: Phase 2 전체 완료 (구현 + 통합 + 테스트)
- 테스트: 1375개 통과 (+117 신규), 9개 실패 (기존 동일)
- Lint: 0 이슈
