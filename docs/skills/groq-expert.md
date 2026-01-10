# groq-expert

Groq API 통합 및 AI 프롬프트 최적화 전문가 스킬

## 목표
- AI 분석 품질 향상
- 토큰 사용량 최적화
- 새로운 AI 기능 설계

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "프롬프트 최적화", "AI 분석 개선" 요청
- `/groq [action]` 명령어
- 분석 결과 품질 이슈 발생 시
- 새로운 AI 기능 추가 요청 시

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `lib/data/datasources/remote/groq_remote_datasource.dart` | API 호출 + 재시도 로직 |
| `lib/core/constants/prompt_constants.dart` | 시스템/유저 프롬프트 템플릿 |
| `lib/data/dto/analysis_response_parser.dart` | 응답 JSON 파싱 |
| `lib/data/dto/analysis_response_dto.dart` | 응답 DTO 정의 |
| `lib/domain/entities/diary.dart` | AnalysisResult 엔티티 |
| `lib/core/constants/ai_character.dart` | AI 캐릭터 정의 |

## 현재 구성

### API 설정
```
Base URL: https://api.groq.com/openai/v1/chat/completions
Model: llama-3.3-70b-versatile
Temperature: 0.7
Max Tokens: 1024
Response Format: JSON Object
```

### 재시도 전략
```dart
최대 재시도: 3회
초기 지연: 1초
백오프 배수: 2.0
재시도 대상: SocketException, TimeoutException, 429 (Rate Limit)
```

### AI 캐릭터 (3가지)
| 캐릭터 | 스타일 | 특징 |
|--------|--------|------|
| warmCounselor | 따뜻한 상담사 | 3문장 공감, 안정적 행동 제안 |
| realisticCoach | 현실적 코치 | 2문장, 측정 가능한 행동 |
| cheerfulFriend | 유쾌한 친구 | 밝은 톤, 즐거운 활동 |

## 프로세스

### Action 1: analyze-prompt
현재 프롬프트 분석 및 개선점 식별

```
Step 1: prompt_constants.dart 읽기
Step 2: 프롬프트 구조 분석
  - System Instruction 검토
  - Style Guide 검토
  - Output Format 검토
  - Few-shot Examples 검토
Step 3: 개선점 식별
  - 토큰 낭비 영역
  - 모호한 지시사항
  - 누락된 제약조건
Step 4: 개선안 제안
```

### Action 2: optimize-tokens
토큰 사용량 최적화

```
Step 1: 현재 프롬프트 토큰 추정
  - System: ~2000 tokens
  - User: ~300 tokens (일기 내용 포함)
Step 2: 불필요한 반복 제거
Step 3: 간결한 표현으로 교체
Step 4: Few-shot 예시 최소화 (필요시)
Step 5: 최적화 결과 비교
```

### Action 3: add-feature
새로운 AI 분석 기능 추가

```
Step 1: 요구사항 분석
Step 2: 프롬프트 확장
  - 새 필드 정의
  - 제약조건 추가
  - Few-shot 예시 추가
Step 3: DTO 업데이트
  - analysis_response_dto.dart 수정
Step 4: 엔티티 확장
  - AnalysisResult 필드 추가
Step 5: 파서 업데이트
  - 새 필드 파싱 로직 추가
Step 6: 테스트 작성
```

### Action 4: test-prompt
프롬프트 변경 후 품질 테스트

```
Step 1: 테스트 일기 샘플 준비
  - 긍정적 일기
  - 부정적 일기
  - 중립적 일기
  - 응급 상황 일기
Step 2: 각 캐릭터별 응답 생성
Step 3: 응답 품질 평가
  - JSON 유효성
  - 한국어 준수
  - 캐릭터 스타일 일관성
  - 행동 제안 다양성
Step 4: 결과 리포트
```

## 프롬프트 최적화 원칙

### 1. 역할 정의 (System Message)
```
[Role]
명확한 페르소나 설정
- 역할 명시
- 대상 사용자 정의
- 핵심 목표 설정
```

### 2. 스타일 가이드
```
[Style Guide]
캐릭터별 차별화된 지시
- empathy_message 형식
- 말투 규칙
- action_item 스타일
```

### 3. 제약조건
```
[Constraint]
필수 준수 사항
- 언어 제약 (한국어만)
- 필드별 형식
- 길이 제한
```

### 4. 출력 형식
```
[Output Format]
JSON Schema 명시
- 필드 타입
- 필수/선택 여부
- 예시 값
```

### 5. Few-shot 예시
```
[Few-shot Examples]
다양한 시나리오 예시
- 입력/출력 쌍
- 엣지 케이스 포함
```

## 응답 필드 정의

| 필드 | 타입 | 설명 |
|------|------|------|
| `keywords` | List<String> | 감정 키워드 5개 |
| `sentiment_score` | int (1-10) | 감정 점수 |
| `empathy_message` | String (50-150자) | 공감 메시지 |
| `action_items` | List<String> (3개) | 단계별 행동 제안 |
| `emotion_category.primary` | String | 1차 감정 |
| `emotion_category.secondary` | String | 2차 감정 |
| `emotion_trigger.category` | String | 감정 원인 카테고리 |
| `emotion_trigger.description` | String | 원인 설명 |
| `energy_level` | int (1-10) | 에너지 수준 |
| `is_emergency` | bool | 응급 상황 플래그 |

## 출력 형식

```
🤖 Groq Expert 분석 결과

Action: [실행한 액션]

분석 결과:
├── 현재 상태: [요약]
├── 개선점: [목록]
└── 권장 조치: [상세]

변경 파일:
├── lib/core/constants/prompt_constants.dart
├── lib/data/dto/analysis_response_dto.dart
└── lib/domain/entities/diary.dart

테스트:
└── /test-unit-gen [파일경로]
```

## 사용 예시

### 프롬프트 분석
```
> "/groq analyze-prompt"

AI 응답:
1. prompt_constants.dart 분석
2. 현재 토큰 사용량: ~2300 tokens
3. 개선점:
   - Few-shot 예시 중복 → 15% 절감 가능
   - 불필요한 반복 설명 → 10% 절감 가능
4. 권장: token 최적화 실행
```

### 새 기능 추가
```
> "/groq add-feature cognitive_distortion"

AI 응답:
1. 요구사항: 인지 왜곡 패턴 감지
2. 프롬프트 확장:
   - cognitive_distortion 필드 추가
   - 10가지 인지 왜곡 유형 정의
3. DTO 업데이트: analysis_response_dto.dart
4. 엔티티 확장: diary.dart
5. 테스트 생성: /test-unit-gen
```

## 연관 스킬
- `/test-unit-gen` - 파서/DTO 테스트 생성
- `/resilience` - API 에러 처리 강화
- `/analytics-event` - AI 분석 이벤트 추가

## 주의사항
- 프롬프트 변경 시 모든 캐릭터 테스트 필수
- 토큰 최적화는 품질 저하 없이 진행
- 응급 상황 감지 로직은 절대 제거 금지
- 한국어 제약조건은 필수 유지
- 빌드 타임 API 키 주입 방식 유지 (`--dart-define`)
