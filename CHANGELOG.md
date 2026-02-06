# Changelog

All notable changes to MindLog will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
