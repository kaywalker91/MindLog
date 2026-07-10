# 현재 작업: 리팩토링 계획서(Health Check) 실행 — S0~S1-B 완료, S4 대기

## 현재 작업

`docs/refactor-plan-health-check-2026-07.md` 순차 실행 중.
실행 순서: **S0 → S1-A → S2 → S1-B → S4 → S5 → (S3) → (S6)**
→ **S0 · S1-A · S2 · S1-B 완료 + strict 게이트 승격.** 다음은 **S4**.

⚠️ **미push 10커밋** (S0~S1-B 9 + 본 핸드오프; `origin/main` = `fde28b7` session-wrap).
📌 **push 정책 (사용자 지시 2026-07-10)**: Health Check 리팩토링 **전체 완료 후**에만 push.
   중간 스프린트(S4/S5 등) 종료 시 push 제안 금지. 완료 시점에 일괄 `pull --rebase && push`.

## 완료된 항목 (이번 세션 2026-07-10, 로컬 커밋만)

| Sprint | 커밋 | 핵심 |
|--------|------|------|
| **S0** | `c03fde0` | `prompt_constants.dart:471` lint info 해소 (`${visionScopeNote}`→`$visionScopeNote`) |
| **S0** | `28c143d` | `scripts/arch-smoke.sh` 신설 + `run.sh arch-smoke` + `quality` Step 2 편입 |
| **S1-A** | `0c05e2d` | 데드코드 10파일 삭제 (prod 8 + test 2) |
| **S2-A** | `5b083c7` | secret pin infra → `core/di/infra_providers.dart` 이전 |
| **S2-B** | `4dde044` | onboarding domain API (Repository 2메서드 + UseCase 2종 + UI 연결, TDD) |
| **S2-C** | `623a51e` | self-encouragement 컨트롤러 → UseCase 5종 (Reorder 신설) |
| **S2** | `7d4daed` | 계획서 S2 체크리스트 갱신 |
| **S1-B** | `38d2e79` | DateFormatter 단일 진입점 (API 5종 + 골든 9건, 인라인 DateFormat 0) |
| 승격 | `c691417` | `quality` arch-smoke → `--strict` (레이어 위반 회귀 차단) |

**최종 게이트**: 전체 **1731 테스트 통과** · lint green · `arch-smoke --strict` 통과.

### 신규 구조물 (다음 세션이 알아야 할 것)
- `scripts/arch-smoke.sh`: 불변식(즉시 실패) vs S2 목표(카운트) 2단. `--strict`로 후자도 실패 처리.
  - 각 스프린트 종료 시 `./scripts/run.sh arch-smoke`. `quality`에 이미 포함(strict).
  - **주의**: `#!/bin/bash`라 대화형 zsh의 `rg`(함수)를 못 씀 → POSIX `grep`으로 구현됨.
- `DateFormatter`(`lib/core/utils/date_formatter.dart`): 날짜 포맷 단일 원천.
  신규 인라인 `DateFormat(...)` 금지 — 여기에 API 추가 후 사용.
- onboarding: `Get/CompleteOnboardingUseCase` + `settingsRepository.is/setOnboardingCompleted()`.
- self-encouragement UseCase provider 5종: `infra_providers.dart`에 등록됨.

## 다음 단계

### push
- **전체 리팩토링 완료 전 금지.** S4·S5·(S3)·(S6 해당 시) 끝난 뒤 일괄 push.

### S4 — 알림 권한 오케스트레이션 + diary 위젯 분리 (~1일) [계획서 §Sprint 4]
- **4-A (P1 우선)**: `notification_section.dart`(452줄) `_handleReminderToggle`(~68줄) 권한 플로우를
  Controller/Coordinator로 이동. sealed `ReminderEnableResult`. 위젯은 표시만.
- **4-B (P2)**: `diary_screen.dart`(535줄) — **위젯 분리만** (`DiaryInputForm` 추출).
  오버레이(메시지·햅틱·2초 타이머)는 **Widget State 로컬 유지**. 분석 컨트롤러 이전 **금지**.
- **4-C**: `notification_diagnostic_widget.dart` ~L279 `n.id == 1001` →
  `NotificationService.isCheerMeId(n.id)` (큐 1001–1007 과소보고 버그).
- 검증: 수동 스모크(정확알람 거부/배터리 최적화) 필요 → **화면 실행 가능한 세션 권장**.

### 이후
- **S5** (notification_settings_service 1262줄 분해): **단독 세션 필수**. seed/RNG 의미 보존, 가중치만 DRY.
- **S3** (korean_text_filter 분리, 후순위), **S6** (선택: ID Policy 내부 별칭 / sqlite / update 응집 등).

## 주의사항

- **push = 전체 리팩토링 완료 후 일괄** (사용자 지시). 중간 push 금지. 현재 10커밋 미push.
- **arch-smoke --strict가 quality에 편입됨** → 신규 `presentation→data` import /
  `PreferencesLocalDataSource()` 직접 생성 시 품질 게이트 실패. S4 위젯 분리 시 data 직접 import 주의.
- **날짜 포맷**: 위젯이 `DateFormatter.formatDate`(ko_KR) 등을 타면, 그 위젯을 렌더하는 테스트는
  `initializeDateFormatting('ko_KR')` 필요 (미초기화 시 `LocaleDataException`). 이번에 3곳 보정함.
- **SE 컨트롤러 계약**: 검증 실패는 `ValidationFailure`만 catch→bool(false), 영속화 오류(CacheFailure 등)는
  전파. UseCase 추가 시 이 구분 유지.
- 보호 대상 불변: `SafetyBlockedFailure`, `safetyFollowupId=2004`, `isCheerMeId`, DB DROP 금지.
- `.claude/settings.json` 수정 + `.bak` 2개는 세션 무관 — 손대지 않음.

## 마지막 업데이트
2026-07-10 · 세션 `cd71ca90` · S0~S1-B + strict 승격 완료, S4 대기, 10커밋 미push (핸드오프 포함)
