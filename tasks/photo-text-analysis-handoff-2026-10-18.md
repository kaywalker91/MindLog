# 일기 사진 보관 / 텍스트 전용 분석 핸드오프

작성: 2026-10-18. 다음 세션은 이 문서를 먼저 읽는다.

## 현재 상태

사용자가 선택한 **사진 첨부·저장·열람 유지, AI는 글만 분석** 방향을 로컬에 반영했다. 전체 테스트 1,847개와 Galaxy A34 별도 패키지의 실제 API/UI 검증은 PASS다. **전체 품질 게이트는 기존 디자인 위반 35건으로 FAIL이며, 커밋·푸시·배포는 수행하지 않았다.** 설치된 배포 앱의 404가 이미 해소됐다고 보고하면 안 된다.

| 항목 | 인계 시점 확인값 |
| --- | --- |
| 브랜치 | `fix/android-system-ui-insets` |
| HEAD | `95e7323b0630f10402884211ff5f54ad72ca9c87` |
| 준비 중인 소스 버전 | `pubspec.yaml`: `1.4.65+73` |
| 공개 업데이트 안내 | `docs/update.json`: `latestVersion=1.4.64`, 변경하지 않음 |
| A34 원본 사용 앱 | `com.mindlog.mindlog`, `1.4.64+72`, 덮어쓰지 않음 |
| 실기 검증 앱 | `com.mindlog.mindlog.a34verify`, 별도 debug 패키지, 검증 후 제거 확인 |
| 외부 배포 상태 | 이번 작업에서 변경하지 않음. 현재 Play Console 상태는 미확인 |

이번 핸드오프의 완료조건은 재개 문서·진입점 작성, 근거 파일 존재 및 로컬 링크 확인, 기존 구현과 사용자 변경의 보존이다. 제품의 전체 품질 게이트 통과나 릴리스 완료와 구분한다.

## 원인과 적용한 결정

- 최초 진단에서 사진 분석에 고정된 `qwen/qwen3.6-27b`가 실제 요청에 HTTP 404 / `model_not_found`를 반환했다. 텍스트 모델은 HTTP 200이었다. 구 코드의 사진 분기는 413/429만 텍스트로 폴백해 404가 그대로 실패했다. 당시 공식 종료 공지와 요청 비교는 [수정계획](photo-text-analysis-plan-2026-10-18.md)에 있다.
- 이제 repository는 첨부 유무와 무관하게 `GroqCacheKey.forText`와 텍스트 `analyzeDiary`만 사용한다. Vision 모델·요청·프롬프트·캐시 생성기·전송용 Base64/다운스케일을 제거했다.
- UseCase/Controller의 사진 인자는 **로컬 저장에 필요하므로 유지**한다. 사진 최대 5장, 저장 압축·초안 복원·열람, 기존 사진/분석 결과 형식은 유지한다.
- 텍스트 모델 `openai/gpt-oss-120b`, 기존 텍스트 프롬프트와 `PromptConstants.version=v1`, 텍스트 캐시 직렬화는 유지했다. 과거 Vision 캐시를 새 분석에 재사용하거나 일괄 삭제하지 않는다.
- 안내 문구는 “사진은 기록용으로 보관되며, AI는 작성한 글만 분석해요.”로 맞췄다. 앱 내/공개 개인정보 처리방침은 **v1.4.65 제공일부터** 사진 미전송이 적용됨을 명시한다. 구버전 동작과 과거 전송 이력을 소급해 바꾸지 않는다.
- DB schema/마이그레이션, `SafetyBlockedFailure`, CI/Fastlane 동작과 강제 업데이트 정책은 변경하지 않았다. 사진만 저장하는 모드나 새 재분석 UI도 추가하지 않았다.

상세 변경과 실패 후 수정 과정은 [구현 기록](photo-text-analysis-implementation-2026-10-18.md), 실기 환경·API·화면 근거는 [A34 검증 기록](photo-text-analysis-a34-verification-2026-10-18.md)을 따른다. 계획 문서의 구현 전 관찰은 역사 기록이며 현재 상태는 구현·실기 기록이 우선이다.

## 검증 결과와 한계

아래는 직전 구현/실기 세션에서 실제 실행한 결과다. 핸드오프 작성 중 제품 테스트를 다시 실행한 것으로 표현하지 않는다.

| 확인 / 실제 명령 | 결과 | 근거 |
| --- | --- | --- |
| `./scripts/run.sh test` | **PASS, rc=0**, 1,847개 및 테스트 부작용 누수 검사 통과 | [전체 로그](/tmp/mindlog-photo-text-full-tests.log) |
| `./scripts/run.sh quality` | **FAIL, rc=1**. 정적 분석·strict 아키텍처·포맷 rc=0 후 디자인 35건에서 중단 | [quality 로그](/tmp/mindlog-photo-text-quality-final.log) |
| 원본 HEAD와 디자인 감사 비교 | 양쪽 감사 **FAIL, rc=1**, 동일 35건. 비교 명령 **PASS, rc=0**, 이번 변경의 신규 위반 0 | [비교 JSON](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-photo-text-implementation-lm_1j5l9/design-baseline-comparison.json) |
| `fvm flutter test integration_test/diary_photo_text_analysis_smoke_test.dart -d emulator-5580 --reporter expanded` | **PASS, rc=0**, 실제 Android SQLite/파일·사진 0/1/5장·HTTP mock 계약 | [스모크 로그](/tmp/mindlog-photo-text-native-smoke.log) |
| A34 별도 패키지 `fvm flutter drive` | **PASS, rc=0**, 실제 Groq HTTP 200, 사진 1/5장 작성·결과·보관·뷰어 왕복 | [실행 로그](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/device-test-complete.log), [rc 파일](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/device-test-complete.rc) |
| A34 native 화면 확인 추가 실행 | **PASS, rc=0**, Android screencap으로 실제 결과 화면 직접 확인 | [로그](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/native-display-device.log), [rc 파일](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/native-display-device.rc), [결과 PNG](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/native-display/photos_5_analysis_success.png) |
| 배포 서명·R8 release·Firebase 부트스트랩·실제 사용자 DB 업그레이드 | **UNVERIFIED**, 해당 배포 환경/경로는 실행하지 않음 | 실기 검증은 별도 debug 패키지 및 격리 DB |
| 핸드오프만을 위한 제품 테스트 재실행 | **N/A**, 문서·진입점만 수정. 기존 실행 근거를 연결하고 문서 검사 수행 | 아래 인계 검사 기록 |

실기기 세부 조건:

- Galaxy A34 `SM-A346N`, Android 16/API 36. 합성 일기·합성 사진을 사용했다. 실제 Groq 요청 두 건에서 텍스트 모델/문자열 메시지와 사진 바이트·경로 부재를 전송 직전에 단언했다.
- 사진 선택은 초안에 넣은 합성 사진 복원으로 검사했다. **삼성 OS 사진 선택기 직접 조작, 앱 재시작에 따른 DB 영속성, 원본 사용자 DB 업데이트는 미검증**이다.
- 실제 Android SQLite 플러그인의 격리된 in-memory DB와 실제 앱 사진 폴더를 사용했다. 통계/알림 후처리는 fixture/override이며, 임시 패키지는 Firebase Gradle 플러그인을 제외했다.
- 원본 앱의 APK 7개 해시·버전·설치 시각이 전후 동일했다. 검증 복사본의 프로덕션 Dart 232개도 원본과 동일했다. 검증 앱·임시 API 키 설정·빌드 복사본은 정리했고 로그·합성 화면·검증 소스만 보존했다.
- Flutter surface 변환 기반 일부 자동 결과 캡처는 흰 화면/이전 프레임이었다. 이를 화면 PASS 근거로 쓰지 않는다. 위 `native-display` PNG와 추가 실행이 실제 시각 근거다. debug 로그의 skipped frames를 release 성능 검증으로 해석하지 않는다.

5자 계획 검토는 메인 Codex + Claude/Grok/agy/Kimi로 실행했으며, 네 launcher 모두 rc=0이었다. 증거 수집은 Kimi만 PASS(rc=0), 나머지는 모델 식별 메타데이터/입력 envelope 한계로 UNVERIFIED(rc=3)다. 이를 “모델 식별까지 검증된 전원 PASS”나 구현 테스트 PASS로 바꾸지 않는다. 추가 모델 리뷰는 구현/실기 단계에서 호출하지 않았다.

## 다음 세션 재개 순서

1. 이 문서와 구현/A34 기록을 읽고 `git status --short`, 현재 diff를 확인한다. 이미 통과한 테스트는 코드 변경·새 실패·근거 소실 등 재실행 이유가 있을 때 범위에 맞게 실행한다.
2. **기존 디자인 위반 35건으로 quality가 FAIL인 상태를 먼저 처리할 작업으로 식별한다.** 본 사진 변경에 무관한 수정이나 게이트 완화를 섞지 않는다. 릴리스 준비 전 별도 범위로 해결하고 필요한 검사를 통과시켜야 전체 품질 완료를 선언할 수 있다.
3. 릴리스를 진행할 때 현재 Play Console의 versionCode/트랙 상태를 확인하고 준비 버전 `1.4.65+73`의 사용 가능 여부를 확정한다. 배포 서명/R8 등 실제 release 빌드 검증과 데이터 보존을 전제로 한 업그레이드 검증을 진행한다. 기존 사용 앱을 대상으로 테스트 APK를 설치하지 않는다.
4. 릴리스 문서/스토어 안내를 새 동작과 맞춘다. `android/fastlane/Fastfile` 네 레인의 **`skip_upload_changelogs: true`** 때문에 changelog 파일만 작성해도 Play 출시 노트는 올라가지 않는다. 현재 콘솔 문구를 확인하고 수기 반영하거나, 별도 승인 범위에서 파이프라인 변경을 결정한다. 이번에는 Fastlane을 바꾸지 않았다.
5. 실제 새 버전을 제공하는 시점에 `docs/update.json`의 안내를 갱신한다. 미배포 1.4.65를 이미 제공 중인 버전으로 알리지 않는다. 앱 내 방침 asset인 `docs/legal/privacy-policy.md`가 새 번들에 포함되는지도 확인한다.
6. 커밋할 경우 이번 범위만 명시적으로 stage한다. **`git push`는 사용자 명시 승인 후에만** 실행한다. 이번 “핸드오프” 요청은 커밋·푸시·배포 지시가 아니다.

## 워킹트리 보존 사항

- 작업 전부터 있던 `.serena/project.yml` 수정과 `.claude/settings.local.json.bak-allowwrite-20260721`은 사용자 변경이다. 이번 기능 커밋에 포함하거나 되돌리지 않는다.
- 이전 Android 시스템 UI 작업은 현재 HEAD까지의 배경이다. [기존 Android 핸드오프](android-system-ui-implementation-handoff-2026-09-08.md)와 기존 progress 이력은 보존했다. 예전의 테스트 개수/클린 워킹트리/버전 표기를 현재 상태로 재사용하지 않는다.
- 기능 변경은 `lib/` 텍스트 경로·Vision 제거, 사진 안내/방침, 관련 테스트, `pubspec.yaml`과 현재 설명 문서에 있다. 신규 회귀 파일은 [텍스트 계약 테스트](../test/data/repositories/diary_text_only_analysis_test.dart)와 [Android 스모크](../integration_test/diary_photo_text_analysis_smoke_test.dart)다. 비전 전용 스모크/프롬프트 테스트 삭제는 의도한 변경이다.
- 기존 결과·사진·캐시를 삭제하거나 DB 마이그레이션을 추가할 이유가 없다. Domain 순수 Dart, 계층 경계 및 `SafetyBlockedFailure` 보호를 유지한다.

## 인계 검사 기록

핸드오프 작성 후 `git diff --check`와 Python 문서·보존 검사를 실행했다. **인계 검사 PASS, 모두 rc=0**: 로컬 Markdown 링크 20개 유효, 공백 오류 없음, 기존 변경 36개 항목 SHA-256/삭제 상태 동일, 허용 범위 밖 신규 변경 없음. 변경 허용 파일은 이 문서와 `.claude/progress/current.md`뿐이다. 검사 로그/종료코드는 [인계 검사 JSON](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-photo-text-handoff-33fzc4nk/handoff-checks.json)에 보존한다.

기존 실행 근거는 로컬 임시 경로에 남아 있으며 Git에는 포함되지 않는다. 경로가 사라졌다면 해당 근거를 UNVERIFIED로 취급하고 필요한 범위에서 다시 확보한다. 공개 문서/커밋에 API 키나 개인 일기·사진을 넣지 않는다.
