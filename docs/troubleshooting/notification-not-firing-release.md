# 예약 알림 미작동 (Release 빌드) 트러블슈팅

> **해결됨** | 2026-01-09 | Android Release Build

## 문제 요약

| 항목 | 내용 |
|------|------|
| 증상 | 설정한 시간에 일기 리마인더 알림이 오지 않음 |
| 환경 | Release APK (minifyEnabled=true) |
| 영향 | 모든 예약 알림 기능 불가 |
| 해결책 | Proguard keep 규칙 추가 |

---

## 근본 원인

### R8/Proguard 코드 난독화

Release 빌드에서 `isMinifyEnabled = true` 설정 시 R8이 `flutter_local_notifications` 패키지의 `ScheduledNotificationReceiver` 클래스를 난독화/제거하여 AlarmManager가 해당 클래스를 찾지 못함.

```
알림 스케줄 → AlarmManager 등록 → 시간 도달 → Receiver 호출 시도 → 클래스 못찾음 → 실패
```

### 증거

**build.gradle.kts (lines 61-62):**
```kotlin
isMinifyEnabled = true
isShrinkResources = true
```

**proguard-rules.pro (수정 전):**
```proguard
# flutter_local_notifications 관련 keep 규칙 없음!
```

---

## 해결 방법

### proguard-rules.pro 수정

**파일:** `android/app/proguard-rules.pro`

**추가된 규칙:**
```proguard
# flutter_local_notifications - 예약된 알림에 필수
# R8이 Receiver 클래스를 난독화/제거하면 AlarmManager가 찾지 못해 알림 발생 안함
-keep class com.dexterous.flutterlocalnotifications.** { *; }
```

### 적용 후 빌드

```bash
flutter clean
flutter build apk --release
```

---

## 진단 과정

### 1차 점검: 코드 흐름 추적

```
NotificationSettingsService.applySettings()
    ↓
NotificationService.scheduleDailyReminder()
    ↓
flutter_local_notifications.zonedSchedule()
    ↓
Android AlarmManager 등록
    ↓
ScheduledNotificationReceiver 호출 ← 여기서 실패
```

### 2차 점검: Release vs Debug 차이 분석

| 환경 | minifyEnabled | 알림 동작 |
|------|---------------|----------|
| Debug | false | 정상 |
| Release | true | **실패** |

### 3차 점검: Proguard 규칙 확인

기존 `proguard-rules.pro`에 `flutter_local_notifications` 패키지 관련 keep 규칙이 전혀 없음을 확인.

---

## 검증 방법

### Quick Test
```bash
# Release APK 빌드 및 설치
flutter build apk --release
adb install build/app/outputs/apk/release/app-release.apk

# 테스트
1. 설정 → 리마인더 ON
2. 현재 시간 + 2분으로 설정
3. 앱 종료 후 대기
4. 알림 수신 확인
```

### Proguard 없이 빌드 (원인 확인용)
```bash
flutter build apk --release --no-shrink
```
이 빌드에서 알림이 정상 작동하면 Proguard가 원인임을 확정.

---

## 관련 파일

| 파일 | 역할 |
|------|------|
| `android/app/proguard-rules.pro` | R8 난독화 예외 규칙 |
| `android/app/build.gradle.kts` | Release 빌드 설정 |
| `lib/core/services/notification_service.dart` | 알림 스케줄링 로직 |
| `AndroidManifest.xml` | Receiver 등록 |

---

## 추가 개선 사항 (선택)

### P1: 타임존 에러 핸들링

일부 기기에서 알 수 없는 타임존 반환 시 UTC 폴백:

```dart
try {
  final timezoneInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
} catch (e) {
  tz.setLocalLocation(tz.UTC);  // 폴백
}
```

### P2: BootReceiver 개선

현재 재부팅 후 앱을 열어야 알림 복원됨. 백그라운드 복원 로직 추가 고려.

### P3: 배터리 최적화 안내

OEM 기기(Samsung, Xiaomi 등)에서 배터리 최적화 제외 안내 추가 고려.

---

## 참고 자료

- [flutter_local_notifications GitHub Issues](https://github.com/MaikuB/flutter_local_notifications/issues)
- [Android R8 Keep Rules](https://developer.android.com/studio/build/shrink-code)
- [AlarmManager 문서](https://developer.android.com/reference/android/app/AlarmManager)

---

## 교훈

1. **Release 빌드 테스트 필수**: Debug와 Release 환경 차이로 인한 버그 발생 가능
2. **Proguard 규칙 확인**: 외부 패키지 사용 시 keep 규칙 필요 여부 확인
3. **BroadcastReceiver 주의**: R8이 리플렉션으로 호출되는 클래스를 제거할 수 있음
