# MindLog 리팩토링 계획서 (Health Check 기반)

> 작성일: 2026-07-10  
> 개정: 2026-07-10 (검토 피드백 반영 — 조건부 승인 보정)  
> 근거: 아키텍처 점검 브리핑 + 코드베이스 교차 검증 + 2차 설계 리뷰  
> 범위: 데드코드 · 레이어 위반 · 중복 패턴 · core 과밀 · presentation 로직 혼입  
> 현재 규모: `lib/` 221 Dart 파일, `test/` 117 Dart 파일  
> 승인 상태: **수정 반영 후 착수 가능 (조건부 승인 해소)**

---

## 0. 검증 요약 (브리핑 vs 실측)

| 항목 | 브리핑 | 실측 | 판정 |
|------|--------|------|------|
| 데드코드 참조 0건 | O | import 교차 검증 일치 (테스트 제외) | 확정 |
| `emotion_garden` / `activity_heatmap` 등 | O | 존재, production import 0 | 삭제 대상 |
| `expandable_text` 경로 | widgets 루트 | `widgets/common/expandable_text.dart` | 경로 보정 |
| `app_changelog` 경로 | utils | `core/constants/app_changelog.dart` | 경로 보정 |
| `DateFormatter` | 데드, 부활 권장 | production import 0, 인라인 DateFormat 5곳+ | 부활 확정 (**출력 호환 필수**) |
| self_encouragement UseCase | 4종 컨트롤러 우회 | 테스트만 사용; 컨트롤러는 Repository 직접 호출 (`reorder` 포함) | **5종 복구 (Reorder 포함)** |
| secret_diary data import | presentation 직접 | `secret_diary_providers.dart:4-5` 확인 | 이동 확정 |
| Preferences 직접 new | onboarding/splash | 양쪽 확인; domain onboarding API **없음** | **Repository+UseCase 신설** |
| `notification_settings_service` | 1262줄 | 1262줄, 테스트 ~1767줄 | 분해 시 테스트 동반 |
| 선택 로직 중복 | 통합 가능 | queue 생성=seeded deterministic (L1064), legacy `selectMessage`=`Random` (L1171) | **가중치만 공유, RNG 의미 보존** |
| `analysis_response_parser` | 441줄 | `lib/data/dto/…` 441줄 | 경로 보정 |
| update provider 5파일 | ~656줄 | 5파일 정확히 656줄 | 응집 권장 |
| `message_input_dialog` | 347줄 | **533줄** (성장) | 분해 우선도↑ |
| `diary_screen` | 네트워크 SM을 P0 | 535줄; 오버레이는 UI 효과(메시지·햅틱·2초 타이머) | **P2로 하향** (폼 분리만) |
| diagnostic `1001` | 상수 치환 | 큐는 1001–1007; `isCheerMeId` 존재 | **범위 카운트로 수정** |
| lint 기준선 | green 가정 | `prompt_constants.dart:471` 문자열 보간 info 1건 → `--fatal-infos` 실패 | **S0 선행** |
| 삭제 파일 개수 | “12개 + 테스트” | **production 8 + test 2 = 10** | 표기 보정 |

### 보호 대상 (전 스프린트 공통)

| 대상 | 제약 |
|------|------|
| `SafetyBlockedFailure` | 수정·삭제·시그니처 변경 금지 |
| `NotificationService.safetyFollowupId = 2004` | **값 불변** + **기존 public 상수·참조 유지** (`SafetyFollowupService.notificationId = NotificationService.safetyFollowupId` 경로 유지) |
| ID Policy 추출 시 | 외부 호출부는 기존 `NotificationService.safetyFollowupId` 를 계속 사용. Policy는 **내부 별칭/단일 정의 원천**만 담당. 참조 강제 이전 금지 |
| `sos_card.dart` | 구조 분해 최소화; 다크모드 색상만 신중 수정 |
| DB `_currentVersion` / `_onUpgrade` | DROP 금지; 스키마 변경 시 버전+1 동기화 |
| `@visibleForTesting` static 오버라이드 | core 분해 시 테스트 어댑터 유지 필수 |
| Cheer Me 선택 의미 | deterministic(seed) vs random(`Random`) **동작 불변**. 가중치 계산만 DRY |

### 검토 보정 요약 (이번 개정)

| # | 이슈 | 보정 |
|---|------|------|
| 1 | safety ID “참조 무변경” vs Policy 경유 충돌 | public 상수·기존 참조 유지, Policy는 내부 별칭만 |
| 2 | UseCase 100% vs `reorder()` 직접 Repo | `ReorderSelfEncouragementMessagesUseCase` 5번째로 추가 |
| 3 | 온보딩 옵션 B가 없는 API 의존 | SettingsRepository onboarding API + Get/Complete UseCase 신설; 공수 상향 |
| 4 | diary 오버레이 P0·컨트롤러 이동 과다 | P2; 오버레이는 UI 로컬 유지; `DiaryInputForm` 분리만 |
| 5 | S5 결정론/랜덤 단순 통합 위험 | 가중치 함수만 공유; seed/RNG 주입 선택기 |
| 6 | DateFormatter 출력 불일치 | 패턴별 API + 문자열 회귀 + `now` 주입 |
| 7 | diagnostic `1001` 상수 치환 불충분 | `NotificationService.isCheerMeId` |
| — | lint 기준선 실패 | **S0** 선행 |
| — | 아키텍처 스모크 주석뿐 | 실제 `rg`/스크립트 고정 (S0) |
| — | “12개 파일” 표기 | production 8 + test 2 |

---

## 1. 우선순위 매트릭스

| 우선순위 | 기준 | 스프린트 |
|----------|------|----------|
| **P0** | 기준선(lint)·레이어 위반·아키텍처 규칙 | S0, S2 |
| **P1** | 데드코드 노이즈, 권한 오케스트레이션 혼입, 알림 서비스 과밀 | S1-A, S4(알림), S5 |
| **P2** | DateFormatter 통합, diary 위젯 분리, KoreanTextFilter | S1-B, S4(diary), S3 |
| **P3** | UX 공통 래퍼, update 응집, ID Policy 내부 정리, sos 색상 | S6 |

---

## 2. 스프린트 로드맵 (개정 실행 순서)

```
S0  lint 기준선 + 아키텍처 검사 명령 고정     [≤1시간, 착수 게이트]
S1-A 데드코드 삭제 (prod 8 + test 2)         [≤1시간, 위험 최저]
S2  레이어 위반 해소 (secret + onboarding domain + SE 5 UseCase)  [1~1.5일]
S1-B DateFormatter 출력 호환 통합            [반나절]
S4  notification permission coordinator 우선
    + diary는 DiaryInputForm 위젯 분리만     [1일]
S5  notification_settings_service 분해
    (가중치 DRY, seed/RNG 의미 보존)         [1.5~2일]
S3  korean_text_filter 분리                  [반나절, 후순위]
S6  후속 (ID 내부 별칭 / sqlite / parser / update / UX) [선택]
```

**권장 커밋 단위**: 스프린트(또는 S1-A / S1-B) 1개 = PR 1개  
**병렬**: S1-A ∥ (S0 직후) 가능. S2 중에는 동일 컨트롤러 파일 충돌 주의. **S5 단독 세션**.

---

## Sprint 0 — 기준선 정상화 (착수 게이트)

### 목표
- 이후 모든 스프린트의 “lint green” 판정이 의미 있도록 기준선 복구
- 아키텍처 스모크를 재현 가능한 명령으로 고정

### 0-A. lint 1건 해소

**현상**: `./scripts/run.sh lint` 실패  
**원인**: `lib/core/constants/prompt_constants.dart:471` 문자열 보간 관련 **info** 1건이 `--fatal-infos`에 걸림  
**조치**: info 규칙에 맞게 보간/문자열 구성 수정 (리팩토링 범위 밖이지만 **게이트 블로커**)

```bash
./scripts/run.sh lint   # exit 0 필수
```

### 0-B. 아키텍처 스모크 명령 고정

아래 명령을 각 스프린트 종료 체크리스트에 그대로 사용한다. (주석만이 아닌 **실행 가능한 게이트**)

```bash
# 1) domain 레이어 Flutter import 0
rg -n "package:flutter" lib/domain --glob '*.dart' && echo 'FAIL: domain flutter import' || echo 'OK: domain pure'

# 2) presentation → data 직접 import (S2 이후 0 목표)
#    허용 예외가 생기면 이 목록에 문서화 후 제외 패턴 추가
rg -n "package:mindlog/data/" lib/presentation --glob '*.dart' || echo 'OK: no presentation→data'

# 3) PreferencesLocalDataSource 직접 인스턴스화 0 (S2 이후)
rg -n "PreferencesLocalDataSource\(\)" lib/presentation --glob '*.dart' || echo 'OK: no direct prefs new'

# 4) SafetyBlockedFailure 존재
rg -n "class SafetyBlockedFailure" lib/core/errors --glob '*.dart'

# 5) safetyFollowupId 값 2004 + SafetyFollowupService 연결 유지
rg -n "safetyFollowupId\s*=\s*2004" lib/core/services/notification_service.dart
rg -n "NotificationService\.safetyFollowupId" lib/core/services/safety_followup_service.dart

# 6) Cheer Me ID 헬퍼 유지
rg -n "static bool isCheerMeId" lib/core/services/notification_service.dart
```

선택: `scripts/arch-smoke.sh` 로 묶어 `./scripts/run.sh quality` 전 단계에 추가 (S0 또는 S2 말미).

### 0-C. 검증

```bash
./scripts/run.sh lint
# 관련 스모크 명령 수동 1회 실행 또는 scripts/arch-smoke.sh
```

### 예상 공수
- **≤ 1시간**

---

## Sprint 1-A — 데드코드 삭제

### 목표
- production 미참조 파일 제거로 탐색 노이즈 제거

### 삭제 목록 (production 8 + test 2 = **총 10개**)

| # | 파일 | 줄 수 | 비고 |
|---|------|------:|------|
| 1 | `lib/presentation/widgets/emotion_garden.dart` | 385 | |
| 2 | `test/presentation/widgets/emotion_garden_test.dart` | — | 동반 삭제 |
| 3 | `lib/presentation/widgets/activity_heatmap.dart` | 355 | 대체: statistics heatmap_card |
| 4 | `lib/presentation/widgets/settings_components.dart` | 153 | 대체: `settings/` |
| 5 | `lib/presentation/widgets/delete_all_diaries_dialog.dart` | 74 | data_management_section 인라인 |
| 6 | `lib/presentation/widgets/common/expandable_text.dart` | 171 | 미사용 |
| 7 | `lib/presentation/widgets/settings/settings.dart` | 9 | 중복 배럴; **유지**: `settings_sections.dart` |
| 8 | `lib/core/constants/app_changelog.dart` | 80 | 원격 JSON 전환 후 미참조 |
| 9 | `lib/core/utils/time_utils.dart` | 43 | |
| 10 | `test/core/utils/time_utils_test.dart` | — | 동반 삭제 |

**삭제하지 않음**

| 파일 | 이유 |
|------|------|
| `lib/core/utils/date_formatter.dart` | S1-B 부활 대상 |
| `lib/domain/usecases/self_encouragement/*` | S2에서 컨트롤러 연결 (+ Reorder 신설) |

### 검증

```bash
./scripts/run.sh lint
# 삭제 심볼 잔존 import 0
rg -n "emotion_garden|activity_heatmap|settings_components|delete_all_diaries_dialog|expandable_text|app_changelog|time_utils" lib test --glob '*.dart' || echo 'OK'
```

### 예상 공수
- **≤ 1시간**

---

## Sprint 2 — 레이어 위반 해소 + UseCase 복구

### 목표
- presentation → data 직접 의존 제거
- 온보딩을 **domain 경유**로 전환 (DataSource provider 직접 watch는 불충분)
- self_encouragement: **CRUD 4 + Reorder 1 = 5 UseCase** 전부 컨트롤러 경유

### 2-A. secret_diary infra 이동

**현재** (`secret_diary_providers.dart`):
- `SecureStorageDataSource` / `SecretPinRepositoryImpl` 를 presentation에서 import·조립

**변경**
1. `lib/core/di/infra_providers.dart`에 추가:
   - `secureStorageDataSourceProvider`
   - `secretPinRepositoryProvider`
2. `secret_diary_providers.dart`에서는 **domain UseCase provider만** 유지
3. data import 제거

**검증**
```bash
rg -n "package:mindlog/data/" lib/presentation --glob '*.dart' || echo 'OK'
```

### 2-B. onboarding / splash — domain API 신설 (옵션 A 폐기)

**현재 문제**
- `onboarding_screen.dart:105` — `PreferencesLocalDataSource().setOnboardingCompleted()`
- `splash_screen.dart:52` — `PreferencesLocalDataSource().isOnboardingCompleted()`
- `SettingsRepository`에 온보딩 조회·완료 API **없음**
- 옵션 A (`ref.read(preferencesLocalDataSourceProvider)`)는 import만 숨길 뿐 **화면이 DataSource를 직접 쓰는 구조** → 레이어 위반 해소로 인정하지 않음

**필수 설계 (개정 확정)**

| 레이어 | 추가 |
|--------|------|
| `SettingsRepository` | `Future<bool> isOnboardingCompleted()` / `Future<void> setOnboardingCompleted()` |
| `SettingsRepositoryImpl` | `PreferencesLocalDataSource` 위임 |
| domain UseCase | `GetOnboardingCompletedUseCase` / `CompleteOnboardingUseCase` (이름 협의 가능) |
| DI | UseCase provider 등록 |
| UI | splash/onboarding은 UseCase provider만 `ref.read` |

**구현 체크리스트**
1. Repository 인터페이스 + impl + 단위 테스트
2. UseCase 2종 + 테스트
3. 화면을 Riverpod Consumer로 정리 후 UseCase 호출
4. `PreferencesLocalDataSource()` production **0건**
5. presentation → data import 0 (prefs 포함)

### 2-C. self_encouragement UseCase 복구 (**5종**)

**현재 문제**
- 기존 UseCase 4종: validation + repository 호출 완비, 프로덕션 미연결
- 컨트롤러가 validation 재구현 + `_repository` 직접 호출
- **`reorder()` (L225)** 가 `reorderSelfEncouragementMessages` Repository 직접 호출 → 4종만 연결하면 “UseCase 100%” 실패

**UseCase 목록 (확정)**

| UseCase | 상태 |
|---------|------|
| `AddSelfEncouragementMessageUseCase` | 기존 → 연결 |
| `UpdateSelfEncouragementMessageUseCase` | 기존 → 연결 |
| `DeleteSelfEncouragementMessageUseCase` | 기존 → 연결 |
| `GetSelfEncouragementMessagesUseCase` | 기존 → 연결 |
| `ReorderSelfEncouragementMessagesUseCase` | **신규** → 연결 |

**변경**
1. Reorder UseCase 신설 (index 검증 정책 필요 시 UseCase에 위치)
2. infra에 UseCase provider **5개** 등록
3. 컨트롤러 `build` / `add` / `update` / `delete` / `reorder` 전부 UseCase `execute()`
4. 컨트롤러 내 중복 validation 제거
5. 컨트롤러 책임: Failure → UI 메시지 + cheer-me reschedule 오케스트레이션만
6. 컨트롤러 테스트 mock 대상을 UseCase 쪽으로 조정

**성공 지표 (모호성 제거)**
- “컨트롤러의 Repository 직접 호출 **0건**” (CRUD + reorder 전부)
- 부분 지표 “CRUD 4종만” 은 **채택하지 않음**

### 2-D. 커밋 계획
1. `fix(arch): move secret pin infra to di providers`
2. `feat(arch): add onboarding settings repository and usecases`
3. `refactor: wire self-encouragement controller to five usecases`

### 예상 공수
- secret: 1~2시간  
- onboarding domain 풀스택: 0.5~1일  
- self_encouragement 5 UseCase: 0.5일  
- **합계: 1~1.5일** (구 “반나절” 폐기)

---

## Sprint 1-B — DateFormatter 부활 (출력 호환 우선)

### 목표
- 날짜 포맷 단일 진입점 확립
- **기존 화면 출력 문자열 불변** (회귀 테스트로 고정)

### 현재 인라인 vs 기존 DateFormatter 불일치 (핵심)

| 호출부 | 실제 패턴 | 기존 `DateFormatter`로 치환 시 |
|--------|-----------|--------------------------------|
| `diary_detail_screen.dart` | `yyyy년 MM월 dd일 (E) a hh:mm` | `formatFullDateTime` = `yyyy년 M월 d일 a h:mm` → **요일 없음, 제로패딩 없음, 출력 변경** |
| `diary_item_card.dart` | `MM월 dd일 (E)` | 해당 API 없음 |
| `emotion_calendar` 등 | `yyyy년 M월 d일` | `formatDate` 일치 가능 |
| `message_card` `_DateFormatter` | 상대 +「작성」 | `formatRelative` 와 문구/경계 상이 |

### API 확장 (출력 1:1 보존)

```dart
// 기존 유지 (다른 호출부용)
formatFullDateTime / formatDate / formatShortDate / formatTime / formatRelative / isToday

// 신규 — 호출부 실측 패턴 고정
static String formatDetailDateTime(DateTime dt);
// → 'yyyy년 MM월 dd일 (E) a hh:mm', ko_KR  (diary_detail)

static String formatListDate(DateTime dt);
// → 'MM월 dd일 (E)', ko_KR  (diary_item_card)

static String formatChartShort(DateTime dt);   // M/d
static String formatChartTooltip(DateTime dt); // M월 d일 (기존 formatShortDate와 동일 가능 시 위임)

static String formatRelativeWritten(
  DateTime date, {
  DateTime? now, // 테스트 주입 — 상대 날짜 결정론
});
// → 오늘 작성 / 어제 작성 / N일 전 작성 / M월 d일 작성
```

### 구현 순서 (TDD)
1. **문자열 회귀 테스트 먼저** (`date_formatter_test.dart`)
   - detail / list / chart / relativeWritten 골든 스트링
   - `formatRelativeWritten` / `formatRelative` 에 `now:` 주입으로 자정·경계 케이스
2. API 구현
3. 호출부 교체 + `message_card` private `_DateFormatter` 삭제
4. **기존 메서드로 억지 매핑 금지** (detail → full 치환 등)

### 검증

```bash
fvm flutter test test/core/utils/date_formatter_test.dart
./scripts/run.sh lint
```

### 예상 공수
- **반나절**

---

## Sprint 4 — Presentation: 알림 권한 오케스트레이션 + diary 위젯 분리

### 4-A. P1 `notification_section.dart` (452줄) — **우선**

**문제**
- `_handleReminderToggle` ~68줄: 정확알람 → 배터리 최적화 → 다이얼로그 → SnackBar → settings update
- 위젯이 `NotificationPermissionService` 직접 오케스트레이션

**제안**
1. `NotificationSettingsController` 또는 `ReminderToggleCoordinator` / permission **gateway** 에 권한 플로우 이동
2. sealed result:
   ```dart
   sealed class ReminderEnableResult {
     // enabled / needExactAlarmPrompt / needBatteryPrompt / deniedPartial / failed
   }
   ```
3. 위젯은 result에 따라 dialog/SnackBar **표시만**
4. SharedPreferences 직접 접근이 있으면 permission service / repository로 흡수

**검증**
```bash
fvm flutter test test/presentation/providers/notification_settings_controller_test.dart
# 수동: 정확알람 거부 / 배터리 최적화 켜짐
```

### 4-B. P2 `diary_screen.dart` (535줄) — **위젯 분리만**

**판정 개정**: 기존 P0 → **P2**. 네트워크 오버레이를 분석 컨트롤러로 옮기지 않는다.

**이유**
- 오버레이 메시지·햅틱·2초 타이머는 **화면 효과(UI 상태)** (`diary_screen` ~L145 일대)
- 분석 비즈니스 상태와 결합 시 책임이 더 섞임

**허용 작업**
1. `_buildInputForm` → `DiaryInputForm` (`widgets/diary/` 등) 파일 분리
2. 오버레이 3필드 + 타이머/햅틱은 **Widget State 로컬 유지**  
   - 필요 시 같은 파일 내 private mixin / 소형 `DiaryNetworkOverlayController`(순수 UI, Riverpod 비즈니스 Notifier 아님) 정도만 허용
3. 이미지 목록·작성 날짜는 폼 로컬 유지

**금지**
- `DiaryAnalysisController`에 overlay visible/message/type 이전
- “상태머신 컨트롤러 이관”을 이 스프린트 완료 조건으로 삼지 않음

**검증**
- 오프라인 → overlay → 재시도 수동 스모크
- 폼 분리 후 analyze 플로우 회귀

### 4-C. diagnostic Cheer Me 카운트 수정 (S4 또는 S6 조기)

**문제**
- `notification_diagnostic_widget.dart` ~L279: `n.id == 1001` 만 카운트
- 실제 큐: `dailyReminderId`..`+cheerMeQueueLength-1` (1001–1007)
- `NotificationService.isCheerMeId(int id)` **이미 존재**

**수정**
```dart
final cheerMeCount = data.pendingNotifications
    .where((n) => NotificationService.isCheerMeId(n.id))
    .length;
```
- `dailyReminderId` 상수 치환만으로는 **버그 미해결**

### 4-D. 기타 P2 (여유 시)
- `message_input_dialog.dart` (533줄) → 서브위젯 분해

### 예상 공수
- 알림 coordinator: 0.5~1일  
- diary 폼 분리: 2~3시간  
- diagnostic 수정: 30분  
- **합계: 약 1일**

---

## Sprint 5 — `notification_settings_service` 분해

### 목표
- 1262줄 오케스트레이션과 순수 알고리즘 분리
- **결정론 큐 생성 vs legacy 랜덤 API의 동작 의미 보존**
- `@visibleForTesting` static override 계약 유지

### 현재 책임 맵 (실측)

| 구간(대략) | 책임 | 난수 의미 |
|-----------|------|-----------|
| L20–72 | DTO/plan 타입 | — |
| L73–166 | 싱글톤 + 테스트 오버라이드 | — |
| L167–281 | 권한 / FCM | — |
| L282–637 | applySettings 오케스트레이션 | — |
| L638+ / 큐 빌드 | 서명·페이로드·큐 | **seeded deterministic** (`_selectDeterministic*`, L1064) |
| L1171 `selectMessage` | 테스트/레거시 API | **`Random()` 비결정** |
| emotion weight | L1073–1087 등과 legacy 쪽 유사 블록 | **공유 가능 (순수 가중치)** |

### 금지 / 허용

| 금지 | 허용 |
|------|------|
| deterministic 경로를 `Random` 으로 통합 | 감정 거리 → weight 배열 계산 함수 1곳 |
| legacy `selectMessage` 를 seed 전용으로 바꿔 테스트 의미 변경 | `CheerMeMessageSelector` 가 `int Function(int max)` / `Random` / `seed` 주입 |
| 가중치 임계값(1.0 / 3.0 → 3/2/1) 변경 | queue planner 추출, facade delegate |

### 목표 구조

```
lib/core/services/cheerme/
  cheer_me_weight.dart           # emotion distance → weights (순수, 유일)
  cheer_me_message_selector.dart # selectDeterministic*(seed) + selectRandom*(rng)
  cheer_me_queue_planner.dart    # 큐 계획·서명·페이로드
  cheer_me_types.dart
notification_settings_service.dart  # applySettings / 권한 / FCM / 테스트 훅 facade
```

### 구현 순서 (TDD)
1. 가중치 순수 함수 추출 + 단위 테스트 (결정론/레거시 **양쪽 호출**)
2. Selector에 seed 경로 / RNG 경로 분리 유지; 기존 `selectMessage` public 시그니처·랜덤 의미 유지
3. QueuePlanner 추출
4. facade static override 유지 → 테스트 diff 최소화
5. `notification_settings_service*_test.dart` (~1767줄) 그린

### 보호
- payload version / signature 알고리즘 호환
- **ID 정책 이 스프린트 미변경**
- safety ID 비관련이나 Cheer Me 알림 회귀에 주의

### 예상 공수
- **1.5~2일**

---

## Sprint 3 — `korean_text_filter` 분리 (후순위)

> 실행 순서상 **S5 이후**. 순수 함수라 위험은 낮으나 제품 임팩트 대비 우선도 하향.

### 목표
- 순수 함수 3책임을 파일 단위로 분리, 파사드 유지로 **호출부 무변경**

### 목표 구조

```
lib/core/utils/korean_text/
  language_detector.dart
  korean_grammar_corrector.dart
  korean_text_filter.dart     # 기존 public API 파사드
```

**호환**: `package:mindlog/core/utils/korean_text_filter.dart` 경로 유지 (re-export)  
**검증**: `fvm flutter test test/core/utils/korean_text_filter_test.dart`

### 예상 공수
- **반나절**

---

## Sprint 6 — 후속 (선택)

### 6-A. `NotificationIdPolicy` — **내부 별칭만** (안전 ID 규칙 충돌 해소)

**확정 규칙**
1. `NotificationService.safetyFollowupId = 2004` **값·public 심볼 유지**
2. `SafetyFollowupService.notificationId = NotificationService.safetyFollowupId` **참조 경로 유지**
3. Policy 도입 시:
   - 단일 정의 원천을 Policy private/const 로 두고
   - `NotificationService.safetyFollowupId` 가 그 값을 **노출하는 별칭**
   - 호출부를 Policy 로 **일괄 이전하지 않음** (외부 참조 무변경)

```dart
// 허용 패턴 (개념)
class NotificationIdPolicy {
  static const int safetyFollowup = 2004;
  // cheer me range …
}
class NotificationService {
  static const int safetyFollowupId = NotificationIdPolicy.safetyFollowup; // 별칭
}
// SafetyFollowupService 는 여전히 NotificationService.safetyFollowupId
```

**금지**: “모든 참조를 Policy 경유로 통일” 문구/작업.

### 6-B. diagnostic
- S4-C 미실시 시 여기서 `isCheerMeId` 적용

### 6-C. `sqlite_local_datasource`
1. `GroqCacheDao` 우선 분리
2. migration 체인 파일화 — onCreate/onUpgrade 동기 체크리스트
3. DROP 금지

### 6-D. `analysis_response_parser`
- 폴백 문자열 중앙화 (카피 결정 후)
- `_validateJsonStructure` 분할
- `is_emergency` regression 유지

### 6-E. update provider 응집
```
lib/presentation/providers/update/
  … (5 files + barrel)
```
- public provider 이름 유지, export 경로만 변경

### 6-F. UX 공통화
| 패턴 | 제안 |
|------|------|
| 삭제 확인 3벌 | `ConfirmDialog` |
| `styleFrom` 다수 | `AppButtonStyles` |
| 바텀시트 핸들 | `AppBottomSheet.show` |

### 6-G. P3 `sos_card` 색상만
- `AppTextStyles.body` → theme-aware
- 위기 플로우 **무변경**

---

## 3. 의존 관계 (개정)

```
S0 ──► S1-A ──► S2 ──► S1-B ──► S4 ──► S5 ──► S3 ──► S6
         │         │
         └─ 병렬 제한: S1-A 후 S2 권장(게이트 명확)
            S1-B는 S2와 파일 겹침 적어 S2 후반 병렬 가능
```

| 관계 | 설명 |
|------|------|
| S0 필수 선행 | lint green 없으면 이후 게이트 무의미 |
| S1-A 먼저 | 노이즈 제거, 리뷰 범위 축소 |
| S2 다음 | 아키텍처 P0; onboarding 공수 큼 |
| S1-B는 S2 후 | DateFormatter는 독립이나 리뷰 순서상 출력 호환 테스트 여유 확보 |
| S4 | 알림 gateway 우선; diary는 분리만 |
| S5 | 알림 코어 — S4와 파일 일부 겹칠 수 있어 **S4 후 단독** |
| S3 | 후순위 (안전하지만 급하지 않음) |
| S6 | S5 이후 ID 내부 별칭 / sqlite |

---

## 4. 전체 검증 게이트

각 스프린트 종료 시:

```bash
./scripts/run.sh lint
# 범위 테스트 우선, 머지 전:
./scripts/run.sh test
# §0-B 아키텍처 스모크 (해당 스프린트 관련 항목)
```

S0 이전에는 lint 실패가 정상임을 인지; S0 완료 후부터 “lint green” 필수.

---

## 5. 커밋 컨벤션 (개정)

| Sprint | Conventional Commit 예시 |
|--------|--------------------------|
| S0 | `fix: resolve prompt_constants lint info blocking fatal-infos` |
| S0 | `chore: add arch-smoke script` (선택) |
| S1-A | `chore: remove unused presentation widgets and utils` |
| S2 | `fix(arch): move secret pin infra to di providers` |
| S2 | `feat(arch): add onboarding settings api and usecases` |
| S2 | `refactor: wire self-encouragement controller to five usecases` |
| S1-B | `refactor: revive DateFormatter with output-compatible APIs` |
| S4 | `refactor: extract reminder enable permission orchestration` |
| S4 | `refactor: extract DiaryInputForm widget` |
| S4 | `fix: count cheer-me queue with isCheerMeId` |
| S5 | `refactor: extract cheer-me weight and selectors preserving rng semantics` |
| S3 | `refactor: split KoreanTextFilter into detector and corrector` |
| S6 | `refactor: introduce NotificationIdPolicy as internal alias only` |

---

## 6. 리스크 레지스터 (개정)

| 리스크 | 영향 | 완화 |
|--------|------|------|
| lint 기준선 미복구 | 모든 스프린트 게이트 무의미 | **S0 필수** |
| safety ID 참조 강제 이전 | SafetyFollowup 단절 | public 별칭 유지, 호출부 무변경 |
| SE UseCase 4종만 연결 | reorder Repo 직접 호출 잔존 | **5번째 Reorder UseCase** |
| 온보딩 옵션 A | 레이어 위반 잔존 | Repository+UseCase 필수, 공수 반영 |
| diary overlay → 분석 컨트롤러 | UI/비즈니스 재결합 | P2, 로컬 UI 유지 |
| S5 seed/Random 통합 | 스케줄·테스트 동작 변경 | 가중치만 DRY, RNG 주입 분리 |
| DateFormatter 기존 API 억지 매핑 | 상세 화면 표시 변경 | `formatDetailDateTime` + 골든 테스트 |
| diagnostic `== 1001` | Cheer Me 예약 수 과소 보고 | `isCheerMeId` |
| core static test override 깨짐 | S5 대량 레드 | facade override 유지 |
| sqlite migration 어긋남 | 데이터 유실 | DROP 금지, 동기 체크리스트 |

---

## 7. 성공 지표 (개정)

| 지표 | Before (실측) | After 목표 |
|------|---------------|------------|
| `./scripts/run.sh lint` | fail (info 1) | pass |
| production 데드 위젯/유틸 | 8 파일 | 0 |
| presentation → data import | secret 조립 + prefs new | **0** |
| onboarding domain API | 없음 | Get/Complete UseCase 경유 |
| self_encouragement Repo 직접 호출 | add/update/delete/get/reorder | **0** (UseCase 5종) |
| DateFormat 인라인 | 5+ 파일 | DateFormatter; **detail 출력 문자열 동일** |
| diagnostic Cheer Me 카운트 | id==1001 만 | `isCheerMeId` 범위 |
| diary overlay 위치 | Widget State | **유지** (분석 컨트롤러 비이전) |
| `notification_settings_service` | 1262줄 | 오케스트레이션 축소; seed/random 의미 동일 |
| `korean_text_filter` | 584줄 단일 | 파사드 + 2 모듈 (후순위) |
| `safetyFollowupId` 외부 참조 | `NotificationService` | **동일 경로 유지** |

---

## 8. 즉시 실행 체크리스트

### S0 ✅ (2026-07-10 완료)
- [x] `prompt_constants.dart` lint info 해소 (`${visionScopeNote}` → `$visionScopeNote`)
- [x] `./scripts/run.sh lint` exit 0 ("No issues found!")
- [x] 아키텍처 스모크 명령 스크립트 고정 (`scripts/arch-smoke.sh` + `run.sh arch-smoke` + `quality` Step 2/5)

### S1-A ✅ (2026-07-10 완료)
- [x] production 8파일 삭제
- [x] test 2파일 삭제 (`emotion_garden_test`, `time_utils_test`)
- [x] 잔존 import 0 (심볼명 포함 교차 검증)
- [x] lint green + arch-smoke 통과

### S2 ✅ (2026-07-10 완료)
- [x] secret DI 이동 (S2-A)
- [x] onboarding Repository + UseCase 2 + UI 연결 (S2-B, TDD)
- [x] SE UseCase 5 (Reorder 신설 포함) + 컨트롤러 Repo 직접 호출 0 (S2-C)
- [x] presentation → data import 0 + prefs 직접 생성 0 (arch-smoke --strict PASS)
- [x] 전체 테스트 1722건 green

### S1-B ✅ (2026-07-10 완료)
- [x] `formatDetailDateTime`/`formatListDate`/`formatChartShort`/`formatChartTooltip`/`formatRelativeWritten` 출력 호환 API + 골든 테스트 9건
- [x] `now` 주입 상대 날짜 테스트 (formatRelativeWritten)
- [x] 호출부 5파일 교체 + day_cell param 제거 (억지 매핑 없음) — 인라인 DateFormat **0**
- [x] 전체 1731건 green (ko_KR 로케일 초기화 테스트 3곳 보정)

### S4
- [x] reminder permission coordinator (`ReminderToggleCoordinator` + sealed `ReminderEnableResult`)
- [x] `DiaryInputForm` 분리 (overlay 로컬 유지)
- [x] diagnostic `isCheerMeId`

### S5+
- [ ] 가중치 DRY, seed/RNG 분리 선택기
- [ ] S3 / S6은 백로그

---

## 9. 다음 액션

1. **착수 순서 확정**: S0 → S1-A → S2 → S1-B → S4 → S5 → (S3) → (S6)
2. 구현 시작 시 S0부터 진행
3. S2 onboarding 공수(1~1.5일 스프린트 전체) 일정 버퍼 확보
4. S5 착수 전 deterministic/legacy 테스트 스위트를 기준선으로 기록

---

## 부록 A. 삭제 파일 수 정정

| 구분 | 개수 |
|------|-----:|
| production 삭제 | 8 |
| test 삭제 | 2 |
| **합계** | **10** |
| 문서 구 표기 “12개 + 테스트” | **폐기** |

## 부록 B. 구 계획 대비 변경 일람

| 구 계획 | 신 계획 |
|---------|---------|
| S1 통합 (삭제+DateFormatter) | S1-A 삭제 / S1-B DateFormatter (S2 뒤) |
| S2 반나절, 옵션 A/B | S2 1~1.5일, 온보딩 domain 필수, SE 5 UseCase |
| diary P0 컨트롤러 이동 | diary P2 폼 분리만, overlay UI 유지 |
| S3 안전 선행 | S3 후순위 (S5 뒤) |
| S5 선택 로직 통합 | 가중치만 통합, seed/RNG 분리 |
| S6 Policy로 참조 통일 | Policy 내부 별칭, public 참조 유지 |
| diagnostic dailyReminderId | `isCheerMeId` |
| lint green 가정 | S0로 기준선 복구 |
| 아키텍처 스모크 주석 | 실행 가능 `rg` 명령 |
