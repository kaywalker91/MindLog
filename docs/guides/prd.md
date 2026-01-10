# [PRD] AI 기반 감정 케어 다이어리 "MindLog" MVP (Revised)

## 1. 프로젝트 개요
* **목표:** 사용자의 텍스트 일기를 Groq API로 분석하여, 즉각적인 위로와 행동 지침을 제공하는 핵심 루프(Core Loop) 검증.
* **타겟:** 번아웃을 겪는 직장인 및 개발자 (초기 Niche 타겟).
* **플랫폼:** Flutter (Android / iOS).
* **일정:** 1주 (핵심 기능 구현 및 배포 기준).

## 2. 기술 스택 (Tech Stack)
안정적인 데이터 모델링과 유지보수성을 강화한 구성입니다.

* **Framework:** Flutter (Latest Stable)
* **Language:** Dart
* **AI Model:** Groq Llama 3.3 70B (JSON Mode 지원)
* **AI Client:** `http` (OpenAI 호환 API)
* **State Management:** `flutter_riverpod` (v2.x, Code Generation 권장)
* **Data Class & Serialization:** `freezed`, `json_serializable` (불변성 및 JSON 파싱 안정성 확보)
* **Local Database:** `isar` (NoSQL, 비동기 처리 우수, Full-text Search 지원)
* **Environment:** `--dart-define` (API Key 보안)
* **UI Utils:** `flutter_animate` (결과 카드 등장 효과), `intl` (날짜 포맷팅)

## 3. 주요 기능 명세 (Feature Specifications)

### F1. 일기 작성 및 로컬 저장 (Diary Entry)
* **기능:** 사용자가 오늘 하루의 감정을 텍스트로 입력.
* **UI 요소:**
    * 감성적인 배경 혹은 깔끔한 텍스트 필드.
    * "마음 털어놓기" 버튼 (Action Trigger).
* **로직:**
* 최소 10자 ~ 최대 5,000자 유효성 검사.
    * 작성 완료 시 즉시 Isar DB에 `status: pending` 상태로 우선 저장 (데이터 유실 방지).

### F2. AI 감정 분석 및 코칭 (AI Analysis) [Core]
* **기능:** Groq API를 호출하여 정형화된 JSON 데이터 수신.
* **설정(Config):**
    * `generationConfig` 내 `responseMimeType: 'application/json'` 설정 필수.
* **데이터 스키마 (JSON):**
    ```json
    {
      "keywords": ["불안", "압박감", "성취욕"],
      "sentiment_score": 4, // 1(매우 부정) ~ 10(매우 긍정)
      "empathy_message": "마감 기한 때문에 많이 쫓기셨군요. 그래도 오늘 하루 최선을 다한 모습이 멋집니다.",
      "action_item": "잠시 모니터 끄고 3분간 눈 감고 있기"
    }
    ```
* **예외 처리 (Safety):**
    * 자해/자살 암시 키워드 감지 시 API가 `FinishReason.safety`로 블락될 수 있음.
    * 이 경우 분석 결과를 보여주는 대신 **SOS 카드(상담 전화 안내 등)**를 렌더링하도록 분기 처리.

### F3. 결과 카드 및 피드백 (Result & Feedback)
* **기능:** 분석된 데이터를 카드 형태로 시각화.
* **UI 요소:**
    * **감정 온도계:** `sentiment_score`를 활용한 게이지 바 또는 아이콘 변화.
    * **위로의 문장:** 타이핑 효과 (`flutter_animate` 또는 `animated_text_kit`)로 감성 전달.
    * **추천 액션:** 체크박스 형태. 체크 시 "작은 성공 경험"을 축하하는 마이크로 인터랙션 제공.

## 4. 데이터 흐름 및 아키텍처 (Clean Architecture)
3년 차 경력을 고려하여 Layer를 명확히 분리합니다.

1.  **Presentation Layer (UI/Riverpod)**
    * `DiaryScreen`: 입력 UI.
    * `DiaryAnalysisController` (AsyncNotifierProvider): UI 상태 관리 (Loading, Success, Error).
2.  **Domain Layer (Pure Dart)**
    * `Entity`: `Diary`, `AnalysisResult` (순수 객체).
    * `Repository Interface`: `DiaryRepository`.
    * `UseCase` (Optional): `AnalyzeDiaryUseCase` (비즈니스 로직이 복잡해질 경우 추가).
3.  **Data Layer (Implementation)**
    * `DataSource`:
        * `GroqRemoteDataSource`: API 통신 (`http`).
        * `IsarLocalDataSource`: DB CRUD.
    * `Repository Implementation`: `DiaryRepositoryImpl` (Data Source를 조율하여 Domain Entity 반환).
    * `DTO`: `DiaryDto`, `AnalysisResponseDto` (JSON/DB 모델 변환).

## 5. 프롬프트 엔지니어링 (System Instruction)
모델에게 부여할 페르소나와 제약사항입니다.

```text
[Role]
당신은 내담자의 마음을 깊이 공감하고, 실질적인 행동 팁을 주는 '따뜻한 AI 심리 상담사'입니다.

[Constraint]
1. 반드시 JSON 포맷으로만 응답하십시오. (Markdown backticks 제외)
2. 'empathy_message'는 존댓말을 사용하며, 부드럽고 따뜻한 어조로 작성하세요.
3. 'action_item'은 당장 실천 가능한 아주 사소하고 구체적인 행동이어야 합니다. (예: "심호흡 3번", "창문 열기" 등)
4. 'keywords'는 명사형으로 3개를 추출하세요.

[Input Text]
"${user_diary_text}"
