# 사진 보관 / 텍스트 전용 분석 구현 기록

작성: 2026-10-18. 기준 HEAD: `95e7323b0630f10402884211ff5f54ad72ca9c87`.
[수정계획](photo-text-analysis-plan-2026-10-18.md)을 구현했다. 커밋·푸시·배포는 수행하지 않았다.

## 적용한 동작

- 사진 첨부·최대 5장 저장·압축·초안 복원·열람 기능을 유지한다. 기존 DB schema와 사진/분석 결과 형식은 변경하지 않았다.
- repository 분석에서 사진 분기와 사진 인자를 제거하고 텍스트 캐시/요청만 사용한다. UseCase/Controller의 첨부 인자는 로컬 저장용으로 유지한다.
- 비전 API, 모델 상수, 프롬프트, 캐시 생성기, 이미지 전송용 Base64/다운스케일을 제거했다. 저장용 ImageService와 공용 파서/isolate, 일반 HTTP 재시도는 유지한다.
- 사진 안내와 분석 로딩 문구를 글 분석 계약에 맞췄다. 413 오류 안내도 사진 수 대신 글 길이를 안내한다.
- 준비 중인 소스 버전은 `1.4.65+73`이다. 앱 내/공개 개인정보 처리방침은 v1.4.65 제공일부터 사진 미전송이 적용됨을 명시하고 구버전·과거 전송 이력과 구분한다. 앱 방침 화면에 남아 있던 2025년 고정 날짜도 적용 버전 안내로 교체했다.
- README, Pages 현재 기능 소개, REQ-014와 분석 아키텍처 설명을 맞췄다. 과거 Vision 구현/릴리스 기록은 보존했다.
- `docs/update.json`은 아직 제공 중인 v1.4.64를 유지한다. 실제 릴리스 제공 후 별도로 업데이트해야 한다. Fastlane/CI/스토어 운영 설정은 변경하지 않았다.

## 검증한 계약

`test/data/repositories/diary_text_only_analysis_test.dart`는 실제 repository/remote datasource와 기록용 HTTP Client를 연결한다.

- 0/1/5장 각각 독립 cache miss에서 최종 URL, 모델, 전체 메시지와 요청 필드를 검사한다. 시간/랜덤을 고정해 원래 텍스트 프롬프트와 정확히 대조한다.
- 작성 UseCase에서 사진 1/5장을 앱 폴더로 복사하고 원본/저장본 바이트·DB 경로가 보존됨을 확인한다.
- 사진이 달라도 텍스트 캐시를 재사용하며, 과거 비전 캐시 행은 삭제하거나 새 분석에 재사용하지 않는다.
- 텍스트 분석 실패 뒤 사진·failed 상태가 남고 동일 저장 일기를 다시 분석할 수 있다.
- 첨부 파일이 없어도 repository의 텍스트 분석은 파일을 읽지 않는다.
- emergency 응답 비캐시와 기존 결과 단순 열람 시 무요청/무변경을 확인한다.

새 Android 스모크 `integration_test/diary_photo_text_analysis_smoke_test.dart`는 실제 Android SQLite와 앱 폴더의 사진 저장을 사용하고 HTTP 경계만 기록용 Client로 대체한다. 외부 사진 다운로드/실 비전 전송을 하던 이전 스모크를 교체했다. 합성 데이터만 사용하며 Groq 실응답 품질이나 A34 실기기 검증으로 확대 해석하지 않는다.

## 실행 결과

| 확인 | 실제 결과 / 로그 |
| --- | --- |
| 변경 전 새 회귀 테스트 | 의도한 RED, rc=1: 3 통과/5 실패. 사진 1/5장의 비전 모델 요청, 사진 유무 캐시 차이, 첨부 파일 읽기를 검출. [로그](/tmp/mindlog-photo-text-red.log) |
| 분석 경로 전환 직후 | rc=0, 새 테스트 8개 통과. [로그](/tmp/mindlog-photo-text-green.log) |
| 영향 테스트 첫 실행 | rc=1, 224 통과/1 실패. 초안 UI의 이전 `첨부 2장` 문구 기대가 실패했고 장수 카운터+새 안내 검사로 수정. [로그](/tmp/mindlog-photo-text-affected.log) |
| 최종 계약+초안 복원 테스트 | rc=0, 20개 통과. [로그](/tmp/mindlog-photo-text-affected-corrected.log) |
| `./scripts/run.sh quality` 최초 | rc=1, 새 테스트의 중괄호 lint 2건. 수정했다. [로그](/tmp/mindlog-photo-text-quality.log) |
| `./scripts/run.sh quality` 수정 후 | **FAIL, rc=1**. 정적 분석·strict 아키텍처·포맷 rc=0 후 디자인 감사 기존 위반 35건에서 중단. [로그](/tmp/mindlog-photo-text-quality-final.log) |
| 원본 HEAD 디자인 검사 | **FAIL, rc=1**, 동일 파일·동일 소스의 35건. 현재 변경으로 추가/제거한 위반 0건. 비교 명령 rc=0. [비교 기록](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-photo-text-implementation-lm_1j5l9/design-baseline-comparison.json) |
| `./scripts/run.sh test` 전체 테스트+로그 누수 검사 | **PASS, rc=0**, 1,847개 통과 및 `No test side-effect leakage patterns detected`. [로그](/tmp/mindlog-photo-text-full-tests.log) |
| Android native 스모크 | **PASS, rc=0**, 사진 0/1/5장 로컬 저장·SQLite 분석 결과·텍스트 HTTP 계약 1개 통합 테스트. [로그](/tmp/mindlog-photo-text-native-smoke.log) |
| 안전 Failure / DB / CI / 기존 사용자 수정 | `git diff --exit-code` 및 작업 전 해시 대조 rc=0. 변경 없음 |

실행 명령:

```bash
fvm flutter test test/data/repositories/diary_text_only_analysis_test.dart --reporter expanded
fvm flutter test test/data/repositories/diary_text_only_analysis_test.dart test/presentation/screens/diary_draft_flow_test.dart --reporter expanded
./scripts/run.sh quality
./scripts/run.sh test
fvm flutter test integration_test/diary_photo_text_analysis_smoke_test.dart -d emulator-5580 --reporter expanded
git diff --check
```

영향 테스트 첫 실행에는 remote/repository/cache/image/prompt/usecase/controller/image picker/draft 15개 파일을 지정했다. 실패 원인 수정 후에는 해당 두 파일을 재실행하고, 최종 전체 테스트로 범위를 확장했다.

## 기기·환경과 남은 한계

- 기기 목록 확인 당시 연결 Android 실기기 없음. 설치된 API 36 시스템 이미지로 `MindLog_Photo_Text_Disposable_20261018` AVD를 새로 만들고 `emulator-5580`에서 테스트했다. 기존 AVD나 사용자의 앱 데이터에는 설치하지 않았다.
- AVD 생성 rc=0, Android 스모크 rc=0. 테스트 종료 후 실제 AVD 이름을 확인한 뒤 해당 에뮬레이터만 종료하고 일회성 AVD 삭제까지 rc=0으로 정리했다. [정리 로그](/tmp/mindlog-photo-text-avd-cleanup.log)
- 최초 구현 시 Galaxy A34는 미연결이었다. 이후 [A34 실기 검증](photo-text-analysis-a34-verification-2026-10-18.md)에서 별도 패키지로 실제 API·사진 보관·초안 복원·뷰어 왕복을 PASS(rc=0)로 확인했다. 실제 사용자 DB를 이용한 업그레이드는 여전히 **UNVERIFIED**다.
- 전체 품질 게이트는 기존 디자인 부채 때문에 **FAIL**이다. 무관한 35건을 고치거나 검사를 완화하는 변경은 이번 작업에 섞지 않았다.
- 이번에는 구현을 진행했고 추가 외부 모델 리뷰는 호출하지 않았다. 이전 5자 계획 검토의 모델 식별 증거 한계는 원본 계획 문서에 그대로 남아 있다.
- 배포가 되기 전까지 설치된 v1.4.64의 사진 분석 404는 해결된 상태가 아니다. 새 버전 제공과 공개 업데이트 안내는 별도 릴리스 단계다.

## 최종 상태

로컬 구현 반영 및 위 자동 테스트/Android 계약 스모크는 PASS다. 전체 `quality`는 기존 디자인 감사 35건으로 FAIL이므로 품질 게이트 전체 통과로 보고하지 않는다. 정적 분석은 `No issues found`, 아키텍처와 포맷도 해당 quality 실행에서 rc=0으로 통과했다. 소스의 이미지 전송 심볼 검색 결과 0건, `git diff --check` rc=0이다.

사용자 기존 변경 2건과 `SafetyBlockedFailure`를 포함한 Failure 파일, SQLite schema, 배포 안내 및 CI는 변경하지 않았다. 새 버전은 미배포다. 후속 A34 실기 검증은 별도 패키지로 PASS이며, 원본 앱(v1.4.64)을 덮어쓰는 업데이트 및 실제 기존 사용자 DB 업그레이드는 수행하지 않았다.
