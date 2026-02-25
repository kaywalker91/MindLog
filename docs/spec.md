# MindLog 요구사항 명세 (spec.md)

**버전**: v1.4 (현재 구현 기준)
**최종 업데이트**: 2026-02-24
**상태**: 안정화 (Stable)

> 이 파일은 SDD 워크플로우의 핵심 트리거입니다.
> 새 기능 구현 전 반드시 이 파일을 업데이트하고 REQ ID를 부여한 뒤 코드 작성을 시작하세요.

---

## 기술 스택 (현재 구현 기준)

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter / Dart (fvm) | 3.38.9 / 3.10.8 |
| State | Riverpod | 2.6.1 |
| Database | SQLite (sqflite) | 2.3.3 |
| Firebase | Analytics, Crashlytics, FCM | 3.8.0+ |
| Routing | go_router | 17.0.1 |
| AI | Groq API | llama-3.3-70b-versatile |
| Chart | fl_chart | 0.68.0 |

---

## REQ-001 ~ REQ-005: 일기 작성 & 저장

### REQ-001: 일기 작성
- 사용자는 텍스트로 감정 일기를 작성할 수 있다
- 최소 10자, 최대 5,000자 유효성 검사 (ValidateDiaryContentUseCase)
- 작성 완료 시 SQLite에 `status: pending`으로 즉시 저장 (데이터 유실 방지)

### REQ-002: 이미지 첨부
- 일기에 최대 N장의 이미지를 첨부할 수 있다 (Android Photo Picker)
- 이미지 경로는 `Diary.imagePaths: List<String>?`에 저장
- 이미지 없음: `imagePaths == null` (하위 호환성 유지)

### REQ-003: 일기 목록 조회
- 전체 일기를 최신순으로 목록 조회 (DiaryListScreen)
- 상단 고정(isPinned) 일기는 목록 최상단에 표시
- 비밀 일기(isSecret)는 목록에서 숨김 (일반 목록에서 제외)

### REQ-004: 일기 상세 조회
- 일기 내용, AI 분석 결과, 첨부 이미지를 함께 표시 (DiaryDetailScreen)
- 분석 결과: 감정 키워드, 감정 점수(1-10), 공감 메시지, 추천 행동 목록
- 추천 행동 완료 체크 (isActionCompleted)

### REQ-005: 일기 삭제
- 일기를 삭제할 수 있다 (낙관적 업데이트 → 즉시 UI 반영)
- 삭제 후 `statisticsProvider` + `diaryListControllerProvider` 동시 invalidate

---

## REQ-010 ~ REQ-015: AI 감정 분석

### REQ-010: AI 분석 요청
- 일기 저장 후 Groq API (llama-3.3-70b-versatile)에 분석 요청
- JSON Mode 사용 (AnalyzeDiaryUseCase)
- 분석 완료 시 `DiaryStatus.analyzed`, 실패 시 `DiaryStatus.failed`

### REQ-011: 감정 분석 응답 스키마
AI 응답 JSON:
```json
{
  "keywords": ["불안", "압박감", "성취욕"],
  "sentiment_score": 4,
  "empathy_message": "...",
  "action_item": "...",
  "action_items": ["즉시 액션", "오늘 액션", "이번주 액션"],
  "emotion_category": { "primary": "불안", "secondary": "걱정" },
  "emotion_trigger": { "category": "업무", "description": "..." },
  "energy_level": 3,
  "cognitive_pattern": "과잉 일반화",
  "is_emergency": false
}
```

### REQ-012: 안전 감지 (Safety Detection) — 불변 정책
- `is_emergency: true` 또는 Groq API Safety 블락 → `DiaryStatus.safetyBlocked`
- UI: SOS 카드 표시 (상담 전화 안내)
- **SafetyBlockedFailure는 절대 수정/제거 금지** (위기 감지 핵심 로직)

### REQ-013: AI 캐릭터 선택
- 사용자는 AI 분석 캐릭터를 선택할 수 있다 (GetSelectedAiCharacterUseCase, SetSelectedAiCharacterUseCase)
- 선택된 캐릭터 ID는 AnalysisResult.aiCharacterId에 저장

### REQ-014: 이미지 분석 (멀티모달)
- 일기에 이미지가 첨부된 경우 Groq Vision API로 이미지 포함 분석
- 이미지 없으면 텍스트 전용 분석

### REQ-015: 안전 팔로업 알림 (Safety Followup)
- 안전 감지 후 N시간 뒤 팔로업 알림 발송 (REQ-042와 연계)
- 알림 ID: 2004 (SafetyFollowup)

---

## REQ-020 ~ REQ-025: 통계 & 시각화

### REQ-020: 감정 통계 조회
- 기간별 감정 점수 평균, 최고/최저 일기를 조회 (GetStatisticsUseCase)
- StatisticsScreen: fl_chart로 시계열 차트 표시

### REQ-021: 감정 추이 차트
- 일별 감정 점수 꺾은선 그래프 (fl_chart LineChart)
- 기간 선택: 1주 / 1개월 / 전체

### REQ-022: 감정 키워드 통계
- 자주 등장한 감정 키워드 top N 표시

### REQ-023: 주간 감정 인사이트 알림 (Weekly Insight)
- 매주 일요일 20:00 주간 통계 요약 알림 (REQ-042와 연계)
- NotificationSettings.isWeeklyInsightEnabled 설정으로 on/off

---

## REQ-030 ~ REQ-035: 비밀 일기

### REQ-030: 비밀 일기 PIN 설정
- 최초 비밀 일기 설정 시 PIN 등록 (SetSecretPinUseCase)
- PIN은 SecureStorage에 저장 (flutter_secure_storage)

### REQ-031: PIN 인증
- 비밀 일기 영역 접근 시 PIN 입력 화면 표시 (SecretDiaryUnlockScreen)
- VerifySecretPinUseCase로 검증

### REQ-032: 비밀 일기 전환
- 일반 일기를 비밀 일기로 전환, 또는 복원 (SetDiarySecretUseCase)
- `Diary.isSecret` 필드 토글

### REQ-033: 비밀 일기 목록 조회
- PIN 인증 후 비밀 일기 목록 조회 (GetSecretDiariesUseCase, SecretDiaryListScreen)

### REQ-034: PIN 변경 / 삭제
- PIN 변경 (SetSecretPinUseCase 재호출)
- PIN 삭제 (DeleteSecretPinUseCase): 모든 비밀 일기 일반 일기로 복원

### REQ-035: PIN 존재 여부 확인
- HasSecretPinUseCase: 비밀 일기 기능 최초 설정 여부 확인

---

## REQ-040 ~ REQ-050: 알림 시스템

### REQ-040: 일기 작성 리마인더
- 사용자가 설정한 시간에 일기 작성 알림 (로컬 알림)
- NotificationSettings.isReminderEnabled + reminderHour/reminderMinute
- 알림 ID: 1001 (CheerMe)

### REQ-041: 마음케어 알림 (Mindcare Topic)
- FCM data-only payload로 개인화된 자기격려 메시지 발송
- 알림 ID: 2001 (FCM Mindcare)
- `isMindcareTopicEnabled` 설정으로 on/off
- FCM은 개인화 불가 → data-only 사용

### REQ-042: 주간 감정 인사이트 알림
- 매주 일요일 20:00 로컬 알림 (isWeeklyInsightEnabled)
- 알림 ID: 2002 (WeeklyInsight)

### REQ-043: 안전 팔로업 알림
- 위기 감지 후 팔로업 로컬 알림 (알림 ID: 2004)

### REQ-044: 알림 설정 적용
- ApplyNotificationSettingsUseCase: 설정 변경 시 알림 스케줄 재등록
- GetNotificationSettingsUseCase / SetNotificationSettingsUseCase

### REQ-045: 알림 메시지 로테이션
- 자기격려 메시지 로테이션: random / sequential / emotionAware
- NotificationSettings.rotationMode

### REQ-046: 배경 FCM 핸들러
- Background Isolate에서 NotificationService.initialize() 호출 필수 (MissingPluginException 방지)
- FCM 핸들러: `message.data['title'] ?? message.notification?.title` (구/신 서버 호환)

---

## REQ-060 ~ REQ-065: 자기격려 메시지 관리

### REQ-060: 메시지 목록 조회
- 사용자가 등록한 자기격려 메시지 목록 (GetSelfEncouragementMessagesUseCase)
- 최대 10개 (SelfEncouragementMessage.maxMessageCount)

### REQ-061: 메시지 추가
- 최대 100자, 최대 10개 제한 (AddSelfEncouragementMessageUseCase)
- 추가 시 writtenEmotionScore (현재 감정 점수) 선택적 기록

### REQ-062: 메시지 수정
- 내용 변경 (UpdateSelfEncouragementMessageUseCase)

### REQ-063: 메시지 삭제
- 삭제 후 displayOrder 재정렬, lastDisplayedIndex 보정 (DeleteSelfEncouragementMessageUseCase)
- `NotificationSettings.adjustIndexAfterDeletion()` 로직 적용

### REQ-064: 감정 인식 메시지 선택 (EmotionAware)
- GetNextSelfEncouragementMessageUseCase: 현재 감정 점수 기반 메시지 선택
- 버킷: score≤3 → low, ≤6 → medium, >6 → high
- 폴백: 매칭 없으면 전체 목록에서 랜덤 선택
- `writtenEmotionScore == null` 메시지는 emotionAware 필터 제외

### REQ-065: 메시지 표시 순서 관리
- displayOrder 기반 순차 모드 지원
- 삭제 후 인덱스 자동 보정

---

## REQ-070 ~ REQ-075: 보안 & 안전

### REQ-070: 안전 팔로업 취소
- 위기 상황 해소 시 팔로업 알림 취소 (NotificationScheduler.cancelFollowup)
- 예약된 안전 팔로업을 취소하는 기능

### REQ-071: PIN 보안 저장
- PIN은 flutter_secure_storage에 암호화 저장
- Plain text / SharedPreferences 저장 금지

### REQ-072: SafetyBlocked 불변성
- DiaryStatus.safetyBlocked 상태는 다른 상태로 전환 불가
- SafetyBlockedFailure는 코드에서 제거/수정 금지

### REQ-073: 이름 개인화 필터
- FCM Mindcare 메시지: `{name}` 패턴 제거 (개인화 불가 채널)
- CheerMe 로컬 알림: `{name}` 패턴 유지 (개인화 가능)
- 한글 조사 후처리: `{name}님[,의은을이]?\s*` 패턴으로 조사+공백 함께 제거

---

## REQ-080 ~ REQ-085: 설정 & 온보딩

### REQ-080: 온보딩
- 최초 실행 시 온보딩 화면 (OnboardingScreen)
- 사용자 이름 입력 (알림 개인화용)

### REQ-081: 설정 화면
- 알림 설정, AI 캐릭터 선택, 비밀 일기 PIN 관리 (SettingsScreen)
- 앱 버전 표시, 개인정보처리방침 링크

### REQ-082: 변경 이력 (Changelog)
- 버전별 변경 이력 표시 (ChangelogScreen)

### REQ-083: 개인정보처리방침
- 인앱 웹뷰로 개인정보처리방침 표시 (PrivacyPolicyScreen)

---

## REQ-090 ~ REQ-099: UI/UX 품질 향상

> **추가일**: 2026-02-24 | **우선순위**: High
> 기능 요구사항이 아닌 품질/경험 요구사항. 기존 REQ와 독립적으로 적용.

### REQ-090: 다크 테마 완성도
- `darkTheme`에 `textTheme` 완전 정의 (현재 누락 → Material3 기본값 폴백 버그)
- `AppTextStyles`의 하드코딩된 `AppColors.textPrimary` → `Theme.of(context).colorScheme` 기반으로 교체
- 다크 모드에서 텍스트 contrast ratio WCAG AA 기준 충족 (≥4.5:1 normal, ≥3:1 large)

### REQ-091: 컬러 시스템 일관성
- 현재 4개 분리된 컬러 팔레트 (AppColors, StatisticsThemeTokens, HealingColorSchemes, CheerMeSectionPalette) 관계 문서화
- `StatisticsThemeTokens`의 `ThemeExtension` 패턴을 참조 모델로 확정
- 하드코딩된 `Colors.white/black/grey` → theme-aware 값으로 마이그레이션
- 마이그레이션 기준: `.claude/rules/patterns-theme-colors.md` 준수

### REQ-092: 반응형 레이아웃 안정성
- 모든 화면에서 텍스트 오버플로우 방지 (overflow: ellipsis 또는 flexible 적용)
- 다이얼로그: 소형 화면(360dp 미만) 대응 (maxWidth/Height 제한)
- Accent Stripe: `Container(Border)` 패턴 사용 (IntrinsicHeight 금지 — RenderFlex overflow 원인)

### REQ-093: 접근성 기준
- 핵심 인터랙션 위젯에 `Semantics` 레이블 추가 (FAB, icon 버튼, 감정 점수 표시)
- 최소 터치 타겟: 48×48dp (Material 가이드라인)
- 화면 리더 지원: `excludeFromSemantics` 장식용 요소에 적용

### REQ-094: 마이크로인터랙션 일관성
- 애니메이션 타이밍 상수화: `AppDurations` 클래스 도입 (fast: 150ms, normal: 250ms, slow: 400ms)
- 햅틱 피드백: 주요 액션 (저장, 삭제, PIN 입력) 에 일관된 햅틱 적용
- 로딩 상태: 스켈레톤 UI 또는 shimmer 효과 (현재 `CircularProgressIndicator` 단순 사용)

### REQ-095: DiaryListScreen UX
- 빈 상태(empty state) UI: 일기 0개일 때 안내 메시지 + 일러스트 (현재 없음)
- 일기 카드: 감정 점수 컬러 배지 시각적 강화
- Pull-to-refresh 인디케이터 색상 테마 일관성

### REQ-096: DiaryScreen (작성) UX
- 글자 수 카운터 표시 (현재 최대 5,000자이나 카운터 없음)
- 키보드 열릴 때 제출 버튼 가시성 보장 (Padding + MediaQuery.viewInsets)
- 분석 진행 중 로딩 상태 메시지 단계 표시 ("저장 중..." → "분석 중...")

---

## 화면 목록 (14 Screens)

| Screen | Route | 연관 REQ |
|--------|-------|---------|
| SplashScreen | `/` | - |
| OnboardingScreen | `/onboarding` | REQ-080 |
| MainScreen | `/main` | - |
| DiaryScreen | `/diary` | REQ-001, REQ-002 |
| DiaryListScreen | `/diary/list` | REQ-003 |
| DiaryDetailScreen | `/diary/:id` | REQ-004 |
| StatisticsScreen | `/statistics` | REQ-020~023 |
| SelfEncouragementScreen | `/self-encouragement` | REQ-060~065 |
| SecretDiaryListScreen | `/secret/list` | REQ-033 |
| SecretDiaryUnlockScreen | `/secret/unlock` | REQ-031 |
| SecretPinSetupScreen | `/secret/setup` | REQ-030 |
| SettingsScreen | `/settings` | REQ-081 |
| ChangelogScreen | `/changelog` | REQ-082 |
| PrivacyPolicyScreen | `/privacy` | REQ-083 |

---

## UseCase 목록 (19 UseCases)

| UseCase | 레이어 | 연관 REQ |
|---------|--------|---------|
| ValidateDiaryContentUseCase | Domain | REQ-001 |
| AnalyzeDiaryUseCase | Domain | REQ-010~014 |
| GetStatisticsUseCase | Domain | REQ-020 |
| GetNotificationSettingsUseCase | Domain | REQ-044 |
| SetNotificationSettingsUseCase | Domain | REQ-044 |
| ApplyNotificationSettingsUseCase | Domain | REQ-044 |
| GetSelectedAiCharacterUseCase | Domain | REQ-013 |
| SetSelectedAiCharacterUseCase | Domain | REQ-013 |
| GetSelfEncouragementMessagesUseCase | Domain | REQ-060 |
| AddSelfEncouragementMessageUseCase | Domain | REQ-061 |
| UpdateSelfEncouragementMessageUseCase | Domain | REQ-062 |
| DeleteSelfEncouragementMessageUseCase | Domain | REQ-063 |
| GetNextSelfEncouragementMessageUseCase | Domain | REQ-064 |
| SetDiarySecretUseCase | Domain | REQ-032 |
| GetSecretDiariesUseCase | Domain | REQ-033 |
| SetSecretPinUseCase | Domain | REQ-030, REQ-034 |
| VerifySecretPinUseCase | Domain | REQ-031 |
| HasSecretPinUseCase | Domain | REQ-035 |
| DeleteSecretPinUseCase | Domain | REQ-034 |

---

## 향후 기능 후보 (미구현, REQ 미부여)

- 감정 일기 내보내기 (PDF/텍스트)
- 클라우드 백업 / 멀티 디바이스 동기화
- 다국어 지원 (현재: 한국어 전용)
- 위젯 (홈 화면 감정 상태 표시)
- Apple Watch / Wear OS 알림 연동
