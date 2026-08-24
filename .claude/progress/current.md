# 현재 작업: 없음 (세션 종료 — v1.4.61 릴리스 + Functions 배포 완료)

## 현재 작업
없음 (세션 종료)

## 완료된 항목 (이번 세션)

FCM 마음케어 푸시 `{name}` 리터럴 노출 **근본 원인 규명 → 수정 → 릴리스 → 배포**까지 종결.

| 작업 | 결과 |
|------|------|
| 3자 교차 진단 | grok · agy · codex 병렬 실행 — 가설 4건 전원 확정, 각자 추가 경로 1건씩 제보 |
| 근본 원인 | 서버 `MESSAGES_BY_SLOT`의 `{name}` 4건 (v1.4.34 `68d46bb` 추가) + 클라 치환 삭제 (`ad6d021`) → `avgScore == null` 분기가 serverTitle 패스스루 |
| 수정 | 서버 템플릿 4건 비개인화 문구 교체 · 주석을 "금지 + 사유"로 교체 (spec REQ-073) |
| 회귀 테스트 | `constants.test.ts` 신설(118줄) + `firestore.service.test.ts` 보강. **수정 전 코드에서 15건 실패 확인**(비공허성 검증) |
| 릴리스 | `1.4.60+68` → **`1.4.61+69`**. CHANGELOG(개발자) · update.json(사용자) · index.html(채용담당자) 3종 톤 분리 |
| 커밋·push | `d92b2e3` `33f9041` `750451e` `09b1a87` — 12파일 +325/−51, origin/main 동기화 완료 |
| Functions 배포 | 4개 함수 ACTIVE, 배포 산출물 `{name}` 0건 검증. Extensions API 403 패치 유효 |
| CD | run 32728374194 ✅ — **1,748 테스트 통과** · Play Store **Internal track 업로드 성공** |

**origin/main = `09b1a87`** · ahead/behind 0/0.

## 다음 단계

| 우선순위 | 작업 | 이유 |
|----------|------|------|
| High | **내일 21:00 KST 발송분 확인** | 오늘치는 배포 42분 **전**에 이미 발송됨. 수정 실효는 다음 발송부터 |
| Medium | **클라 sanitize (진단 2번 항목)** | 서버 수정으로 정기 발송은 막혔으나 `http.ts` 수동 발송 + `fcm_service.dart:299-306` catch 폴백은 여전히 raw serverTitle 사용 |
| Medium | **Cloud Functions Node.js 20 → 22+** | **2026-10-30 decommission** — 이후 배포 불가. `firebase-functions@^5` 업그레이드에 breaking change 있음 |
| Low | Artifact Registry 정리 정책 | 컨테이너 이미지 누적 과금. `firebase functions:artifacts:setpolicy` (보존 기간 결정 필요) |
| Low | GH Actions 액션 버전 갱신 | `setup-java@v4` deprecated, checkout/upload-artifact Node20 타겟, Fastlane Ruby 3.3 요구 예정 |
| Low | 수동 스모크 · S3(#2) · S6(#3) | 이전 세션 잔여 백로그 |

## 주의사항

- **`{name}` 정본은 채널별로 다르다**: Cheer Me(로컬)=클라 치환, 마음케어(FCM)=**서버가 정본, `{name}` 금지**. 클라만 고치면 재발한다 (3회 반복된 오진).
- **공허한 테스트 주의**: "X가 없어야 한다"를 X 없는 입력으로 검증하면 항상 통과. 새 회귀 테스트는 `git show HEAD:<path>`로 되돌려 실패를 확인할 것.
- `EmotionScoreService.getRecentAverageScore()`는 예외를 삼키고 `null` 반환 → 백그라운드 isolate DB 실패가 서버 문구 폴백으로 조용히 유입된다.
- **RTK git diff 손상**: `git diff --stat/--numstat`가 비거나 `+0 -0`이면 `rtk proxy git diff ...`로 재실행. 이번 세션에서도 `ls`, `wc`, eslint JSON 출력 등이 동일하게 손상됨.
- `.claude/settings.local.json.bak-allowwrite-20260721` — 로컬 권한 백업, 의도적으로 미추적 유지.

## 마지막 업데이트
2026-08-24 / 세션 09b1a87 (v1.4.61 릴리스 · Functions 배포 · CD Internal track 성공)
