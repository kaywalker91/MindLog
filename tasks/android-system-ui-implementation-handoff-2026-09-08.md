# Android 시스템 UI 구현 핸드오프 — 2026-09-08

사용자가 “일단 지금까지 작업만 마무리하고 핸드오프”를 요청해 신규 수정·검증 확대를 중단했다. **구현 일부 및 관련 검증 완료, 전체 quality/최종 검토 미완료. 커밋·푸시 없음.**

## 시작 기준과 보존

- 브랜치 `fix/android-system-ui-insets`, 기준 HEAD `3b536bbc2833dae9507b9e86575cec1c45e08ccd`.
- 시작부터 존재한 변경: `.claude/progress/current.md`; 미추적 기존 계획·핸드오프 및 `.claude/settings.local.json.bak-allowwrite-20260721`. 보존했다.
- 기존 계획: [android-system-ui-plan-2026-09-08.md](android-system-ui-plan-2026-09-08.md). 그 파일의 “구현 미착수”는 계획 작성 시점 기록이다. 현재 상태는 본 문서를 우선한다.
- SafetyBlockedFailure, domain, 공통 ResponsiveUtils, 알림 서비스, 보호된 Pages/CI 변경 없음. SDK 업데이트 없음.

## 실제 변경

1. `lib/presentation/screens/self_encouragement_screen.dart`
   - body에 `SafeArea(top: false)`, FAB 조건 공유, 목록 bottom padding 기본 80(FAB)/16(없음).
   - floating SnackBar가 **FAB 위**에 배치되어 마지막 카드를 가리는 현상을 테스트로 재현. 화면을 ConsumerStatefulWidget으로 바꾸고 SnackBar의 GlobalKey 실측 높이를 목록 패딩에 더한다. 종료 시 여백 복원, 새 피드백은 현재 SnackBar를 교체한다.
   - 320dp/글자 2배에서 FAB left=-16 재현. 해당 좁은 조건에서는 개수 없는 “메시지 추가” 라벨, 전체 개수는 tooltip 유지. 스와이프 안내 Text에 Flexible.
2. `message_input_dialog.dart`: `useSafeArea: true`. 기존 내부 SafeArea 및 IME 패딩 유지.
3. PIN 설정/해제 두 screen: contentPadding 단일 계산, minHeight에서 실제 vertical padding 차감.
4. `message_card.dart`, `notification_preview_widget.dart`: 320dp/글자 2배에서 메타정보·헤더 Row overflow를 재현해 해당 Row만 Wrap으로 수정.
5. 테스트: 목록 screen 신규, 기존 시트 및 PIN screen 테스트 확장. 실제 뷰 인셋을 사용하는 `integration_test/android_system_ui_test.dart` 신규.
6. 사진 뷰어 앱 코드는 변경하지 않았다.

## 검증 증거

| 검사 | 결과 / 한계 |
| --- | --- |
| 수정 전 RED | `/tmp/mindlog-before.log`, rc=1: 목록 하단 915가 안전/FAB 경계 침범, 시트 scroll top=12 < 32, PIN 두 화면 maxScrollExtent=48(기대 0). 19개 실패에는 당시 하네스의 Haptic mock 미설정도 포함되므로 모두 제품 결함으로 세지 않는다. |
| SnackBar RED | `/tmp/mindlog-list.log`, 마지막 카드 bottom=787, 요구 경계=724. floating SnackBar와 카드 겹침. 실측 높이 보완 후 통과. |
| 관련 테스트 | `/tmp/mindlog-related.log`, **rc=0, 89 tests passed**. 목록 9/10 및 9→10→9, 수정/삭제/재정렬, SnackBar 표시·해제 여백, 320dp 글자 2배, 시트 12개 조합, PIN 인셋/작은 화면, 기존 사진 뷰어 테스트 포함. |
| quality | `/tmp/mindlog-quality.log`, **rc=1**: 신규 integration test의 unnecessary_import 1건으로 analyze 단계 중단. import 제거했으나 quality 재실행하지 않았다. format/design audit/전체 테스트/로그 누수 게이트 통과로 간주 금지. |
| 최종 포맷 | 명시한 변경 Dart 11개 대상으로 rc=0. PIN 테스트 2개 포맷만 변경. git diff --check 통과. 이후 테스트 재실행 없음(의미 변경 없음). |
| debug APK | 초기 일반 앱 build rc=0, 설치 rc=0. 당시 API36 기기에서 version 1.4.64+72 / targetSdk36 확인. 이후 integration APK가 대체 설치됨. |
| Android integration | `/tmp/mindlog-android-gesture.log`, **rc=0, 1 test passed**, Pixel_7_Test API36 제스처(secure navigation_mode=2), 1080×2400 DPR2.625. 9/10개 카드 하단 안전 및 FAB 경계, 실제 IME 위 취소 버튼, PIN 두 화면 maxScrollExtent=0 및 0/삭제 탭, 사진 닫기·Flutter back route·드래그 복귀 확인. |

관련 테스트 명령:
```bash
fvm flutter test --no-pub test/presentation/screens/self_encouragement_screen_test.dart test/presentation/screens/secret_pin_setup_screen_test.dart test/presentation/screens/secret_diary_unlock_screen_test.dart test/presentation/widgets/self_encouragement/message_input_dialog_test.dart test/presentation/widgets/self_encouragement/message_card_test.dart test/presentation/widgets/fullscreen_image_viewer_test.dart test/presentation/widgets/fullscreen_image_viewer_nocache_test.dart --reporter expanded
```

Android 명령:
```bash
fvm flutter test integration_test/android_system_ui_test.dart -d emulator-5554 --reporter expanded
```

### Android 검증 범위 및 환경 변경 — 반드시 확인

- 기존 Pixel_7_Test AVD를 `-no-snapshot-save -no-audio`로 시작했다. 초기 실제 앱 UI에서 기본 목록/PIN 설정 화면을 열어 보았으나 화면 전체 회귀로 확대 해석하지 않는다.
- integration harness는 provider/SharedPreferences 데이터만 대체하고 MediaQuery/물리 화면 인셋은 합성 주입하지 않는다. Firebase를 초기화하지 않는 독립 화면 하네스이며 실제 앱 전체 흐름 테스트가 아니다.
- 로그의 padding/viewPadding/viewInsets 객체 문자열은 `Instance of FakeViewPadding`만 남는다. 숫자 전체 관측을 주장할 수 없다. 카드/버튼 좌표 및 PIN extent 숫자, 사진 진입 전후 top/bottom 동일 단언은 기록/통과했다.
- 사진 back은 `handlePopRoute()` 호출이며 실제 Android 시스템 뒤로가기 제스처 자체를 검증한 것이 아니다. 시스템 바 가시성/아이콘 대비/스크린샷, 백그라운드 복귀, API34/35, 3버튼/가로/실기 OEM 미검증. 사진 D는 계속 미확정이며 모드 변경 금지.
- **설치 사고:** integration APK 설치 시 `INSTALL_FAILED_INSUFFICIENT_STORAGE` 발생 후 Flutter CLI가 자동으로 `Uninstalling old version...`를 실행하고 재설치했다. 기존 에뮬레이터 앱 데이터가 삭제됐을 수 있다. 별도 백업을 확보하지 못했다. 보호 해제 재시도나 수동 uninstall은 하지 않았으며 CLI 원본 오류 로그를 보존했다.
- 핸드오프 정리에서 이번 세션에 기동한 에뮬레이터를 `adb -s emulator-5554 emu kill`로 종료했다(rc=0). 실행 중인 추가 리뷰/테스트 없음.
- 최종 설치 APK는 **integration test 앱**이다. 일반 앱으로 되돌리는 빌드/설치는 하지 않았다. 재개 시 이를 정상 앱 설치로 오인하지 말 것.

## agy·Grok·Claude 협업

요청에 따라 cooperation protocol을 읽고 설치된 delegate.sh만 사용. 메인 세션만 저장소 수정. 리뷰어에 텍스트만/도구금지/수정금지/재위임금지 명시.

- 최초 라운드 `20260908081742`: **agy/Grok/Claude 모두 응답 수신, rc=0**. 원본 로그는 `~/.claude/plans/harness-2026-09-01-model-rounds/r20260908081742-{agy,grok,claude}.out`.
- 채택: 단일 FAB 조건, 인셋 주입 하네스, 실제 Rect/제스처, SnackBar 중 가림 검사. agy/Claude의 “floating SnackBar가 FAB를 위로 민다”는 설명 반려. SDK scaffold.dart에서 floating은 FAB 위에 배치됨을 확인; Grok도 이를 구분했다.
- Claude의 동일 build 내 AsyncValue 두 번 읽기 사이 상태가 변할 수 있다는 설명, 커밋부터 하라는 제안은 채택하지 않았다.
- 최종 diff 라운드 `20260908084001`: **agy rc=0**, Grok/Claude는 사용자 중단 요청에 따라 응답 없이 프로세스를 종료(**rc=143**). 완료 검토/동의로 세지 않는다.
- agy 최종 의견: (a) `_measureFeedback`의 currentContext.size 수명/레이아웃 안전성, (b) build마다 post-frame 예약 비용, (c) useSafeArea bottom gap, (d) FAB 360dp 이상 고배율 잔여 위험.
- (a)/(b)는 **아직 코드·테스트로 판정하지 않은 후속 검토 항목**. inactive Element가 post-frame 시점에 실제 남는지와 dismiss/replace/route 이탈 테스트를 먼저 확인할 것. agy의 suggested mounted check가 inactive를 모두 배제한다고 단정하지 말 것.
- (c)는 **반려**: 현재 Flutter route는 `SafeArea(bottom: false, child: content)`. 공식 문서도 상단·좌우만 보호, false일 때 내부 상단 padding 제거를 설명한다. `useSafeArea: false + 내부 SafeArea`로 되돌리지 말 것.
- (d)는 현 범위 밖 조합 미검증으로 기록. 좁은 화면/측면 인셋 대응은 다음 검증에서 판단.
- sandbox/auth 실패는 관측되지 않았다. 중단 rc143은 사용자 요청에 따른 종료이며 모델 실패/합의 아님. 최초 Grok은 프롬프트가 잘렸다는 진행 문구를 남겼으나 최종 리뷰를 반환했다. 도구 사용 여부에 대한 독립 감사는 하지 않았다.

공식 근거:
- https://api.flutter.dev/flutter/material/ModalBottomSheetRoute/useSafeArea.html
- https://api.flutter.dev/flutter/services/SystemChrome/setEnabledSystemUIMode.html

## 재개 순서

1. 이 문서와 git diff 확인. `_measureFeedback`의 종료·교체·화면 이탈 및 재레이아웃 안전성 검토/테스트. 최종 agy 원문 주장을 사실로 자동 채택하지 않는다.
2. PIN 확인/불일치/잠금해제 실패/초기화 링크의 작은 화면 좌표·탭 추가, 시트 수정 모드의 인셋 행렬, 측면 인셋·가로·SnackBar 도중 재정렬 등 계획의 남은 조합 확인. 기존 기능 테스트 통과와 결합 조건 검증을 구분.
3. 현재 import 수정 상태에서 **`./scripts/run.sh quality` 재실행 필수**. 범위 밖 format 드리프트 혼입 금지.
4. Android 3버튼 및 실제 앱 전체 화면 회귀, 사진 D의 숫자 인셋/가시성/대비/라이프사이클 관측. 최신 일반 앱 APK와 integration APK를 구분하고 **기기 저장공간 및 데이터 보존을 먼저 확인**.
5. 필요 시 최신 diff로 미완료 Grok/Claude 최종 리뷰를 새 숫자 라운드로 재요청. 기존 로그 덮어쓰기 금지.

## 원본 로그 보존

`/tmp` 로그를 다음 디렉터리에도 복사했다:
`/Users/kaywalker/.claude/plans/mindlog-system-ui-20260908-implementation/`

모델 로그는 기존 harness 디렉터리에 원본 그대로 유지. 기존 계획/원본 핸드오프는 덮어쓰지 않았다.
