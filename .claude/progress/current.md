# Current Progress

## 현재 작업
- 알림 기능 차별화 Phase 1 완료 (미커밋)
- Phase 2 다음 세션 진행 예정

## 완료된 항목 (2월 6일)

### 알림 기능 차별화 Phase 1 ✅ (최신, 미커밋)
- [x] P1-1: 알림 채널 분리 — `mindlog_cheerme` + `mindlog_mindcare` 이중 채널
- [x] P1-2: 설정 UI — `_AccentSettingsCard` (좌측 4px accent stripe)
- [x] P1-3: Welcome Dialog — Calm Teal 브랜딩 + CBT 설명 + Cheer Me 비교
- [x] P1-4: 프리셋 템플릿 — 5카테고리 x 4메시지 (20개)
- [x] P1-5: CBT 기법별 메시지 풀 — `MindcareCategory` 8종, 44개 메시지
- [x] P1-6: 탭 라우팅 — cheerme→selfEncouragement, mindcare→statistics
- **변경 규모**: 8파일 +515 -145
- **테스트**: 1258개 통과, lint 0 이슈
- **미커밋 상태** — 다음 세션 시작 시 커밋 필요

### 마음케어 FCM 알림 userName 개인화 제거 ✅
- [x] FCM notification payload 구조적 제약 분석 → 백그라운드 개인화 불가 확인
- [x] `notification_messages.dart`: 마음케어 템플릿 24개에서 `{name}` 제거
- [x] `fcm_service.dart`: userName 로직 삭제

### Cheer Me 알림 제목/본문 자동 개인화 ✅
- [x] `getCheerMeTitle(userName)` 8개 풀
- [x] `applySettings()` userName 파라미터 + 재스케줄링 연동
- [x] 테스트 22개 추가

## 다음 단계: Phase 2 (다음 세션)

### 커밋 우선
- Phase 1 변경사항 커밋 (8파일)

### Wave 1 (독립, 동시 진행 가능)
1. **P2-1**: EmotionTrendService — 감정 트렌드 감지 (하락/회복/꾸준/공백)
2. **P2-3**: 주간 감정 인사이트 알림 — 매주 일요일 로컬 알림
3. **P2-5**: SafetyBlockedFailure 팔로업 — 24h 후 체크인 (Critical)
4. **P2-7**: DB 마이그레이션 v7 — `category` + `writtenEmotionScore` 추가

### Wave 2 (의존성 있음)
5. **P2-2**: 감정 트렌드 알림 (← P2-1)
6. **P2-4**: 인지 패턴 연계 CBT 메시지
7. **P2-6**: 감정 연동 자기 대화 프롬프트
8. **P2-8**: 감정 기반 메시지 선택 모드 (← P2-7)

### 의존성 그래프
```
P2-7 (DB) ← P2-8 (emotionAware)
P2-1 (TrendService) ← P2-2 (트렌드 알림)
P2-3, P2-4, P2-5, P2-6: 독립
```

### 알림 ID 체계
```
1001: Cheer Me 일일 (기존)
2001: 마음케어 일일 (로컬 전환 시)
2002: 주간 감정 인사이트
2003: 감정 트렌드 경고
2004: SafetyBlockedFailure 팔로업
3001+: 동적
```

## 보류
1. ARCH-001/002: splash_screen, onboarding_screen 레이어 위반
2. Phase 3: AI 자기대화 제안, AI 마음돌봄 레터, 타임캡슐

## 주의사항
- `SafetyBlockedFailure` 로직 자체 절대 수정 금지 (Phase 2-5에서 읽기만)
- DB 마이그레이션 v7: `_currentVersion` 증분 + `_onCreate`/`_onUpgrade` 동기화
- FCM은 보조 역할, 주요 개인화 메시지는 로컬 알림으로 전환

## 핵심 참조 파일
- 메모리: `memory/notification-differentiation-2026-02-06.md`
- 메시지 풀: `lib/core/constants/notification_messages.dart`
- 알림 서비스: `lib/core/services/notification_service.dart`
- 오케스트레이터: `lib/core/services/notification_settings_service.dart`
- 설정 UI: `lib/presentation/widgets/settings/notification_section.dart`

## 마지막 업데이트
- 날짜: 2026-02-06
- 세션: 알림 기능 차별화 Phase 1 완료 + 메모리화
- 테스트: 1258개 통과
- Lint: 0 이슈
