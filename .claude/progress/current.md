# 현재 작업: 리팩토링 계획서(Health Check) 실행 — S0~S5 완료, S3/S6 백로그

## 현재 작업

`docs/refactor-plan-health-check-2026-07.md` 순차 실행 중.
실행 순서: **S0 → S1-A → S2 → S1-B → S4 → S5 → (S3) → (S6)**
→ **S0~S5 핵심 스프린트 완료.** 남은 것은 후순위 **S3** · 선택 **S6**.

⚠️ **미push 커밋** (`origin/main` = `fde28b7`).
📌 **push 정책 (사용자 지시 2026-07-10)**: Health Check 리팩토링 **전체 완료 후**에만 push.
   S3/S6을 “전체”에 포함할지는 사용자 결정 — 핵심 경로(S0~S5)는 완료.

## 완료된 항목

### S0 ~ S4 (이전)
lint · arch-smoke · 데드코드 · 레이어 위반 해소 · DateFormatter · ReminderToggleCoordinator · DiaryInputForm · isCheerMeId

### S5 (2026-07-10 이번 세션)
| 모듈 | 역할 |
|------|------|
| `cheerme/cheer_me_weight.dart` | 감정 거리 → 가중치 순수 함수 (결정론/레거시 공유) |
| `cheerme/cheer_me_message_selector.dart` | seed 결정론 경로 + `Random` 레거시 경로 **분리 유지** |
| `cheerme/cheer_me_queue_planner.dart` | 큐 plan · signature · payload · rebuild |
| `cheerme/cheer_me_types.dart` | CheerMeQueuePlan 등 타입 |
| `notification_settings_service.dart` | facade (applySettings / 권한 / FCM / 테스트 override) **729줄** (was 1262) |

**보호 확인**: static override 유지 · `selectMessage` public 시그니처·Random 의미 유지 · payload version/signature 호환 · ID 정책 미변경

**게이트**: 전체 **1748** 테스트 통과 · analyze green · `arch-smoke --strict` 통과

## 다음 단계

### 백로그 (후순위/선택)
- **S3**: `korean_text_filter` 분리 (detector/corrector)
- **S6**: ID Policy 내부 별칭 / sqlite / update 응집 / message_input_dialog 등

### push
- 사용자: 전체 완료 후 일괄. S3/S6 포함 여부 확인 후 `git pull --rebase && git push`.

## 주의사항

- **S5 함정**: deterministic 큐를 `Random`으로 통합 금지. 가중치만 DRY.
- Cheer Me 가중치 임계값(1.0→3, 3.0→2, else 1) 변경 금지.
- facade `@visibleForTesting` override 깨지 말 것.
- push 중간 금지 정책 유지(사용자 지시).
- 보호: SafetyBlockedFailure, safetyFollowupId=2004, isCheerMeId, DB DROP 금지.
- `.claude/settings.json` 손대지 않음.

## 마지막 업데이트
2026-07-10 · S5 완료 (cheerme 분해 + facade), S3/S6 백로그, push 보류
