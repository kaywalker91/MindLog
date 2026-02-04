# emotion-analyze

감정 분석 심화 및 Mental Health 패턴 인식 (`/emotion-analyze [action]`)

## 목표
- 감정 일기의 심층 분석 품질 향상
- 감정 패턴 및 트렌드 인식
- 개인화된 인사이트 제공
- Mental Health 지표 모니터링

## 트리거 조건
- `/emotion-analyze [action]` 명령어
- 감정 분석 로직 개선 필요 시
- 새로운 감정 카테고리 추가 시
- 분석 정확도 개선 작업 시

## 핵심 파일

| 파일 | 역할 |
|------|------|
| `lib/core/constants/prompt_constants.dart` | 감정 분석 프롬프트 |
| `lib/data/dto/analysis_response_dto.dart` | 분석 결과 DTO |
| `lib/domain/entities/diary.dart` | AnalysisResult 엔티티 |
| `lib/core/constants/ai_character.dart` | AI 캐릭터별 분석 스타일 |
| `lib/presentation/screens/statistics/` | 감정 통계 화면 |

## Actions

### audit-accuracy
감정 분석 정확도 감사
1. 현재 분석 필드 완전성 검사
2. emotion_category 매핑 검토
3. sentiment_score 분포 분석
4. 개선 영역 식별

```bash
> /emotion-analyze audit-accuracy

감사 결과:
├── 분석 필드: 8개 (완전)
├── emotion_category: 6개 primary + 12개 secondary
├── sentiment_score: 1-10 (정상 분포)
└── 개선 영역: emotion_trigger 세분화
```

### enhance-categories
감정 카테고리 체계 강화
1. 기존 카테고리 분석
2. 누락된 감정 카테고리 식별
3. 세분화 제안 (primary → secondary)
4. 프롬프트 업데이트

```dart
// 현재 감정 카테고리
final emotionCategories = {
  'joy': ['happiness', 'excitement', 'gratitude', 'hope'],
  'sadness': ['grief', 'disappointment', 'loneliness', 'regret'],
  'anger': ['frustration', 'irritation', 'resentment', 'rage'],
  'fear': ['anxiety', 'worry', 'panic', 'insecurity'],
  'surprise': ['amazement', 'confusion', 'shock'],
  'neutral': ['calm', 'indifferent', 'contemplative'],
};
```

### optimize-prompt
감정 분석 프롬프트 최적화
1. 현재 프롬프트 토큰 분석
2. 중복/불필요 지시 제거
3. Few-shot 예시 최적화
4. 한국어 감정 표현 강화

### add-insight [type]
새로운 인사이트 타입 추가
- `pattern`: 감정 패턴 분석 (주간/월간)
- `trigger`: 감정 트리거 심화 분석
- `coping`: 대처 전략 제안
- `growth`: 성장 포인트 식별

```dart
// 인사이트 타입별 프롬프트 확장
enum InsightType {
  pattern,   // "지난 7일간 [감정] 패턴이 관찰됩니다"
  trigger,   // "주요 트리거: [상황/인물/환경]"
  coping,    // "효과적인 대처: [구체적 행동]"
  growth,    // "성장 포인트: [관찰된 개선]"
}
```

### test-sentiment
감정 분석 품질 테스트
1. 긍정/부정/중립 샘플 테스트
2. 복합 감정 테스트
3. 한국어 특수 표현 테스트
4. 정확도 메트릭 산출

```dart
// 테스트 샘플
final testSamples = {
  'positive': [
    '오늘 정말 행복했어요! 오랜만에 친구를 만나서...',
    '드디어 프로젝트가 끝났다. 뿌듯하다.',
  ],
  'negative': [
    '왜 항상 나만 이런 일이 생기는 걸까...',
    '오늘도 피곤한 하루였다.',
  ],
  'mixed': [
    '기쁘면서도 불안해. 새로운 시작이니까.',
    '슬프지만 이별이 필요했어.',
  ],
};
```

## 감정 분석 필드 가이드

### 필수 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| keywords | List<String> | 핵심 키워드 5개 |
| sentiment_score | int (1-10) | 감정 점수 |
| empathy_message | String | 공감 메시지 (50-150자) |
| action_items | List<String> | 행동 제안 3개 |

### 심화 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| emotion_category | Object | {primary, secondary} |
| emotion_trigger | Object | {category, description} |
| energy_level | int (1-10) | 에너지 수준 |
| is_emergency | bool | 위기 감지 플래그 |

## 감정 트리거 카테고리

```dart
enum EmotionTriggerCategory {
  work,          // 업무/학업
  relationship,  // 대인관계
  health,        // 건강/신체
  finance,       // 재정
  family,        // 가족
  selfEsteem,    // 자존감
  environment,   // 환경/상황
  achievement,   // 성취/목표
  loss,          // 상실/이별
  uncertainty,   // 불확실성
}
```

## 패턴 분석 가이드

### 시간 기반 패턴
- **일간**: 시간대별 감정 변화
- **주간**: 요일별 패턴 (주중 vs 주말)
- **월간**: 장기 트렌드

### 상관관계 분석
- 날씨 ↔ 감정
- 수면 ↔ 에너지 레벨
- 활동 ↔ 만족도

### 개선 지표
- 평균 sentiment_score 변화
- 부정 감정 빈도 감소
- 긍정 트리거 증가

## 출력 형식

```
감정 분석 감사 결과
====================

📊 현황:
├── 분석 필드: 8개 ✅
├── 카테고리 커버리지: 92%
├── 평균 정확도: 87%
└── 한국어 특화: ✅

🔍 분석 품질:
├── 긍정 감지: 91% 정확
├── 부정 감지: 88% 정확
├── 복합 감정: 79% 정확
└── 트리거 식별: 82% 정확

📋 개선 제안:
1. 복합 감정 분석 강화 필요
2. 한국어 완곡 표현 패턴 추가
3. 계절성 트리거 반영

다음 단계:
└── /emotion-analyze enhance-categories
```

## AI 캐릭터별 분석 스타일

| 캐릭터 | 분석 초점 | 메시지 톤 |
|--------|----------|----------|
| warmCounselor | 감정 공감 | 따뜻하고 지지적 |
| realisticCoach | 행동 제안 | 구체적이고 실용적 |
| cheerfulFriend | 긍정 발견 | 밝고 격려적 |

## 연관 스킬
- `/groq [action]` - AI 프롬프트 최적화
- `/crisis-check` - 위기 감지
- `/db schema-report` - 분석 데이터 스키마

## 주의사항
- 감정 분석은 참고용이며 전문 진단 대체 불가
- is_emergency 로직은 crisis-detection과 연동 필수
- 한국어 감정 표현의 문화적 맥락 고려
- 개인정보 보호: 분석 결과는 기기 내 저장

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P1 |
| Category | core / ai |
| Dependencies | groq-expert, crisis-detection |
| Created | 2025-02-03 |
| Updated | 2025-02-03 |
