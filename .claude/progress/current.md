# 현재 작업: 일기 임시저장(Draft) — Phase 1·2·3 + D-1·D-3 완료, 결함 2건 미수정

## 이어받는 사람에게 (3줄 요약)

1. 기능은 **끝났고 검증도 끝났다**. analyze rc=0 · test 1814건 통과 · 에뮬레이터 실기 7종 확인.
   로컬 커밋 16건이 `feat/diary-draft` 에 쌓여 있고 **푸시 승인만 남았다**.
   (초안 작업 11건 + 포맷 1건 + 기록 1건 + 이전 v1.4.63 세션 3건 `f0e1068`·`ef5fd22`·`a422bba` 도 아직 원격에 없다 — 푸시하면 함께 올라간다.)
2. ~~`dart format` 전역 드리프트~~ → **해결됨** (`87f5b29`, 2026-08-28). 실측 **53파일**(52 아님)을
   단일 전용 커밋으로 정리했고 `dart format --set-exit-if-changed .` rc=0 확인. PR 차단 요인 없음.
3. 남은 결함은 **D-2**(복원 경합, 창 <50ms)와 **D-5**(TTL 만료 시 이미지 파일 잔류, 구조적) 둘뿐.
   둘 다 데이터 유실이 아니며 급하지 않다. 「설계 판정」 4건은 되돌리지 말 것.

## 현재 작업

**브랜치 `feat/diary-draft` (main 아님). `origin/main` 대비 16건 앞섬, 전부 로컬 — 아직 푸시 안 함.**

| 커밋 | 내용 |
|------|------|
| `ab0f6f4` | Phase 1 — domain/data 레이어 |
| `34b3842` | Phase 2 — 자동저장·복원 UI 연결 |
| `9314968` | Phase 1·2 핸드오프 기록 |
| `918b042` | Phase 3 — `docs/spec.md` REQ-006 명세 |
| `ecbef57` | **D-1 수정** — `__draft__` 고아 이미지 정리 (유일한 프로덕션 변경) |
| `fd44cbe` | 에뮬레이터 검증 기록 |
| `ce1b9fc` | REQ-006 을 D-1 수정 후 실제와 맞춤 + TTL 고아 명시 |
| `62affc4` | **D-3 수정** — 테스트 공허/누락 5건 보강 |
| `287ec4e` | D-3 결과 기록 |

작성 중 유실을 막는 초안 기능. REQ-001(제출 시 pending 저장)이 보호하지 못하는 **제출 이전** 구간을 담당한다.
설계는 grok·agy·codex 3안을 대조해 확정했고, 갈린 쟁점은 코드로 판정했다(아래 「설계 판정」).

## 완료된 항목

### Phase 1 — domain/data (`ab0f6f4`)
- `DiaryDraft`(freezed) + `DiaryDraftRepository` + UseCase 3종(save/get/clear)
- `DiaryDraftRepositoryImpl` (`with RepositoryFailureHandler`), `PreferencesLocalDataSource` 에 JSON 단일 슬롯 추가
- `AppConstants.diaryDraftDebounce`(800ms) / `diaryDraftTtl`(7일)
- **DB 스키마 무변경** — `_currentVersion` 8 유지
- 테스트 34건 (save 12 · get 6 · clear 4 · repo impl 12)

### Phase 2 — presentation (`34b3842`)
- `DiaryDraftController` — 디바운스/flush/discard, 복원 전 선점 저장 차단, revision 직렬화
- `DiaryDraftBanner` — 복원 안내 + [삭제]/닫기
- `DiaryScreen` — PopScope·AppLifecycleListener **신규 도입**(이 화면에 없던 것), 이미지 `__draft__` 승격
- 테스트 28건 (컨트롤러 13 · 배너 9 · 화면 플로우 6)

### 품질 게이트 (최종, 2026-08-28)
`fvm flutter analyze` → **No issues found!** (rc=0) · `fvm flutter test` → **1814건 전부 통과** (`[E]` 0건)

`fvm dart format --output=none --set-exit-if-changed .` → **rc=0** (`87f5b29` 이후). 3개 게이트 전부 통과.

### 전역 포맷 정리 (`87f5b29`, 2026-08-28)
- `fvm dart format .` → 53파일 (lib 22 · test 30 · integration_test 1), 생성 파일 0건, 로직 변경 없음
- 원인: Dart 3.7+ tall-style 포맷터 규칙 차이 (인자를 여러 줄로 펼침) — 방치가 아님
- 검증: format rc=0 · analyze rc=0(No issues found!) · test **1814건 전부 통과**([E] 0건)

## 다음 단계

| 우선순위 | 작업 | 이유 |
|----------|------|------|
| **High** | **결함 D-2 — 복원 지연 중 입력이 기존 초안에 덮어써짐** | `DiaryDraftLoading` 동안 입력 UI는 열려 있는데 `onChanged`가 조기 반환(`diary_draft_controller.dart:153`), 이후 `_applyRestoredDraft`가 `_textController.text` 교체 |
| Medium | 결함 D-5 — TTL 만료 시 `__draft__` 파일 잔류 | grok 재대조 발견. `GetDiaryDraftUseCase`가 `clearDraft()`(prefs)만 호출 — 순수 Dart라 `ImageService` 호출 불가(구조적). 다음 터미널 분석·배너 [삭제] 때 정리되므로 누수는 유한 |
| Low | 결함 D-4 — `SaveDiaryDraftUseCase` 미래 날짜 미검증 | agy 트리아지 **[불필요]**: DatePicker `lastDate` + 복원 클램프 + `AnalyzeDiaryUseCase` 검증으로 3중 방어. 초안에 예외를 넣으면 자동저장이 조용히 멈출 위험이 오히려 큼 |
| **High** | `feat/diary-draft` → main 푸시·PR | 선행 조건(포맷) 해소됨 — 남은 건 사용자 푸시 승인뿐 |
| Medium | `cd.yml` `paths-ignore` 근본 수정 (이월) | 방침 asset 함정이 아직 살아 있음. `paths` 화이트리스트 전환 등 |
| Medium | Cloud Functions Node.js 20 → 22+ (이월) | **2026-10-30 decommission** |
| Medium | `action_item_preview` Analytics 전송 중단 검토 (이월) | AI 행동 제안 앞 50자 전송 중 |
| Medium | 방침 URL GitHub Pages 이전 (이월) | Google Sites 임베드 9,482자로 한도 근접 |
| Low | 스토어 설명 비의료기기 면책 문구 (이월) | 충돌할 주장 자체가 없어 선택적 |
| Low | `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` 재검토 (이월) | |
| Low | AI 생성 콘텐츠 인앱 신고 기능 (이월) | |
| Low | Groq API 키 서버 프록시 (이월) | |

> v1.4.63 프로덕션 승격은 이전 세션 건. 상태 확인 필요 시 `docs/tasks/history.md` 참조.

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

2026-08-28 · 브랜치 `feat/diary-draft` · `origin/main` 대비 16건, **푸시 안 함** · 워킹트리 클린
(`.claude/settings.local.json.bak-allowwrite-20260721` 은 세션 전부터 있던 untracked 백업 파일)
