# Groq 모델 마이그레이션 계획 (2026-07)

> **상태**: 계획 수립 완료 — 구현 착수 전
> **작성일**: 2026-07-04
> **트리거**: Groq 공식 폐기 공지 메일 (2026-07-04 수신) + Groq deprecations 문서 실측 조회

---

## 1. 배경 및 마감 기한

Groq이 MindLog가 사용 중인 모델 2종의 폐기(deprecation)를 공지했다.
폐기일 이후 해당 모델로의 요청은 **전부 거부**되며, 이는 무료/개발자 티어 모두에 적용된다.

| 용도 | 현재 모델 | 서비스 종료일 | 남은 기간 |
|------|-----------|---------------|-----------|
| 이미지 분석 (Vision) | `meta-llama/llama-4-scout-17b-16e-instruct` | **2026-07-17** ⚠️ | ~2주 |
| 텍스트 감정 분석 (핵심) | `llama-3.3-70b-versatile` | **2026-08-16** | ~6주 |

**주의**: 공지 메일에는 텍스트 모델(8/16)만 언급되었으나, Groq deprecations 문서 확인 결과
비전 모델이 **한 달 먼저(7/17)** 종료된다. 사실상의 마감은 7월 17일.

**구조적 리스크**: 모델 ID가 클라이언트에 하드코딩되어 있어, 교체 버전 배포 후에도
**미업데이트 사용자는 종료일 이후 AI 분석이 전부 실패**한다.
→ 조기 릴리스로 업데이트 유도 기간 확보 필수 + Phase 2에서 원격 설정 전환.

---

## 2. 대체 모델 선정

| 용도 | 신규 모델 | 등급 | 가격 ($/1M in/out) | 선정 근거 |
|------|-----------|------|--------------------|-----------|
| 텍스트 | `openai/gpt-oss-120b` | **Production** | 0.15 / 0.60 | Groq 공식 권장 대체재 중 유일한 Production 등급. 기존(0.59/0.79) 대비 입력 -75%, 출력 -24%. `json_object` + `json_schema strict` 지원. 한국어 MMLU-KO 82.9% |
| 비전 | `qwen/qwen3.6-27b` | Preview | 0.60 / 3.00 | 폐기 대상 권장 대체 중 **비전 지원 유일** 후보 (gpt-oss는 비전 미지원). Preview 등급이나 대안 부재. 이미지 3장/20MB 제한 |

**탈락 후보**: Kimi K2 (Groq에서 이미 종료), `qwen3-32b` (2026-07-17 동반 폐기),
`groq/compound` (에이전틱 시스템형, 단순 chat completion 대체 부적합).

**비용 영향**: 텍스트(사용량 대부분) 대폭 절감 + 비전(저빈도) 소폭 상승 → 총비용 하락 예상.
현재 무료 티어이므로 실질 영향은 rate limit뿐 (신규 모델 무료 한도: 30 RPM / 1K RPD / 8K TPM / 200K TPD).

---

## 3. 코드 변경 상세 (Phase 1)

### 3-1. `lib/core/constants/app_constants.dart` (17행, 20~21행)

```dart
// Before
static const String _groqModel = 'llama-3.3-70b-versatile';
static const String _groqVisionModel =
    'meta-llama/llama-4-scout-17b-16e-instruct';

// After
static const String _groqModel = 'openai/gpt-oss-120b';
static const String _groqVisionModel = 'qwen/qwen3.6-27b';
```

### 3-2. `lib/data/datasources/remote/groq_remote_datasource.dart`

**핵심**: `gpt-oss-120b`는 reasoning 모델 — 추론 토큰이 completion 토큰 예산에서 차감된다.
현행 `max_tokens: 1024` 유지 시 추론이 예산을 소진해 **JSON 응답이 잘릴 위험**.

**텍스트 분석 요청** (354행 부근, `analyzeDiary`):

```dart
body: jsonEncode({
  'model': AppConstants.groqModel,
  'messages': [...],                          // 변경 없음
  'temperature': 0.7,                          // 유지
  'max_completion_tokens': 2048,               // max_tokens: 1024 → 교체 + 상향
  'reasoning_effort': 'low',                   // 추가 — 감정분석에 깊은 추론 불필요
  'include_reasoning': false,                  // 추가 — 응답 reasoning 필드 억제 (방어)
  'response_format': {'type': 'json_object'},  // 유지 (gpt-oss 지원 확인됨)
}),
```

**비전 분석 요청** (252행 부근, Vision API):

```dart
'model': AppConstants.groqVisionModel,
'temperature': 0.7,                            // 유지
'max_completion_tokens': 2048,                 // max_tokens: 1500 → 교체 + 상향
'response_format': {'type': 'json_object'},    // 유지
```

> ⚠️ **미확정 사항**: `qwen3.6-27b`의 `reasoning_effort` / `include_reasoning` 파라미터
> 지원 여부는 구현 시점에 Groq 모델 문서로 실측 확인할 것.
> 미지원 파라미터 전송 시 400 에러 가능 → 확인 전에는 비전 요청에 넣지 않는다.

### 3-3. 변경 불필요 (확인 완료)

| 항목 | 이유 |
|------|------|
| `groq_cache_key.dart` | 캐시 키에 모델 ID 포함 → 교체 시 구모델 캐시 자동 무효화 |
| `PromptConstants` (시스템 프롬프트) | 모델 독립적. 한국어 제약 + `is_emergency` 스키마 유지 |
| 응답 파서 (`AnalysisResponseParser`) | `message['content']`만 읽음. reasoning 필드는 `include_reasoning: false`로 차단 |
| 429/재시도/서킷브레이커 | HTTP 레이어 — 모델 무관 |
| 엔드포인트/인증 | 동일 OpenAI 호환 API (`/openai/v1/chat/completions`) |
| `functions/` (서버) | Groq 미사용 |

### 3-4. 테스트 수정

- `test/core/services/image_service_test.dart:30-33` — 비전 모델 ID 검증 문자열
  `'meta-llama/llama-4-scout-17b-16e-instruct'` → `'qwen/qwen3.6-27b'`

### 3-5. 문서 갱신

| 파일 | 변경 내용 |
|------|-----------|
| `CLAUDE.md` | Tech Stack 표 `AI | Groq API | llama-3.3-70b-versatile` → `openai/gpt-oss-120b` |
| `.claude/rules/architecture-layers.md` | "Groq API Settings" 섹션 모델/max_tokens 갱신 |
| `.claude/skills/groq-expert.md` | llama-3.3-70b 기준 기술 → 신규 모델 기준으로 갱신 |

---

## 4. 검증 절차 (구현보다 중요)

1. **품질 게이트**: `./scripts/run.sh quality` (analyze + format + test)
2. **실 API 검증 (텍스트)**: 로컬 빌드로 한국어 일기 샘플을 3개 AI 캐릭터
   (warmCounselor / realisticCoach / cheerfulFriend)별 분석:
   - [ ] JSON 스키마 정합 (`is_emergency` 필드 존재 포함)
   - [ ] 한국어 응답 자연스러움 (llama 대비 톤 회귀 여부)
   - [ ] 코드펜스(```json) 등 이물질 미포함
   - [ ] 응답이 `max_completion_tokens` 내에서 완결 (truncation 없음)
3. **위기 감지 경로 (최우선)**: 위기 표현 테스트 문장으로
   `is_emergency: true` → `SafetyBlockedFailure` 흐름 정상 작동 확인.
   **이 경로 회귀 시 릴리스 중단.**
4. **실 API 검증 (비전)**: 이미지 첨부 일기 1회 이상 분석 성공 확인
5. **rate limit 헤더 확인**: `x-ratelimit-remaining-*` 값이 정상 수신되는지 (무료 티어 모니터링 수단)

---

## 5. 릴리스 계획

- 버전: **v1.4.57** (`/release-unified`)
- 목표일: **2026-07-07~09** (비전 종료 7/17 대비 최소 1주 업데이트 유도 기간 확보)
- 커밋 컨벤션: `fix(ai): Groq 폐기 모델 교체 (llama-3.3 → gpt-oss-120b, scout → qwen3.6-27b)`
- update.json 릴리스 노트: "AI 분석 엔진 업그레이드 — 반드시 업데이트해 주세요" 톤으로
  (7/17, 8/16 이후 구버전은 분석 불가함을 사용자 친화적으로 안내)

---

## 6. Phase 2 — 재발 방지 (별도 작업, 릴리스 후)

1. **모델 ID 원격 설정 전환**: 기존 `update.json` 인프라(또는 Firebase Remote Config)로
   모델 ID를 서버에서 내려받고, `AppConstants` 값은 폴백으로 유지.
   → 향후 모델 폐기 시 앱 릴리스 없이 대응 가능, 미업데이트 사용자 구제.
2. **폐기 에러 방어 매핑**: Groq `model_decommissioned` 계열 에러 감지 →
   "앱 업데이트가 필요합니다" 안내로 매핑 (`FailureMapper` 확장).
3. **분기별 deprecations 문서 점검** 루틴 (Groq은 폐기 공지~종료까지 통상 2개월).

---

## 7. 리스크 및 대응

| 리스크 | 수준 | 대응 |
|--------|------|------|
| 감정 분석 품질/톤 회귀 | 중 | 검증 2단계에서 캐릭터별 실응답 비교. 심각 시 `qwen3.6-27b`를 텍스트 A/B 후보로 |
| 위기 감지 회귀 | **높음(치명)** | 검증 3단계 필수 통과. 실패 시 릴리스 중단 + 프롬프트 보강 |
| reasoning 토큰으로 JSON 잘림 | 중 | `reasoning_effort: low` + 2048 토큰. 검증에서 truncation 확인 |
| 비전 모델 Preview 등급 불안정 | 중 | 비전 실패 시 기존 에러 처리(재시도/폴백) 경로 동작 확인. 이미지 분석은 부가 기능 |
| 미업데이트 사용자 분석 실패 | 높음 | 조기 릴리스(5절) + Phase 2 원격 설정으로 근본 해결 |
| qwen 미지원 파라미터 400 | 낮음 | 3-2 미확정 사항 — 구현 시 문서 실측 후 적용 |

---

## 출처

- [Groq Deprecations](https://console.groq.com/docs/deprecations) — 폐기 일정
- [Groq Supported Models](https://console.groq.com/docs/models) — 신규 모델 스펙
- [GPT OSS 120B](https://console.groq.com/docs/model/openai/gpt-oss-120b) / [Qwen 3.6 27B](https://console.groq.com/docs/model/qwen/qwen3.6-27b)
- [Groq Structured Outputs](https://console.groq.com/docs/structured-outputs) — json_object/json_schema 지원
- [Groq Rate Limits](https://console.groq.com/docs/rate-limits) — 무료 티어 한도
