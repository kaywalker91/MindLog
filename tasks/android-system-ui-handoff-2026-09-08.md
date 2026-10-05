# Android 시스템 UI 겹침 — 수정계획 수립용 핸드오프

작성일: 2026-09-08. 상태: **정적 점검 완료 / 구체적 수정계획·구현·기기 재현 미착수**.

## 다음 세션의 목표

사용자는 일부 화면에서 Android 시스템 UI와 앱 화면이 겹친다고 보고했다. 점검 브랜치 생성 및 agy·Claude·Grok 협업 리뷰까지 요청했고, 이후 **다음 세션에서 구체적인 수정계획을 수립할 수 있도록 핸드오프**를 요청했다.

다음 세션은 아래 근거를 바탕으로 파일별 변경 범위, 재현 조건, 회귀 테스트, 완료 기준을 갖춘 계획을 작성한다. 이 문서의 수정 방향은 후보이며 승인된 구현 설계나 수정 완료 기록이 아니다. 사용자가 겹침을 본 정확한 화면·OS·내비게이션 방식은 아직 특정되지 않았다. 정보가 없어도 아래 코드 기반 계획은 진행할 수 있다.

## 인계 시 저장소 상태

- 작업 디렉터리: `/Users/kaywalker/AndroidStudioProjects/mindlog`
- 브랜치: `fix/android-system-ui-insets` — 로컬 `main`에서 생성·이동 완료.
- 점검 기준 HEAD: `3b536bbc2833dae9507b9e86575cec1c45e08ccd`.
- 이번 작업의 앱 코드 변경·커밋·푸시 없음. 핸드오프 문서와 진행 파일만 변경.
- 기존 미추적 `.claude/settings.local.json.bak-allowwrite-20260721` 보존. 작업 산출물로 포함하지 말 것.
- 점검 당시 `adb devices -l`에 연결 기기 없음. 기기 재현, 스크린샷, 테스트, analyze, quality gate를 실행하지 않았다.
- `.fvmrc`는 `stable`이며 점검 당시 로컬 SDK의 `FlutterExtension.kt` 기본 targetSdk는 36. `android/app/build.gradle.kts`는 `flutter.targetSdkVersion` 사용. **배포 APK의 targetSdk나 Flutter 버전을 확인한 것은 아니다.** 다음 세션에서 실제 SDK 및 대상 빌드를 기록한다.

## 우선순위와 근거

### A. Cheer Me 목록 하단 — 우선 수정 후보, 세 모델 공통 지적

- 위치: `lib/presentation/screens/self_encouragement_screen.dart:50`, `:214–215`.
- 독립 `Scaffold`의 본문에 하단 `SafeArea`가 없고 `ReorderableListView.builder`는 수평 패딩 16만 지정한다. 시스템 하단 인셋과 플로팅 추가 버튼을 피할 스크롤 여유가 없다.
- 목록이 충분히 길고 edge-to-edge로 그려질 때 마지막 카드가 시스템 내비게이션 바/FAB에 가려질 구조다. 정확한 메시지 개수나 가려지는 크기는 화면·글자 크기에 따라 달라지므로 고정값으로 단정하지 않는다.
- 수정 방향 후보: 목록 하단에 시스템 인셋 + FAB 회피 여백. `ResponsiveUtils.bottomSafeAreaPadding` 활용과 본문 `SafeArea(top: false)` 중 책임 위치를 선택하고 중복 패딩을 피한다. FAB가 없는 최대 10개 상태도 고려한다.
- 완료 기준: 마지막 카드와 수정/삭제·재정렬 조작 영역을 안전 영역 안으로 스크롤할 수 있음. FAB 표시/미표시 모두 확인.

### B. 응원 메시지 작성/수정 시트 상단 — 보호 누락 확인, 겹침 재현 필요

- 위치: `lib/presentation/widgets/self_encouragement/message_input_dialog.dart:43`, `:193`.
- `isScrollControlled: true`이나 `useSafeArea` 미지정(기본 false). 이때 라우트가 상단 `MediaQuery.padding`을 제거하므로 내부 `SafeArea`도 상단 시스템 영역을 보호하지 못한다.
- 키보드·작은 화면·큰 글씨로 시트가 화면 위까지 확장되면 상태바 침범 가능. 키보드 하단 `viewInsets.bottom` 처리 자체를 결함으로 단정하지 않는다.
- 수정 방향 후보: 라우트 `useSafeArea: true`. 기존 하단 `SafeArea`, 키보드 패딩, 내부 스크롤, 고정 저장/취소 버튼의 역할을 유지하며 여백 중복 확인.
- 완료 기준: 시트가 커져도 상단 제목/핸들이 상태바를 침범하지 않고 저장/취소가 키보드 위에서 접근 가능. 키보드 닫힘 상태도 확인.
- 공식 근거: <https://api.flutter.dev/flutter/material/ModalBottomSheetRoute/useSafeArea.html>.

### C. PIN 설정·잠금해제 높이 계산 — 보조 레이아웃 결함

- 위치: `lib/presentation/screens/secret_pin_setup_screen.dart:125–146`, `lib/presentation/screens/secret_diary_unlock_screen.dart:150–171`.
- `minHeight = constraints.maxHeight - 24`이나 실제 상하 패딩 합은 `24 + padding.bottom`이다. 따라서 최소 스크롤 콘텐츠 높이가 `viewport + bottomInset`이 되어 불필요한 스크롤과 중앙 정렬 오차가 생긴다.
- 수정 방향 후보: 실제 상하 패딩을 한 번 계산해 최소 높이에서 차감하거나, 안전 영역을 먼저 확보한 뒤 내부 가용 높이를 기준으로 계산.
- 하단 패딩은 이미 있으므로 **키패드가 영구적으로 가려지거나 접근 불가능하다고 단정하지 않는다**. 짧은 화면에서 필요한 스크롤은 유지한다.
- 완료 기준: 내용이 들어가는 화면은 인셋 때문에만 스크롤이 생기지 않음. 작은 화면·오류 안내·초기화 링크 표시 시 하단까지 접근 가능.

### D. 사진 전체화면 및 복귀 — 런타임 가설, 원인 확정 전 일괄 수정 금지

- 위치: `lib/presentation/widgets/fullscreen_image_viewer.dart:72`, `:79–82`, `:129`, `:151`, `:166`.
- 진입 시 `immersiveSticky`, 종료 시 `manual + SystemUiOverlay.values`. 이전 모드 보존 없이 전역 시스템 UI 모드를 바꾸는 구조다.
- 최신 Android의 edge-to-edge 정책으로 호출이 무시될 수 있다. 따라서 사진 종료 후 다른 화면 겹침의 확정 원인으로 보지 않는다.
- 재현 항목: 진입 전/진입 후/종료 후 `padding`, `viewPadding`, `viewInsets`와 화면 비교, 일시적 시스템 바 노출, 닫기 버튼·페이지 번호, 라이트/다크, 백그라운드 복귀.
- 수정계획에서 앱의 정상 UI 모드와 버전별 지원 범위를 먼저 정한다. `manual → edgeToEdge` 치환 또는 고정 컷아웃 여백 추가를 근거 없이 확정하지 않는다.
- 공식 근거: <https://api.flutter.dev/flutter/services/SystemChrome/setEnabledSystemUIMode.html>.

## 오탐으로 걸러낸 항목과 미확인 범위

- `MainScreen`의 하단 내비게이션은 `SafeArea(top: false)`로 보호됨. 바깥 Scaffold가 본문 하단 패딩을 소비하므로 내부 목록/통계/설정의 패딩을 무조건 중복이라 판단하지 않는다.
- `AppBar`가 상단 인셋을 처리하는 화면을 SafeArea 부재만으로 결함 처리하지 않는다. FAB 슬롯도 기본 인셋 처리가 있으나 본문 목록의 FAB 회피 공간은 별도다.
- 가로 방향 측면 내비게이션/컷아웃은 추가 검증 대상이다. 기본 탭 정상 판단은 모든 방향·기기를 보증하지 않는다.
- agy/Claude/Grok의 시트 설명 중 “내부 SafeArea가 상단 보호 또는 불필요한 상태바 여백 생성”은 위 공식 API와 모순되어 채택하지 않았다.
- 몰입 모드에서 컷아웃 인셋이 반드시 0이라는 주장, 고정 인셋 크기, 모델들이 제시한 Flutter 기본 모드 도입 버전은 검증되지 않아 채택하지 않았다.

## 다음 세션 진행 순서 및 계획에 포함할 검증

1. `git status --short --branch`와 HEAD 확인. `docs/ai-guidelines.md`, `tasks/lessons.md` 최근 항목 및 해당 레이어 규칙 확인. 이 문서의 라인 번호는 점검 기준이므로 다시 위치 확인.
2. `fvm flutter --version`, 실제 Android targetSdk/기기 API/내비게이션 모드 기록. 기기 연결 여부 재확인. 사용자 재현 화면 정보가 도착하면 우선순위 조정.
3. A/B/C에 대해 변경할 위젯·패딩 책임·완료 기준을 계획에 명시. D는 재현 및 버전 정책 확인을 선행 작업으로 둔다. 공통 유틸 수정은 다른 화면 영향이 있어 필요성을 입증한다.
4. 기존 테스트를 확장할지 신규 화면 테스트를 만들지 결정한다. 단순 위젯 존재나 overflow 예외 유무만 확인하지 말고 인셋을 주입하고 실제 조작 영역의 경계를 검증한다.
5. 구현 후 관련 테스트 → `./scripts/run.sh quality` → 대상 Android 화면 확인 순서로 검증한다. 기기 검증이 불가능하면 품질 게이트와 분리해 미검증으로 보고한다.

기존 관련 테스트:

- `test/presentation/widgets/self_encouragement/message_input_dialog_test.dart` — 화면 크기 테스트는 있으나 시스템 인셋 주입 검증 부족. Navigator/Overlay까지 인셋과 글자 크기가 전달되는지 확인한다.
- `test/presentation/widgets/fullscreen_image_viewer_test.dart`
- `test/presentation/widgets/fullscreen_image_viewer_nocache_test.dart`
- `test/presentation/screens/secret_pin_setup_screen_test.dart`
- `test/presentation/screens/secret_diary_unlock_screen_test.dart`
- Cheer Me 화면 전용 테스트는 이번 파일 목록 검색에서 찾지 못했다. 기존 provider/card 테스트를 화면 인셋 검증으로 간주하지 말고 화면 하네스 추가 필요성을 계획에 명시한다.

최소 검증 조합:

| 대상 | 조건 | 확인할 결과 |
| --- | --- | --- |
| Cheer Me | 긴 목록, FAB 있음/없음, 하단 인셋 0/제스처/3버튼 | 마지막 카드 전체와 조작 영역 접근 |
| 작성 시트 | 상하 인셋, IME 열림/닫힘, 작은 높이, 큰 글씨 | 상단 보호 및 저장/취소 접근 |
| PIN 2화면 | 충분한 높이/짧은 높이, 하단 인셋, 오류 상태 | 불필요 스크롤 제거 및 필요한 스크롤 유지 |
| 사진 뷰어 | API 34/35/36 중 확보 가능한 환경, 시스템 바 재노출/복귀 | 전환 전후 UI 모드와 인셋 비교 |
| 기본 탭 | 세로/가로, 제스처/3버튼 | 기존 상하 보호 회귀 및 측면 겹침 |

전체 조합을 무조건 전수 실행하기보다 결함을 구분하는 대표 조합을 계획에 선택하고 제외 범위를 기록한다. Flutter 위젯 테스트만으로 Android 시스템 모드 복원을 검증했다고 주장하지 않는다.

## 협업 증거와 실행 이력

- 설치된 `~/.claude/scripts/delegate.sh` 사용. agy/Claude/Grok 새 라운드 `20260908143701` 모두 실제 리뷰 수신 및 종료코드 0 확인.
- 원본 로그(로컬 파일, 저장소 외부): `~/.claude/plans/harness-2026-09-01-model-rounds/r20260908143701-{agy,claude,grok}.out`.
- 원본 프롬프트: `/private/tmp/mindlog-system-ui-review-2026090802.txt`. 임시 점검 기록: `/private/tmp/mindlog-android-system-ui-audit-20260908.md`. 임시 파일이 사라져도 본 핸드오프만으로 계획 수립 가능.
- 초기 브랜치 생성은 `.git` 쓰기 제한으로 rc=128 후 승인된 재실행 성공. 최초 round `2026090802`는 agy/Grok 기존 로그 중복 rc=3, Claude rc=71/출력 없음(원인 미확정). 보호 설정을 유지한 새 라운드에서 성공했으며 이전 로그는 덮어쓰지 않았다.
- 리뷰어에게 텍스트 검토/도구 사용 금지/수정 금지/재위임 금지를 요청했다. Grok 응답에는 프롬프트 파일을 읽겠다는 서술이 있어 도구 미사용을 보증하지 않는다. 저장소 앱 파일 변경은 없었다.
- 다음 세션에서 외부 모델 재검토가 필요하면 기존 프로토콜에 따라 새 숫자 라운드를 사용한다. 핸드오프 문서 작성 자체를 위해 모델을 재호출하지 않았다.

## 범위와 주의사항

- `SafetyBlockedFailure` 수정/삭제 금지. domain 순수 Dart 및 계층 경계 유지.
- 보호된 docs Pages 파일과 CI workflow 변경/삭제 금지. 현재 작업과 무관한 릴리스·알림·초안 이슈를 섞지 않는다.
- `git push`는 사용자 명시 승인 필요. 이번 핸드오프는 커밋하지 않았다.
- 검증 종료코드를 파이프 뒤 값으로 오인하지 않는다. analyze timeout/환경 실패를 통과로 기록하지 않는다.
- 과거 진행 파일의 SDK/배포/샌드박스 상태는 당시 기록이다. 현재 권한과 환경은 세션 지시를 따른다.
