# prompt-optimization

LLM 프롬프트 체계적 최적화 (`/prompt-opt [action]`)

## 목표
- 토큰 효율성 극대화
- 응답 품질 일관성 향상
- 프롬프트 구조화 패턴 적용
- Few-shot 예시 최적화

## 트리거 조건
- `/prompt-opt [action]` 명령어
- AI 분석 품질 저하 시
- 토큰 비용 절감 필요 시
- 새로운 AI 기능 추가 시

## 핵심 파일

| 파일 | 역할 |
|------|------|
| `lib/core/constants/prompt_constants.dart` | 프롬프트 정의 |
| `lib/core/constants/ai_character.dart` | AI 캐릭터 |
| `lib/data/dto/analysis_response_parser.dart` | JSON 파싱 |

## Actions

### analyze
프롬프트 구조 분석
1. 현재 프롬프트 읽기
2. 구조 분해 (System/Style/Output/Few-shot)
3. 토큰 사용량 분석
4. 개선점 식별

```bash
> /prompt-opt analyze

프롬프트 분석:
├── 총 토큰: ~850
├── System 지시: 45%
├── Output 형식: 30%
├── Few-shot 예시: 20%
├── 기타: 5%
└── 개선 가능: ~15% 절감
```

### compress
토큰 압축 최적화
1. 반복 표현 제거
2. 간결한 대안 제시
3. 지시어 최적화
4. Before/After 비교

```markdown
## 압축 전략

### 1. 반복 제거
❌ "다음 JSON 형식으로 응답해주세요. 반드시 JSON 형식이어야 합니다."
✅ "JSON 형식으로 응답:"

### 2. 지시어 간결화
❌ "분석 결과를 바탕으로 사용자에게 도움이 될 수 있는 구체적인 행동 제안을 3가지 작성해주세요."
✅ "행동 제안 3가지 (구체적):"

### 3. 예시 최소화
❌ 3개의 상세 예시
✅ 1개의 핵심 예시 + 형식 스키마
```

### structure
프롬프트 구조화 템플릿 적용
1. ROLE 정의 (명확한 역할)
2. TASK 명시 (구체적 작업)
3. FORMAT 지정 (출력 형식)
4. CONSTRAINTS 설정 (제약 조건)

```markdown
## RFTC 구조

### Role (역할)
"당신은 감정 분석 전문 상담사입니다."

### Task (작업)
"사용자의 일기를 분석하여 감정 상태를 파악합니다."

### Format (형식)
"응답: JSON
필드: keywords, sentiment_score, ..."

### Constraints (제약)
- 한국어로 응답
- 50-150자 empathy_message
- is_emergency 필드 필수
```

### few-shot
Few-shot 예시 최적화
1. 예시 품질 평가
2. 최소 필수 예시 선별
3. 다양성 확보 (긍정/부정/중립)
4. 토큰 효율적 예시 형식

```dart
// Few-shot 최적화 가이드

// ❌ 과도한 예시 (토큰 낭비)
final examples = '''
예시 1: [상세한 입력과 출력...]
예시 2: [상세한 입력과 출력...]
예시 3: [상세한 입력과 출력...]
''';

// ✅ 최적화된 예시
final examples = '''
예시:
입력: "오늘 정말 힘들었다. 회사에서..."
출력: {
  "sentiment_score": 3,
  "keywords": ["힘듦", "회사", ...],
  ...
}
''';
```

### validate
프롬프트 품질 검증
1. 응답 일관성 테스트
2. Edge case 처리 확인
3. 에러 케이스 테스트
4. 품질 메트릭 산출

```dart
// 검증 테스트 케이스
final testCases = {
  'positive': '오늘 정말 좋은 하루였어요!',
  'negative': '모든 게 잘 안 풀려서 지쳤어요.',
  'neutral': '평범한 하루였다.',
  'mixed': '기쁘면서도 불안한 마음이에요.',
  'short': '피곤',
  'long': '오늘은... (500자 이상)',
  'crisis': '모든 것을 끝내고 싶어...',
};
```

## 프롬프트 최적화 원칙

### 1. 명확성 (Clarity)
- 모호한 표현 제거
- 구체적인 지시어 사용
- 예상 출력 명시

### 2. 간결성 (Brevity)
- 불필요한 반복 제거
- 핵심 지시만 포함
- 예시는 최소화

### 3. 일관성 (Consistency)
- 용어 통일
- 형식 일관
- 톤 유지

### 4. 완전성 (Completeness)
- 필수 필드 명시
- Edge case 처리
- 에러 케이스 대비

## 토큰 절감 기법

| 기법 | 예상 절감 | 예시 |
|------|----------|------|
| 반복 제거 | 10-20% | "JSON 형식" 1회만 언급 |
| 지시어 압축 | 5-10% | "~해주세요" → "~:" |
| 예시 최소화 | 15-25% | 3개 → 1개 |
| 스키마 사용 | 10-15% | 예시 대신 JSON 스키마 |

## 출력 형식

```
프롬프트 최적화 결과
===================

📊 토큰 분석:
├── Before: 850 tokens
├── After: 680 tokens
├── 절감: 170 tokens (20%)
└── 월간 절감: ~$12 (10K 요청 기준)

🔍 적용된 최적화:
├── [COMPRESS] 반복 표현 3건 제거
├── [STRUCTURE] RFTC 구조 적용
├── [FEW-SHOT] 예시 3개 → 1개
└── [FORMAT] JSON 스키마 도입

📋 변경 사항:
1. System prompt 간결화
2. Few-shot 예시 최적화
3. Output format 명확화

다음 단계:
└── /prompt-opt validate
```

## 연관 스킬
- `/groq [action]` - Groq API 전문가
- `/emotion-analyze` - 감정 분석
- `/crisis-check` - 위기 감지

## 주의사항
- 토큰 절감이 품질 저하로 이어지면 안 됨
- is_emergency 감지 로직 절대 제거 금지
- 한국어 제약조건 필수 유지
- 최적화 후 반드시 품질 검증 수행

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P2 |
| Category | ai / optimization |
| Dependencies | groq-expert |
| Created | 2025-02-03 |
| Updated | 2025-02-03 |
