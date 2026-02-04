# crisis-detection

위기 감지 및 안전 개입 프로토콜 (`/crisis-check [action]`)

## 목표
- 자해/자살 관련 콘텐츠 조기 감지
- SafetyBlockedFailure와 연동된 안전 개입
- 위기 상황 에스컬레이션 프로토콜 구현
- 사용자 안전을 최우선으로 보장

## 트리거 조건
- `/crisis-check [action]` 명령어
- 새로운 위기 감지 패턴 추가 필요 시
- SafetyBlockedFailure 핸들링 검토 시
- AI 프롬프트의 위기 감지 로직 검증 시

## 핵심 파일

| 파일 | 역할 |
|------|------|
| `lib/core/errors/failures.dart` | SafetyBlockedFailure 정의 |
| `lib/core/constants/prompt_constants.dart` | 위기 감지 프롬프트 |
| `lib/data/dto/analysis_response_dto.dart` | is_emergency 필드 |
| `lib/presentation/providers/diary_analysis_controller.dart` | 위기 상황 처리 |
| `lib/presentation/screens/diary/components/` | 위기 UI 컴포넌트 |

## Actions

### audit
현재 위기 감지 시스템 전체 감사
1. SafetyBlockedFailure 사용처 전수 조사
2. is_emergency 필드 처리 흐름 추적
3. 위기 감지 프롬프트 패턴 검토
4. 누락된 핸들링 케이스 식별

```bash
> /crisis-check audit

감사 결과:
├── SafetyBlockedFailure 사용처: 5개 파일
├── is_emergency 처리: 정상
├── 프롬프트 위기 패턴: 8개
└── 누락 케이스: 없음
```

### validate-prompt
AI 프롬프트의 위기 감지 로직 검증
1. `prompt_constants.dart`에서 위기 관련 지시사항 추출
2. 위기 키워드/패턴 완전성 검사
3. False positive/negative 시나리오 분석
4. 개선 권고사항 제시

### add-pattern [pattern]
새로운 위기 감지 패턴 추가
1. 패턴 유효성 검증 (너무 광범위/협소 체크)
2. 기존 패턴과 중복 검사
3. 프롬프트에 패턴 추가
4. 테스트 케이스 생성

### test-scenarios
위기 감지 시나리오 테스트
1. 명시적 위기 표현 테스트
2. 암시적/완곡한 표현 테스트
3. False positive 케이스 테스트
4. 경계 케이스 테스트

```dart
// 테스트 시나리오 예시
final testCases = [
  // True positive (감지해야 함)
  '살고 싶지 않아',
  '모든 것을 끝내고 싶어',
  '아무 의미가 없어',

  // True negative (감지하면 안 됨)
  '오늘 정말 지쳤어',
  '스트레스 받는다',
  '기분이 우울해',
];
```

### enhance-response
위기 감지 시 응답 메시지 개선
1. 현재 SafetyBlockedFailure 메시지 검토
2. 공감적이고 지지적인 메시지 제안
3. 전문 도움 연결 정보 포함
4. 다국어 지원 검토

## 위기 감지 프로토콜

### Level 1: 주의 (Caution)
- 부정적 감정 패턴 반복 감지
- 에너지 레벨 지속적 저하 (3일 이상)
- 조치: 부드러운 체크인 메시지

### Level 2: 경고 (Warning)
- 암시적 위기 표현 감지
- is_emergency: false, but elevated risk
- 조치: 전문 상담 권유 메시지 표시

### Level 3: 위기 (Crisis)
- 명시적 자해/자살 표현 감지
- is_emergency: true
- 조치: SafetyBlockedFailure + 긴급 연락처 안내

```dart
// 위기 레벨별 처리 예시
switch (crisisLevel) {
  case CrisisLevel.caution:
    // 일반 분석 + 체크인 메시지 추가
    break;
  case CrisisLevel.warning:
    // 분석 제공 + 전문 상담 권유
    break;
  case CrisisLevel.crisis:
    // 분석 차단 + 긴급 지원 정보 표시
    throw SafetyBlockedException();
}
```

## 긴급 연락처 (한국)

| 서비스 | 연락처 | 운영시간 |
|--------|--------|----------|
| 자살예방상담전화 | 1393 | 24시간 |
| 정신건강위기상담전화 | 1577-0199 | 24시간 |
| 생명의전화 | 1588-9191 | 24시간 |
| 청소년전화 | 1388 | 24시간 |

## 안전 가이드라인

### 절대 금지 사항
- SafetyBlockedFailure 로직 제거/비활성화
- is_emergency 필드 무시 또는 숨김
- 위기 감지 우회 경로 생성
- 위기 메시지의 심각성 축소

### 필수 준수 사항
- 모든 위기 감지는 보수적으로 (over-detection 허용)
- 전문 도움 연결 정보 항상 포함
- 사용자의 자율성 존중 (강제 차단 최소화)
- 정기적 프로토콜 검토 및 업데이트

## 출력 형식

```
위기 감지 감사 결과
====================

📊 현황:
├── SafetyBlockedFailure 통합: ✅ 완료
├── is_emergency 처리: ✅ 정상
├── 위기 프롬프트 패턴: 8개
└── 긴급 연락처 표시: ✅ 활성

🔍 발견 사항:
├── [INFO] 위기 감지 정확도: 95%+
├── [WARN] 암시적 표현 감지 보강 필요
└── [OK] 에스컬레이션 프로토콜 정상

📋 권장 조치:
1. 암시적 위기 표현 패턴 추가 검토
2. 다국어 긴급 연락처 업데이트

다음 단계:
└── /crisis-check validate-prompt
```

## 연관 스킬
- `/groq analyze-prompt` - AI 프롬프트 분석
- `/emotion-analyze` - 감정 분석 심화
- `/resilience error-handling` - 에러 처리 패턴

## 주의사항
- 위기 감지 관련 코드 변경 시 반드시 리뷰어 2인 이상 검토
- 테스트 케이스 추가 없이 패턴 변경 금지
- 프로덕션 배포 전 위기 시나리오 전수 테스트 필수
- SafetyBlockedFailure는 앱의 안전 장치로 절대 제거 금지

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P0 (Critical Safety) |
| Category | core / safety |
| Dependencies | groq-expert, resilience-expert |
| Created | 2025-02-03 |
| Updated | 2025-02-03 |
