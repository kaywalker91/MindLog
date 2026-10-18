# Galaxy A34 사진 보관 / 텍스트 분석 실기기 검증

작성: 2026-10-18. [구현 기록](photo-text-analysis-implementation-2026-10-18.md)의 후속 검증이다.

## 기기와 설치 경계

- 실제 연결 기기: Samsung Galaxy A34, `SM-A346N`, Android 16 / API 36, One UI 속성 `80500`.
- 현재 기기 설정을 유지했다. 화면 1080×2340, physical density 450 / override 420, 글자 크기 배율 1.15.
- 기존 사용 앱: `com.mindlog.mindlog`, v1.4.64 / versionCode 72. 설치 시각과 APK 7개(split 포함)의 경로·SHA-256을 먼저 기록했다.
- 검증 앱: **별도 패키지 `com.mindlog.mindlog.a34verify`**, v1.4.65 / versionCode 73, 표시 이름 `MindLog A34 검증`. 원래 패키지에 설치·재설치·삭제·데이터 삭제를 실행하지 않았다.
- 설치는 APK의 실제 package ID를 `aapt dump badging`으로 확인한 뒤 primary Android user 0으로 한정했다. 추가 사용자 범위 조회는 권한 오류가 있어 사용하지 않았다.
- 현재 미커밋 구현을 별도 임시 프로젝트로 복사했다. 프로덕션 `lib/` Dart 파일 232개 SHA-256이 원본과 일치함을 확인했다. 임시 프로젝트에서만 applicationId/앱 이름을 바꾸고 Google Services·Crashlytics Gradle 플러그인을 제외했다. 원본 소스·빌드 설정은 바꾸지 않았다.

## 완료 기준과 범위

1. A34에서 0/1/5장 사진을 실제 앱 폴더/SQLite에 저장하고 최종 HTTP 요청이 글만 포함함을 확인한다.
2. 프로덕션 작성 화면·초안 복원·분석 Controller/UseCase/Repository를 연결해 사진 1/5장 첨부 상태에서 실제 Groq 분석을 실행한다.
3. HTTP 200, 결과 카드, SQLite analyzed 상태, 저장 사진 장수와 바이트 보존을 확인한다.
4. 실제 사진 갤러리/전체화면 뷰어를 열고 닫으며 5장일 때 넘기기 동작도 관찰한다.
5. 원래 앱의 설치 상태/APK 해시 불변과 별도 검증 앱 정리를 확인한다.

합성 일기와 앱 캐릭터 PNG 사본만 썼다. 개인 일기·사진·원본 앱 DB를 읽지 않았다. 사진 선택은 합성 사진이 포함된 초안을 복원하는 방식으로 구성했다. 삼성 OS 사진 선택기에서 사용자의 갤러리를 탐색·선택한 테스트는 아니다.

통계는 빈 fixture, 알림 후처리는 테스트 override를 사용했다. 분석 Controller·UseCase·사진 로컬 처리·Repository·RemoteDataSource·실 API 호출은 프로덕션 코드다. SQLite는 실제 Android 플러그인의 격리된 in-memory DB를 주입했고 사진은 실제 앱 폴더에 썼다. 별도 Android 스모크는 HTTP만 기록용 mock으로 바꿔 0/1/5장 계약을 검증했다. 두 증거를 구분한다.

## 실행 기록

작업 디렉터리: `/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6`.

- 기존 APK 7개 해시 기록: 모두 rc=0.
- 검증 APK 최초 빌드 rc=1: 임시 검증 코드가 갤러리 위젯의 실제 인자명과 맞지 않았다. 수정 후 빌드 rc=0. 제품 코드 오류가 아니다.
- 별도 패키지 설치: `adb install --user 0 -r -t <확인한 APK>` rc=0.
- 첫 실기 실행 rc=1: 복원 목록 값보다 실제 렌더링을 기다려야 하는 자동화 타이밍 문제와 ADB/VM 연결 단절이 관측됐다. 원본 로그를 보존하고 렌더링된 장수 카운터 기준으로 보완했다.
- 다음 실기 실행 rc=1: 사진 수가 붙는 실제 제출 버튼 문구와 캡처 초기화 범위에 맞춰 임시 검증 코드를 수정했다.
- 후속 실행에서 1장 실제 API·결과·사진 보관·뷰어는 통과했고, 5장도 실제 API 200/결과/사진 보관까지 통과했다. 다만 5장 뷰어 넘기기 단언이 실패해 스와이프별 실제 페이지를 별도 진단했다. 이 시점의 전체 실행을 PASS로 계산하지 않는다.
- 뷰어 진단: 순간 기본 드래그는 page=0(1/5 유지), 화면 내부에서 폭 70%를 450ms 동안 드래그하면 사진 중앙·하단 모두 page=1(2/5)이었다. 이 측정으로 제품 뷰어를 바꾸지 않고 자동화 제스처의 위치/시간을 실제 사용 조건으로 맞췄다. 진단 실행 rc=0. 최초 진단은 이전 설치의 파일이 남아 있을 것이라는 가정 때문에 rc=1이었고, 자체 합성 파일을 만드는 방식으로 보완했다.
- 최종 5장 검사는 화면 내부 timed drag로 1→2→3→4→5→4→3→2→1 왕복을 단언한다. 페이지 컨트롤러 강제 이동을 통과 근거로 쓰지 않는다.
- 테스트 종료 후 별도 검증 앱이 자동 제거되는 경로가 관측돼, 최종 JSON/PNG 증거는 기기 파일의 존속에 의존하지 않고 integration driver의 응답 데이터로 회수한다. API 키가 포함된 임시 설정은 검증 후 제거한다.

검증 앱 실행 명령(임시 프로젝트 디렉터리):

```bash
fvm flutter build apk --debug --no-pub \
  --target=integration_test/a34_live_validation_test.dart \
  --dart-define-from-file=<권한 600의 임시 설정 파일>
fvm flutter drive --no-pub --device-user=0 -d RFCW615RBFT \
  --driver=test_driver/a34_driver.dart \
  --target=integration_test/a34_live_validation_test.dart \
  --use-application-binary=<별도 패키지 APK>
```

API 키는 출력하지 않았고 합성 글만 Groq로 보냈다. 기록용 HTTP Client는 실제 전송 직전에 모델/문자열 메시지 형식/사진 바이트·경로 부재를 단언하고, 실제 네트워크 응답 상태만 별도로 기록한다.

## 최종 결과

최종 통합 실행은 **PASS, rc=0**이다. 이전 실패 로그는 덮어쓰지 않고 보존했다.

| 검증 | 실제 관찰 |
| --- | --- |
| Android 계약 스모크 | 0/1/5장, 실제 Android SQLite·사진 저장, 최종 텍스트 HTTP 계약 PASS. 이 시나리오만 HTTP mock |
| 사진 1장 작성 UI | 초안 복원 → 실제 제출 버튼 → 실제 Groq HTTP 200 → 결과 카드 → SQLite analyzed / 사진 1장 보존 → 갤러리·전체화면 열기/닫기 PASS |
| 사진 5장 작성 UI | 초안 복원 → 실제 제출 버튼 → 실제 Groq HTTP 200 → 결과 카드 → SQLite analyzed / 사진 5장 보존 → 갤러리·전체화면 PASS |
| AI 전송 내용 | 두 live 요청 모두 `openai/gpt-oss-120b`, 메시지 content는 문자열, 사진 바이트·파일 경로 미포함 |
| 사진 넘기기 | 1→2→3→4→5→4→3→2→1을 실제 제스처 후 표시된 페이지 번호로 확인 PASS |
| 원래 앱 | APK 7개 SHA-256, versionName 1.4.64 / versionCode 72, 설치·업데이트 시각 동일 |
| 프로덕션 코드 | 검증 복사본과 현재 원본 `lib/` 232개 파일 SHA-256 동일. 이번 실기 검증에서 제품 코드 변경 없음 |
| 검증 앱 정리 | Flutter drive 종료 후 user 0 패키지 목록에서 검증 앱 부재 확인, 조회 rc=0. 원래 앱 삭제/재설치 없음 |
| 실제 표시 화면 | Flutter surface 캡처 모드를 사용하지 않는 추가 실행 rc=0. 사진 첨부·실 API 분석 결과·전체화면 뷰어를 Android 기본 `screencap`으로 캡처하고 직접 확인 |

증거:

- [최종 실행 명령](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/final-complete-command.json), [최종 로그](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/device-test-complete.log), [실제 종료코드](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/device-test-complete.rc)
- [1장 실 API 결과](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/artifacts/result_1.json), [5장 실 API 결과](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/artifacts/result_5.json)
- [5장 첨부 화면](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/artifacts/photos_5_before_analysis.png), [5장 전체화면 뷰어](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/artifacts/photos_5_fullscreen.png)
- [뷰어 제스처 진단](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/probe-artifacts/viewer_probe.json), [원본 앱/정리 요약](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/summary.json)
- [검증에 사용한 코드](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/a34_live_validation_test.dart), [원본 Dart 파일 해시](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/tested-production-source-sha256.json)

자동 캡처 6장을 회수했으나 분석 결과 화면의 자동 캡처에는 흰 화면/이전 프레임이 있어 시각 PASS 근거로 사용하지 않았다. 캡처 surface 변환을 제외한 추가 실 API 실행을 **rc=0**으로 통과했고, foreground가 검증 앱임을 확인한 뒤 Android 기본 `adb exec-out screencap -p`로 세 화면을 회수했다. 실제 표시 화면에서 분석 카드·감정 점수·감정 분류·키워드가 보임을 직접 확인했다.

- [실제 A34 분석 결과 화면](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/native-display/photos_5_analysis_success.png)
- [실제 A34 사진 첨부 화면](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/native-display/photos_5_before_analysis.png), [전체화면 사진 보기](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/native-display/photos_5_fullscreen.png)
- [native 표시 검증 로그](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/native-display-device.log), [종료코드](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/native-display-device.rc), [캡처·실 API 자료 manifest](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/native-display-manifest.json)
- [최종 원본 앱/검증 앱 정리 확인](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/cleanup-final.json), [임시 빌드·키 설정 정리](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/staging-cleanup.json)

추가 실행은 같은 명령의 target을 `integration_test/a34_native_display_test.dart`로 지정했다. 검증 코드는 [별도 보존](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-a34-verification-d72va_o6/a34_native_display_test.dart)했고 API 키 파일과 빌드 복사본은 제거했다. 원본 프로젝트의 제품 코드는 그대로다.

## 한계

- 별도 패키지의 debug 빌드 검증이다. 배포 서명·R8 release 빌드, Firebase 부트스트랩, 실제 사용자 DB를 이용한 업데이트/마이그레이션은 검증 대상에 포함하지 않는다.
- 원본 앱은 v1.4.64를 유지한다. 테스트가 통과해도 현재 설치된 배포 앱이 업데이트된 것은 아니다.
- 직전 구현의 전체 품질 게이트는 기존 디자인 감사 35건으로 FAIL이다. A34 검증을 이를 해소한 근거로 쓰지 않는다.
