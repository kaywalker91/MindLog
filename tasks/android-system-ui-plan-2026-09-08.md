# Android 시스템 UI 수정 실행계획

작성: 2026-09-08. 범위: 계획 수립만. 앱 구현·커밋·푸시 없음.
기준: `fix/android-system-ui-insets`, HEAD `3b536bbc2833dae9507b9e86575cec1c45e08ccd`.
원본 근거: [핸드오프](android-system-ui-handoff-2026-09-08.md).

## 현재 확인과 한계

- `fvm flutter --version` 성공(rc=0): Flutter 3.38.9 / Dart 3.10.8. SDK 업데이트하지 않음.
- 현재 FVM SDK `FlutterExtension.kt`의 compileSdk/targetSdk 기본값은 36이고 앱 Gradle은 해당 값을 참조한다. 설치·배포 APK의 실제 targetSdk는 미확인.
- `adb devices -l` 성공(rc=0), 연결 기기 없음. 화면 재현·스크린샷·위젯 테스트·quality는 이번 계획 단계에서 미실시.
- A/B/C는 코드 근거가 있는 수정 대상이다. 사용자가 본 실제 화면과 일치하는지는 미확인. D는 런타임 가설이다.

## 단계 0 — 구현 시작 기준과 회귀 테스트 하네스

1. 변경 전 git 상태를 보존하고 실제 대상 APK의 targetSdk, 기기 API, 내비게이션 방식, 방향, 글자 크기를 기록한다. 현재 `stable` 별칭을 새 버전으로 업데이트하지 않는다.
2. 테스트 인셋은 Navigator/Overlay 상위에 주입한다. 시트 기존 테스트의 route 내부 `MediaQuery(textScaler)`는 모달 라우트까지 전달을 보장하지 않으므로 `MaterialApp.router.builder`에서 child를 감싸도록 하네스를 수정한다. 시트 내부에서 실제 textScaler/viewInsets 값을 확인한다.
3. DPR=1 테스트에서 padding/viewPadding/viewInsets를 일관되게 설정한다. IME 열림은 padding.bottom=0, viewPadding.bottom은 유지, viewInsets.bottom은 키보드 높이로 설정한다. 테스트 종료 후 모두 reset한다.
4. 시스템 바 수치는 0/24/48dp, 상단 32dp 등 합성 fixture이며 특정 Android 모드의 고정 높이가 아니다. 실제 기기는 보고한 값을 쓴다.

완료 기준: 각 수정의 기존 결함을 드러내는 좌표/스크롤 단언이 수정 전 실패하고, fixture가 검사 대상 모달/화면에 전달됨을 확인한다. 단순 `SafeArea` 존재나 overflow 부재만으로 통과시키지 않는다.

## 단계 1 — Cheer Me 마지막 카드 접근 보장 (A)

대상: `lib/presentation/screens/self_encouragement_screen.dart`.

- `Scaffold.body`를 `SafeArea(top: false)`로 감싸 하단·좌우 시스템 인셋을 한 곳에서 소비한다. 상단은 기존 AppBar 책임이다.
- FAB 표시 조건(메시지 1~9개)을 한 번 계산하고 `_MessageList`에 전달해 FAB와 목록 패딩 조건을 일치시킨다.
- 목록 패딩을 좌우 16, 위 0, 아래 `hasFab ? 80 : 16`으로 둔다. 80은 현재 M3 extended FAB 높이 56 + 기본 margin 16 + 간격 8의 초기값이다. 실제 FAB Rect로 충분함을 확인한다. 시스템 bottomInset은 다시 더하지 않는다.
- 빈 목록·로딩·오류도 body SafeArea 보호를 받는다. 기존 provider, 알림 로직, 공통 ResponsiveUtils는 변경하지 않는다.

테스트: `test/presentation/screens/self_encouragement_screen_test.dart` 신규 하네스. 메시지/미리보기 provider와 SharedPreferences 힌트 상태를 제어하고 반복 힌트 애니메이션을 배제한다. 9개/FAB 있음, 10개/FAB 없음, 9→10→9 추가/삭제 전환, 0·1개 상태를 검사한다.

완료 기준: 목록을 최대 스크롤한 뒤 마지막 카드 전체 Rect가 안전 영역에 있고 FAB 표시 시 카드 bottom ≤ FAB top − 8dp. 마지막 카드의 수정/삭제를 스와이프로 노출하고 탭이 실행되며 재정렬도 동작한다. 10개일 때 FAB 회피용 여백이 남지 않는다. 카드 자체가 viewport보다 큰 조건은 각 조작 영역의 순차 접근으로 판정한다. SnackBar가 FAB를 위로 이동시키는 동안에도 마지막 카드 조작이 가능한지 확인하고, 실패 시 실제 가림 높이를 반영하는 보완안을 적용한다. 320dp 폭/큰 글씨에서 FAB 실제 높이·라벨 접근성을 확인하고 실패하면 해당 레이아웃만 보완한다.

## 단계 2 — 작성·수정 시트 상단 보호 (B)

대상: `lib/presentation/widgets/self_encouragement/message_input_dialog.dart`.

- `showModalBottomSheet`에 `useSafeArea: true`를 추가한다.
- 기존 내부 SafeArea, IME `viewInsets.bottom` 패딩, Flexible/스크롤, 고정 저장·취소 버튼은 유지한다. 바깥 SafeArea가 소비한 상단 인셋은 자식에서 제거되므로 내부 SafeArea 상단을 중복이라는 이유로 삭제하지 않는다.
- 수동 화면 높이 차감이나 키보드 높이 중복 차감을 추가하지 않는다.

테스트: 기존 `test/presentation/widgets/self_encouragement/message_input_dialog_test.dart` 확장. 320×640/412×915, 글자 1.0/1.3/2.0, 상단 인셋, IME 0/280dp 대표 조합. 짧은 화면+큰 글씨+IME는 시트가 상단까지 확장되는 실패 검출 케이스로 선정한다.

완료 기준: 제목/핸들을 상단 안전 영역 안으로 표시·스크롤할 수 있고 저장/취소 전체 터치 영역이 키보드 상단보다 위에 있다. 버튼 아래 기존 20dp 간격도 검사해 이중 패딩을 검출한다. 닫힘 상태에서는 내비게이션 안전 영역 안에 있다. 입력→저장 결과 및 취소 null 반환도 유지한다. 극단 조건에서 고정 버튼 때문에 overflow가 재현되면 그 조건을 근거로 제한적인 반응형 배치 보완을 추가한다.

공식 근거: [ModalBottomSheetRoute.useSafeArea](https://api.flutter.dev/flutter/material/ModalBottomSheetRoute/useSafeArea.html)는 상단·좌우를 보호하며 하단은 보호하지 않는다. false일 때는 상단 padding을 제거해 내부 SafeArea의 상단 보호도 무효화한다.

## 단계 3 — PIN 두 화면 높이 산식 일치 (C)

대상: `lib/presentation/screens/secret_pin_setup_screen.dart`, `lib/presentation/screens/secret_diary_unlock_screen.dart`.

- `_buildCenteredBody`에서 현재 `EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, bottomSafeAreaPadding(context, extra: 12))`를 `contentPadding`으로 한 번 계산한다.
- `minHeight = max(0, constraints.maxHeight - contentPadding.vertical)`로 변경하고 SingleChildScrollView.padding에 같은 값을 쓴다. 기존 clamp 방식 사용 가능.
- 기존 스크롤·Center·maxWidth 420·배경을 유지한다. 별도 bottom SafeArea를 겹쳐 추가하지 않는다. Scaffold의 bounded constraints 밖 재사용을 위한 추상화는 범위에 넣지 않는다.

테스트: 기존 두 screen 테스트 확장. 콘텐츠가 충분히 들어가는 큰 높이에서 bottomInset 0/48을 비교해 maxScrollExtent가 허용 오차 0.5dp 안에서 0인지 확인하고 내용 중심이 패딩을 제외한 viewport 중심과 일치하는지 확인한다. 320×640 및 짧은 높이에서는 필요한 스크롤을 허용하며 마지막 키/삭제 키/초기화 링크까지 스크롤 후 탭 가능해야 한다. 설정 확인 단계·불일치 오류와 잠금해제 오류/초기화 링크 표시를 포함한다.

완료 기준: 인셋 때문에만 생기는 스크롤은 제거되고 내용이 큰 경우의 필요한 스크롤과 PIN 동작은 유지된다. 좌우 컷아웃 결함은 별도 재현되면 국소 보완하며 높이 산식 수정의 효과로 단정하지 않는다.

## 단계 4 — 사진 뷰어 재현 후 조건부 수정 (D)

대상 후보: `lib/presentation/widgets/fullscreen_image_viewer.dart`.

- 실제 targetSdk와 OS 조합에서 진입 전/후/닫기 후의 padding, viewPadding, viewInsets, 바 가시성 및 스크린샷을 수집한다. 앱 정상 모드 정책을 먼저 명시한다.
- 닫기 버튼, 시스템 뒤로가기, 수직 드래그 종료, 시스템 바 일시 재노출, 백그라운드 복귀, 연속 열기/닫기를 조사한다. 라이트/다크에서 아이콘 대비도 확인한다.
- 모드 전환이 유효하고 복귀 불일치가 관측되면 앱의 명시적 정상 모드로 복원하는 국소 설계를 작성한다. 최신 정책상 호출이 무시되는 환경이면 이미지 full bleed는 유지하면서 제어 UI 인셋 대응 필요성을 먼저 판정한다.
- 재현 없이 `manual → edgeToEdge`, 고정 컷아웃 여백, 지연 재호출을 도입하지 않는다. 재현되지 않으면 D는 미확정으로 남긴다.

공식 근거: [SystemChrome.setEnabledSystemUIMode](https://api.flutter.dev/flutter/services/SystemChrome/setEnabledSystemUIMode.html). 지원하지 않는 모드는 무시될 수 있고 target API 35/36에 따른 제약이 문서화되어 있다. 설치 OS만으로 호출 성공 여부를 단정하지 않는다.

완료 기준: 전후 모드·인셋 관측으로 수정 필요/불필요/미확인을 구분한다. 수정 시 기존 fullscreen_image_viewer 두 테스트를 확장하되 MethodChannel 호출 검증을 Android 실제 복원 검증과 구분한다.

## 단계 5 — 통합 검증 및 결과 보고

- 관련 위젯 테스트를 `fvm flutter test <대상 파일들>`로 실행한 뒤 `./scripts/run.sh quality` 실행. 이 스크립트는 analyze --fatal-infos → strict architecture smoke → format → design audit → 테스트/로그 누수 검사를 수행한다.
- format 단계는 파일을 실제 수정할 수 있으므로 실행 전후 diff를 확인하고 범위 밖 드리프트를 이번 수정에 섞지 않는다.
- 종료코드와 실제 성공 출력을 함께 확인한다. timeout/환경 실패는 실패 또는 미검증으로 남긴다.
- Android API 36 제스처를 우선 확보하고 같은 환경 3버튼으로 A/B/C를 확인한다. API 34는 D의 이전 정책 비교, API 35는 확보 시 추가. 세로 전체 흐름과 가로 측면 인셋을 확인한다. 미확보 API·실기/OEM 조합은 명시적으로 제외 기록한다.
- 기본 탭(목록/통계/설정)과 사진 뷰어 복귀 후 화면도 회귀 확인한다. 전체 조합 전수 대신 위 결함별 대표 조합을 사용한다.
- 자동 검증 통과와 실제 기기 검증을 별도 보고한다. 기기 미확보 시 Android UI 해결 완료라고 선언하지 않는다.
- 단계별 브리핑: 변경 파일/사용자에게 달라지는 동작/통과한 검증/남은 미확인 각 한 줄. 안전 Failure, domain, 보호된 Pages/CI, 기존 백업 파일 보존. 커밋·푸시는 이번 계획 범위 밖이다.

## 협업 결과

사용자 요청에 따라 `~/.claude/protocols/multi-model-cooperation.md`를 읽고 설치된 `~/.claude/scripts/delegate.sh`로 agy·Codex·Claude에 동일 코드/핸드오프/설계 후보를 제공했다. 텍스트만/도구 금지/수정 금지/재위임 금지를 제목과 본문에 명시했다. 이번 라운드에 Grok은 호출하지 않았다.

| 모델 | 실제 응답/종료 | 채택 내용 | 보정·반려 |
| --- | --- | --- | --- |
| agy | 응답 수신, rc=0 | A의 SafeArea와 FAB 조건 공유, C의 패딩 단일 계산, D 조사 선행 | 시트 route가 하단까지 보호할 수 있다는 설명 및 내부 SafeArea 상단 중복 추정 반려. 현재 Scaffold 밖 무한 높이 가드는 필요 근거 없어 제외 |
| Codex (gpt-6-astra) | 응답 수신, rc=0 | A/B/C 방향 동의, 실제 FAB Rect 기준, 9↔10 전환, 큰 카드 순차 조작, PIN 중앙 정렬, 중첩 SafeArea 유지 | 80dp는 검증 전 후보값으로 유지. SnackBar 표시 조건을 추가 검증 대상으로 반영 |
| Claude (claude-sonnet-4-6) | 응답 수신, rc=0 | A 조건 공유, C 산식, D 조사 선행, 빈 상태·측면 검증 | route SafeArea가 bottom까지 소비해 내부 SafeArea가 no-op이라는 설명 및 제거 제안 반려. 패딩 상수/위젯 존재만 보는 테스트는 실제 좌표·탭 검증으로 대체 |

모델별 구현 순서는 달랐다(Claude는 독립적인 C 먼저). 최종 순서는 사용자 가림 영향이 큰 A→B→C로 결정했다. 모든 세부 설명을 만장일치 합의로 간주하지 않는다.

반려 근거는 주 세션이 직접 확인했다. 현재 FVM SDK `material/bottom_sheet.dart:1120`은 `SafeArea(bottom: false, child: content)`이고 `widgets/safe_area.dart`는 소비한 인셋을 `MediaQuery.removePadding`으로 자식에서 제거한다. 따라서 내부 SafeArea의 하단 역할이 남는다. Claude 응답의 “Flutter 소스 확인 완료” 문구는 텍스트 전용 리뷰 지시/제공 자료 범위로 입증되지 않으므로 검증 증거로 채택하지 않았다.

- 새 라운드: `20260908073228`. 원본 로그는 덮어쓰지 않았다.
- agy: `/Users/kaywalker/.claude/plans/harness-2026-09-01-model-rounds/r20260908073228-agy.out`
- Codex: `/Users/kaywalker/.claude/plans/harness-2026-09-01-model-rounds/r20260908073228-codex.out`
- Claude: `/Users/kaywalker/.claude/plans/harness-2026-09-01-model-rounds/r20260908073228-claude.out`
- 프롬프트: `/private/tmp/mindlog-system-ui-plan-20260908073228.txt`
- 이번 호출의 sandbox/auth/실행 실패 없음. 로그 헤더의 shell escape 바이트로 Python strict UTF-8 읽기가 한 번 실패해 원본 보존 상태에서 replacement decoding으로 응답을 읽었다. 이는 모델 실행 실패가 아니다.
- 모델 텍스트와 launcher 종료코드를 확인했으며, 이를 런타임 재현·테스트 통과·독립적인 커널 격리 재검증으로 확대 해석하지 않는다.

## 계획 수립 결과

계획 수립 완료. 수정 예정 앱 파일 4개(A 1/B 1/C 2), D 1개는 조사 후 조건부. 관련 테스트 신규 1개와 기존 3개 확장이 기본 범위다. 현재 실제 변경은 본 계획 문서와 `.claude/progress/current.md`이며, 기존 핸드오프와 백업 파일은 보존했다. 구현 및 품질/기기 검증은 다음 실행 단계다.
