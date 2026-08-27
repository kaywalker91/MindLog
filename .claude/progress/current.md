# 현재 작업: 일기 임시저장(Draft) — Phase 1·2 완료, Phase 3 남음

## 현재 작업

**브랜치 `feat/diary-draft` (main 아님). 커밋 2건, 아직 푸시 안 함.**

| 커밋 | 내용 |
|------|------|
| `ab0f6f4` | Phase 1 — domain/data 레이어 |
| `34b3842` | Phase 2 — 자동저장·복원 UI 연결 |

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

### 품질 게이트
`fvm flutter analyze` → **No issues found!** (rc=0) · `fvm flutter test` → **1810건 전부 통과** (`[E]` 0건)

## 다음 단계

| 우선순위 | 작업 | 이유 |
|----------|------|------|
| **High** | **Phase 3 — `docs/spec.md` 에 REQ-006 추가** | 스펙 미반영 상태. REQ-005 뒤, REQ-006~009 미사용 확인됨. 문구 초안은 아래 「REQ-006 초안」 |
| **High** | **실기기 수동 검증** | 자동 테스트로 못 잡는 것: 앱 강제 종료 후 재진입 복원, 백그라운드 전환 flush, 실제 이미지 첨부 후 복원 |
| Medium | `feat/diary-draft` → main PR | **`dart format` 드리프트 43파일이 `ci.yml:115` 에서 PR 즉시 실패시킨다** (이전 세션 이월). PR 전 해결 필요 |
| Medium | `__draft__` 이미지 고아 파일 정리 | 현재는 터미널 상태에서만 삭제. 앱이 강제 종료되면 남는다. 앱 시작 시 청소 루틴 검토 |
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

## REQ-006 초안 (Phase 3에서 `docs/spec.md` REQ-005 뒤에 삽입)

```
### REQ-006: 일기 임시저장(Draft)
- 작성 중 본문·작성일·첨부 이미지를 단일 초안 슬롯에 자동 저장한다
  (텍스트 800ms 디바운스, 이미지·날짜 변경 및 화면 이탈·백그라운드 전환 시 즉시)
- 10자 미만도 저장한다 (10자는 제출 게이트이지 초안 게이트가 아님). 공백뿐이면 기존 초안을 삭제한다
- 재진입 시 복원하고 배너로 [삭제]를 제공한다. 경로가 유효하지 않은 이미지는 복원에서 제외한다
- 분석 성공·안전차단·명시 삭제·7일 경과 시 폐기한다. 분석 실패 시에는 유지한다
- REQ-001(제출 시 pending 저장)과 분리된 제출 이전 구간의 유실 방지책이다
```

## 마지막 업데이트

2026-08-27 · session cfbbb749 · 브랜치 `feat/diary-draft` · 커밋 `ab0f6f4`, `34b3842` (푸시 안 함)
