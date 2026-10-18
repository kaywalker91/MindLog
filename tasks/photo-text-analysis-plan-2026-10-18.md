# 사진은 기록으로 보관하고 글만 AI 분석하는 수정계획

작성: 2026-10-18. 범위: 계획 수립. 앱 구현·커밋·푸시·배포는 수행하지 않는다.
기준: `fix/android-system-ui-insets`, HEAD `95e7323b0630f10402884211ff5f54ad72ca9c87`.
대상 배포 기준: 공개 `update.json` 및 로컬 태그의 v1.4.64, `pubspec.yaml`의 `1.4.64+72`.
사용자 증상: Galaxy A34, 사진을 첨부한 일기의 분석에서 404. 기기의 설치 버전과 직접 재현은 미확인.

## 1. 결정과 관찰 가능한 완료조건

사용자 결정은 **사진 첨부·기기 저장·열람을 유지하고, AI는 작성한 글만 분석**하는 것이다.

구현 완료 시 다음 조건을 모두 만족해야 한다.

1. 동일한 글·캐릭터·이름을 넣으면 사진 0/1/5장 모두 같은 텍스트 요청 계약을 사용한다. 사진 자체, 파일 경로, 첨부 수 등 사진에서 자동 생성한 정보를 AI 요청에 추가하지 않는다.
2. 사진 1/5장이 있는 일기도 분석에 성공하고 상세 화면에서 사진을 볼 수 있다. 텍스트 분석이 실패해도 이미 저장한 사진을 삭제하지 않는다.
3. 업데이트 전 사진과 분석 결과를 그대로 읽을 수 있다. 기존 결과를 일괄 재분석하거나 덮어쓰지 않는다.
4. 초안 저장·복원, 사진 선택·삭제·뷰어, 저장 제한 5장, 본문 10~5000자 검증과 안전 처리는 유지한다. 사진만 있는 일기 저장은 이번 범위에 추가하지 않는다.
5. UI, 앱 내/공개 개인정보 처리방침, 현재 기능 설명이 새 동작과 일치하고 구버전의 사진 전송 시도와 새 버전의 미전송을 구분한다.
6. 아래 회귀 테스트와 품질 게이트는 실제 rc=0이어야 한다. 기기/환경 미확보는 UNVERIFIED로 남긴다. 계획 검토 PASS를 구현·테스트 PASS로 표현하지 않는다.

이번에 제외하는 작업: 대체 비전 모델 도입, 사진 OCR/AI 캡션 생성, 사진 분석 토글, 사진만 저장하는 새 모드, 새로운 재분석 UI/API, DB 마이그레이션, 기존 데이터/캐시 일괄 삭제, 강제 업데이트 정책 변경, CI·Fastlane 동작 변경.

## 2. 원인과 코드 근거

- [AppConstants](../lib/core/constants/app_constants.dart): 비전 모델 `qwen/qwen3.6-27b`가 고정돼 있다. [Groq 공식 공지](https://console.groq.com/docs/deprecations)에 따른 종료일은 2026-09-14.
- 직전 진단의 실제 API 비교: 구모델 사진 요청은 HTTP 404 / `model_not_found`, 대체 비전 모델과 현재 텍스트 모델 `openai/gpt-oss-120b`는 HTTP 200. 이는 합성 이미지/글로 실행한 API 진단이며 A34 앱 종단 검증은 아니다.
- [DiaryRepositoryImpl](../lib/data/repositories/diary_repository_impl.dart): 사진이 있으면 비전 API와 `forVision` 캐시를 선택하며 413·429만 텍스트로 폴백한다. 404는 실패로 전파된다.
- [AnalyzeDiaryUseCase](../lib/domain/usecases/analyze_diary_usecase.dart): 사진 복사·압축 → `createDiary(imagePaths)` → `analyzeDiary(imagePaths)` 순이다. **저장용 사진 인자는 유지하고 분석용 사진 인자만 제거**해야 한다.
- [DiaryScreen](../lib/presentation/screens/diary_screen.dart): `_onRetryAnalysis()`도 `_startAnalysis()`를 거쳐 기존 UseCase를 다시 실행한다. 기존 일기 ID를 재사용하는 독립 재분석 UI는 이번 호출부 검색에서 확인되지 않았다. 재시도의 기존 신규 저장 동작을 이번에 변경하지 않는다.
- [GroqCacheKey](../lib/data/datasources/local/groq_cache_key.dart): 텍스트 키는 모델·글·캐릭터·이름·프롬프트 버전을 포함하고 사진 해시는 빈 배열이다. 비전 키와 이미 분리돼 있다.
- [PrivacyPolicyScreen](../lib/presentation/screens/privacy_policy_screen.dart)은 `docs/legal/privacy-policy.md`를 번들에서 읽는다. 공개 `docs/privacy-policy.html`도 별도로 갱신해야 한다.

## 3. 구현 순서와 파일별 책임

### 단계 A — 기존 결함을 잡는 테스트와 저장 계약 고정

프로덕션 변경 전에 아래 테스트를 준비한다. 사진 1/5장 케이스가 기존 코드에서 비전 호출 또는 이미지 payload 때문에 실패하는지 확인하고, 0장 케이스는 기존 정상 동작의 대조군으로 둔다.

- `test/data/repositories/diary_repository_impl_test.dart`: 사진을 가진 저장 일기도 실제 `GroqRemoteDataSource` + 기록용 `http.Client`를 연결해 최종 HTTP 요청을 관찰한다. 로컬 저장소는 기존 테스트 대역으로 격리할 수 있다.
- 0/1/5장 각각 독립적인 cache miss fixture를 사용한다. 같은 캐시를 공유해 요청이 생략되는 것을 사진 미전송 증거로 삼지 않는다.
- 성공·API 실패 뒤 `diary.imagePaths`/사진 파일/상태를 확인한다. repository 단위 테스트와 실제 사진을 복사하는 UseCase 테스트를 분리해 저장과 전송 두 책임을 검증한다.

### 단계 B — 저장과 분석의 경계 분리

같은 컴파일 단위로 다음 변경과 모든 호출/mock/stub를 맞춘다.

| 파일 | 변경 |
| --- | --- |
| `lib/domain/repositories/diary_repository.dart` | `analyzeDiary`의 `imagePaths` 인자와 Vision 주석 제거. `createDiary`의 사진 인자는 유지 |
| `lib/data/repositories/diary_repository_impl.dart` | `effectiveImagePaths`/`hasImages`, 비전 캐시, 비전 호출, 413·429 폴백 분기를 제거. 항상 `forText` → 캐시 miss 시 `analyzeDiary(content, character, userName)` |
| `lib/domain/usecases/analyze_diary_usecase.dart` | `_repository.analyzeDiary`로 사진을 전달하는 부분만 제거. `execute(imagePaths)`, `_processImages`, `createDiary(imagePaths)`, 안전 필터는 유지 |
| `lib/presentation/providers/diary_analysis_controller.dart` | 첨부를 저장할 수 있도록 `analyzeDiary(imagePaths)`와 UseCase 전달은 유지. 필요 시 주석만 저장 책임으로 명확화 |
| `test/mocks/mock_datasources.dart`, `test/mocks/mock_repositories.dart` 및 해당 호출 테스트 | 변경 시그니처와 호출 기록에 맞게 정리. `integration_test/diary_flow_test.dart`의 repository stub도 전수 확인 |

`rg`로 `.analyzeDiary(` 및 인터페이스 구현 전체를 다시 확인한다. named parameter 변경으로 stub가 미매칭한 예외가 일반 오류 경로에 흡수되지 않도록, 에러 테스트는 기대한 Failure 종류·statusCode까지 단언한다.

사진 저장이 실패하면 기존 로컬 이미지 오류를 유지한다. 이미 저장된 일기를 repository에서 분석할 때는 첨부 파일을 읽거나 인코딩하지 않으므로, 사진 파일 유실 자체가 텍스트 요청을 막아서는 안 된다. 유실 파일의 뷰어 UX 개선은 이번 범위 밖이다.

### 단계 C — 비전 전송 기능 정리

단계 B의 회귀 통과 후 별도 검토 가능한 변경 묶음으로 정리한다. 최종 릴리스에는 비전 호출 경로를 남기지 않는 것을 목표로 하되, 저장 helper와의 의존성이 발견되면 전송 기능만 제거하고 공유 부분은 보존한다. 단순 문자열 일괄 삭제는 하지 않는다.

- `lib/data/datasources/remote/groq_remote_datasource.dart`: `analyzeDiaryWithImages`, `_analyzeDiaryWithImagesRetry`, `_analyzeDiaryWithImagesOnce`, 비전 장수 상한 및 불필요한 `ImageService` import 제거.
- `lib/core/constants/prompt_constants.dart`: `systemInstructionForVision`, `createAnalysisPromptWithImages` 제거. 텍스트 프롬프트와 `version`은 유지.
- `lib/core/constants/app_constants.dart`: 비전 모델, 전송 상한, 비전용 384px/Q55 상수/getter 제거. 사진 저장의 5장·4MB·1920px·Q85는 유지하고 API 제한으로만 설명된 주석을 로컬 저장 정책으로 고친다.
- `lib/core/services/image_service.dart`: `_encodeToBase64InIsolate`, `encodeToBase64DataUrl`, `encodeMultipleToBase64DataUrls`, `encodeToBase64DataUrlForVision`, `encodeMultipleForVisionApi`, 실제 helper명 `_prepareVisionPayloadPath`를 사용처 확인 후 제거한다. 저장 복사·압축·읽기·삭제 helper와 해당 의존 패키지는 유지한다.
- `lib/data/datasources/local/groq_cache_key.dart`: `forVision` 및 비전 전용 설명 제거. `forText`의 직렬화 필드·정규화·버전·모델값은 유지한다.
- 비전 전용 테스트와 mock 필드를 새 계약 테스트로 교체한다. obsolete Vision 테스트를 삭제할 수 있으므로 전체 테스트 수 83개 유지는 완료조건으로 삼지 않는다.
- 공용 응답 파서의 isolate, DTO/엔티티 필드, 일반 네트워크 재시도·429 대기·서킷 브레이커는 유지한다. 사진 첨부를 위한 카메라/갤러리 권한도 유지한다.

413 오류 안내에 남은 "사진 수를 줄여" 문구는 텍스트 분석 상황에 맞게 교정한다. 사진 분석용 폴백은 사라지지만 텍스트 요청 자체의 413/429/네트워크 오류 처리는 보존한다.

### 단계 D — 사용자 안내와 문서 일치

- `lib/presentation/widgets/image_picker_section.dart`: 0/1/여러 장 안내에서 대표 1장 분석 표현을 제거한다. 장수 카운터·추가·삭제·비활성 상태는 유지한다.
- 공통 안내 후보: **"사진은 기록용으로 보관되며, AI는 작성한 글만 분석해요."** 필요하면 설명을 **"첨부한 사진은 AI 분석 서버로 전송하지 않아요."**로 보강한다. 운영체제 백업 등 모든 외부 전송이 없다고 보장하는 표현으로 확장하지 않는다.
- `lib/presentation/screens/diary_screen.dart`: 사진 유무에 따른 로딩 문구 분기를 없애고 글 분석 안내로 통일한다. 선택한 사진을 Controller로 전달하는 저장 동작은 유지한다.
- `docs/legal/privacy-policy.md`, `docs/privacy-policy.html`: 요약, 기기 저장, AI 전송 항목, 제3자 처리 항목, 국외 이전 항목, 이용자 전송 범위, 개정일·이력을 함께 갱신한다. 본문과 설정한 이름의 전송 설명, Firebase 설명은 실제 동작에 맞게 유지한다.
- 공개 방침에는 **새 버전 V_NEXT부터 사진을 AI 분석 서버로 전송하지 않음**과 시행일을 명시한다. v1.4.64 이하의 동작 및 과거 전송 이력을 소급해 바꾸지 않는다. 정확한 V_NEXT/시행일은 릴리스 준비 때 확정하며 임의로 이미 배포됐다고 적지 않는다.
- `README.md`, `docs/index.html`의 현재 기능 소개·기술표, `docs/spec.md` REQ-014, `docs/plan.md` 현재 분석 경로를 사진 기록/텍스트 분석 계약으로 맞춘다.
- 과거 changelog, TIL, 모델 마이그레이션 문서는 당시 이력으로 보존한다. `docs/index.html`의 과거 Vision 릴리스 기록도 삭제·현재 사실로 덮어쓰기하지 않는다. 현재 기능 설명과 이력을 명확히 구분한다.
- 온보딩/다국어/스토어 문구는 실제 검색에서 사진 분석 주장과 연결된 표면만 교정한다. 새로운 동의 플로우나 무관한 개인정보 정책 개편은 추가하지 않는다.

## 4. 사진·기존 분석·캐시 보존 계약

| 항목 | 보존/변경 원칙 |
| --- | --- |
| 사진 파일과 `Diary.imagePaths` | 현재 저장·초안·열람·사용자 삭제 계약 유지. 분석 전송만 제거 |
| 기존 분석 결과 | DB/DTO/엔티티 형식 유지. 열람 시 재분석·변환·일괄 덮어쓰기 없음 |
| DB schema | 변경 없음. schema version 증가 및 데이터 migration 없음 |
| 텍스트 캐시 | `forText` 값과 의미 유지. 같은 글/캐릭터/이름이면 사진 변경으로 cache miss를 만들지 않음 |
| 과거 비전 캐시 | 신규 분석에서는 조회하지 않음. 이번 변경을 이유로 삭제·DB 이동하지 않음. 기존 일반 eviction 정책은 유지 |
| 안전 응답 | `SafetyBlockedFailure` 수정/삭제 금지. 사전 위기 감지, AI emergency 처리, emergency 비캐시 유지 |
| 오류와 재시도 | 텍스트 요청 실패 시 기존 failed 상태와 오류 전달 유지. 현재 화면의 재시도 동작에 새 ID 재사용 정책을 끼워 넣지 않음 |

사진 유무와 cache miss/hit을 구분한다. 사진이 있는 기존 일기에 과거 비전 캐시가 있더라도 신규 분석은 텍스트 캐시만 사용하며, 저장된 과거 `analysisResult`를 열람하는 동작과 캐시 재사용을 혼동하지 않는다.

## 5. 검증 계획

### 필수 자동 검증

| 시나리오 | 관찰과 통과 기준 |
| --- | --- |
| 동일 글·캐릭터·이름, 사진 0/1/5장 | 각 cache miss에서 캡처한 최종 HTTP JSON이 같은 텍스트 계약. URL은 기존 공용 `/openai/v1/chat/completions`, `model`은 텍스트 모델, `messages[].content`는 문자열 |
| 사진 미전송 | 이미지 content block/`image_url`/자동 생성 Data URL·사진 바이트·경로·첨부 메타데이터가 전송 payload에 없음. repository mock 호출만으로 판정하지 않음 |
| 사진을 언급하는 글 | 사용자가 직접 쓴 사진 관련 텍스트는 그대로 분석. 문자열에 `image_url`/`base64`가 있다는 이유만으로 실패시키는 광범위 금지 검사는 사용하지 않음 |
| 저장·성공·실패 | 실제 파일 fixture로 1/5장 저장 후 분석 성공/실패 각각 파일/경로/내용 유지. failed 상태·정확한 Failure 확인 |
| 캐시 | 사진 유무·순서가 다른 동일 글은 텍스트 캐시 재사용. 텍스트 키 기준 fixture 값 불변. 과거 비전 캐시 fixture는 신규 분석에서 미사용 |
| 안전 | 사전 emergency 키워드 시 원격 요청 없음. AI emergency 응답은 기존 안전 상태 및 비캐시. 일반 오류와 안전 오류 구분 |
| 기존 데이터 | 업데이트 전 사진·분석 결과 fixture를 같은 schema로 읽음. 단순 열람에서 네트워크/사진 삭제/결과 덮어쓰기 없음 |
| 초안·UI | 사진 포함 초안 저장→복원→제출, 장수 제한·추가·삭제·전체화면 보기, 공통 안내, 분석 로딩 문구 검증 |

확장/교체할 기존 테스트:

- `test/data/datasources/remote/groq_remote_datasource_test.dart`
- `test/data/repositories/diary_repository_impl_test.dart`
- `test/data/datasources/local/groq_cache_key_test.dart`
- `test/core/services/image_service_test.dart`
- `test/core/constants/prompt_constants_test.dart` 및 비전 전용 테스트 정리
- `test/domain/usecases/analyze_diary_usecase_test.dart`
- `test/presentation/providers/diary_analysis_controller_test.dart`
- `test/presentation/widgets/image_picker_section_test.dart`, `image_picker_section_cachewidth_test.dart`
- `test/presentation/screens/diary_draft_flow_test.dart`와 기존 draft 저장/복원 테스트
- `integration_test/diary_flow_test.dart`의 시그니처/stub 및 사진 포함 흐름

`integration_test/groq_vision_emulator_smoke_test.dart`는 합성 로컬 사진을 이용하는 **사진 보관 + 텍스트 분석 계약** 스모크로 대체한다. 더 이상 검증 목적과 무관한 외부 사진 다운로드나 비전 API 호출을 하지 않는다. 새 이름 후보는 `diary_photo_text_analysis_smoke_test.dart`다. 최종 HTTP 전송 계약 자동 테스트와 실 API 텍스트 응답 스모크는 증거를 구분한다. 라이브 모델 출력 문장의 완전 동일성은 요구하지 않는다.

구현 후 실행 순서:

1. `fvm flutter test <위 영향 테스트 파일들>` → 테스트별 실제 종료코드와 로그 보존.
2. `./scripts/run.sh quality` → analyze/architecture/format/design/test+로그 검사 모두 rc=0. 현재 스크립트의 `dart format --set-exit-if-changed .`는 파일을 바꿀 수 있으므로 실행 전후 diff를 확인한다.
3. 전용 일회성 AVD에서 0/1/5장 작성→분석→상세 사진 보기, 초안 복원, 오류 후 재시도, 기존 fixture 열람 확인.
4. Galaxy A34는 데이터 보존 가능한 환경에서 동일 경로를 확인한다. 기기 접근이 없으면 미검증으로 보고하고, 자동 테스트 통과를 A34 실검증으로 표현하지 않는다. 테스트 설치 중 기존 앱 자동 uninstall이 일어나지 않도록 전용 환경을 우선한다.

`rg` 검색은 실제 네트워크 검증을 보완한다. 역사 문서의 Vision 문자열까지 0건으로 만들 필요는 없다. Flutter/Dart SDK 업데이트나 무관한 아키텍처 리팩터링은 이 작업에 포함하지 않는다.

## 6. 배포 경계와 롤백

- 릴리스 준비 시 V_NEXT와 build number를 확정하고 `pubspec.yaml`, `docs/update.json` 및 출시 안내를 맞춘다. 다음 번호 후보를 실제 배포 상태 확인 없이 확정 사실로 기록하지 않는다.
- 구버전은 앱에 박힌 비전 요청을 계속 시도할 수 있다. `update.json`은 그 코드를 원격으로 제거하는 기능이 없으므로 새 버전 업데이트 안내가 필요하다. 강제 업데이트 설정 변경은 이번 수정에 자동 포함하지 않는다.
- 공개 방침은 버전별 동작과 시행일을 명시하고 새 릴리스 제공 시점에 맞춰 게시한다. 사진 전송 중단은 과거 외부 전송 자료의 삭제를 보장하는 조치가 아니다.
- `android/fastlane/Fastfile`은 `skip_upload_changelogs: true`다. 출시 노트 파일 작성과 Play Console 반영 확인을 분리한다. 운영 콘솔 현재 상태는 미확인이다.
- 이 작업의 rollback은 DB 복구 없이 코드 수준에서 가능하지만, **사진 전송 경로 복원은 새 개인정보 계약과 충돌**한다. 문제 발생 시 텍스트 경로/저장 문제를 전진 수정하고, 비전 업로드 재활성화를 자동 fallback으로 두지 않는다.
- 커밋·푸시·릴리스는 이번 계획 수립 범위 밖이다. 특히 `git push`는 사용자 명시 승인 없이 실행하지 않는다. CI/Pages 파일을 삭제하지 않는다.

## 7. 5자 오케스트레이션 및 판단 기록

구성: 메인 Codex + 텍스트 리뷰어 Claude·Grok·Gemini(agy)·Kimi.
적용 규칙: `~/.claude/protocols/multi-model-cooperation.md`, `delegate-evidence.md`.
리뷰어는 동일 인라인 코드 발췌와 계획 초안을 받고 도구·수정·재위임 금지 조건으로 호출했다. 앱 저장소의 작성자는 메인 세션뿐이다.

라운드: `20261018205321`.
고정 입력 SHA-256: `b87bd53cb3747df35783a58ef5649db1c114c286d46be4ce7fa34827df766a78`.
프로필: `claude-hold`, `grok-hold`, `agy-default`, `kimi-baseline`.
실행: `MULTI_ROUND=20261018205321 MULTI_TIMEOUT=900 bash ~/.claude/scripts/multi-round.sh --profile claude=claude-hold --profile grok=grok-hold --profile agy=agy-default --profile kimi=kimi-baseline <고정 프롬프트> claude grok agy kimi`.
`multi-round.sh`가 설치된 `delegate.sh`로 각 리뷰어를 보호 설정 그대로 호출한다. 보호 없는 재시도/자동 모델 fallback은 하지 않는다.

네 리뷰어 모두 본문 응답을 반환했고 launcher rc=0, orchestration rc=0이었다. 네 응답의 판정은 모두 조건부 적합이며, 조건과 반론을 코드에 대조해 위 계획에 반영했다. 이를 모델별 실제 식별이나 구현 검증의 만장일치 PASS로 해석하지 않는다.

| 참가자 | 주요 의견과 최종 반영 | 응답/증거 상태 |
| --- | --- | --- |
| Codex 메인 | 호출부/저장 helper/DTO/재시도 경로를 직접 대조하고 최종 범위·순서 결정 | 계획 작성·코드 확인. 앱 구현 검증 아님 |
| Claude | 구버전 방침 경계, 저장본 사진으로 비전이 재선택되는 경로, 정리 작업 분리 | 응답 rc=0. 수집기 rc=3, native identity 부재로 UNVERIFIED |
| Grok | repository 분기 제거가 필수, 저장본 사진/인자 null 사례, 기존 결과 열람과 명시적 분석 구분 | 응답 rc=0. 수집기 rc=3, native identity 부재로 UNVERIFIED |
| Gemini(agy) | 기존 데이터 역직렬화 보존, 파라미터 경계, 구버전 업데이트 안내 | 응답 rc=0. 수집기 rc=3, `unsupported native user-input envelope`로 UNVERIFIED |
| Kimi | 비전 전용 삭제 목록, UseCase 저장/분석 인자 분리, 텍스트 키 불변 확인 | 응답 rc=0. 수집기 rc=0, PASS. 클라이언트 식별·본문·무결성 검사 범위 |

채택·보정한 쟁점:

1. **비전 코드 삭제 시점**: Claude는 후속 릴리스/별도 커밋 분리를 권고했고 나머지는 사용처를 확인해 같은 릴리스에서 제거하는 안을 지지했다. 최종안은 단계 B의 실제 요청 회귀를 먼저 통과시키고 단계 C를 별도 검토 단위로 진행한다. 공유 저장 코드는 보존한다. 사진 분석을 영구 종료하는 결정에 맞춰 최종 제품의 비전 전송 기능은 제거한다.
2. **재시도 사실과 가정 분리**: 별도 failed 일기 재분석 UI가 있을 것이라는 리뷰 가정은 채택하지 않았다. 현재 확인된 `_onRetryAnalysis`는 기존 작성 UseCase를 재실행한다. repository 테스트에서는 저장된 사진이 있는 일기를 분석해도 텍스트 경로만 사용함을 검증하고, 기존 UI 흐름에 새 재분석 기능을 추가하지 않는다.
3. **파일/URL 정정**: 리뷰의 `create_diary_use_case.dart`, `groq_remote_data_source.dart`, `_prepareImageForVisionApi`는 실제 수정 위치로 사용하지 않는다. 실제 이름은 위 파일표 및 `_prepareVisionPayloadPath`다. 텍스트와 비전은 같은 HTTP URL을 사용하며 모델 ID는 URL이 아닌 JSON `model` 필드다.
4. **증거 수준 보정**: Dio 관련 제안은 이 프로젝트의 `package:http` 기록용 Client로 바꾼다. `base64`라는 단어 전체 금지보다 JSON 구조/사진 fixture 유출 검사를 사용한다. 기존 83개 테스트 유지가 아니라 유효한 계약 유지와 회귀 검출을 기준으로 한다. 사진 0장 baseline까지 수정 전 실패해야 한다는 조건은 두지 않는다.
5. **과도한 확장 제외**: DTO/schema 변경, 비전 캐시 일괄 삭제, 새 재분석 API, 강제 업데이트 자동 적용, 과거 이력 재작성은 제외한다. 텍스트 키는 모델을 이미 포함하므로 모델 변경이 별도의 캐시 버전 bump를 항상 요구한다는 리뷰 주장도 채택하지 않는다. 이번에는 텍스트 모델·프롬프트·키가 모두 유지된다.

회수 기대값은 부모 stdout에서 고정했다. 현재 index를 새로 해싱해 기대값으로 재주입하지 않았다.

- operation: `2a78ed31-d5c3-40bf-8131-f56e997068f3`
- index SHA-256: `2bb3636ccdc4f53ac983df2c54deb413b145a655637940cde5a2be3953c586b4`
- [부모 index](/Users/kaywalker/.claude/plans/harness-2026-09-01-model-rounds/r20261018205321.operation/run-index.json)
- 원본 응답: [Claude](/Users/kaywalker/.claude/plans/harness-2026-09-01-model-rounds/r20261018205321-claude.out), [Grok](/Users/kaywalker/.claude/plans/harness-2026-09-01-model-rounds/r20261018205321-grok.out), [agy](/Users/kaywalker/.claude/plans/harness-2026-09-01-model-rounds/r20261018205321-agy.out), [Kimi](/Users/kaywalker/.claude/plans/harness-2026-09-01-model-rounds/r20261018205321-kimi.out)
- 리더의 고정 기대값/실행 로그/수집기 출력: [작업 기록](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-photo-text-plan-_1jwhakp/leader-bindings.json), [실행 로그](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-photo-text-plan-_1jwhakp/orchestration-launch.log), [수집 요약](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-photo-text-plan-_1jwhakp/collection-summary.json)
- 수집 명령: `python3 ~/.claude/scripts/collect-round-result.py --index <부모 index> --index-sha256 <고정 SHA> --operation 2a78ed31-d5c3-40bf-8131-f56e997068f3 --round 20261018205321 --backend <claude|grok|agy|kimi> --input-sha256 b87bd53cb3747df35783a58ef5649db1c114c286d46be4ce7fa34827df766a78`.
- 관측한 launcher sandbox/auth 실패와 timeout은 없다. 세 수집 UNVERIFIED를 우회하거나 모델 자기소개로 식별을 대체하지 않았다. 리뷰 내용은 코드에 대조한 검토 의견으로만 사용하며 미확인 모델 identity를 검증 완료로 보고하지 않는다.

## 8. 현재 작업의 완료 증거와 한계

- 이번 작업의 완료 대상은 검토된 수정계획 문서다. 구현 검증 항목은 앞으로 실행할 체크이며 현재 PASS가 아니다.
- 직전 장애 진단의 datasource/repository 테스트 83개 rc=0과 실 API 비교 rc=0은 baseline 근거다. 새 동작의 검증으로 전용하지 않는다.
- 이번에는 앱 소스를 바꾸지 않으므로 구현 품질 게이트와 기기 검증 실행은 N/A(계획 수립 범위). 향후 구현의 검증 상태는 아직 UNVERIFIED.
- 초기 사용자 변경 `.serena/project.yml`, `.claude/settings.local.json.bak-allowwrite-20260721`을 보존한다.
- 계획 문서의 로컬 Markdown 링크 존재 검사 rc=0. `git diff --exit-code -- lib test integration_test docs README.md pubspec.yaml android .github` rc=0으로 앱/문서/배포 파일의 기존 tracked 내용 변경이 없음을 확인했다.
- 신규 파일 비교 명령 `git diff --no-index --check /dev/null tasks/photo-text-analysis-plan-2026-10-18.md`는 진단 출력 없이 rc=1이었다. 신규 파일의 차이를 보고하는 no-index 종료값이므로 이 결과를 whitespace PASS로 사용하지 않는다. 별도 Python 파일 검사로 UTF-8·줄 끝 공백·최종 newline을 확인한다.
- 검사 원본과 실제 종료값: [초기 검사 기록](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-photo-text-plan-_1jwhakp/plan-validation.json), [최종 검사 기록](/var/folders/bl/11gbdbms3fs4k_6l88lmbbw40000gn/T/mindlog-photo-text-plan-_1jwhakp/plan-validation-final.json).
- 최종 저장소 변경 범위는 본 계획 파일 1개 추가와 위 기존 사용자 변경 2건이다. 구현·배포는 미착수다.
