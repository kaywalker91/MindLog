# Fix Plan: Cheer Me `{name}` 플레이스홀더 미치환 수정

> **상태**: planned | 2026-03-14 | 대상 버전: 1.4.50+

## 개요

Cheer Me 알림 제목에 `{name}님` 리터럴이 그대로 표시되는 문제를 4개 파일 수정으로 완전히 해소한다. 리스크가 낮은 정적 수정(Fix D → Fix C)부터 시작하여 런타임 동작을 바꾸는 수정(Fix B → Fix A) 순서로 진행한다.

---

## 수정 범위

| 우선순위 | 파일 | 변경 타입 | 원인 |
|--------|------|----------|------|
| P0 | `lib/core/constants/notification_messages.dart` | 정규식 확장 | D |
| P0 | `lib/core/constants/notification_messages.dart` | API 시그니처 변경 | C |
| P1 | `lib/presentation/providers/user_name_controller.dart` | 비동기 로딩 방식 변경 | B |
| P1 | `lib/main.dart` | 조기 반환 가드 강화 | A |

---

## TDD 전략

### 테스트 파일 및 케이스

#### Fix D — `_nameWithSuffixPattern` 확장
**파일**: `test/core/constants/notification_messages_test.dart`

```
group('applyNamePersonalization - 조사 커버리지', () {
  // RED: 다음 케이스들이 먼저 실패해야 함
  test('should remove {name}님에게 when userName is null');
    // input:  '{name}님에게 보내는 응원'
    // expect: '보내는 응원'
  test('should remove {name}님께 when userName is null');
    // input:  '{name}님께 드리는 메시지'
    // expect: '드리는 메시지'
  test('should replace {name}님에게 with actual name when userName is set');
    // input:  '{name}님에게 보내는 응원', userName='지수'
    // expect: '지수님에게 보내는 응원'
  // 기존 케이스 회귀 보장
  test('should still handle {name}님, (comma suffix)');
  test('should still handle {name}님의');
  test('should still handle {name}님은');
  test('should still handle {name}님을');
  test('should still handle {name}님이');
});
```

#### Fix C — `getRandomReminderTitle` userName 파라미터 추가
**파일**: `test/core/constants/notification_messages_test.dart`

```
group('getRandomReminderTitle', () {
  // RED: 시그니처 변경 전에는 컴파일 에러
  test('should apply name personalization when userName is provided');
    // setRandom(MockRandom(fixedIndex: 0))  →  _reminderTitles[0] = '{name}님, 오늘 하루는 어떠셨나요?'
    // getRandomReminderTitle('지수') → '지수님, 오늘 하루는 어떠셨나요?'
  test('should remove {name}님 pattern when userName is null');
    // getRandomReminderTitle(null) → '오늘 하루는 어떠셨나요?'
  test('should remove {name}님 pattern when userName is empty string');
    // getRandomReminderTitle('') → '오늘 하루는 어떠셨나요?'
  test('should return non-name template unchanged regardless of userName');
    // setRandom(MockRandom(fixedIndex: 1))  →  _reminderTitles[1] = '오늘 기분이 어떠셨어요?'
    // getRandomReminderTitle('지수') → '오늘 기분이 어떠셨어요?'
  test('backward-compat: no-arg call compiles and returns non-placeholder string');
    // getRandomReminderTitle()  →  (선택 인자이므로 컴파일 OK, {name} 제거 후 반환)
});
```

#### Fix B — `setUserName` 비동기 로딩 대기
**파일**: `test/presentation/providers/user_name_controller_test.dart`

```
group('setUserName - reschedule timing', () {
  // RED: 현재는 messages=[] 시 reschedule 스킵됨
  test('should reschedule even when selfEncouragementProvider is still loading');
    // 시나리오: selfEncouragementProvider → AsyncLoading
    // setUserName('지수') 호출
    // rescheduleWithMessages 1회 호출됨을 verify
  test('should reschedule with loaded messages when provider eventually resolves');
    // 시나리오: selfEncouragementProvider → AsyncData([msg1, msg2]) (1초 후)
    // setUserName('지수') 호출
    // rescheduleWithMessages([msg1, msg2]) 1회 호출됨을 verify
  test('should NOT fail when reschedule throws — name state must be saved first');
    // rescheduleWithMessages가 Exception 발생해도
    // state == AsyncValue.data('지수') 임을 확인
});
```

#### Fix A — `hasReminder` 가드 강화 (통합 성격, main.dart)
**파일**: `test/reschedule_notifications_test.dart` (신규) 또는 기존 통합 테스트

```
group('_rescheduleNotificationsIfNeeded - placeholder guard', () {
  // RED: 현재는 hasReminder=true 시 항상 return
  test('should skip reschedule when pending notification has no placeholder');
    // pending: [id=1001, title='지수님의 응원 메시지']  ({name} 없음)
    // → applySettings 미호출
  test('should force reschedule when pending notification title contains {name}');
    // pending: [id=1001, title='{name}님의 응원 메시지']
    // → applySettings 1회 호출됨
  test('should skip reschedule when no reminder is pending (original behavior)');
    // pending: []  → applySettings 미호출
  test('should skip reschedule when reminder is disabled');
    // SharedPreferences: notification_reminder_enabled=false
    // → applySettings 미호출
});
```

---

## 구현 단계 (순서 있음)

### Step 1 — `_nameWithSuffixPattern` 정규식 확장 (P0, Fix D)

**파일**: `lib/core/constants/notification_messages.dart`

**변경 전** (line 431):
```dart
static final RegExp _nameWithSuffixPattern = RegExp(r'\{name\}님[,의은을이]?\s*');
```

**변경 후**:
```dart
static final RegExp _nameWithSuffixPattern = RegExp(r'\{name\}님(?:[,의은을이]|에게|께)?\s*');
```

**근거**: `_cheerMeTitles` 내 `'{name}님에게 보내는 응원'` (line 304), `'{name}님께 드리는'` 패턴 등이 `userName=null` 일 때 `님에게` 잔류 문자열을 남긴다. `(?:...)` 비캡처 그룹으로 `에게`/`께` 를 alternation에 추가한다. `[,의은을이]`는 1글자 한정이므로 2글자인 `에게`는 character class 밖 alternation으로 처리해야 한다.

---

### Step 2 — `getRandomReminderTitle` userName 파라미터 추가 (P0, Fix C)

**파일**: `lib/core/constants/notification_messages.dart`

**변경 전** (lines 319-321):
```dart
/// 랜덤 리마인더 제목 반환
static String getRandomReminderTitle() =>
    _reminderTitles[_random.nextInt(_reminderTitles.length)];
```

**변경 후**:
```dart
/// 랜덤 리마인더 제목 반환 (이름 개인화 적용)
static String getRandomReminderTitle([String? userName]) {
  final template = _reminderTitles[_random.nextInt(_reminderTitles.length)];
  return applyNamePersonalization(template, userName);
}
```

**근거**: `_reminderTitles`의 8개 항목 중 3개가 `{name}님` 패턴을 포함한다 (lines 77, 79, 84). 이 함수는 현재 `notification_service.dart` fallback 경로에서만 호출되지만, 향후 직접 호출 경로가 생기거나 테스트에서 사용 시 치환되지 않은 문자열이 누출될 수 있다. 선택 인자(`[String? userName]`)로 추가하여 기존 호출부 컴파일 호환성을 유지한다.

**`getRandomReminderMessage()` 연동 수정** (line 328):

`getRandomReminderMessage()`는 `getRandomReminderTitle()`을 호출한다. userName을 전달하지 않는 현재 구조는 유지해도 되지만, 향후 호출부에서 userName을 넘길 수 있도록 해당 메서드도 선택 인자를 추가한다.

**변경 전** (lines 327-329):
```dart
/// 랜덤 리마인더 메시지 쌍 반환
static ({String title, String body}) getRandomReminderMessage() =>
    (title: getRandomReminderTitle(), body: getRandomReminderBody());
```

**변경 후**:
```dart
/// 랜덤 리마인더 메시지 쌍 반환 (이름 개인화 적용)
static ({String title, String body}) getRandomReminderMessage([
  String? userName,
]) => (title: getRandomReminderTitle(userName), body: getRandomReminderBody());
```

---

### Step 3 — `setUserName` future 기반 재스케줄 (P1, Fix B)

**파일**: `lib/presentation/providers/user_name_controller.dart`

**변경 전** (lines 24-36):
```dart
// 이름 변경 → 알림 재스케줄링 (개인화 반영)
try {
  final messages = ref.read(selfEncouragementProvider).valueOrNull ?? [];
  if (messages.isNotEmpty) {
    await ref
        .read(notificationSettingsProvider.notifier)
        .rescheduleWithMessages(messages);
  }
} catch (e) {
  if (kDebugMode) {
    debugPrint('[UserNameController] Reschedule failed: $e');
  }
}
```

**변경 후**:
```dart
// 이름 변경 → 알림 재스케줄링 (개인화 반영)
// selfEncouragementProvider가 로딩 중이면 완료를 기다린 후 재스케줄
// messages.isEmpty 시 applySettings 내부에서 cancel 처리되므로 외부 guard 불필요
try {
  final messages = await ref.read(selfEncouragementProvider.future);
  await ref
      .read(notificationSettingsProvider.notifier)
      .rescheduleWithMessages(messages);
} catch (e) {
  if (kDebugMode) {
    debugPrint('[UserNameController] Reschedule failed: $e');
  }
}
```

**근거**:
- `valueOrNull`은 `AsyncLoading` 상태에서 `null`을 반환 → `messages = []` → `if (messages.isNotEmpty)` 조건 불충족 → reschedule 스킵. 온보딩 시나리오(이름 설정 직후 selfEncouragementProvider 미로딩)에서 반드시 발생한다.
- `selfEncouragementProvider.future`를 await하면 로딩 완료 후 메시지를 가져온다.
- `messages.isEmpty` 조건부 guard를 제거한다. `applySettings` (notification_settings_service.dart line 196)가 `messages.isNotEmpty` 여부에 따라 schedule/cancel을 이미 분기 처리하므로 외부 guard는 중복이며 race condition을 유발한다.
- 이름 저장(`state = AsyncValue.data(finalName)`, line 22)은 reschedule 이전에 완료되므로 reschedule 실패 시에도 이름 상태는 보존된다. catch 블록이 이를 보장한다.

---

### Step 4 — `hasReminder` 조기 반환 가드 강화 (P1, Fix A)

**파일**: `lib/main.dart`

**변경 전** (lines 75-83):
```dart
final hasReminder = pendingNotifications.any(
  (n) => n.id == NotificationService.dailyReminderId,
);
if (hasReminder) {
  if (kDebugMode) {
    debugPrint('[Main] Reminder already pending, skipping reschedule');
  }
  return;
}
```

**변경 후**:
```dart
final hasReminder = pendingNotifications.any(
  (n) => n.id == NotificationService.dailyReminderId,
);
if (hasReminder) {
  // 예약된 알림이 있어도 {name} 플레이스홀더가 포함되어 있으면 강제 재스케줄
  // (이전 버전에서 bake-in 된 리터럴 알림 덮어쓰기)
  final hasPlaceholder = pendingNotifications.any(
    (n) =>
        n.id == NotificationService.dailyReminderId &&
        (n.title?.contains('{name}') ?? false),
  );
  if (!hasPlaceholder) {
    if (kDebugMode) {
      debugPrint('[Main] Reminder already pending (clean), skipping reschedule');
    }
    return;
  }
  if (kDebugMode) {
    debugPrint(
      '[Main] Reminder pending but contains {name} placeholder — forcing reschedule',
    );
  }
}
```

**근거**:
- 기존 코드는 알림 예약 존재 여부만 확인하여 조기 반환한다. 이전 버전에서 `{name}` 리터럴이 bake-in 된 알림이 ID 1001로 예약된 경우, 앱 재시작 시 해당 알림을 덮어쓰지 못한다.
- `pendingNotificationRequest.title`은 `flutter_local_notifications`의 `PendingNotificationRequest` 객체에서 접근 가능하다.
- `hasPlaceholder`가 true인 경우 fall-through하여 이후 `applySettings` 호출 경로를 실행한다. `NotificationService.cancelDailyReminder()`는 `applySettings` 내부에서 messages 유무에 따라 처리되므로 별도 cancel 호출 불필요.
- 정상 케이스(플레이스홀더 없는 알림이 예약된 경우)는 기존과 동일하게 조기 반환한다.

---

## 검증 체크리스트

- [ ] Fix D: `applyNamePersonalization('{name}님에게 보내는 응원', null)` → `'보내는 응원'`
- [ ] Fix D: `applyNamePersonalization('{name}님에게 보내는 응원', '지수')` → `'지수님에게 보내는 응원'`
- [ ] Fix D: `applyNamePersonalization('{name}님께 드리는 메시지', null)` → `'드리는 메시지'`
- [ ] Fix D: 기존 조사(`의`, `은`, `을`, `이`, `,`) 모두 회귀 테스트 통과
- [ ] Fix C: `getRandomReminderTitle('지수')` → 선택된 템플릿의 `{name}` 이 `지수`로 치환
- [ ] Fix C: `getRandomReminderTitle(null)` → `{name}님` 패턴 제거
- [ ] Fix C: `getRandomReminderTitle()` (인자 없음) → 컴파일 오류 없음, `{name}` 제거됨
- [ ] Fix B: `selfEncouragementProvider`가 `AsyncLoading` 상태일 때 `setUserName` 호출 → 로딩 완료 후 `rescheduleWithMessages` 1회 호출됨
- [ ] Fix B: `rescheduleWithMessages` 내부에서 예외 발생 시 `state` 가 이름 값 유지
- [ ] Fix A: pending notification에 `{name}` 없음 → `applySettings` 미호출
- [ ] Fix A: pending notification title이 `{name}님의 응원 메시지` → `applySettings` 1회 호출됨
- [ ] 전체: `flutter analyze` — 0 errors, 0 warnings
- [ ] 전체: `flutter test` — 전체 테스트 통과
- [ ] 수동: 앱 삭제 후 재설치 → 이름 설정 → Cheer Me 활성화 → 알림 발화 시 `{이름}님의 응원 메시지` 표시 (리터럴 아님)
- [ ] 수동: 이름 변경 → 다음 알림 발화 시 새 이름 반영 확인

---

## 예상 리스크

| 리스크 | 가능성 | 완화 방법 |
|--------|--------|---------|
| Fix B에서 `selfEncouragementProvider.future` await 중 타임아웃 → 이름 저장 후 reschedule이 장시간 blocking | 낮음 | `setUserName`의 catch 블록이 `state` 업데이트 이후에 위치하므로 이름 저장은 항상 완료됨; reschedule은 fire-and-forget 특성 유지 가능 (unawaited 전환 고려) |
| Fix A의 `n.title` 접근: `flutter_local_notifications`의 `PendingNotificationRequest`가 title을 null로 반환하는 플랫폼 케이스 | 낮음 | `n.title?.contains('{name}') ?? false` null-safe 처리로 방어; null이면 `hasPlaceholder=false` → 조기 반환 유지 (안전한 방향) |
| Step 2에서 `getRandomReminderMessage` 시그니처 변경 → 기존 호출부 컴파일 에러 | 없음 | 선택 인자(`[String? userName]`) 사용으로 기존 호출부 변경 불필요 |
| Fix D 정규식 변경으로 기존 테스트 케이스 중 `에게`/`께` 미커버 케이스가 갑자기 통과 → false green | 낮음 | RED phase에서 변경 전 테스트를 실행하여 실패 확인 필수 |
| Fix A 적용 후 `{name}` bake-in 알림이 매 앱 시작마다 재스케줄 → 알림 ID 1001 중복 등록 | 낮음 | `NotificationService.scheduleDailyReminder`가 같은 ID로 덮어쓰므로 중복 없음; 재스케줄 1회 후 다음 앱 시작에서는 `hasPlaceholder=false` → 정상 조기 반환 |

---

## 관련 파일

- 트러블슈팅 원인 분석: `docs/troubleshooting/cheer-me-name-placeholder-not-replaced.md`
- 알림 설정 적용 서비스: `lib/core/services/notification_settings_service.dart`
- 알림 설정 컨트롤러: `lib/presentation/providers/notification_settings_controller.dart`
- 알림 메시지 상수: `lib/core/constants/notification_messages.dart`
- 이름 컨트롤러: `lib/presentation/providers/user_name_controller.dart`
- 앱 시작 재스케줄 로직: `lib/main.dart` (함수: `_rescheduleNotificationsIfNeeded`)
