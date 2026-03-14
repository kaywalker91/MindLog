# Cheer Me 알림에 `{name}님` 플레이스홀더가 치환되지 않고 그대로 표시

> **resolved** | 2026-03-14 → 2026-03-14 | notification | android, ios

## 문제 요약

| 항목 | 내용 |
|------|------|
| 증상 | 사용자 이름을 설정했음에도 Cheer Me 알림 제목에 `{name}님의 응원 메시지` 등 플레이스홀더 원문이 그대로 표시됨 |
| 환경 | Android / iOS, 로컬 예약 알림 (flutter_local_notifications) |
| 영향 | Cheer Me 리마인더 알림 제목 개인화 완전 실패 — 이름 대신 `{name}` 리터럴 노출 |
| 심각도 | high |
| 근본 원인 유형 | timing + logic (복합) |
| 해결책 | 아래 3개 경로 동시 수정 필요 |

---

## 근본 원인

### 원인 A — `hasReminder` 조기 반환 가드 (메인 트리거)

`lib/main.dart`의 `_rescheduleNotificationsIfNeeded` 함수는 앱 시작 시 이미 예약된 알림이 있으면 재스케줄을 **완전히 건너뛴다**.

```dart
// lib/main.dart:75-83
final hasReminder = pendingNotifications.any(
  (n) => n.id == NotificationService.dailyReminderId,
);
if (hasReminder) {
  debugPrint('[Main] Reminder already pending, skipping reschedule');
  return;  // ← 여기서 즉시 반환
}
```

**문제**: 이전 버전의 앱(또는 이름이 설정되기 전)에서 `{name}님, ...` 템플릿 문자열이 그대로 notification title로 bake-in 된 알림이 예약됐다면, 이후 앱 업데이트 / 이름 설정 후에도 이 가드가 재스케줄을 막아 악성 알림이 계속 발화한다.

```
예전 알림 스케줄링 → {name}님 bake-in
     ↓
앱 재시작 → hasReminder=true → 조기 반환 → 알림 덮어쓰기 불가
     ↓
사용자가 이름 설정해도 효과 없음 (아래 원인 B와 결합)
     ↓
{name}님 알림 계속 발화
```

---

### 원인 B — `setUserName` 재스케줄 조건부 스킵

`lib/presentation/providers/user_name_controller.dart:setUserName`에서 이름 변경 후 재스케줄 로직이 `selfEncouragementProvider.valueOrNull`이 비어 있으면 완전히 건너뛴다.

```dart
// lib/presentation/providers/user_name_controller.dart:25-31
state = AsyncValue.data(finalName);   // 이름 state 즉시 업데이트

try {
  final messages = ref.read(selfEncouragementProvider).valueOrNull ?? [];
  if (messages.isNotEmpty) {           // ← Cheer Me 메시지가 아직 로딩 중이면 []
    await ref
        .read(notificationSettingsProvider.notifier)
        .rescheduleWithMessages(messages);
  }
  // messages.isEmpty면 재스케줄 없음 → 기존 알림({name}님 포함) 그대로 유지
} catch (e) { ... }
```

**타이밍 조건**: 온보딩 중 또는 앱 초기 실행 시 이름 설정 화면에 진입한 경우, `selfEncouragementProvider`가 아직 DB에서 로딩 중(`AsyncLoading`)이면 `valueOrNull`이 `null` → `messages = []` → 재스케줄 스킵.

---

### 원인 C — `getRandomReminderTitle()` 이름 치환 미적용 (잠재적 원인)

`lib/core/constants/notification_messages.dart:320`의 `getRandomReminderTitle()`은 `{name}님, ...` 패턴을 그대로 반환한다.

```dart
// lib/core/constants/notification_messages.dart:320-321
static String getRandomReminderTitle() =>
    _reminderTitles[_random.nextInt(_reminderTitles.length)];
// ↑ userName 인자 없음, applyNamePersonalization 미호출
```

`_reminderTitles`의 일부 항목:
```dart
'{name}님, 오늘 하루는 어떠셨나요?',   // line 77
'{name}님, 오늘 하루 수고하셨어요',    // line 79
'{name}님, 오늘도 고생 많으셨어요',   // line 84
```

현재 코드에서 이 함수의 반환값은 알림 제목으로 직접 사용되지 않지만 (`notification_service.dart:164`의 fallback title은 `'Cheer Me'`), 이전 버전에서 이 경로를 통해 `{name}님` 리터럴이 bake-in 됐을 가능성이 있다.

---

### 원인 D — `_nameWithSuffixPattern` 정규식 미커버 조사 (표시 품질 이슈)

`applyNamePersonalization`의 `_nameWithSuffixPattern`이 `님에게`, `님께` 조합을 처리하지 못한다.

```dart
// lib/core/constants/notification_messages.dart:431
static final RegExp _nameWithSuffixPattern = RegExp(r'\{name\}님[,의은을이]?\s*');
//                                                                ^^^^^^^^^
//                                         '에게', '께'는 여기에 없음
```

결과:
- `{name}님에게 보내는 응원` + `userName=null` → `님에게 보내는 응원` (부자연스러운 표시)
- `{name}님에게 보내는 응원` + `userName='Kay'` → `Kay님에게 보내는 응원` (정상)

---

## 복합 재현 시나리오

```
[앱 v1.4.x 이전 또는 이름 미설정 상태]
  → Cheer Me 알림 예약: title에 {name}님 리터럴 bake-in
  → 알림 유효 상태로 유지 (ID: 1001)

[앱 업데이트 또는 이름 설정 시도]
  Step 1: main.dart → _rescheduleNotificationsIfNeeded
          → hasReminder=true → 조기 반환 (원인 A)
  Step 2: 사용자가 이름 설정 → setUserName("김민준")
          → selfEncouragementProvider.valueOrNull == null (로딩 중)
          → messages = [] → reschedule 스킵 (원인 B)
  Step 3: 알림 발화 → {name}님의 응원 메시지 그대로 표시
```

---

## 코드 위치 정리

| 파일 | 라인 | 문제 |
|------|------|------|
| `lib/main.dart` | 75-83 | `hasReminder` 조기 반환 — 기존 알림 덮어쓰기 불가 |
| `lib/presentation/providers/user_name_controller.dart` | 26-31 | `valueOrNull` timing — 메시지 미로딩 시 reschedule 스킵 |
| `lib/core/constants/notification_messages.dart` | 320-321 | `getRandomReminderTitle()` 이름 치환 없음 |
| `lib/core/constants/notification_messages.dart` | 431 | `_nameWithSuffixPattern` 미커버 조사 (`에게`, `께`) |

---

## 해결 완료 (2026-03-14)

4개 Fix를 D→C→B→A 순서(리스크 낮은 것 먼저)로 적용. **117개 테스트 전체 통과.**

### Fix D — `_nameWithSuffixPattern` 정규식 확장 ✅

```dart
// lib/core/constants/notification_messages.dart:431
// Before
static final RegExp _nameWithSuffixPattern = RegExp(r'\{name\}님[,의은을이]?\s*');
// After
static final RegExp _nameWithSuffixPattern = RegExp(r'\{name\}님(?:[,의은을이]|에게|께)?\s*');
```

**핵심**: character class `[...]`는 1자만 매칭 — 2자 조사 `에게`/`께`는 `(?:...|...)` alternation 필수.

### Fix C — `getRandomReminderTitle` userName 파라미터 추가 ✅

```dart
// Before
static String getRandomReminderTitle() =>
    _reminderTitles[_random.nextInt(_reminderTitles.length)];

// After
static String getRandomReminderTitle([String? userName]) {
  final template = _reminderTitles[_random.nextInt(_reminderTitles.length)];
  return applyNamePersonalization(template, userName);
}
```

`getRandomReminderMessage`도 동일하게 optional `userName` 파라미터 추가. 기존 호출부 호환성 유지.

### Fix B — `setUserName` future 기반 재스케줄 ✅

```dart
// Before
final messages = ref.read(selfEncouragementProvider).valueOrNull ?? [];
if (messages.isNotEmpty) {
  await ref.read(notificationSettingsProvider.notifier).rescheduleWithMessages(messages);
}

// After
final messages = await ref.read(selfEncouragementProvider.future);
await ref.read(notificationSettingsProvider.notifier).rescheduleWithMessages(messages);
```

`isNotEmpty` guard 제거 — `applySettings` 내부에서 이미 messages 유무에 따라 schedule/cancel 분기 처리.

### Fix A — `hasReminder` 플레이스홀더 검증 추가 ✅

```dart
// Before
if (hasReminder) return;

// After
if (hasReminder) {
  final hasPlaceholder = pendingNotifications.any(
    (n) => n.id == NotificationService.dailyReminderId &&
           (n.title?.contains('{name}') ?? false),
  );
  if (!hasPlaceholder) return;
  // placeholder 있으면 fall-through → 강제 재스케줄
}
```

### 검증 결과

```bash
flutter test test/core/constants/notification_messages_test.dart \
            test/presentation/providers/user_name_controller_test.dart
# → 117 tests passed ✅
```

신규 테스트: Fix D 조사 커버리지 9개 + Fix C userName 파라미터 5개 = 14개 추가.

---

## 수정 방향 (참고용 — 실제 적용됨)

### Fix A — `hasReminder` 가드 강화 (main.dart)

단순 존재 여부만 확인하지 말고, 알림 제목에 `{name}` 리터럴이 있으면 강제 재스케줄.

```dart
// 현재 (문제)
if (hasReminder) return;

// 수정 방향
if (hasReminder) {
  final hasPlaceholder = pendingNotifications.any(
    (n) => n.id == NotificationService.dailyReminderId &&
           (n.title?.contains('{name}') ?? false),
  );
  if (!hasPlaceholder) return;
  // placeholder가 있으면 fall-through하여 재스케줄
}
```

또는 더 단순하게: 이름이 설정된 경우 항상 재스케줄 (중복 스케줄은 `cancelDailyReminder` 선행으로 안전).

### Fix B — `setUserName` future 기반 재스케줄 (user_name_controller.dart)

`valueOrNull` 대신 `future`를 await하거나, 별도 reschedule 흐름을 통해 반드시 최신 messages와 함께 재스케줄.

```dart
// 현재 (문제)
final messages = ref.read(selfEncouragementProvider).valueOrNull ?? [];
if (messages.isNotEmpty) { ... }

// 수정 방향
// 방법 1: future await (비동기 로딩 완료 대기)
final messages = await ref.read(selfEncouragementProvider.future);

// 방법 2: 메시지 여부와 무관하게 항상 재스케줄 (빈 messages는 applySettings에서 cancel 처리)
await ref
    .read(notificationSettingsProvider.notifier)
    .rescheduleWithMessages(messages);
// → applySettings 내부 messages.isEmpty 분기가 cancel or no-op 처리
```

### Fix C — `getRandomReminderTitle(userName)` API 수정 (notification_messages.dart)

```dart
// 현재 (문제)
static String getRandomReminderTitle() =>
    _reminderTitles[_random.nextInt(_reminderTitles.length)];

// 수정 방향
static String getRandomReminderTitle([String? userName]) {
  final template = _reminderTitles[_random.nextInt(_reminderTitles.length)];
  return applyNamePersonalization(template, userName);
}
```

### Fix D — 정규식 확장 (notification_messages.dart)

```dart
// 현재 (문제)
static final RegExp _nameWithSuffixPattern = RegExp(r'\{name\}님[,의은을이]?\s*');

// 수정 방향 — 에게, 께, 과, 와 추가
static final RegExp _nameWithSuffixPattern = RegExp(r'\{name\}님(?:[,의은을이에]게?|께)?\s*');
// 또는 더 포괄적으로:
static final RegExp _nameWithSuffixPattern = RegExp(r'\{name\}님\S{0,3}?\s*');
```

---

## 진단 절차

### 1단계: 현재 예약된 알림 확인

```dart
// DevTools 또는 디버그 버튼에서 실행
final pending = await FlutterLocalNotificationsPlugin().pendingNotificationRequests();
for (final n in pending) {
  print('ID: ${n.id}, Title: ${n.title}, Body: ${n.body}');
}
```

`{name}` 리터럴이 title에 포함되어 있으면 원인 A/B 확인.

### 2단계: userNameProvider 상태 확인

```dart
// 이름 설정 화면 진입 시점
print('userName: ${ref.read(userNameProvider).valueOrNull}');
print('messages: ${ref.read(selfEncouragementProvider).valueOrNull?.length ?? 0}');
```

`messages == 0`이면 원인 B 확인.

### 3단계: 강제 재스케줄로 즉시 우회

```dart
// 임시 해결: 앱에서 알림 끄기 → 다시 켜기
// → NotificationSettingsController.updateReminderEnabled(false) → true
// → applySettings가 messages + userName을 다시 로드하여 재스케줄
```

---

## 검증 방법

### 자동 검증 (수정 후)

```bash
# {name} 리터럴을 그대로 반환하는 함수 사용처 확인
grep -rn "getRandomReminderTitle()" lib/
# → notification_service.dart의 fallback body에서만 사용되어야 함 (title 아님)

# applyNamePersonalization 미호출 경로 확인
grep -rn "scheduleDailyReminder" lib/
# → 항상 applySettings를 경유해야 함
```

### 수동 검증

1. 앱을 삭제 후 재설치 (기존 예약 알림 초기화)
2. 이름 설정 → Cheer Me 메시지 작성 → 알림 활성화
3. 알림 발화 시 `{이름}님의 응원 메시지` 형태 표시 확인 (리터럴 아님)
4. 이름 변경 후 알림이 즉시 재스케줄되는지 확인

---

## 관련 파일

| 파일 | 역할 |
|------|------|
| `lib/main.dart` | 앱 시작 시 `_rescheduleNotificationsIfNeeded` |
| `lib/presentation/providers/user_name_controller.dart` | 이름 변경 후 재스케줄 트리거 |
| `lib/presentation/providers/notification_settings_controller.dart` | `rescheduleWithMessages`, `userNameProvider.valueOrNull` 읽기 |
| `lib/core/services/notification_settings_service.dart` | `applySettings`, 개인화 적용 지점 |
| `lib/core/constants/notification_messages.dart` | `{name}` 템플릿, `applyNamePersonalization`, `getCheerMeTitle` |
| `lib/core/services/notification_service.dart` | `scheduleDailyReminder`, title/body fallback |

---

## 교훈

### 재발 방지 규칙

1. **이름 변경 재스케줄은 무조건 실행**: `messages.isNotEmpty` 같은 guard 조건은 race condition을 유발. `applySettings` 내부에서 messages 없으면 cancel 처리가 이미 되므로 외부에서 guard 불필요.
2. **`hasReminder` 조기 반환은 위험**: 알림이 이미 예약된 경우에도 플레이스홀더 오염 가능 — 내용 검증 없는 skip 금지.
3. **템플릿 반환 함수는 항상 personalze**: `{name}` 패턴을 포함하는 문자열을 반환하는 모든 함수는 `userName` 인자를 받아 `applyNamePersonalization`을 호출해야 함.
4. **정규식 커버리지 테스트 필수**: `님` 뒤에 붙는 조사(의/을/은/이/에게/께) 전체 목록으로 테스트.

---

## 관련 이슈

- [예약 알림 미작동 (Release)](./notification-not-firing-release.md) — 알림 자체가 안 오는 경우
- [FCM 마음케어 알림 body 빈 문자열](./fcm-notification-empty-body.md) — FCM 알림 content 관련
