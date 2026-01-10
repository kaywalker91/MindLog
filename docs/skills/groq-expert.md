# groq-expert

Groq API 통합 및 AI 프롬프트 최적화 (`/groq [action]`)

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `lib/data/datasources/remote/groq_remote_datasource.dart` | API 호출 + 재시도 |
| `lib/core/constants/prompt_constants.dart` | 프롬프트 템플릿 |
| `lib/data/dto/analysis_response_parser.dart` | JSON 파싱 |
| `lib/data/dto/analysis_response_dto.dart` | 응답 DTO |
| `lib/domain/entities/diary.dart` | AnalysisResult |
| `lib/core/constants/ai_character.dart` | AI 캐릭터 정의 |

## API 설정
```
URL: https://api.groq.com/openai/v1/chat/completions
Model: llama-3.3-70b-versatile
Temperature: 0.7, Max Tokens: 1024
재시도: 3회, 초기지연 1초, 백오프 2.0x
```

## AI 캐릭터
| 캐릭터 | 스타일 |
|--------|--------|
| warmCounselor | 따뜻한 상담사 (3문장 공감) |
| realisticCoach | 현실적 코치 (측정 가능한 행동) |
| cheerfulFriend | 유쾌한 친구 (밝은 톤) |

## Actions

### analyze-prompt
프롬프트 분석 및 개선점 식별
1. `prompt_constants.dart` 읽기
2. 구조 분석 (System/Style/Output/Few-shot)
3. 토큰 낭비/모호한 지시 식별
4. 개선안 제안

### optimize-tokens
토큰 사용량 최적화 (불필요한 반복 제거, 간결화)

### add-feature
새 AI 분석 기능 추가
1. 프롬프트 확장 (새 필드/제약조건)
2. DTO 업데이트 (`analysis_response_dto.dart`)
3. 엔티티 확장 (`AnalysisResult`)
4. 파서 업데이트

### test-prompt
프롬프트 품질 테스트 (긍정/부정/중립/응급 샘플)

## 응답 필드
| 필드 | 타입 |
|------|------|
| keywords | List<String> (5개) |
| sentiment_score | int (1-10) |
| empathy_message | String (50-150자) |
| action_items | List<String> (3개) |
| emotion_category | {primary, secondary} |
| emotion_trigger | {category, description} |
| energy_level | int (1-10) |
| is_emergency | bool |

## 주의사항
- 응급 상황 감지 로직 절대 제거 금지
- 한국어 제약조건 필수 유지
- API 키는 `--dart-define`으로 주입
