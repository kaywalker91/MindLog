# 현재 작업: 없음 (세션 종료 — v1.4.62 릴리스 + 개인정보 고지 정합화)

## 현재 작업
없음 (세션 종료)

## 완료된 항목 (이번 세션)

시작은 "Play 심사가 멈춰 있는데 오류인가?" 였고, **심사 정체는 오류가 아니었으나 조사 과정에서 실제 결함 3건**이 나와 전부 처리했다.

| 작업 | 결과 |
|------|------|
| 심사 정체 진단 | grok · agy · codex 3자 교차 검토. **오류 아님 — 정상 대기**로 판정. CD run `32728374194` success, 실패 스텝 0건 |
| 🔴 인증 없는 엔드포인트 제거 | `http.ts` 삭제(215줄). `sendMindcareNotification`/`addMindcareMessage`/`getMindcareStatus` 가 `cors:true` + 인증 0줄. 앱 호출부 0건 확인 후 삭제 → **프로덕션 반영, 404 확인** |
| 🔴 온보딩 거짓 고지 수정 | `onboarding_screen.dart:61` "외부로 전송되지 않으니 안심하세요" → 실제로는 **저장=분석**이라 모든 일기 본문이 Groq(미국) 전송. 정반대 고지였음 |
| 🔴 개인정보 처리방침 전면 재작성 | 기존은 `App Privacy Policy Generator` 템플릿 원문. Groq/Firebase 언급 0건, "익명화된 데이터만 전송"이라 명시 |
| 게시 | Google Sites(Play 등록 URL) 임베드 교체 ✅ · GitHub Pages `docs/privacy-policy.html` 신규 ✅ (13섹션·표3개 잘림 없음 검증) |
| Data safety | `docs/legal/play-data-safety.md` 정답표 작성. CSV 782행 생성 → 사용자가 가져오기·저장·**검토 요청 제출 완료** |
| 릴리스 | `1.4.61+69` → **`1.4.62+70`**. CD run `32851680602` ✅ Internal track 업로드 성공 |
| 커밋 | `4acadb4` `07d3658` `681468d` + 문서 수정분. 1,748 테스트 그린 · analyze rc=0 · Functions tsc/eslint rc=0 · jest 34 |

## 다음 단계

| 우선순위 | 작업 | 이유 |
|----------|------|------|
| **High** | **v1.4.63 앱 빌드 — 앱 내 방침 asset 갱신** | ⚠️ **versionCode 70 AAB에 틀린 문장이 들어갔다.** `docs/legal/privacy-policy.md` 는 pubspec asset 인데, 수정본은 CD 이후에 커밋됐고 `cd.yml` `paths-ignore` 가 `docs/**` 를 제외해 재빌드되지 않았다. 앱 내 방침 화면만 "이름은 전송 안 됨"으로 표시된다(웹은 정상). **프로덕션 승격 전 반드시 수정** |
| **High** | **위기상담 번호 `1393` → `109` 통일** | `sos_card.dart` 만 통합번호 109. `app_strings.dart` `safety_constants.dart` `prompt_constants.dart` `analyze_diary_usecase.dart` 는 구번호 1393. **위기 경로에서 안 받는 번호 안내 소지**. 위 High 건과 같은 빌드에 묶을 것 |
| Medium | Play Console **Health apps declaration** | 정신·행동 건강 범주. 미완료 |
| Medium | 스토어 설명 비의료기기 면책 문구 | `ko/full_description.txt` 에 의료·진단·전문가 관련 문구 grep 0건 |
| Medium | `action_item_preview` Analytics 전송 중단 검토 | AI 행동 제안 앞 50자를 전송 중. 방침에 적느니 끊는 편이 낫다 |
| Medium | 방침 URL을 GitHub Pages 로 이전 | Google Sites 임베드가 9,482자로 한도(~1만자)에 근접. 다음 문단 추가 시 넘칠 가능성 |
| Medium | Cloud Functions Node.js 20 → 22+ | **2026-10-30 decommission** |
| Low | `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` 직접 요청 재검토 | inexact 알람 폴백이 있는데도 요청. Play 정책상 허용 사례 아닐 가능성 (codex 지적) |
| Low | AI 생성 콘텐츠 인앱 신고 기능 | 생성형 AI 정책 적용 시 요구될 수 있음 |
| Low | Groq API 키 AAB 내장 → 서버 프록시 | `--dart-define` 은 바이너리에서 회수 가능 |
| Low | 서명 파일 없을 때 debug key 폴백 | `build.gradle.kts` — fail-closed 로 변경 권장 |
| Low | Functions orphan 정리 | `addMessage` `getStats` `checkIfSentToday` `markAsSent` `ApiResponse` — 인증 붙인 관리자 API 재도입 대비 존치 중 |

## 주의사항

- **`docs/legal/privacy-policy.md` 는 문서가 아니라 앱 asset이다** (`pubspec.yaml:136`, `privacy_policy_screen.dart:32` 가 `rootBundle` 로 읽음). 그런데 `cd.yml` `paths-ignore` 가 `docs/**` 를 제외하므로 **이 파일만 고치면 앱에 반영되지 않는다.** 반드시 앱 코드 변경과 같은 빌드에 실어야 한다. ← 이번 세션에서 실제로 당한 함정
- **저장 = 분석이다.** `diary_screen.dart:64` `_onSubmit()` → `_startAnalysis()` 가 유일 경로. `DiaryRepository.createDiary()` 는 인터페이스에만 있고 presentation 호출 0건. "분석 안 하면 전송 안 된다"는 **거짓**
- **이름/애칭도 Groq 로 전송된다** (`prompt_constants.dart:361-367`). 캐시 키에만 쓰이는 게 아니라 프롬프트 본문에 삽입된다. Play 의 `Name` 정의는 애칭(nickname)을 명시적으로 포함하므로 신고 대상
- **Data safety 재검토 트리거**: Firebase↔Ads/AdMob 연결, BigQuery export, 광고 ID 수집 활성화 중 하나라도 하면 **Shared = 아니오가 뒤집힌다**. 근거·판단 전문은 `docs/legal/play-data-safety.md`
- **IP 기반 위치도 신고 대상**: 위치 권한이 없어도 Performance 가 IP 수집, GA 가 마스킹 IP 에서 대략 위치 파생 → `Approximate location` 필수
- `user_name_dialog.dart:76,85` 가 "이름을 입력하세요"라고 물어 실명 입력을 유도한다. 의도가 애칭이면 문구 변경 권장(신고 의무는 불변, 수집 민감도만 하락)
- **RTK 출력 손상**: `ls`, `wc`, eslint JSON, `git diff --stat` 이 비거나 깨지면 `rtk proxy <cmd>` 로 재실행
- `.claude/settings.local.json.bak-allowwrite-20260721` — 로컬 권한 백업, 의도적으로 미추적 유지

## 마지막 업데이트
2026-08-25 / v1.4.62 릴리스 · 엔드포인트 하드닝 · 개인정보 고지 정합화 · Data safety 제출
