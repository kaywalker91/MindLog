# 현재 작업: Health Check 리팩토링 — S0~S5 핵심 완료, S3/S6 백로그

## 현재 작업

`docs/refactor-plan-health-check-2026-07.md` 실행.
순서: **S0 → S1-A → S2 → S1-B → S4 → S5 → (S3) → (S6)**

→ **핵심 스프린트 S0~S5 전부 완료.** 잔여 = 후순위 **S3** · 선택 **S6**.

⚠️ **미push 16커밋** (`origin/main` = `fde28b7` session-wrap).
📌 **push 정책 (사용자 지시 2026-07-10)**: Health Check **전체 완료 후**에만 push.
   중간 스프린트 종료 시 push 제안 금지. S3/S6을 “전체”에 넣을지는 **사용자 결정**.

---

## 완료된 항목 (로컬 커밋, 미push)

| Sprint | 커밋(대표) | 핵심 |
|--------|------------|------|
| **S0** | `c03fde0` `28c143d` `c691417` | lint green · `scripts/arch-smoke.sh` · quality `--strict` |
| **S1-A** | `0c05e2d` | 데드코드 10파일 삭제 (prod 8 + test 2) |
| **S2** | `5b083c7` `4dde044` `623a51e` `7d4daed` | secret DI · onboarding domain API · SE UseCase 5종 · presentation→data **0** |
| **S1-B** | `38d2e79` | DateFormatter 단일 진입점 (인라인 DateFormat **0**) |
| **S4** | `a0cdc56` `064d152` `35de3fc` `11d9c43` | ReminderToggleCoordinator · DiaryInputForm · isCheerMeId |
| **S5** | `d3ccc47` `7ab329c` | cheerme/ 분해 · facade 729줄 (was 1262) · seed/RNG 의미 보존 |
| 핸드오프 | `df498e1` 등 docs | progress / 계획서 체크리스트 동기화 |

**최종 게이트 (S5 직후 실측)**: 전체 **1748** 테스트 통과 · analyze green · `arch-smoke --strict` 통과.

---

## 신규 구조물 (다음 세션이 알아야 할 것)

### 게이트 · 유틸
- `scripts/arch-smoke.sh` + `./scripts/run.sh arch-smoke` — quality Step에 **`--strict`** 편입.
  - `#!/bin/bash` → POSIX `grep` (zsh `rg` 함수 의존 금지).
- `DateFormatter` (`lib/core/utils/date_formatter.dart`) — 신규 인라인 `DateFormat` 금지.

### S2 domain / DI
- onboarding: `Get/CompleteOnboardingUseCase` + settingsRepository onboarding API.
- SE UseCase 5종 provider: `infra_providers.dart`.
- secret pin infra: `core/di/infra_providers.dart`.

### S4 presentation
- `lib/presentation/services/reminder_toggle_coordinator.dart`
  - sealed `ReminderEnableResult` (NeedExactAlarm / NeedBattery / Enabled+warnings / Disabled / Failed).
  - 위젯은 dialog/SnackBar **표시만**.
- `lib/presentation/widgets/diary/diary_input_form.dart`
  - 오버레이·햅틱·2초 타이머는 **DiaryScreen 로컬 유지** (분석 컨트롤러 이전 금지).
- diagnostic: `NotificationService.isCheerMeId` (1001–1007 전체).

### S5 cheerme/
```
lib/core/services/cheerme/
  cheer_me_weight.dart           # 감정 거리 → weights (순수, 유일)
  cheer_me_message_selector.dart # seed 결정론 + Random 레거시 분리
  cheer_me_queue_planner.dart    # plan / signature / payload / rebuild
  cheer_me_types.dart            # CheerMeQueuePlan 등
notification_settings_service.dart  # facade: applySettings / 권한 / FCM / @visibleForTesting override
```
- `CheerMeQueuePlan`은 facade에서 `export` — 기존 import 경로 유지.
- 단위 테스트: `test/core/services/cheerme/cheer_me_weight_test.dart`.

---

## 다음 단계

### 즉시 결정 (사용자)
1. **S3/S6을 이번 리팩토링 “완료”에 포함할지**  
   - 미포함 → S0~S5 컷오프 후 일괄 push 승인 가능  
   - 포함 → 해당 스프린트 후 push
2. push 승인 시: `git pull --rebase && git push` (**16커밋**, settings.json 제외)

### 백로그
| ID | 내용 | 비고 |
|----|------|------|
| **S3** | `korean_text_filter` → detector + corrector | 후순위, 순수 함수, 위험 낮음 |
| **S6** | ID Policy 내부 별칭 · sqlite 응집 · update provider · message_input_dialog 등 | 선택. Policy로 public 참조 통일 **금지**(내부 별칭만) |

### 수동 스모크 (화면 실행 세션 권장)
- Cheer Me 토글: 정확알람 거부 / 배터리 최적화 활성
- 일기 작성 → 분석 플로우 (DiaryInputForm 분리 후)
- 설정 진단: Cheer Me 예약 수 1001–1007 반영

---

## 주의사항 · 함정

### push
- **전체 완료 전 중간 push 금지** (사용자 지시).
- `.claude/settings.json` 수정 + `.bak` — **세션 무관, 커밋/손대지 않음**.

### 아키텍처
- `arch-smoke --strict`: `presentation→data` import / `PreferencesLocalDataSource()` 직접 생성 시 quality 실패.
- `SafetyBlockedFailure`, `safetyFollowupId=2004`, `isCheerMeId`, DB DROP 금지.

### DateFormatter
- `formatDate`(ko_KR) 경로 위젯 테스트 → `initializeDateFormatting('ko_KR')` 필수.

### SE 컨트롤러
- `ValidationFailure`만 catch→false, 영속화 오류(CacheFailure 등)는 전파.

### S5 Cheer Me (최중요)
- **가중치만 DRY** — deterministic(seed/SHA1) 경로와 legacy `selectMessage`(`Random`) **통합 금지**.
- 가중치 임계값 불변: 거리 ≤1.0 → 3, ≤3.0 → 2, else 1 (null written → 1).
- facade `@visibleForTesting` static override 유지 (깨면 알림 테스트 대량 레드).
- payload version / signature 알고리즘 호환 유지. ID 정책은 S5에서 **미변경**.

### arch-smoke 구현
- bash shebang → zsh 함수 `rg` 사용 불가 → POSIX `grep`.

---

## 미커밋 잔여 (의도적)
- `.claude/settings.json` (1줄 M) — 핸드오프/리팩토링과 무관, 커밋하지 않음.
- 본 progress 갱신은 커밋 여부는 다음 세션/사용자 선택 (직전 docs 커밋 이후 추가 갱신).

## 마지막 업데이트
2026-07-10 · 핸드오프 작성 · S0~S5 핵심 완료 · 16커밋 미push · S3/S6 백로그 · push 보류
