# 현재 작업: 없음 — v1.4.64(일기 임시저장) 배포 완료

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
