# Play Console — Data safety 신고 답표

MindLog(`com.mindlog.mindlog`) 의 Google Play **Data safety** 폼 작성용 정답표.
Play Console 은 코드로 관리할 수 없으므로, **무엇을 왜 그렇게 신고했는지**를 이 문서에 남긴다.
다음 갱신 때 처음부터 다시 조사하지 않기 위한 문서이며, 심사 문의 대응 근거로도 쓴다.

- 작성 기준일: **2026-08-25** (앱 v1.4.62 / versionCode 70)
- 대응 개인정보 처리방침: [`privacy-policy.md`](privacy-policy.md) · 웹 <https://kaywalker91.github.io/MindLog/privacy-policy.html>

**근거 문서** (작성 시점에 직접 확인)

| 출처 | 용도 |
|------|------|
| [Play Data safety 공식 안내](https://support.google.com/googleplay/android-developer/answer/10787469) | 데이터 유형 분류표, "수집"·"공유" 정의, 서비스 제공자 예외 |
| [Firebase Android Play 데이터 공개 가이드](https://firebase.google.com/docs/android/play-data-disclosure) | SDK별 자동 수집 항목, 암호화·공유·삭제 |
| [Google Analytics 수집 데이터](https://support.google.com/analytics/answer/11582702) | 광고 ID·마스킹 IP 처리 |

---

## 1. 개요 질문

| 질문 | 답 | 근거 |
|------|-----|------|
| 앱이 필수 사용자 데이터 유형을 수집하거나 공유합니까? | **예** | 아래 2항 참조 |
| 수집하는 모든 사용자 데이터가 전송 중 암호화됩니까? | **예** | Groq API 는 HTTPS(`https://api.groq.com`). Firebase 는 "collected end-user data ... encrypts the data in transit using HTTPS" 명시. 앱에 평문 HTTP 통신 경로 없음(별도 network security config 없이 targetSdk 36 기본 cleartext 차단) |
| 사용자가 데이터 삭제를 요청할 수 있는 방법을 제공합니까? | **예** | 앱 내에서 일기 개별·전체 삭제 가능. 계정이 없으므로 계정 삭제 개념은 없으며, 그 외 요청은 `eorkr112@naver.com` 으로 접수 |

> **"수집(Collected)"의 정의** — 기기 밖으로 전송되는 것. 기기에만 머무르는 데이터는 수집이 아니다.
> 일기 본문·사진 원본·PIN·앱 설정은 기기에 저장되지만, **일기 본문/사진/이름은 분석을 위해 전송되므로 수집에 해당**한다.

---

## 2. 데이터 유형별 답표

전 항목 **Shared = 아니오** (근거는 3-1 참조). 아래 표의 "선택/필수"는 Play 의 *Optional / Required* 항목이다.

| 카테고리 | 데이터 유형 | 수집 | 공유 | 선택/필수 | 목적 | 무엇이 해당하는가 |
|---|---|---|---|---|---|---|
| Personal info | **Name** | 예 | 아니오 | **선택** | App functionality, Personalization | 이용자가 설정한 이름/애칭. 설정 시 Groq 프롬프트에 포함되어 전송 |
| Health and fitness | **Health info** | 예 | 아니오 | 필수 | App functionality, Analytics | 감정 점수(`sentiment_score`), 에너지 수준(`energy_level`) |
| Photos and videos | **Photos** | 예 | 아니오 | **선택** | App functionality | 일기 첨부 사진 중 **첫 1장**만 분석용으로 전송 |
| App activity | **Other user-generated content** | 예 | 아니오 | 필수 | App functionality, Analytics | 일기 본문 텍스트, AI 행동 제안 문구 앞 50자 |
| App activity | **App interactions** | 예 | 아니오 | 필수 | Analytics | 화면 조회, 통계 조회 기간, 리마인더 설정 시각, 캐릭터 변경 |
| App info and performance | **Crash logs** | 예 | 아니오 | 필수 | Analytics | Crashlytics 스택 트레이스·앱 상태 |
| App info and performance | **Diagnostics** | 예 | 아니오 | 필수 | Analytics | Performance Monitoring 시작 시간·네트워크 지연·CPU/메모리 |
| Device or other IDs | **Device or other IDs** | 예 | 아니오 | 필수 | App functionality, Analytics | Firebase installation ID, Crashlytics installation UUID, FCM 등록 토큰 |
| Location | **Approximate location** | 예 | 아니오 | 필수 | Analytics | IP 기반 국가 수준 추론 (Performance 가 IP 수집, GA 가 마스킹 IP 에서 대략 위치 파생) |

### 명시적으로 "아니오"로 두는 항목

실수로 체크하기 쉬운 것들을 근거와 함께 기록한다.

| 항목 | 답 | 근거 |
|------|-----|------|
| Precise location | 아니오 | 위치 권한 자체를 선언하지 않음 |
| Email address / User IDs / Address / Phone number | 아니오 | 계정 체계 없음. 어느 것도 수집·전송하지 않음 |
| Financial info 전체 | 아니오 | 결제·구독 없음 |
| Messages (Emails / SMS / 기타) | 아니오 | 일기는 메시지가 아니라 user-generated content 로 분류 |
| Videos / Audio files / Music files | 아니오 | 이미지만 첨부 가능 |
| Files and docs | 아니오 | 파일 첨부 기능 없음 |
| Calendar events / Contacts | 아니오 | 권한 미선언 |
| In-app search history | 아니오 | 검색어를 전송하지 않음 |
| Installed apps / Web browsing history | 아니오 | 수집 경로 없음 |
| Race and ethnicity / Political or religious beliefs / Sexual orientation | 아니오 | 별도 수집 항목으로 존재하지 않음. 이용자가 일기 본문에 자발적으로 쓸 수는 있으나, 이는 Other user-generated content 로 이미 신고됨 |

---

## 3. 판단이 갈렸던 항목과 근거

### 3-1. 왜 전 항목 Shared = 아니오인가

Play 는 **서비스 제공자(service provider)** 로의 이전을 "공유"에서 제외한다.

> "Transferring user data to a 'service provider' that processes it on behalf of the developer."
> "'Service provider' means an entity that processes user data on behalf of the developer and based on the developer's instructions."

- **Groq** — MindLog 의 분석 요청을 처리해 결과를 돌려주는 처리자. 자체 목적의 프로파일링 근거 없음 → 서비스 제공자.
- **Firebase / Google** — Firebase 문서가 "does not transfer this data to third-parties except: to third-party subprocessors ... / in accordance with your instructions" 라고 명시 → 서비스 제공자.

**단, 아래에 해당하게 되면 Shared 재검토 대상이다** (현재 모두 해당 없음):
- Firebase 를 Google Ads / AdMob 에 연결
- BigQuery export 활성화 (FCM `setDeliveryMetricsExportToBigQuery` 포함)
- 광고 ID 수집 활성화 — 현재 `AndroidManifest.xml` 에서 `AD_ID`, `ACCESS_ADSERVICES_AD_ID`, `ACCESS_ADSERVICES_ATTRIBUTION` 를 `tools:node="remove"` 로 제거 중

### 3-2. Approximate location — 놓치기 쉬운 항목

위치 권한을 쓰지 않으므로 "위치는 수집 안 함"으로 답하기 쉽지만, Play 분류표는 다음과 같이 못 박는다.

> "Approximate location that is **inferred, such as via IP address** or Access Point Name, must be disclosed here."

Firebase Performance 는 "Collects the IP address to map performance events to the countries they originate from", GA 는 "Derives coarse location data from the masked IP addresses" 라고 명시한다. 국가 수준은 3km² 를 훨씬 넘으므로 **Precise 가 아닌 Approximate** 로 신고한다.

### 3-3. Health info — 판단 항목

Play 정의는 "Information about a user's health, such as medical records or symptoms" 로, 정신·정서 상태 점수를 명시하지는 않는다. 그러나

- Google 은 정신·행동 건강 및 스트레스 관리 앱을 Health 앱 범주로 다룬다,
- `sentiment_score` / `energy_level` 은 이용자의 정서 상태를 수치화한 값이며 Analytics 로 전송된다,
- 과소 신고는 정책 위반이지만 과다 신고는 아니다

는 이유로 **신고하는 쪽**을 택했다. Health apps declaration 과도 일관된다.

### 3-4. "Processed ephemerally" 는 체크하지 않는다

Groq 로 보낸 일기 본문·사진을 개발자가 서버에 보관하지는 않는다. 그러나 ephemeral 은 *메모리에서만 쓰고 보관하지 않음* 을 뜻하는데, **Groq 측 보관 정책을 개발자가 통제하지 못한다.** 통제하지 못하는 것을 근거로 면제 항목을 체크하는 것은 위험하므로 체크하지 않는다. (과다 신고 방향이므로 안전)

### 3-5. Name 을 "선택"으로 두는 이유

`user_name_dialog.dart` 에서 이용자가 직접 입력하는 값이며, 비워 두면 `prompt_constants.dart:361` 의 개인화 섹션이 프롬프트에 붙지 않아 전송되지 않는다. 즉 이용자가 수집 여부를 통제할 수 있으므로 Optional.

> ⚠️ 다이얼로그 문구가 "이름을 입력하세요" / "AI 상담사가 이름을 불러드려요" 라서 실명 입력을 유도한다. 의도가 애칭이라면 문구를 애칭으로 바꾸는 편이 수집 범위를 줄인다. **다만 Play 의 Name 정의는 "first or last name, **or nickname**" 이므로 애칭으로 바꿔도 신고 의무는 그대로다.**

---

## 4. 코드 근거

| 신고 항목 | 코드 위치 |
|---|---|
| 일기 본문 → Groq | `lib/data/datasources/remote/groq_remote_datasource.dart:367-374` |
| 사진 1장 → Groq | `lib/data/datasources/remote/groq_remote_datasource.dart:240, 249-250` |
| 이름/애칭 → Groq | `lib/core/constants/prompt_constants.dart:361-367` · `lib/domain/usecases/analyze_diary_usecase.dart:73, 121` |
| 저장 = 분석 (전송 회피 경로 없음) | `lib/presentation/screens/diary_screen.dart:64-93` (`_onSubmit` → `_startAnalysis`) |
| 감정 점수·에너지 수준 → Analytics | `lib/core/services/analytics_service.dart:69-79` |
| 행동 제안 앞 50자 → Analytics | `lib/core/services/analytics_service.dart:87-95` |
| 화면 조회·통계·리마인더 → Analytics | `lib/core/services/analytics_service.dart:36, 118-147` |
| Crashlytics / Performance | `lib/core/services/firebase_service.dart:22, 26-27` |
| FCM 토큰 | `lib/core/services/fcm_service.dart:115` |
| 광고 ID 차단 | `android/app/src/main/AndroidManifest.xml` (`AD_ID` 외 2건 `tools:node="remove"`) |

---

## 5. 이 답표를 다시 봐야 하는 때

- 새 Firebase SDK 추가 (특히 Remote Config, In-App Messaging, AI Logic)
- Firebase ↔ Google Ads / AdMob / BigQuery 연동
- 로그인·계정 기능 도입
- Groq 외 다른 AI 제공자 추가, 또는 자체 서버 도입
- Analytics 이벤트에 새 파라미터 추가 — **특히 사용자 입력 원문이 들어가는 경우**
- 파일·음성·위치 등 새로운 권한 추가

## 6. 함께 처리해야 할 Play Console 항목

Data safety 만으로는 끝나지 않는다.

- [ ] **Health apps declaration** — 정신·행동 건강 범주
- [ ] **앱 액세스 권한** — 계정 없음 + 비밀일기 PIN 안내문 유지 (versionCode 64 거부 이력, 영문 500자 이내)
- [ ] **개인정보처리방침 URL** — 현재 Google Sites. GitHub Pages(`kaywalker91.github.io/MindLog/privacy-policy.html`)로 이전 예정
- [ ] **스토어 설명** — 비의료기기·비진단 면책 문구 추가 (현재 없음)
