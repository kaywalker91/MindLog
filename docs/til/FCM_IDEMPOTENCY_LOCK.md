# FCM 중복 발송 방지: Firestore Pre-lock 패턴

**날짜**: 2026-02-27
**태그**: FCM, Firestore, idempotency, iOS, APNS

---

## 문제

Firebase Functions `retryCount=3` 설정 + Firestore `markAsSent` 실패 조합으로 FCM 알림이 3회 중복 발송됨.

**재현 시나리오**:
1. Cloud Function 실행: FCM 발송 성공
2. Firestore `markAsSent` 업데이트 실패 (네트워크 에러, 타임아웃 등)
3. Function이 에러를 throw → Firebase가 재시도 (retry 1)
4. 다시 FCM 발송 성공 → 다시 `markAsSent` 실패 → 재시도 (retry 2)
5. 결과: 동일 알림 3회 발송 (21:00, 22:00, midnight KST)

**근본 원인**: check-send-mark 패턴은 send와 mark 사이에 실패 지점이 존재하여 멱등성을 보장할 수 없음.

---

## 핵심 학습

### 1. Firestore `create()`를 원자적 잠금으로 활용

Firestore `create()`는 문서가 이미 존재하면 `ALREADY_EXISTS` (gRPC code 6)를 throw한다. `set()`은 기존 문서를 덮어쓰지만, `create()`는 "first writer wins" 패턴을 원자적으로 보장한다.

```
create() → 문서 없음 → 생성 성공 (잠금 획득)
create() → 문서 있음 → ALREADY_EXISTS 에러 (잠금 실패 = 이미 처리됨)
```

이 특성을 이용하면 별도 분산 잠금 시스템(Redis, Memcached) 없이 Firestore만으로 멱등성 잠금을 구현할 수 있다.

**주의**: `set()`과 혼동하지 말 것. `set()`은 항상 성공하므로 잠금 용도로 사용 불가.

### 2. fail-open vs fail-safe

멱등성 검사가 실패할 때 두 가지 전략이 있다:

| 전략 | 동작 | 결과 |
|------|------|------|
| **fail-open** | 검사 에러 시 `return false` (미발송 취급) | 중복 발송 (Firestore 장애 시 알림 폭탄) |
| **fail-safe** | 검사 에러 시 `throw error` (발송 중단) | 미발송 (안전하지만 누락 가능) |

**알림 시스템의 올바른 선택: fail-safe**

- 중복 발송은 사용자 경험을 직접적으로 해침 (스팸)
- 누락은 다음 스케줄에서 자연스럽게 복구됨
- 특히 마음케어 같은 정기 알림은 1회 누락보다 3회 중복이 훨씬 나쁨

### 3. iOS APNS alert vs background payload

| 타입 | 헤더 | payload | OS 동작 | Flutter 매핑 |
|------|------|---------|---------|-------------|
| **alert** | `apns-push-type: alert` | `aps.alert{title, body}` | OS가 자동으로 알림 표시 | `RemoteMessage.notification` |
| **background** | `apns-push-type: background` | `aps.content-available: 1` | 백그라운드 핸들러만 실행, OS 표시 안 함 | `RemoteMessage.data` only |

**data-only payload 사용 이유**:
- `notification` 필드가 있으면 OS가 직접 표시 → 클라이언트 개인화(`{name}` 치환) 불가
- data-only로 보내면 클라이언트가 직접 `flutter_local_notifications`로 표시 → 완전한 제어 가능
- 단, iOS에서는 `content-available: 1`이 반드시 필요 (백그라운드 wake-up)

### 4. check-send-mark 패턴의 한계

**기존 패턴 (취약)**:
```
1. check: 이미 발송했는지 확인
2. send: FCM 발송
3. mark: 발송 완료 기록
```

문제: step 2 성공 + step 3 실패 → 재시도 시 step 1이 false 반환 → 중복 발송

**수정 패턴: lock-send-complete/release**:
```
1. lock: Firestore create()로 원자적 잠금 획득
   → ALREADY_EXISTS면 즉시 return (이미 처리됨)
2. send: FCM 발송
3. complete: 잠금 문서에 발송 결과 기록
   → 실패해도 잠금은 유지됨 (다음 재시도에서 ALREADY_EXISTS)
```

핵심 차이: 잠금이 **발송 전**에 획득되므로, 이후 어느 단계에서 실패하더라도 재시도 시 중복 발송이 원천 차단됨.

---

## 코드 패턴

### Pre-lock 패턴 (권장)

```typescript
async function sendWithIdempotency(
  userId: string,
  notificationType: string,
  dateKey: string,
  sendFn: () => Promise<void>
): Promise<boolean> {
  const lockRef = db
    .collection('notification_locks')
    .doc(`${userId}_${notificationType}_${dateKey}`);

  try {
    // Step 1: 원자적 잠금 획득 (create = first writer wins)
    await lockRef.create({
      createdAt: FieldValue.serverTimestamp(),
      status: 'processing',
    });
  } catch (error: any) {
    if (error.code === 6) {
      // ALREADY_EXISTS → 이미 처리됨 (정상 흐름)
      console.log(`Already processed: ${lockRef.path}`);
      return false;
    }
    // Firestore 장애 → fail-safe: 발송하지 않음
    throw error;
  }

  try {
    // Step 2: FCM 발송
    await sendFn();

    // Step 3: 완료 기록
    await lockRef.update({
      status: 'completed',
      completedAt: FieldValue.serverTimestamp(),
    });
    return true;
  } catch (error) {
    // 발송 실패 시 잠금 해제 (재시도 허용)
    await lockRef.delete().catch(() => {});
    throw error;
  }
}
```

### iOS data-only payload

```typescript
const message: admin.messaging.Message = {
  token: fcmToken,
  data: {
    type: 'mindcare',
    title: '마음 챙김 시간',
    body: '오늘 하루는 어떠셨나요?',
  },
  apns: {
    headers: {
      'apns-push-type': 'background',
      'apns-priority': '5', // background = must be 5
    },
    payload: {
      aps: {
        'content-available': 1,
        // alert 필드 없음 → OS가 알림 표시 안 함
      },
    },
  },
  android: {
    priority: 'high',
    // notification 필드 없음 → data-only
  },
};
```

---

## 교훈

1. **분산 시스템에서 "확인 후 실행" 패턴은 본질적으로 취약하다.** check와 execute 사이에 항상 경쟁 조건이 존재한다. 대신 "잠금 획득 후 실행" 패턴을 사용해야 한다.

2. **Firestore `create()`는 저비용 분산 잠금이다.** Redis나 별도 잠금 서비스 없이도 원자적 "first writer wins"를 구현할 수 있다. 단, TTL이 없으므로 잠금 문서의 만료/정리 전략이 필요하다.

3. **알림 시스템은 항상 fail-safe로 설계해야 한다.** 사용자에게 알림 1회 누락보다 3회 중복이 훨씬 나쁜 경험이다. 불확실할 때는 보내지 않는 것이 맞다.

4. **iOS APNS payload 구조를 정확히 이해해야 한다.** `alert` payload는 OS가 직접 표시하므로 클라이언트 로직을 우회한다. 개인화나 커스텀 로직이 필요하면 반드시 data-only(`content-available: 1`)를 사용해야 한다.

5. **retry + 부분 실패 = 중복 실행.** Firebase Functions의 retry 메커니즘은 함수 전체를 재실행한다. 부분적으로 성공한 작업(FCM 발송)은 되돌릴 수 없으므로, 멱등성 잠금이 반드시 **부작용(side effect) 이전**에 위치해야 한다.

---

## 관련 파일

| 위치 | 파일 | 역할 |
|------|------|------|
| Server | `functions/src/scheduled/sendMindcareNotifications.ts` | 스케줄 함수 + pre-lock |
| Client | `lib/core/services/fcm_service.dart` | FCM 수신 + 로컬 알림 표시 |
| Client | `lib/core/constants/notification_messages.dart` | 알림 메시지 상수 |

---

**참고**: Agent Teams 패턴으로 서버(TypeScript)와 클라이언트(Dart)를 병렬 수정하면 효율적. 두 코드베이스는 완전히 독립적이므로 병렬 작업에 적합하다.
