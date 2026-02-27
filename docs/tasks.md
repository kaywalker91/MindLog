# MindLog 태스크 추적 (tasks.md)

**최종 업데이트**: 2026-02-27 (TASK-A11Y-001~009 완료, Sprint 1+2)
**현재 버전**: v1.4.48

> SDD 워크플로우 포맷: `TASK-XXX (REQ-YYY): 설명`
> 새 태스크는 이 파일에 추가 후 코드 작성 시작.

---

## 진행 중 (In Progress)

_현재 없음_

---

## 백로그 (Pending)

### Phase 1: 테마 시스템 수복 (Foundation)

- [x] **TASK-UI-001** (REQ-090): `darkTheme`에 완전한 `textTheme` 정의
  - 완료: v1.4.47 (2026-02-24)
  - 파일: `lib/core/theme/app_theme.dart`
  - 추가: `darkTextColor(#E8E8F0)`, `darkSecondaryTextColor(#AAAAAA)` + `textTheme` 블록

- [x] **TASK-UI-002** (REQ-090): `AppTextStyles` 다크 모드 대응 가이드라인 확립
  - 완료: v1.4.47 (2026-02-24)
  - 파일: `.claude/rules/patterns-theme-colors.md`
  - 추가: "AppTextStyles vs textTheme 사용 가이드라인" 섹션

- [x] **TASK-UI-003** (REQ-091): 컬러 시스템 관계 문서화
  - 완료: v1.4.47 (2026-02-24)
  - 파일: `docs/til/COLOR_SYSTEM.md` (신규)
  - 4개 팔레트 역할/범위/사용 규칙 명문화, `StatisticsThemeTokens` 참조 패턴 지정

### Phase 2: 하드코딩 색상 마이그레이션 (Consistency)

- [x] **TASK-UI-004** (REQ-091): Presentation 레이어 하드코딩 색상 감사
  - 완료: 2026-02-24
  - 범위: `lib/presentation/widgets/` 전체 감사
  - 수정: 4개 파일 (`update_up_to_date_dialog.dart`, `image_picker_section.dart`,
    `mindlog_app_bar.dart`, `message_input_dialog.dart`)
  - 유지 (의도적): `Colors.transparent`, ShaderMask `Colors.white` (dstIn 마스크),
    brightness-based on-accent 계산, `Color.lerp(…, Colors.white, …)`, tooltip text
  - 검증: `flutter analyze` — No issues

- [x] **TASK-UI-005** (REQ-091, REQ-092): 다이얼로그 & 카드 하드코딩 색상 마이그레이션
  - 완료: 2026-02-24
  - 결과: 5개 중 4개(`delete_diary_dialog`, `delete_all_diaries_dialog`,
    `help_dialog`, `whats_new_dialog`) 이미 clean
  - `mindcare_welcome_dialog.dart` — `Colors.white/black` 유지
    (ThemeData.estimateBrightnessForColor 기반 on-accent 계산,
    colorScheme.surface로 교체 시 다크 모드 대비 저하)
  - 검증: `flutter analyze` — No issues

### Phase 3: 핵심 화면 UX 개선 (Impact)

- [x] **TASK-UI-006** (REQ-095): DiaryListScreen 빈 상태(empty state) UI 구현
  - 완료: 2026-02-24
  - 파일: `lib/presentation/screens/diary_list_screen.dart`
  - `_buildEmptyState()` 메서드 추출: 원형 컨테이너(primary 8% alpha) + Icons.book_outlined(48px)
  - 제목 "아직 작성된 일기가 없어요" + 서브텍스트 "첫 일기를 기록해볼까요?" 분리 표시
  - `Semantics(label: '일기 없음, 새 일기 작성 버튼을 눌러 시작하세요')` 추가
  - 테스트: `diary_list_screen_test.dart` line 89에 기존 빈 상태 테스트 확인 (이미 존재)

- [x] **TASK-UI-007** (REQ-096): DiaryScreen 글자 수 카운터 추가
  - 완료: 2026-02-24
  - 파일: `lib/presentation/screens/diary_screen.dart`
  - `TextFormField.buildCounter` 콜백으로 커스텀 카운터 구현
  - 포맷: `X,XXX/5,000` (1000 이상 콤마 삽입)
  - 색상: 4,500자+ → `AppColors.warning`, 5,000자 → `AppColors.error`, 그 외 → `onSurfaceVariant`

- [x] **TASK-UI-008** (REQ-096): DiaryScreen 분석 단계 메시지 개선
  - 완료: 2026-02-24
  - 파일: `lib/presentation/widgets/loading_indicator.dart`
  - `analysisMessages` 업데이트: "일기를 저장하는 중..." → "AI가 감정을 분석하는 중..." → "거의 다 됐어요"
  - 기존 회전 메커니즘(2초 인터벌) 유지, 메시지만 단계 의미에 맞게 교체

- [x] **TASK-UI-009** (REQ-093): 핵심 위젯 접근성 Semantics 추가
  - 완료: 2026-02-24
  - `write_fab.dart`: label `'오늘 기록하기'` → `'새 일기 작성'`
  - `diary_item_card.dart`: `Semantics(label: '${date} 일기, 감정 점수 ${score}점', button: true)`
  - `emotion_garden.dart`: `Semantics(label: '마음의 정원, 최근 N주 감정 기록 캘린더')` + `ExcludeSemantics`로 셀 노이즈 제거
  - `pin_keypad_widget.dart`: 숫자 버튼 `Semantics(label: digit)`, 삭제 버튼 `Semantics(label: '지우기')`
  - 검증: `flutter analyze` — No issues

### Phase 5: 접근성 개선 (Accessibility, v1.5.x 예정)

> Sprint 1~3 상세: `memory/a11y-backlog.md`

#### Sprint 1 — High 우선순위 (2~3시간)

- [x] **TASK-A11Y-001** (REQ-093): `tappable_card.dart` — GestureDetector Semantics 래핑
  - 완료: v1.4.48 (2026-02-27)
  - 파일: `lib/presentation/widgets/common/tappable_card.dart`
  - 추가: Semantics(button:true) 래핑으로 스크린리더 버튼 인식

- [x] **TASK-A11Y-002** (REQ-093): `day_cell.dart` — 날짜 셀 + 이모지(🌱🌿🌷) 레이블 추가
  - 완료: v1.4.48 (2026-02-27)
  - 파일: `lib/presentation/widgets/emotion_calendar/day_cell.dart`
  - 추가: 날짜 버튼 semantics + 이모지 excludeSemantics

- [x] **TASK-A11Y-003** (REQ-093): `sentiment_dashboard.dart` — 에너지 이모지(🔋⚡💪) Semantics
  - 완료: v1.4.48 (2026-02-27)
  - 파일: `lib/presentation/widgets/result_card/sentiment_dashboard.dart`
  - 추가: 에너지 레벨 Semantics(label) 래핑

- [x] **TASK-A11Y-004** (REQ-093): 이미지 위젯 5개 `semanticLabel` 추가 (diary_image_gallery 등)
  - 완료: v1.4.48 (2026-02-27)
  - 파일: `lib/presentation/widgets/diary_image_gallery.dart`, `lib/presentation/widgets/image_picker_section.dart`, `lib/presentation/widgets/result_card/character_banner.dart`
  - 추가: 이미지 5개 semanticLabel 추가

- [x] **TASK-A11Y-005** (REQ-093): IconButton Semantics 3개 (삭제, 비밀일기, 이전/다음달 버튼)
  - 완료: v1.4.48 (2026-02-27)
  - 파일: `lib/presentation/widgets/emotion_calendar/calendar_header.dart`
  - 추가: prev/next 달 이동 버튼 tooltip 추가

#### Sprint 2 — Medium 우선순위 (1일)

- [x] **TASK-A11Y-006** (REQ-093): `fullscreen_image_viewer.dart` — 하드코딩 색상 8건 theme-aware 전환
  - 완료: v1.4.48 (2026-02-27)
  - 파일: `lib/presentation/widgets/fullscreen_image_viewer.dart`
  - 추가: scrim/shadow/onSurface/onSurfaceVariant/surfaceContainerLowest theme-aware 전환

- [x] **TASK-A11Y-007** (REQ-093): 다이얼로그 하드코딩 색상 (mindcare_welcome, weekly_insight_guide, activity_heatmap)
  - 완료: v1.4.48 (2026-02-27)
  - 파일: `lib/presentation/widgets/mindcare_welcome_dialog.dart`, `lib/presentation/widgets/weekly_insight_guide_dialog.dart`, `lib/presentation/widgets/activity_heatmap.dart`
  - 추가: Colors.white/black → colorScheme.onPrimary/onSurface; Color.lerp(Colors.white) → colorScheme.surface

- [x] **TASK-A11Y-008** (REQ-093): `diary_item_card.dart` — `AppAccessibility.diaryItemLabel()` 유틸 도입
  - 완료: v1.4.48 (2026-02-27)
  - 파일: `lib/presentation/widgets/diary_list/diary_item_card.dart`
  - 추가: AppAccessibility.diaryItemLabel() (date/sentimentScore/contentPreview/keywords)

- [x] **TASK-A11Y-009** (REQ-093): 14개 화면 `AccessibilityWrapper` 추가 (screenTitle Semantics)
  - 완료: v1.4.48 (2026-02-27)
  - 파일: `lib/presentation/screens/` 전체 14개 화면
  - 추가: AccessibilityWrapper(screenTitle: '...') 래핑 (모든 Scaffold 루트)

### Phase 4: 마이크로인터랙션 (Polish)

- [x] **TASK-UI-010** (REQ-094): `AppDurations` 애니메이션 상수 클래스 도입
  - 완료: 2026-02-24
  - 파일: `lib/core/theme/app_durations.dart` (신규) — `fast=150ms`, `normal=250ms`, `slow=400ms`
  - `emotion_calendar.dart`: `_prevMonth`/`_nextMonth`/`_goToToday` → `AppDurations.normal`
  - `empathy_message.dart`: `AnimatedContainer`, `AnimatedCrossFade`, `AnimatedRotation` → `AppDurations.normal`

- [x] **TASK-UI-011** (REQ-094): 햅틱 피드백 일관화
  - 완료: 2026-02-24
  - `diary_screen.dart`: `DiaryAnalysisSuccess` 콜백에 `HapticFeedback.lightImpact()` 추가
  - `delete_diary_dialog.dart`: 삭제 확인 버튼에 `unawaited(HapticFeedback.mediumImpact())` 추가
  - `pin_keypad_widget.dart`: 이미 구현됨 (숫자키/지우기 `lightImpact`)

- [x] **TASK-UI-012** (REQ-095): Pull-to-refresh 인디케이터 색상 테마 일관성
  - 완료: 2026-02-24
  - `diary_list_screen.dart`: `color: colorScheme.primary`, `backgroundColor: colorScheme.surfaceContainerHighest` 추가
  - `statistics_screen.dart`: `statsTokens.primaryStrong` → `colorScheme.primary`, `backgroundColor` 추가
  - 검증: `flutter analyze` — No issues

---

## 완료 (Completed)

### Phase 7: Secret Diary 완성 ✅ (v1.4.44, 2026-02-19)

> 설계 상세: `memory/secret-diary-plan-2026-02-19.md`

- [x] **TASK-SD-001** (REQ-030): Domain layer — Diary.isSecret entity + SecretPinRepository 인터페이스 + 6개 UseCase (TDD)
  - 완료: v1.4.44 (2026-02-19)
  - 파일: `lib/domain/entities/diary.dart`, `lib/domain/repositories/secret_pin_repository.dart`, `lib/domain/usecases/secret/`
  - 테스트: `test/domain/usecases/secret/` 3개 파일, 17 tests pass

- [x] **TASK-SD-002** (REQ-031): Data layer — SQLite v7 마이그레이션 (`is_secret` 컬럼) + SecureStorageDataSource
  - 완료: v1.4.44 (2026-02-19)
  - 파일: `lib/data/datasources/local/sqlite_local_datasource.dart`, `lib/data/datasources/local/secure_storage_datasource.dart`
  - PIN 해싱: SHA-256(rawPin + salt), salt = Random.secure() 32바이트 base64

- [x] **TASK-SD-003** (REQ-032): Provider + DI — SecretAuthProvider (in-memory 세션) + secretDiaryListProvider
  - 완료: v1.4.44 (2026-02-19)
  - 파일: `lib/presentation/providers/secret_auth_provider.dart`, `lib/presentation/providers/secret_diary_providers.dart`

- [x] **TASK-SD-004** (REQ-033): PIN 키패드 위젯 + PIN 설정/잠금해제 화면
  - 완료: v1.4.44 (2026-02-19)
  - 파일: `lib/presentation/widgets/secret/pin_keypad_widget.dart`, `lib/presentation/screens/secret_pin_setup_screen.dart`, `lib/presentation/screens/secret_diary_unlock_screen.dart`

- [x] **TASK-SD-005** (REQ-034): 비밀일기 목록 화면 + DiaryItemCard 롱프레스 메뉴 (비밀 설정/해제)
  - 완료: v1.4.44 (2026-02-19)
  - 파일: `lib/presentation/screens/secret_diary_list_screen.dart`, `lib/presentation/widgets/diary_list/diary_item_card.dart`

- [x] **TASK-SD-006** (REQ-035): 라우팅 보호 + DiaryListScreen AppBar 진입점 + 통합 테스트
  - 완료: v1.4.44 (2026-02-19)
  - 파일: `lib/presentation/router/app_router.dart`, `lib/presentation/screens/diary_list_screen.dart`

---

- [x] **TASK-003** (REQ-064): EmotionAware UseCase 통합 테스트
  - 완료: v1.4.46 (2026-02-24)
  - 파일: `test/core/services/notification_scheduler_impl_test.dart` (9 tests)
  - 검증: `NotificationSchedulerImpl.apply()` → `applySettings()` 위임, recentEmotionScore 전파, 감정 근접 선택, sequential wrap-around

- [x] **TASK-002** (REQ-020~023): StatisticsScreen 위젯 테스트 추가
  - 완료: v1.4.46 (2026-02-24)
  - 파일: `test/presentation/screens/statistics_screen_test.dart` (6 tests)
  - 검증: 로딩/데이터/에러/재시도/기간탭/빈데이터 상태

- [x] **TASK-001** (REQ-070): `cancelFollowup` 테스트 `LateInitializationError` 수정
  - 완료: v1.4.46 (2026-02-24)
  - 파일: `test/presentation/screens/diary_creation_flow_test.dart` (9 tests)
  - 방법: static override 패턴으로 `SafetyFollowupService.scheduleOneTimeOverride` 모킹

- [x] **TASK-P01** (REQ-064): `GetNextSelfEncouragementMessageUseCase` EmotionAware 구현
  - 완료: v1.4.46 (2026-02-24)
  - 버킷: score≤3→low, ≤6→medium, >6→high; 폴백: 전체 랜덤

- [x] **TASK-P02** (REQ-040, REQ-041): 중복 알림 방지 (CheerMe + FCM Mindcare)
  - 완료: v1.4.45 (2026-02-11)
  - 고정 ID: 2001(FCM), 덮어쓰기로 중복 방지

- [x] **TASK-P03** (REQ-044): NotificationScheduler 아키텍처 리팩토링
  - 완료: v1.4.46
  - Port/Adapter 패턴 적용: domain interface → core 구현

- [x] **TASK-P04** (REQ-045): 자기격려 메시지 순차 로테이션 lastDisplayedIndex 보정
  - 완료: v1.4.x
  - 삭제 후 index wrap-around 처리

---

## 향후 기능 (Future, REQ 미부여)

새 기능 개발 시 `docs/spec.md`에 REQ ID를 먼저 추가한 뒤 이 목록에서 TASK로 격상.

- [ ] 감정 일기 내보내기 (PDF/텍스트)
- [ ] 클라우드 백업 / 멀티 디바이스 동기화
- [ ] 다국어 지원 (한국어 외)
- [ ] 홈 화면 위젯 (감정 상태 표시)
- [ ] iOS 배포 (현재 Android 전용)

---

## 태스크 추가 가이드

```
1. docs/spec.md 에서 해당 REQ ID 확인 (없으면 먼저 추가)
2. docs/tasks.md 백로그에 TASK-XXX 추가
3. 코드 작성 시작
4. 완료 후 [x] 처리 + 버전/날짜 기록
```
