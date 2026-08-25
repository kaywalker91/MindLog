# 현재 작업: v1.4.63 프로덕션 검토 중 (Play 자동 게시 대기)

## 현재 작업

**v1.4.63(versionCode 71) 프로덕션 승격 제출 완료 — Play 검토 중.** 사전 검사 통과 후 검토로 전송되며, 「관리형 게시」가 꺼져 있어 **검토 통과 시 자동 게시**된다. 출시 범위는 「전체 출시」(100%) — 1개국·설치 0.00% 규모에선 단계적 출시 실익이 없어 그대로 진행. 문제 발견 시 프로덕션 트랙에서 「출시 중단」 가능.

asset 검증은 기기 없이 종결했다 — `flutter build bundle` rc=0, 번들 내 `build/flutter_assets/docs/legal/privacy-policy.md` 가 저장소 원본과 **SHA256 완전 일치**(`2bd36259…`), 55행 = 정정된 이름 전송 문장. `privacy_policy_screen.dart:31` 이 정확히 그 경로를 `rootBundle.loadString` 하며 이번 릴리스에서 미변경.

**프로덕션은 아직 1.4.61(versionCode 69).** 방침 문구가 틀렸던 **versionCode 70 은 프로덕션에 나간 적이 없다** — 내부 테스터만 노출됐고 71 승격 시 건너뛴다. 따라서 프로덕션 사용자 기준 릴리스 노트는 **v1.4.62 + v1.4.63 합본**이어야 한다.

승격 방식: `fastlane deploy_production` **사용 금지**(`Fastfile:85` 가 `build` 를 먼저 호출해 AAB 를 새로 빌드 → versionCode 71 중복 + 로컬 GROQ_API_KEY + 미검증 아티팩트). Play Console 에서 **Internal → 프로덕션 승격**(같은 아티팩트 이동), 단계적 출시 20% 로 시작.

## 완료된 항목 (이번 세션)

시작은 "v1.4.63 착수할까?" 였고, 릴리스 + 프로덕션 승격까지 마쳤다.

| 작업 | 결과 |
|------|------|
| 🔴 위기상담 번호 109 통일 | 핸드오프엔 5파일이었으나 실제 **lib 6곳 + test 4곳**. `app_strings` `safety_constants` `prompt_constants` `analyze_diary_usecase`(2) `help_dialog`(2). **조사 교정 필수** — `help_dialog` 는 번호와 조사가 별도 `TextSpan` 이라 번호만 바꾸면 "109으로" 노출 |
| 🔴 방침 asset 재빌드 | `pubspec.yaml` 변경으로 CD 트리거 → versionCode 71 에 정정본 반영. **검증은 기기 없이 종결** — `flutter build bundle` 후 번들 파일이 저장소 원본과 SHA256 일치(`2bd36259…`) |
| 릴리스 | `1.4.62+70` → **`1.4.63+71`**. 커밋 `1dd9ad8`. CD run `32854926836` ✅ Internal 출시 |
| 프로덕션 승격 | 1.4.61(69) → **1.4.63(71)** 제출, 검토 중. **70 은 프로덕션에 나간 적 없음** — 틀린 고지 문구는 내부 테스터만 노출 |
| 출시 노트 | `ko/changelogs/71.txt`(314자) · `en-US/71.txt`(494자) 신규. v1.4.62+63 합본. **커밋 `f0e1068` 푸시 보류** |
| Health apps declaration | 백로그 오기 정정 — **원래 완료 상태였다**. 「정신 및 행동 건강」 항목만 추가(앱이 CBT 기법·인지왜곡 분류·위기 감지를 실제 구현). 2단계 지역별 요구사항은 현재 없음 |
| 품질 | analyze rc=0 · **1,748 테스트 그린**(영향 118건 선행) · pre-push 훅 재실행 통과 |

## 다음 단계

| 우선순위 | 작업 | 이유 |
|----------|------|------|
| **High** | **v1.4.63 앱 내 방침 화면 육안 대조 → 프로덕션 승격** | 위 두 High(방침 asset 재빌드 · 109 통일)는 커밋 `1dd9ad8` + CD `32854926836` success 로 **완료**. 남은 건 화면 검증뿐 |
| Medium | `cd.yml` `paths-ignore` 근본 수정 | 방침 asset 함정이 아직 살아 있다. `paths-ignore` 는 `!` 부정 패턴 미지원 → (a) `paths` 화이트리스트 전환 (b) asset 을 `docs/` 밖으로 이동 (c) 방침 수정 시 버전 범프 강제 체크 |
| Medium | `dart format` 드리프트 43파일 | `ci.yml:115` 가 `--set-exit-if-changed .` 검사 → **PR 여는 순간 실패**. `cd.yml` 은 미검사라 main 직push 로는 안 드러남. v1.4.63 변경분 9파일은 클린(교집합 0) |
| Medium | `action_item_preview` Analytics 전송 중단 검토 | AI 행동 제안 앞 50자를 전송 중. 방침에 적느니 끊는 편이 낫다 |
| Medium | 방침 URL을 GitHub Pages 로 이전 | Google Sites 임베드가 9,482자로 한도(~1만자)에 근접. 다음 문단 추가 시 넘칠 가능성 |
| Medium | Cloud Functions Node.js 20 → 22+ | **2026-10-30 decommission** |
| Low | 스토어 설명 비의료기기 면책 문구 | `android/fastlane/metadata/android/ko/full_description.txt`(263B)에 치료·진단·의료·효과 문구 **0건** 재확인 → 충돌할 주장 자체가 없어 선택적 하드닝. Medium 과대평가였음 |
| Low | `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` 직접 요청 재검토 | inexact 알람 폴백이 있는데도 요청. Play 정책상 허용 사례 아닐 가능성 (codex 지적) |
| Low | AI 생성 콘텐츠 인앱 신고 기능 | 생성형 AI 정책 적용 시 요구될 수 있음 |
| Low | Groq API 키 AAB 내장 → 서버 프록시 | `--dart-define` 은 바이너리에서 회수 가능 |
| Low | 서명 파일 없을 때 debug key 폴백 | `build.gradle.kts` — fail-closed 로 변경 권장 |
| Low | Functions orphan 정리 | `addMessage` `getStats` `checkIfSentToday` `markAsSent` `ApiResponse` — 인증 붙인 관리자 API 재도입 대비 존치 중 |

## 주의사항

- **백로그의 Play Console 상태는 콘솔에서 확인한 것만 적을 것.** 이 파일은 `Health apps declaration` 을 "미완료"로 적어 뒀으나 **실제로는 이미 제출돼 있었다**(2026-08-25 확인). 콘솔을 안 열고 추정으로 적은 항목이었고, 그 탓에 불필요한 확인 작업이 발생했다. 2단계 「지역별 요구사항」은 현재 아무것도 요구하지 않는다
- **`docs/legal/privacy-policy.md` 는 문서가 아니라 앱 asset이다** (`pubspec.yaml:136`, `privacy_policy_screen.dart:32` 가 `rootBundle` 로 읽음). 그런데 `cd.yml` `paths-ignore` 가 `docs/**` 를 제외하므로 **이 파일만 고치면 앱에 반영되지 않는다.** 반드시 앱 코드 변경과 같은 빌드에 실어야 한다. ← 이번 세션에서 실제로 당한 함정
- **저장 = 분석이다.** `diary_screen.dart:64` `_onSubmit()` → `_startAnalysis()` 가 유일 경로. `DiaryRepository.createDiary()` 는 인터페이스에만 있고 presentation 호출 0건. "분석 안 하면 전송 안 된다"는 **거짓**
- **이름/애칭도 Groq 로 전송된다** (`prompt_constants.dart:361-367`). 캐시 키에만 쓰이는 게 아니라 프롬프트 본문에 삽입된다. Play 의 `Name` 정의는 애칭(nickname)을 명시적으로 포함하므로 신고 대상
- **Data safety 재검토 트리거**: Firebase↔Ads/AdMob 연결, BigQuery export, 광고 ID 수집 활성화 중 하나라도 하면 **Shared = 아니오가 뒤집힌다**. 근거·판단 전문은 `docs/legal/play-data-safety.md`
- **IP 기반 위치도 신고 대상**: 위치 권한이 없어도 Performance 가 IP 수집, GA 가 마스킹 IP 에서 대략 위치 파생 → `Approximate location` 필수
- `user_name_dialog.dart:76,85` 가 "이름을 입력하세요"라고 물어 실명 입력을 유도한다. 의도가 애칭이면 문구 변경 권장(신고 의무는 불변, 수집 민감도만 하락)
- **RTK 출력 손상**: `ls`, `wc`, eslint JSON, `git diff --stat` 이 비거나 깨지면 `rtk proxy <cmd>` 로 재실행
- `.claude/settings.local.json.bak-allowwrite-20260721` — 로컬 권한 백업, 의도적으로 미추적 유지

## 마지막 업데이트
2026-08-25 / v1.4.63 릴리스 + 프로덕션 승격 제출 · 세션 `f0e1068`