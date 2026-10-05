# 현재 작업: Android 시스템 UI — 구현 진행 후 사용자 요청으로 핸드오프 (2026-09-08)

## 2026-10-05 재개순서 2 — 결합 조건 검증 (미커밋)

- **결함 발견·수정: PIN 오류 SnackBar가 키패드를 가림.** 320×480(인셋 32/48)에서 1회 실패 직후 최대 스크롤에도 `0`·삭제 키 탭 불가(글자 2배는 `7` 행까지), 3회 실패 시 「아래 링크를 통해 초기화」 SnackBar(y364–480)가 그 링크(y368–389)를 4초간 덮음. 사용자 선택으로 **인라인 오류 문구**로 전환: `PinKeypadWidget.errorText`(도트 아래, `Semantics(liveRegion)`), 잠금해제 불일치/검증오류·설정 불일치/저장오류. PIN 초기화 실패는 키패드 재입력과 무관해 SnackBar 유지. 설정 화면 미사용 `_showMessage` 제거.
  - RED 4건(메시지가 카드 밖·링크 가림) → GREEN.
- 추가 검증: PIN 두 화면 작은화면×글자1/2 흐름(설정: 확인→불일치→재입력 완료 / 해제: 3회 실패→링크→다이얼로그 버튼 안전영역), 시트 행렬 12→24(수정 모드+긴 초기값), 가로 915×412 좌측 컷아웃 48 시트 2건·목록 1건, SnackBar 표시 중 마지막 카드 재정렬 후 여백 복원.
- 게이트: analyze rc=0 · arch rc=0 · format 0 changed · design-audit 35건 HEAD와 동일 · **전체 1865 passed** · leakage rc=0.
- 테스트 하네스 한계: 잠금해제 테스트는 GoRouter 없는 `MaterialApp(home:)`라 다이얼로그 `ctx.pop()` 취소 탭은 검증 불가(기존 테스트도 미탭).

## 2026-10-05 재개 — 핸드오프 재개순서 1·3 완료

- **결함 발견·수정: SnackBar `GlobalKey` 중복 크래시.** `ScaffoldMessenger`는 모든 root Scaffold에 같은 SnackBar를 빌드한다(SDK `scaffold.dart` `_updateScaffolds`). 설정→Cheer Me push 시 아래 Settings Scaffold에도 빌드돼 `Multiple widgets used the same GlobalKey`. 기존 테스트는 단일 라우트라 못 잡음.
  - RED: 신규 테스트 「다른 Scaffold 위로 push된 상태에서 피드백 후 뒤로 가도 예외가 없어야 한다」 rc=1(예외 4건).
  - 수정: SnackBar 키 제거 → 화면 Scaffold에 `_scaffoldKey`, post-frame에 그 하위에서 SnackBar Element 크기 측정. 종료 판별은 토큰 객체.
  - 돌연변이(측정값 0 고정) 시 2건 실패 → 측정 로직이 테스트로 보호됨 확인 후 원복(cmp 동일).
- agy (a) inactive Element 우려: post-frame은 `finalizeTree` 이후라 inactive Element는 이미 unmount됨 — 위 구조 변경으로 GlobalKey 조회 자체가 사라져 해당 없음. (b) build마다 post-frame 예약은 setState가 0.5 초과 변화일 때만이라 루프 없음.
- **quality 5단계 수동 실행**(스크립트의 format은 in-place라 `--output=none`으로 대체): analyze `--fatal-infos` rc=0 · arch-smoke strict rc=0 · format 0 changed · **design-audit rc=1, 35건 — HEAD 스냅샷도 동일 35건(파일·내용 일치) = 기존 부채, 본 브랜치 유입 0** · 전체 테스트 **1845 passed rc=0** · leakage rc=0.
- 남은 것: 재개순서 2(PIN 확인/불일치/잠금실패 등 결합 조건), 4(Android 3버튼·실제 앱·사진 D — **에뮬레이터 데이터 보존 먼저 확인**), 5(Grok/Claude 재리뷰). 커밋·푸시 없음.

**재개 시 [구현 핸드오프](../../tasks/android-system-ui-implementation-handoff-2026-09-08.md)를 먼저 읽는다.** 기존 계획의 “미착수” 기록보다 최신이다.

- A/B/C 구현 및 목록 좁은 화면·SnackBar 실측 여백 보완. 앱 6파일, 기존 테스트 3파일 변경; 목록 테스트와 Android integration test 신규.
- 관련 테스트 **89개 통과(rc=0)**. API36 제스처 integration **1개 통과(rc=0)**. 앱 전체/3버튼/실기 검증과 구분.
- **quality 미통과(rc=1)**: integration test unnecessary_import 제거 후 재실행하지 않음. 최종 format/diff --check 통과.
- agy/Grok/Claude 최초 검토 모두 rc=0. 최종 diff는 agy만 rc=0; Grok/Claude 응답 전 사용자 요청으로 종료(rc143). agy의 snackbar 수명 관련 의견 검증 대기, SafeArea bottom 설명은 공식/SDK 근거로 반려.
- 사진 코드 미변경, D 계속 미확정. PIN/시트의 추가 결합 조건, 사진 가시성/대비/라이프사이클 등 남음.
- **주의: integration APK 설치 저장공간 오류 후 Flutter CLI가 기존 에뮬레이터 앱을 자동 삭제·재설치했다. 기존 앱 데이터 유실 가능, 백업 없음. 최종 설치는 테스트 하네스 APK.** 재개 전 핸드오프 환경 변경 항목 필독.
- 커밋·푸시 없음. 기존 계획·핸드오프·백업 파일 보존. 아래 릴리스 내용은 역사 기록.

---

# 이전 작업 기록 — v1.4.64(일기 임시저장) 배포 완료

## 이어받는 사람에게 (3줄 요약)

1. **일기 임시저장(REQ-006)은 설계·구현·검증·릴리스까지 전부 끝났다.** v1.4.64+72 가 Play Internal 트랙에
   업로드됐고(CD run `33122480912` success), **미푸시 커밋 0건**. 이어받을 미완 작업 없음.
2. **남은 결함은 D-2**(복원 경합, 창 <50ms)**와 D-5**(TTL 만료 시 `__draft__` 이미지 잔류, 구조적) **둘뿐.**
   둘 다 데이터 유실이 아니다. 「설계 판정」 4건은 되돌리지 말 것.
3. **Play Console 출시 노트가 비어 있다.** `Fastfile` 4개 레인 전부 `skip_upload_changelogs: true` 라
   커밋해 둔 `72.txt` 가 업로드되지 않았다 — 아래 「다음 단계」 참조. 사용자 안내(`docs/update.json`)는 정상 반영됨.

## 현재 상태

**`origin/main` = `0a9505d` · `pubspec.yaml` = `1.4.64+72` · 워킹트리 클린 · 미푸시 0건.**
(`.claude/settings.local.json.bak-allowwrite-20260721` 은 세션 전부터 있던 untracked 백업 파일)

| 파이프라인 | 결과 |
|-----------|------|
| CI (PR #4) | 4/4 SUCCESS — Setup · **Analyze & Format** · Tests · Build Verification |
| 머지 | MERGED — **머지 커밋 `0a9505d`** (부모 `1dd9ad8` + `87d437b`). main 최초의 머지 커밋으로, 그전까지 선형이던 히스토리가 여기서 갈라진다 · `mergedAt` 2026-08-27T22:26Z |
| CD `33122480912` | success — headSha `0a9505d` 빌드. `Successfully finished the upload to Google Play` (Internal, AAB 52.6MB) |
| GitHub Pages | success — `docs/index.html` 카드 3건 반영 |

`ci.yml` 은 로컬보다 엄격하다: `flutter analyze --fatal-infos` + **build_runner 재생성 이후** format 검사.
생성 파일은 `.gitignore` 대상이라 CI 가 매번 새로 만든다 — 로컬 검증 시 이 두 가지를 같이 맞춰야 한다.

## 이번 세션 완료

| 커밋 | 내용 |
|------|------|
| `87f5b29` | `dart format` 전역 드리프트 **53파일** 정리 (원인: Dart 3.7+ tall-style 규칙 변화). PR 차단 요인 해소 |
| `16a7591` | progress 갱신 + 커밋 수 정정 |
| `87d437b` | v1.4.64 릴리스 문서 3종 + 버전 범프 |

릴리스 문서는 독자별로 분리해 작성 — `CHANGELOG.md`(개발자, 설계 판단 근거까지) ·
`docs/update.json`(사용자 안내 4건) · `docs/index.html`(채용담당자용 카드 3건) ·
`android/fastlane/.../72.txt`(ko·en-US, Play 500자 한도 내 — **다만 업로드되지 않음**, 아래 참조).

게이트: `dart format` rc=0 · `analyze --fatal-infos` rc=0 · `test` **1814건 전부 통과**.

## 다음 단계

| 우선순위 | 작업 | 이유 |
|----------|------|------|
| **High** | **결함 D-2 — 복원 지연 중 입력이 복원본에 덮어써짐** | `DiaryDraftLoading` 동안 입력 UI 는 열려 있는데 `_canSave`(`diary_draft_controller.dart:153`)가 `onChanged`(`:74`)를 조기 반환시키고, 뒤이어 `_applyRestoredDraft`(`diary_screen.dart:238`)가 `_textController.text` 를 교체. 창 <50ms |
| **High** | **`skip_upload_changelogs` 결정** | `android/fastlane/Fastfile` 4개 레인 전부 `skip_upload_metadata: true` + `skip_upload_changelogs: true` → CD 가 AAB 만 올린다. 출시 노트를 CD 로 내보내려면 플래그를 끄고, 아니면 Play Console 수기 입력. **배포 파이프라인 동작 변경이라 사용자 판단 대기 중** |
| Medium | 결함 D-5 — TTL 만료 시 `__draft__` 파일 잔류 | `GetDiaryDraftUseCase` 는 순수 Dart라 `ImageService` 호출 불가(구조적) — 만료 시 prefs 슬롯만 삭제. 다음 배너 [삭제]·터미널 분석에서 정리되므로 누수는 유한 |
| Low | 결함 D-4 — 미래 날짜 미검증 | **[불필요] 판정 유지.** DatePicker `lastDate` + 복원 클램프 + `AnalyzeDiaryUseCase` 3중 방어. 초안에 예외를 넣으면 자동저장이 조용히 멈출 위험이 더 큼 |
| Medium | `cd.yml` `paths-ignore` 근본 수정 (이월) | 방침 asset 함정이 아직 살아 있음. `paths` 화이트리스트 전환 등 |
| Medium | Cloud Functions Node.js 20 → 22+ (이월) | **2026-10-30 decommission** |
| Medium | `action_item_preview` Analytics 전송 중단 검토 (이월) | AI 행동 제안 앞 50자 전송 중 |
| Medium | 방침 URL GitHub Pages 이전 (이월) | Google Sites 임베드 9,482자로 한도 근접 |
| Low | 스토어 설명 비의료기기 면책 문구 (이월) | 충돌할 주장 자체가 없어 선택적 |
| Low | `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` 재검토 (이월) | |
| Low | AI 생성 콘텐츠 인앱 신고 기능 (이월) | |
| Low | Groq API 키 서버 프록시 (이월) | |

**확인 필요(미확인)**: Play Console Internal 트랙에 versionCode 72 도착 여부. 업로드 성공 로그는 있으나 콘솔은 열어보지 않았다.

## 설계 판정 (3안이 갈렸고 코드로 결론낸 것 — 되돌리지 말 것)

1. **SafetyBlocked 시 초안 파기** — `analyze_diary_usecase.dart:66` 이 분석 **전에** `createDiary` 로 pending 저장하고, L110 이 `updateDiary(status: safetyBlocked)` 로 저장 후 return 한다. 즉 위기 본문은 **이미 DB 에 있다** → 초안을 지워도 유실이 아니고, 남기면 다음 진입 배너가 위기 본문을 재노출한다.
2. **폐기는 터미널 상태에서만** (제출 시작 시점 아님) — 실행 순서가 `validate → _processImages(수백ms~초) → createDiary` 라, 제출 시작 시 지우면 이미지 처리 중 강제 종료 시 본문이 **DB 에도 초안에도 없다**. 대가로 분석 중 강제 종료 시 재제출하면 row 중복 가능 — 유실(회복 불가) < 중복(삭제 가능) 으로 수용.
3. **이미지는 선택 즉시 `__draft__` 승격** — `_selectedImages` 에 담기는 건 image_picker 캐시 경로이고 `copyToAppDirectory` 는 `analyze_diary_usecase.dart:188`, 즉 **제출 시점에만** 호출된다. 경로만 저장하면 복원이 죽은 경로를 가리킨다.
4. **SharedPreferences 단일 슬롯** (SQLite v9 테이블 아님) — 휘발성 1건에 `_onCreate`/`_onUpgrade` 동기화·DROP 금지 제약을 지불하지 않는다.

## 주의사항

- **`ProviderContainer` 는 `fakeAsync` 존 안에서 만들 것.** 밖(`setUp`)에서 만들면 컨트롤러 내부 Future 체인이 실제 zone 에 묶여 `async.flushMicrotasks()` 로 진행되지 않는다. 이번 세션에서 이것 때문에 9건이 "no calls at all" 로 실패했고, **저장 성공 케이스만 실패하고 `verifyNever` 부정 단언은 전부 공허 통과**했다. 실제 타이머로 별도 진단 테스트를 돌려 제품 코드가 정상임을 먼저 갈랐다.
- **`build_runner`/`flutter` 는 샌드박스에서 실행조차 안 된다** — `flutter/bin/cache/engine.stamp: Operation not permitted`. 에러 한 줄만 남아 "이슈 없음" 처럼 보인다.
- `docs/spec.md` 090번대는 UX 품질 구간(실부여 최댓값 REQ-096, 099는 구간 상한) — 신규 REQ 에 쓰지 말 것.

## Phase 3 결과 (2026-08-27)

`docs/spec.md` REQ-006 반영 완료 (+33 / -3). 섹션 헤더 `REQ-001 ~ REQ-006`, 화면 매핑표 DiaryScreen, UseCase 목록 19→22 동기화.

### 에뮬레이터 실기 검증 (Pixel_7_Test, debug 빌드)

증거는 전부 온디바이스 `shared_prefs/FlutterSharedPreferences.xml` 직접 판독 + 스크린샷.

| 시나리오 | 결과 | 증거 |
|----------|------|------|
| 자동저장이 디스크에 기록 | PASS | `flutter.draft_diary_entry` JSON (content/entryDate/updatedAt/imagePaths) |
| 작성 중 강제 종료 → 재진입 복원 | PASS | `am force-stop` 후 재기동, 배너 「이전에 작성하던 내용을 불러왔어요」 + 본문 31자 복원 |
| 백그라운드 전환 flush (디바운스 만료 전) | PASS | HOME 직후 `updatedAt` 21:29:57 → 21:31:16 갱신 |
| 화면 이탈(PopScope) flush | PASS | 입력→뒤로가기→즉시 force-stop 조건에서 `updatedAt` 갱신(디바운스 불가 구간) |
| 이미지 `__draft__` 승격 | PASS | `app_flutter/diary_images/__draft__/image_0.jpg` (100,226 B) + 초안 `imagePaths` 기록 |
| 강제 종료 후 이미지 복원 | PASS | 재진입 시 썸네일 1/5 + 「마음 털어놓기 (사진 1장 포함)」 |
| 배너 [삭제] 후 이미지 파일 정리 | FAIL → **수정 후 PASS** | 수정 전: 초안 키는 0개인데 `__draft__/image_0.jpg` 잔류. 수정 후: `__draft__` 디렉토리 자체 소멸 |

미검증: TTL 7일 만료(시각 조작 필요), 안전차단 경로(실제 위기 문구 필요).

### D-1 수정 (`lib/presentation/screens/diary_screen.dart`, +43/-6)

- `_onDraftDelete`: `ImageService.deleteDiaryImages('__draft__')` 추가
- `_onImageRemoved`: 제거된 경로가 `__draft__` 승격본이고 목록에 남은 참조가 없을 때만 `deleteImage`.
  승격 실패로 폴백한 **picker 원본 경로는 사용자 파일이라 삭제하지 않는다**
- 파일명 인덱스를 목록 길이 → **단조 증가**(`_draftImageSeq`)로 교체.
  기존 방식은 삭제 후 재추가 시 남아 있던 승격본을 덮어써 두 목록 항목이 같은 파일을 가리켰다
  (고아 파일을 지우기 시작하면 이 충돌이 곧 데이터 유실이 되므로 함께 고침)
- 복원 시 `_nextDraftImageSeq()` 로 복원된 `image_N` 뒤 번호에서 이어받는다

검증(에뮬레이터): 2장 첨부 → 첫 장 제거 시 `image_0.jpg`만 삭제 · 재추가는 `image_2.jpg` 생성으로
`image_1.jpg` 보존 · 배너 [삭제] 시 `__draft__` 디렉토리 소멸. `flutter analyze` rc=0, `flutter test` 1810건 통과.

### D-3 수정 (테스트 5건, `62affc4`)

프로덕션 코드 변경 없음. 1810 → **1814건**.

| 항목 | 문제 | 조치 |
|------|------|------|
| 배너 색상 | `isNot(AppColors.primary)` 부정 단언 — 색 누락·오지정도 통과 | 문구별 지정 토큰 긍정 단언 (onSurface / onSurfaceVariant / error) |
| 케이스 f (미래→오늘 클램프) | `_selectedDate` 기본값이 이미 '오늘' → 날짜 복원을 통째로 지워도 통과 | 케이스 **g**(과거 날짜 복원) 추가로 공백 차단 |
| 이미지 복원 | 미검증 | **h** — 실제 임시 PNG 2장으로 `Image.file` 예외 회피 |
| 백그라운드 flush | 미검증 | **i** — enterText 후 200ms만 경과시켜 800ms 디바운스와 분리 |
| `restore()` Failure 분기 | 미검증 | **j** — 상태 + 이후 입력이 저장까지 도달하는지까지 확인 |

**돌연변이 검증 통과** — 해당 프로덕션 로직을 각각 제거하면 5건 모두 실패한다
(M1 날짜복원 · M2 이미지복원 · M3 lifecycle배선 · M4 제목색 · M5 Absent전환).
M4는 1차 시도에서 앵커 불일치로 돌연변이가 **적용되지 않은 채** "통과"가 나왔다 —
돌연변이 검증은 적용 성공 여부를 먼저 확인해야 한다.

미이관: PopScope flush 는 위젯 테스트 하네스에 GoRouter 가 없어 `context.pop()` 이 던진다.
에뮬레이터 검증으로만 확인된 상태.

### 3사 위임 결과

- **codex** (코드 결함): 확정 3건 — D-1 고아 파일, D-2 복원 경합, 백그라운드 flush 가 `unawaited` 라 저장 완료 전 프로세스 종료 가능. out-of-order 덮어쓰기는 「미확인」으로 반려(`_operationTail` 직렬화가 실제로 막음).
  - 단, codex 의 「PopScope `didPop == true` 로 flush 누락」은 **반려**: `canPop: false` 라 시스템 뒤로가기·AppBar 백버튼(`Navigator.maybePop`) 모두 핸들러를 탄다. 남는 위험은 외부에서 `context.pop()` 을 직접 부르는 경로뿐이고 현재 그런 호출은 없다.
- **grok** (스펙 적대적 검토): 5건 반영 — trim 규칙, 공백 본문+이미지 케이스, TTL 판정 시점(타이머 아님), 죽은 경로의 저장본 미갱신, isSecret 미저장·PIN 미보호.
- **agy** (스펙↔구현↔테스트 갭): 8건. 그중 D-3(공허/누락 테스트 5건)과 D-4(미래 날짜)를 다음 단계에 등재.

### 최종 검토 라운드 (D-1 수정 후)

- **grok**: 갭 문구 3경우를 갈라 판정 — 배너 [삭제]/개별 제거는 [사실아님](해소), 승격 복사 중 이탈만 [여전히사실].
  추가로 **TTL 만료 시 파일 잔류**(D-5)를 찾아냄. spec `ce1b9fc` 로 반영.
- **agy**: D-2 [이슈등록](복원 창 <50ms로 재현 희박) · D-3 [지금수정] · D-4 [불필요].
  단, **「셰이더 크래시로 CI 실패」 주장은 반려** — 테스트 로그에 `ink_sparkle` 언급 0회, 1810건 전부 통과.
- **codex**: 2회 연속 리포트 미산출(탐색 로그만 98KB, 재시도는 헤더만). 5개 검토 항목은 직접 확인:
  원본 파일 삭제 위험 없음(`/__draft__/` 가드) · `contains` 가드 유효(첫 await 전 동기 실행) ·
  `_nextDraftImageSeq` 호출됨(누락 시 복원본 덮어씀) · `!mounted` 고아 확정 · 두 unawaited 경합 없음(자원 분리).

### 부수 관찰 (미확정)

- 배너 제목 「이전에 작성하던 내용을 불러왔어요」가 2줄로 접히며 「요」만 다음 줄로 떨어진다 (`DiaryDraftBanner` 폭 제약).
- 백그라운드 복귀 후 폼 텍스트가 직전 편집 이전 상태로 되돌아간 정황이 1회 있었다. `adb shell input text` 의 IME 상태 복원 아티팩트일 가능성이 커 **제품 결함으로 단정하지 않는다**. 디스크 기록은 매 단계 최신이었다.

## 마지막 업데이트

2026-08-28 · `origin/main` `0a9505d` · v1.4.64+72 Play Internal 업로드 완료 · **미푸시 0건** · 워킹트리 클린
· 에뮬레이터 `emulator-5554` 종료됨 (연결 기기 0)
