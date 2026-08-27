# 현재 작업: 없음 (v1.4.63 배포 완료 — 프로덕션 승격 대기)

## 현재 작업
없음. 코드 상 High 과제는 전부 해소됐고, 남은 건 **Play Console 수작업 3건**과 **포맷 드리프트 정리** 뿐이다.

## 완료된 항목 (v1.4.63)

직전 세션(v1.4.62)이 High 로 넘긴 2건을 모두 처리하고 배포까지 마쳤다.

| 작업 | 결과 |
|------|------|
| ✅ **긴급 상담전화 109 통일** | `1393` 이 앱 안에 6곳 남아 있었다. `app_strings.dart:30` · `safety_constants.dart:78` · `prompt_constants.dart:293` · `analyze_diary_usecase.dart:84,86` · `help_dialog.dart:245` → 전부 `109`. **현재 `grep -rn "1393" lib/` 0건 검증 완료** |
| ✅ 조사(助詞) 동반 교정 | `1393으로` → `109로`. `help_dialog` 는 번호와 조사가 별도 `TextSpan` 이라 `'으로 연락해주세요'` → `'로 연락해주세요'` 까지 수정 (번호만 치환하면 "109으로" 노출) |
| ✅ `1577-0199` 미변경 | `sos_card.dart:27` 과 게시된 방침 양쪽이 109 와 **별개 회선으로 병기** 중 — 저장소 정본 표기 유지 |
| ✅ **방침 asset 재빌드** | v1.4.62(versionCode 70) AAB 에 못 실린 `docs/legal/privacy-policy.md` 를, `pubspec.yaml` 변경으로 CD 를 트리거해 versionCode 71 에 반영. **현재 asset 55행이 "이름 또는 애칭을 설정한 경우 그 값도 함께 전송됩니다" 로 정정된 것 확인** |
| ✅ 배포 | `1.4.62+70` → **`1.4.63+71`**. CD run `32854926836` (#112) **success** · Internal track 업로드 완료 (2026-08-25) |
| ✅ 문서 동기화 | `CHANGELOG.md` [1.4.63] · `docs/update.json` `latestVersion: 1.4.63` |
| ✅ 품질 | `flutter analyze` rc=0 · **1,748 테스트 그린** · 테스트 4곳 동반 갱신 (`safety_constants_test` `diary_fixtures` `analysis_response_dto_test` `analyze_diary_usecase_test`) |
| 커밋 | `1dd9ad8` |

## 다음 단계

| 우선순위 | 작업 | 이유 |
|----------|------|------|
| **High** | **`dart format` 드리프트 43개 파일 정리** | ⚠️ **PR 경로가 막혀 있다.** `ci.yml:115` 가 `dart format --set-exit-if-changed .` 을 검사하므로 **PR 을 열면 CI 실패**한다. `cd.yml` 은 format 미검사라 배포만 통과 중인 상태. v1.4.63 변경분 9개 파일은 포맷 클린(교집합 0건) — 기존 드리프트다. 별도 `chore(format)` 커밋 하나로 분리 처리할 것 |
| **High** | **`cd.yml` paths-ignore 근본 수정** | ⚠️ **재발 예약된 함정.** `paths-ignore` 가 `**.md` 와 `docs/**` 를 제외하는데 `docs/legal/privacy-policy.md` 는 **앱 asset**(`pubspec.yaml:136`)이다. v1.4.63 은 pubspec 변경에 편승해 우회한 것일 뿐, **규칙은 손대지 않았다.** 방침 파일만 단독 수정하는 다음 커밋에서 동일 누락 재발 |
| **High** | Play Console **프로덕션 승격** | versionCode 71 이 Internal track 에 대기 중. 위 두 건은 배포물에 영향 없으므로 승격 자체는 진행 가능 |
| Medium | Play Console **Health apps declaration** | 정신·행동 건강 범주. 미완료 (코드 외 수작업) |
| Medium | 스토어 설명 비의료기기 면책 문구 | `ko/full_description.txt` 에 의료·진단·전문가 관련 문구 grep 0건 |
| Medium | `action_item_preview` Analytics 전송 중단 검토 | `analytics_service.dart:90` — AI 행동 제안 앞 50자를 전송 중. 방침에 적느니 끊는 편이 낫다 |
| Medium | **Cloud Functions Node.js 20 → 22+** | `functions/package.json:17` `"node": "20"`. **2026-10-30 decommission — 잔여 약 2개월** |
| Medium | 방침 URL 을 GitHub Pages 로 이전 | Google Sites 임베드가 9,482자로 한도(~1만자) 근접 |
| Low | 이슈 #3 — ID Policy 별칭 · sqlite 응집 · update provider 정리 (S6) | 리팩토링 백로그 |
| Low | 이슈 #2 — `KoreanTextFilter` 를 detector + corrector 로 분리 (S3) | 리팩토링 백로그 |
| Low | `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` 직접 요청 재검토 | inexact 알람 폴백이 있는데도 요청. Play 정책상 허용 사례 아닐 가능성 |
| Low | AI 생성 콘텐츠 인앱 신고 기능 | 생성형 AI 정책 적용 시 요구될 수 있음 |
| Low | Groq API 키 AAB 내장 → 서버 프록시 | `--dart-define` 은 바이너리에서 회수 가능 |
| Low | 서명 파일 없을 때 debug key 폴백 | `build.gradle.kts` — fail-closed 로 변경 권장 |
| Low | Functions orphan 정리 | `addMessage` `getStats` `checkIfSentToday` `markAsSent` `ApiResponse` — 인증 붙인 관리자 API 재도입 대비 존치 중 |

## 주의사항

- **`docs/legal/privacy-policy.md` 는 문서가 아니라 앱 asset이다** (`pubspec.yaml:136`, `privacy_policy_screen.dart:32` 가 `rootBundle` 로 읽음). `cd.yml` `paths-ignore` 가 `docs/**` 를 제외하므로 **이 파일만 고치면 앱에 반영되지 않는다.** 반드시 pubspec 등 paths-ignore 밖의 파일과 같은 커밋에 실을 것. ← v1.4.62 에서 실제로 당했고, **규칙은 아직 안 고쳤다**
- **저장 = 분석이다.** `diary_screen.dart:64` `_onSubmit()` → `_startAnalysis()` 가 유일 경로. `DiaryRepository.createDiary()` 는 인터페이스에만 있고 presentation 호출 0건. "분석 안 하면 전송 안 된다"는 **거짓**
- **이름/애칭도 Groq 로 전송된다** (`prompt_constants.dart:361-367`). 캐시 키 전용이 아니라 프롬프트 본문에 삽입. Play 의 `Name` 정의는 애칭을 명시적으로 포함하므로 신고 대상
- **Data safety 재검토 트리거**: Firebase↔Ads/AdMob 연결, BigQuery export, 광고 ID 수집 활성화 중 하나라도 하면 **Shared = 아니오가 뒤집힌다**. 근거·판단 전문은 `docs/legal/play-data-safety.md`
- **IP 기반 위치도 신고 대상**: 위치 권한이 없어도 Performance 가 IP 수집, GA 가 마스킹 IP 에서 대략 위치 파생 → `Approximate location` 필수
- `user_name_dialog.dart:76,85` 가 "이름을 입력하세요"라고 물어 실명 입력을 유도한다. 의도가 애칭이면 문구 변경 권장(신고 의무는 불변, 수집 민감도만 하락)
- **`memory/` 는 git 미추적 로컬 전용 디렉토리다.** `CLAUDE.md`(`memory/a11y-backlog.md`)와 `CHANGELOG.md` [1.4.63](`memory/privacy-policy-is-an-app-asset.md`)이 참조하지만 **저장소에는 없다.** 원격/신규 클론(예: Claude Code on the web 세션)에서는 열리지 않으므로, 해당 참조에 의존하는 판단은 로컬에서 확인할 것
- **`fvm`/`flutter` 가 없는 환경이 있다.** 원격 세션에서는 dart MCP 서버가 `ENOENT: fvm` 으로 연결 실패한다 → `analyze`·`test`·`format` 을 직접 실행할 수 없다. 품질 게이트가 필요한 작업은 로컬 세션에서 수행할 것
- **RTK 출력 손상**: `ls`, `wc`, eslint JSON, `git diff --stat` 이 비거나 깨지면 `rtk proxy <cmd>` 로 재실행
- `.claude/settings.local.json.bak-allowwrite-20260721` — 로컬 권한 백업, 의도적으로 미추적 유지

## 마지막 업데이트
2026-08-27 / v1.4.63 배포 확인 (CD #112 success) · 109 통일·방침 asset 반영 검증 · 잔여 과제 재정렬
