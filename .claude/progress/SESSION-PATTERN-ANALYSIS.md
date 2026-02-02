# Session Pattern Analysis: App Update Notification Improvement

**분석 기간**: 2026-02-02 (app-update-notification-improvement 세션)
**분석 대상**: Phase 1-3 구현 패턴의 재사용성 및 스킬화 가능성

---

## Executive Summary

세션에서 구현한 3가지 패턴 모두 **다른 기능에서 재사용 가능한 범용 패턴**으로 분류됨.

| 패턴 | 재사용성 | 스킬화 우선순위 | 이유 |
|------|---------|-----------------|------|
| **Timestamp-based Suppress** | 높음 | P1 | 최소 3개 분야 적용 가능 |
| **Periodic Timer with Cleanup** | 높음 | P1 | 6시간 체크패턴이 기존 코드에도 있음 |
| **Platform-specific Service Wrapper** | 중간 | P2 | 패턴은 재사용 가능하나 platform-specific |

---

## 패턴 1: Timestamp-based Suppress (24시간 억제)

### 패턴 식별

**구현 파일들:**
- `lib/data/datasources/local/preferences_local_datasource.dart` (L81-102)
- `lib/domain/repositories/settings_repository.dart` (L22-26)
- `lib/presentation/providers/update_state_provider.dart` (L28-39)

**핵심 개념:**
```dart
// 1. SharedPreferences에 타임스탬프 저장
Future<void> setDismissedUpdateVersionWithTimestamp(String version) async {
  await prefs.setString(_dismissedUpdateVersionKey, version);
  await prefs.setInt(
    _dismissedUpdateTimestampKey,
    DateTime.now().millisecondsSinceEpoch,  // 핵심: 현재 시간 저장
  );
}

// 2. 상태에서 경과 시간 계산
bool get shouldShowBadge {
  if (dismissedAt != null) {
    final elapsed = DateTime.now().difference(dismissedAt!);
    if (elapsed >= suppressDuration) return true;  // 24시간 이상 경과
  }
  return false;
}
```

### 재사용 가능한 분야

#### 1) 알림 Snooze 기능 (미구현)
```dart
// 예: "1시간 나중에 알림" → 1시간 경과 후 재표시
class NotificationSnoozeState {
  final String notificationId;
  final DateTime? snoozedUntil;

  bool get shouldShow {
    if (snoozedUntil != null) {
      return DateTime.now().isAfter(snoozedUntil!);
    }
    return true;
  }
}
```

#### 2) 도움말 다이얼로그 "다시 보지 않기" (L10 참고)
```dart
// lib/presentation/widgets/help_dialog.dart 에서 활용 가능
// "이 팁을 7일간 숨기기" 같은 시간제한 숨김 기능
```

#### 3) 마인드케어 토픽 구독 갱신
```dart
// 예: 사용자가 구독 취소 후 30일 뒤에 다시 구독 권유
class SubscriptionState {
  final bool isSubscribed;
  final DateTime? lastUnsubscribedAt;

  bool get shouldShowResubscribeOffer {
    if (lastUnsubscribedAt != null) {
      return DateTime.now().difference(lastUnsubscribedAt!) >= Duration(days: 30);
    }
    return false;
  }
}
```

### 현재 코드 규모

- **DataSource 메서드**: 2개 (get/set with timestamp)
- **Repository 인터페이스**: 2개 메서드
- **State 로직**: `bool get` 계산 속성 (~10줄)

### 스킬화 제안

**스킬 이름**: `/suppress-pattern [entity] [duration]`

**입력 인자:**
```
entity        : "update" | "notification" | "tip" | "offer"
duration      : "1h" | "24h" | "7d" | "30d"
```

**자동 생성 내용:**
1. SharedPreferences 키 정의 (`_suppressedAtKey`)
2. DataSource 메서드 2개 (get/set timestamp)
3. Repository 인터페이스 메서드 2개
4. Repository 구현체
5. State class의 계산 속성 (`bool get shouldShow`)
6. StateNotifier 메서드 (`suppress()`, `clearSuppression()`)
7. Unit test 템플릿

**사용 예시:**
```bash
/suppress-pattern notification 24h
# → notification_suppression_extension.dart 생성
#   - PreferencesLocalDataSource 확장
#   - NotificationSuppressionRepository 생성
#   - NotificationSuppressionState 생성
```

---

## 패턴 2: Periodic Timer with Resource Cleanup

### 패턴 식별

**구현 파일:**
- `lib/presentation/providers/update_check_timer_provider.dart` (L15-75)

**핵심 개념:**
```dart
// 1. Provider.autoDispose로 자동 정리
final updateCheckTimerProvider = Provider.autoDispose<UpdateCheckTimer>((ref) {
  final timer = UpdateCheckTimer(ref);
  ref.onDispose(() => timer.dispose());  // 핵심: 리소스 정리 보장
  return timer;
});

// 2. Timer.periodic으로 주기적 실행
Timer.periodic(_updateCheckInterval, (_) => _performCheck());

// 3. Dispose 패턴으로 타이머 중지
void dispose() {
  _isDisposed = true;
  stop();  // cancel() 호출
}
```

### 기존 재사용 사례 발견

**diary_list_controller.dart (L14, L82)에서 이미 사용 중:**
```dart
// 1. onDispose로 정리
ref.onDispose(_cancelAllPendingDeletions);

// 2. Timer 기반 Undo (5초)
final timer = Timer(const Duration(seconds: 5), () {
  _executeDeletion(diary.id);
});
```

**⚠️ 발견 사항**: `Timer.periodic` 패턴은 `UpdateCheckTimerProvider`에서만 사용
→ 주기적 체크 유즈케이스가 적음

### 재사용 가능한 분야

#### 1) 주기적 DB 동기화 (미구현)
```dart
// 예: 5분마다 로컬 DB ↔ 클라우드 동기화 확인
final syncCheckTimerProvider = Provider.autoDispose<SyncCheckTimer>((ref) {
  final timer = SyncCheckTimer(ref);
  ref.onDispose(() => timer.dispose());
  return timer;
});
```

#### 2) 주기적 네트워크 연결 확인 (미구현)
```dart
// 예: 30초마다 인터넷 연결 상태 확인
final networkStatusTimerProvider = Provider.autoDispose<NetworkStatusTimer>((ref) {
  // 유사 구조
});
```

#### 3) 주기적 분석 API 호출 갱신 (미구현)
```dart
// 예: 하루 1회 최신 분석 결과 폴링
```

### 현재 코드 규모

- **클래스 라인 수**: 76줄
- **메서드 수**: 5개 (start, stop, dispose, _performCheck, kDebugMode log)
- **외부 의존성**: UpdateStateProvider, AppInfoProvider

### 스킬화 제안

**스킬 이름**: `/periodic-timer [name] [interval] [action]`

**입력 인자:**
```
name          : "sync-check" | "network-status" | "analytics-refresh"
interval      : "30s" | "5m" | "1h" | "6h"
action        : Provider/메서드명 (예: "updateStateProvider.notifier.check")
```

**자동 생성 내용:**
1. `{Name}Timer` 클래스 (start/stop/dispose)
2. `{name}TimerProvider` (Provider.autoDispose)
3. 초기화 메서드 (MainScreen에 통합)
4. 디버그 로깅
5. Unit test 템플릿

**사용 예시:**
```bash
/periodic-timer sync-check 5m "ref.read(syncProvider.notifier).sync()"
# → sync_check_timer_provider.dart 생성
```

**통합 패턴** (MainScreen):
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  ref.watch(updateCheckTimerProvider).start();  // 또는 notifier.start()
  ref.watch(syncCheckTimerProvider).start();
  return ...;
}
```

---

## 패턴 3: Platform-specific Service Wrapper

### 패턴 식별

**구현 파일들:**
- `lib/core/services/in_app_update_service.dart` (L1-106)
- `lib/presentation/providers/in_app_update_provider.dart` (L69-166)
- `lib/presentation/widgets/settings/app_info_section.dart` (L78-89, L107-176)

**핵심 개념:**
```dart
// 1. Platform 체크로 platform-specific 로직 분기
class InAppUpdateService {
  Future<AppUpdateInfo?> checkForUpdate() async {
    if (!Platform.isAndroid) return null;  // iOS는 null
    return await InAppUpdate.checkForUpdate();
  }
}

// 2. Provider에서도 platform 체크 필터링
class InAppUpdateNotifier {
  Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) {
      state = state.copyWith(status: InAppUpdateStatus.upToDate);
      return;  // iOS는 업데이트 불가
    }
  }
}

// 3. UI에서 platform 분기 처리
if (Platform.isAndroid) {
  await ref.read(inAppUpdateProvider.notifier).checkForUpdate();
  // Android 특화 로직
}
```

### 현재 코드 규모

**Service:**
- 클래스 라인 수: 106줄
- 메서드 수: 4개 (checkForUpdate, performImmediateUpdate, startFlexibleUpdate, completeFlexibleUpdate)

**Provider:**
- 클래스 라인 수: 166줄
- 상태 enum + state class + notifier

**UI:**
- `_checkForUpdates()`: 30줄
- `_handleInAppUpdate()`: 68줄

### 패턴의 한계

❌ **부분적 재사용만 가능** (대부분의 경우 Android-only 기능)

#### 재사용 가능한 분야

#### 1) Firebase Dynamic Links (Android/iOS 다르게 처리)
```dart
// Android: FCM + Deep link
// iOS: Universal Links + Deep link
```

#### 2) Biometric Auth (플랫폼별 지문 인식 API)
```dart
// Android: BiometricPrompt
// iOS: LocalAuthentication
```

#### 3) Share 기능 (플랫폼별 UI)
```dart
// Android: Android Share Sheet
// iOS: iOS Share Sheet
```

#### ⚠️ 대부분의 경우 `platform_specific_plugin`을 사용하므로, 순수 Dart 분기는 드물음

### 현재 코드 문제점

**중복된 Platform.isAndroid 체크:**
```dart
// 문제: Service에서 체크, Provider에서도 체크, UI에서도 체크 (3중 중복)
if (!Platform.isAndroid) return null;  // Service
if (!Platform.isAndroid) { ... return; }  // Provider
if (Platform.isAndroid) { ... }  // UI (app_info_section.dart:79)
```

**개선안:**
Platform 체크를 **서비스 내부에만** 집중화

```dart
// Service에서만 Platform 체크 → null 또는 값 반환
// Provider/UI에서는 null 체크만 수행
if (info == null) { /* handle not available */ }
```

### 스킬화 제안

**스킬 이름**: `/platform-service [name] [android-impl] [ios-impl]`

⚠️ **우선순위 낮음** (Android-only가 대부분 + 기존 플러그인으로 충분)

**생성할 경우 구조:**
```bash
/platform-service update-check "InAppUpdate" "URLFetcher"
# → platform_service_base.dart (abstract)
# → update_check_service.dart (impl)
# → platform_check 로직 내장
```

---

## 스킬 카탈로그와의 중복 검토

### 기존 스킬 카탈로그 현황

```markdown
# 현재 등록된 스킬 (47개)
- Commands: 11개
- Quality & Refactoring: 11개
- Testing & Recovery: 2개
- CI/CD: 2개
- Swarm: 3개
- Workflows: 12개
```

### 패턴별 중복 분석

#### Pattern 1: `/suppress-pattern` (신규 필요)
- 기존 스킬: **없음**
- 관련 스킬: `/database-expert` (DB 스키마) - 서로 다른 영역
- 상태: **신규 추가 권장**

#### Pattern 2: `/periodic-timer` (신규 필요)
- 기존 스킬: **없음**
- 관련 스킬: `/riverpod-widget-test-gen` (테스트만 담당)
- 상태: **신규 추가 권장**

#### Pattern 3: `/platform-service` (낮은 우선순위)
- 기존 스킬: `/resilience-expert` (에러 처리)
- 겹치는 부분: 약간 있음 (fallback 로직)
- 상태: **나중에 고려** (당분간 필요 없음)

---

## 스킬 파일 작성 계획

### 1. `/suppress-pattern` 스킬 (우선순위: P1)

**파일명:** `docs/skills/suppress-pattern.md`

**목차:**
```
1. 개요 & 사용 시기
2. 패턴 설명
3. 구현 단계 (7단계)
   - SharedPreferences 키 정의
   - DataSource 메서드 생성
   - Repository 인터페이스 확장
   - Repository 구현
   - State class 수정
   - StateNotifier 메서드 추가
   - Unit test 생성
4. 사용 예시 (3가지)
5. 검증 체크리스트
```

**예상 라인 수:** 250-350줄

### 2. `/periodic-timer` 스킬 (우선순위: P1)

**파일명:** `docs/skills/periodic-timer.md`

**목차:**
```
1. 개요 & 사용 시기
2. 패턴 설명
3. 구현 단계 (5단계)
   - Timer 클래스 생성
   - Provider 작성
   - MainScreen 초기화
   - 정리(cleanup) 로직
   - 디버그 로깅
4. 사용 예시 (2가지)
5. 자동화 가능 부분
6. 검증 체크리스트
```

**예상 라인 수:** 200-300줄

### 3. `/platform-service` 스킬 (우선순위: P3)

**파일명:** `docs/skills/platform-service.md`

**상태:** 문서화만 (아직 생성하지 않음)
**이유:** 현재 코드에서는 Android-only 사용으로 제한적

---

## 세션 학습 사항 (TIL 메모리화)

### 1. Timestamp-based Suppression Pattern

**개념:** 특정 시점(dismiss 시간)을 저장하고, 현재 시간과의 차이로 경과 시간을 계산

**재사용성:** ⭐⭐⭐⭐⭐ (매우 높음)

**공통 코드:**
```dart
// 고정 부분
Duration suppressDuration;  // 24h, 7d 등
DateTime? suppressedAt;

// 계산 속성
bool get isSuppressed =>
  suppressedAt != null &&
  DateTime.now().difference(suppressedAt!) < suppressDuration;
```

### 2. Periodic Timer Cleanup Pattern

**개념:** `Timer.periodic` + `Provider.autoDispose` + `ref.onDispose` 조합

**재사용성:** ⭐⭐⭐⭐ (높음, 주기성 필요한 경우)

**공통 코드:**
```dart
// 고정 부분
Timer? _timer;
bool _isDisposed = false;

void start() {
  _timer = Timer.periodic(interval, (_) => _action());
}

void dispose() {
  _isDisposed = true;
  _timer?.cancel();
}
```

### 3. Platform Check in Service Layer

**개념:** Platform 체크를 서비스에 집중화하여 UI/Provider 복잡도 감소

**재사용성:** ⭐⭐⭐ (중간, 플랫폼별 구현이 필요한 경우만)

**교훈:** 중복 Platform 체크 제거 → 테스트성 향상

---

## 실행 계획

### Phase 1: 스킬 문서 작성 (2시간)
- [ ] `/suppress-pattern` 스킬 작성 + 예시
- [ ] `/periodic-timer` 스킬 작성 + 예시
- [ ] 스킬 카탈로그 업데이트

### Phase 2: 스킬 테스트 (1시간)
- [ ] `/suppress-pattern 공지사항 1h` 테스트
- [ ] `/periodic-timer polled-sync 5m` 테스트

### Phase 3: 코드 개선 (선택사항)
- [ ] app_info_section Platform 체크 정리
- [ ] 기존 코드에 suppress-pattern 적용 (예: help_dialog)

---

## 결론

### ✅ 확정된 신규 스킬

| 스킬 | 우선순위 | 라인 수 | 재사용성 |
|------|---------|--------|---------|
| `/suppress-pattern` | P1 | 250-350 | ⭐⭐⭐⭐⭐ |
| `/periodic-timer` | P1 | 200-300 | ⭐⭐⭐⭐ |

### ⏳ 나중에 고려할 패턴

| 스킬 | 우선순위 | 이유 |
|------|---------|------|
| `/platform-service` | P3 | Android-only 특화, 플러그인 사용 추세 |

### 예상 효과

- **suppress-pattern**: 공지사항, 팁, 구독 권유 등 3+개 분야에서 즉시 적용 가능
- **periodic-timer**: 동기화, 연결 상태 확인 등 필요 시 재사용 가능
- **중복 코드 감소**: 20-30줄/기능
