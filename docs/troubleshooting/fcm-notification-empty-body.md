# FCM 마음케어 알림 body 빈 문자열 트러블슈팅

> **resolved** | 2026-02-27 | notification | android, ios

## 문제 요약

| 항목 | 내용 |
|------|------|
| 증상 | FCM 마음케어 알림이 사용자 기기에 표시되지 않음 |
| 환경 | Android / iOS, FCM data-only + notification payload |
| 영향 | 마음케어 알림 전체 미수신 (Firebase Console에는 전송 성공 표시) |
| 심각도 | high |
| 근본 원인 유형 | data |
| 해결책 | `NotificationMessages.getRandomMindcareBody()` 강제 사용 |

---

## 근본 원인

### 원인 분석

FCM `notification` payload에서 `body` 필드가 빈 문자열(`''`)이면 Android와 iOS 모두 해당 알림을 **플랫폼 레벨에서 무시**한다. FCM 전송 자체는 성공(HTTP 200)으로 처리되므로 Firebase Console 대시보드에서는 전달 성공으로 표시되지만, 실제 기기에는 알림이 나타나지 않는다.

이 동작은 FCM/APNs 스펙의 의도된 동작이며 버그가 아니다. 플랫폼은 표시할 내용이 없는 알림을 자동으로 드롭한다.

### 데이터 흐름

```
Cloud Functions scheduled → fcm.service.ts → notification.body = '' → FCM 전송
    → Android/iOS 수신 → body 빈 문자열 감지 → 알림 드롭 (사용자에게 미표시)
```

### 증거

- Firebase Console: 알림 전송 수 = 수신 기기 수 (성공으로 표시)
- 기기 알림 트레이: 아무것도 표시 안 됨
- `tasks/lessons.md` 2026-02 항목: "알림 표시 안 됨" 보고

---

## 해결 방법

### 수정 내용

FCM 알림 body를 항상 `NotificationMessages.getRandomMindcareBody()`를 통해 공급한다.

**`functions/src/services/fcm.service.ts` (Cloud Functions 측)**:
```typescript
// ❌ 잘못된 방식
notification: {
  title: '마음케어',
  body: '',   // 빈 문자열 — 플랫폼이 무시
}

// ✅ 올바른 방식
import { NotificationMessages } from '../constants/notification_messages';

notification: {
  title: '마음케어',
  body: NotificationMessages.getRandomMindcareBody(),  // 항상 non-empty
}
```

**`lib/core/constants/notification_messages.dart` (Flutter 측 참조)**:
```dart
static String getRandomMindcareBody() {
  // 정의된 메시지 풀에서 랜덤 반환 — 절대 빈 문자열 없음
}
```

### 적용 방법

1. `functions/src/services/fcm.service.ts`에서 body 할당 부분 확인
2. 빈 문자열 리터럴(`''`, `""`) 제거
3. `NotificationMessages.getRandomMindcareBody()` (또는 동등한 TS 함수) 호출로 교체
4. `firebase deploy --only functions`로 배포

---

## 진단 과정

### 1차: FCM 전송 성공 확인

Firebase Console → Cloud Messaging → 메시지 전송 이력 확인.
전송 수와 수신 수가 일치 → 네트워크 문제 아님.

### 2차: 페이로드 검사

Cloud Functions 로그에서 실제 전송 payload 출력.
`notification.body: ""` 확인 → 원인 특정.

### 3차: 가설 검증

| 가설 | 결과 | 비고 |
|------|------|------|
| 네트워크 오류 | 기각 | Firebase Console 전송 성공 |
| 기기 알림 권한 없음 | 기각 | 다른 알림 유형은 정상 수신 |
| FCM 토큰 만료 | 기각 | 토큰 갱신 후에도 동일 증상 |
| body 빈 문자열 | **확인** | body 채우자 즉시 정상 수신 |

---

## 검증 방법

### 자동 검증

```bash
# Flutter 측 상수 파일에 빈 문자열 없는지 확인
grep -n "body: ''" lib/core/constants/notification_messages.dart
grep -n 'body: ""' functions/src/services/fcm.service.ts
```

### 수동 검증

1. 테스트 기기에서 마음케어 알림 수동 트리거
2. 알림 트레이에 메시지 텍스트 포함된 카드 표시 확인
3. Firebase Console → DebugView에서 `notification_receive` 이벤트 확인

---

## 관련 파일

| 파일 | 역할 |
|------|------|
| `lib/core/constants/notification_messages.dart` | 알림 메시지 상수 풀 (Flutter) |
| `functions/src/services/fcm.service.ts` | FCM 알림 전송 서비스 (Cloud Functions) |
| `functions/src/functions/scheduled.ts` | 마음케어 스케줄 트리거 |

---

## 교훈

### 재발 방지 규칙

- FCM `notification.body`는 **항상 non-empty 문자열**이어야 한다
- `NotificationMessages.getRandomMindcareBody()` (또는 동등한 상수 함수) 경유 필수
- 빈 문자열 리터럴(`''`, `""`) 직접 할당 절대 금지
- 새 FCM 알림 유형 추가 시 body 필드 체크리스트에 포함

### 일반화된 패턴

- **FCM 전송 성공 ≠ 사용자 수신**: Firebase Console의 성공 지표만 신뢰하지 말 것
- **플랫폼 silent drop**: body/title 빈 값은 에러 없이 무시됨 — 로그만으로 탐지 불가
- **알림 메시지는 상수 풀로 관리**: 분산된 인라인 문자열은 이런 실수를 유발

---

## 관련 이슈

- [예약 알림 미작동 (Release)](./notification-not-firing-release.md) — 다른 원인이지만 같은 notification 카테고리

## 관련 커밋

- (커밋 해시 없음 — 패턴 발견 후 예방 규칙으로 적용)
