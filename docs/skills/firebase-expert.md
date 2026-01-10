# firebase-expert

Firebase 서비스 통합 관리 및 최적화 전문가 스킬

## 목표
- Firebase 서비스 통합 관리
- Analytics/Crashlytics/FCM 최적화
- Firebase 설정 및 디버깅 지원

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "Firebase 설정", "Analytics 이벤트" 요청
- `/firebase [action]` 명령어
- Firebase 서비스 문제 디버깅 시
- 새 Firebase 기능 추가 시

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `lib/core/services/firebase_service.dart` | Firebase 통합 초기화 |
| `lib/core/services/analytics_service.dart` | Firebase Analytics 래퍼 |
| `lib/core/services/crashlytics_service.dart` | Crashlytics 에러 리포팅 |
| `lib/core/services/fcm_service.dart` | FCM 푸시 알림 |
| `lib/core/services/notification_service.dart` | 로컬 알림 관리 |
| `firebase_options.dart` | Firebase 프로젝트 설정 |

## 현재 Firebase 서비스 구성

### 초기화 순서
```dart
FirebaseService.initialize()
├── Firebase.initializeApp()
├── CrashlyticsService.initialize()
├── AnalyticsService.initialize()
└── [Smoke Test] (CRASHLYTICS_SMOKE_TEST 플래그)
```

### Analytics 이벤트 목록
| 이벤트 | 메서드 | 파라미터 |
|--------|--------|----------|
| screen_view | logScreenView | screenName |
| app_open | logAppOpen | - |
| diary_created | logDiaryCreated | contentLength, aiCharacterId |
| diary_analyzed | logDiaryAnalyzed | aiCharacterId, sentimentScore, energyLevel |
| action_item_completed | logActionItemCompleted | actionItemText |
| ai_character_changed | logAiCharacterChanged | fromCharacterId, toCharacterId |
| statistics_viewed | logStatisticsViewed | period |
| reminder_scheduled | logReminderScheduled | hour, minute, source |
| reminder_cancelled | logReminderCancelled | source |
| reminder_schedule_failed | logReminderScheduleFailed | errorType |

### Crashlytics 설정
```dart
// 디버그 모드에서는 수집 비활성화
await _crashlytics!.setCrashlyticsCollectionEnabled(!kDebugMode);

// 에러 기록 메서드
CrashlyticsService.recordError(exception, stack, reason: '설명', fatal: false);
```

### FCM 설정
```dart
// 권한 요청
await _messaging!.requestPermission(
  alert: true,
  badge: true,
  sound: true,
  provisional: false,
);

// 메시지 핸들러
FirebaseMessaging.onMessage → 포그라운드 메시지
FirebaseMessaging.onMessageOpenedApp → 백그라운드 → 앱 열림
getInitialMessage() → 종료 상태 → 앱 열림
```

## 프로세스

### Action 1: add-analytics-event
새 Analytics 이벤트 추가

```
Step 1: 이벤트 정보 정의
  - 이벤트명 (snake_case, 40자 이내)
  - 파라미터 (snake_case, 값 100자 이내)
  - 필수/선택 여부

Step 2: analytics_service.dart 수정
  - 새 메서드 추가
  - 파라미터 타입 정의
  - _debugLog 호출

Step 3: UI에서 이벤트 호출
  - 적절한 위치에 이벤트 로깅

Step 4: Firebase Console 설정
  - 커스텀 정의 등록 (필요시)
```

**Analytics 이벤트 템플릿:**
```dart
/// {이벤트 설명}
static Future<void> log{EventName}({
  required {Type} {param},
}) async {
  await _instance()?.logEvent(
    name: '{event_name}',
    parameters: {
      '{param_key}': {paramValue},
    },
  );
  _debugLog('{event_name}', {'{param_key}': {paramValue}});
}
```

### Action 2: configure-crashlytics
Crashlytics 에러 리포팅 최적화

```
Step 1: 현재 에러 수집 상태 확인
  - Firebase Console에서 에러 목록 확인
  - 빈도 높은 에러 식별

Step 2: 커스텀 키 추가
  - 사용자 컨텍스트 정보
  - 앱 상태 정보

Step 3: 에러 그룹화 최적화
  - 의미 있는 reason 추가
  - fatal 플래그 적절히 설정

Step 4: 비치명적 에러 분류
  - 예상된 에러 vs 예상치 못한 에러
```

**Crashlytics 커스텀 키:**
```dart
// 사용자 컨텍스트 추가
await FirebaseCrashlytics.instance.setCustomKey('current_screen', screenName);
await FirebaseCrashlytics.instance.setCustomKey('ai_character', characterId);
await FirebaseCrashlytics.instance.setCustomKey('diary_count', count);
```

### Action 3: configure-fcm
FCM 푸시 알림 설정 및 최적화

```
Step 1: 토큰 관리 확인
  - FCM 토큰 획득 로직
  - 토큰 갱신 처리

Step 2: 메시지 핸들러 검토
  - 포그라운드 처리
  - 백그라운드 처리
  - 종료 상태 처리

Step 3: 토픽 구독 관리
  - 사용자 세그먼트별 토픽
  - 구독/해제 로직

Step 4: 알림 채널 설정 (Android)
  - 중요도 설정
  - 사운드/진동 설정
```

**FCM 토픽 패턴:**
```dart
// 토픽 구독
await FCMService.subscribeToTopic('all_users');
await FCMService.subscribeToTopic('premium_users');

// 토픽 해제
await FCMService.unsubscribeFromTopic('promotional');
```

### Action 4: debug-firebase
Firebase 연동 디버깅

```
Step 1: 초기화 상태 확인
  - FirebaseService.isInitialized
  - 각 서비스 초기화 로그

Step 2: Analytics 디버그 모드
  - Firebase DebugView 활성화
  - 실시간 이벤트 확인

Step 3: Crashlytics 테스트
  - 테스트 크래시 발생
  - Console에서 확인

Step 4: FCM 토큰 확인
  - FCMService.fcmToken
  - 토큰 갱신 이벤트
```

**디버그 모드 활성화:**
```bash
# Android
adb shell setprop debug.firebase.analytics.app com.kaywalker.mindlog

# iOS
# Xcode → Edit Scheme → Arguments → -FIRDebugEnabled
```

### Action 5: firebase-report
Firebase 서비스 상태 리포트

```
Step 1: 서비스 목록 조회
  - Analytics 이벤트 수
  - Crashlytics 에러 요약
  - FCM 토픽 구독 현황

Step 2: 설정 검증
  - firebase_options.dart 확인
  - 플랫폼별 설정 확인

Step 3: 권장 개선사항
  - 누락된 이벤트 추적
  - 에러 처리 개선
  - 알림 최적화
```

## Firebase Console 가이드

### Analytics 대시보드
```
1. Firebase Console → Analytics → Events
2. 이벤트 목록 확인
3. 커스텀 이벤트 파라미터 등록
4. 전환 이벤트 설정
```

### Crashlytics 대시보드
```
1. Firebase Console → Crashlytics
2. 에러 목록 및 영향받는 사용자 확인
3. 스택 트레이스 분석
4. 커스텀 키로 필터링
```

### Cloud Messaging
```
1. Firebase Console → Cloud Messaging
2. 새 캠페인 생성
3. 토픽/세그먼트 타겟팅
4. 테스트 메시지 전송
```

## 출력 형식

```
🔥 Firebase Expert 실행 결과

Action: [실행한 액션]

변경 사항:
├── 새 Analytics 이벤트: diary_shared
├── Crashlytics 커스텀 키 추가
└── FCM 토픽 구독 설정

수정 파일:
├── lib/core/services/analytics_service.dart
├── lib/core/services/crashlytics_service.dart
└── lib/core/services/fcm_service.dart

테스트:
└── Firebase Console DebugView에서 이벤트 확인

다음 단계:
└── /test-unit-gen lib/core/services/analytics_service.dart
```

## 사용 예시

### Analytics 이벤트 추가
```
> "/firebase add-analytics-event diary_shared"

AI 응답:
1. 이벤트 정의:
   - 이벤트명: diary_shared
   - 파라미터: share_method, content_length
2. analytics_service.dart 업데이트
3. UI 호출 예시 제공
4. Firebase Console 설정 안내
```

### Crashlytics 디버깅
```
> "/firebase debug-crashlytics"

AI 응답:
1. Crashlytics 상태 확인
2. 최근 에러 요약
3. 커스텀 키 현황
4. 개선 권장사항
```

### FCM 토픽 관리
```
> "/firebase configure-fcm --topic=announcements"

AI 응답:
1. 토픽 구독 코드 추가
2. 적절한 호출 위치 안내
3. 토픽 메시지 전송 방법
```

## 에러 해결 가이드

### Analytics 이벤트 미수집
```
원인:
- 디버그 모드에서 수집 비활성화
- 이벤트 파라미터 형식 오류
- Firebase 초기화 실패

해결:
1. DebugView로 실시간 확인
2. 파라미터 형식 검증
3. 초기화 로그 확인
```

### Crashlytics 에러 미보고
```
원인:
- 디버그 모드에서 수집 비활성화
- dSYM/ProGuard 매핑 누락
- 초기화 순서 문제

해결:
1. 프로덕션 빌드로 테스트
2. CI/CD에서 매핑 파일 업로드
3. 초기화 순서 확인
```

### FCM 토큰 미획득
```
원인:
- 권한 거부
- iOS APNS 토큰 지연
- 네트워크 문제

해결:
1. 권한 상태 확인
2. APNS 토큰 대기 로직 확인
3. 재시도 로직 검토
```

## 연관 스킬
- `/analytics-event` - 개별 Analytics 이벤트 추가
- `/crashlytics-setup` - Crashlytics 상세 설정
- `/fcm-setup` - FCM 상세 설정
- `/resilience` - 에러 처리 연동

## 주의사항
- 디버그 모드에서 수집 비활성화 유지
- 개인정보는 Analytics/Crashlytics에 전송 금지
- FCM 백그라운드 핸들러는 Top-level 함수로 정의
- iOS에서 APNS 토큰 대기 필수
- 프로덕션 빌드에서만 전체 기능 테스트 가능
- firebase_options.dart는 FlutterFire CLI로 생성 권장
