# TIL: Emotion-Based Notification Patterns

**날짜**: 2026-02-04
**주제**: 감정 기반 알림 메시지 개인화 구현
**관련 파일**:
- `lib/core/constants/notification_messages.dart`
- `lib/core/services/emotion_score_service.dart`
- `lib/core/services/fcm_service.dart`

---

## 1. Testable Random Pattern

### 문제
`Random()`을 직접 사용하면 테스트에서 결과 예측 불가

### 해결
```dart
class NotificationMessages {
  static Random _random = Random();

  @visibleForTesting
  static void setRandom(Random random) => _random = random;

  @visibleForTesting
  static void resetForTesting() => _random = Random();
}
```

### 테스트 활용
```dart
setUp(() {
  NotificationMessages.setRandom(Random(42)); // 시드로 결정적 결과
});

tearDown(() {
  NotificationMessages.resetForTesting();
});
```

### 적용 시점
- 랜덤 선택 로직이 있는 모든 서비스
- 게임 로직, 셔플, 샘플링 등

---

## 2. Weighted Selection via List Duplication

### 문제
가중치 기반 선택 시 확률 계산이 복잡함

### 해결 (리스트 복제 방식)
```dart
static List<String> _selectBodiesWithWeight(EmotionLevel level) {
  switch (level) {
    case EmotionLevel.low:
      // 공감 80%, 자기돌봄 20%
      return [
        ..._empathyBodies, ..._empathyBodies,
        ..._empathyBodies, ..._empathyBodies,  // 4배
        ..._selfCareBodies,                     // 1배
      ];
    case EmotionLevel.high:
      // 격려 60%, 긍정 40%
      return [
        ..._encouragementBodies, ..._encouragementBodies,
        ..._encouragementBodies,                // 3배
        ..._positiveBodies, ..._positiveBodies, // 2배
      ];
    // ...
  }
}
```

### 장점
- 확률 계산 불필요 (리스트 길이가 곧 가중치)
- 디버깅 용이 (어떤 항목이 몇 번 들어갔는지 명확)
- 테스트 용이 (리스트 길이만 검증하면 됨)

### 단점
- 메모리 사용량 증가 (큰 리스트에서는 비효율)
- 정밀한 확률 제어 어려움 (1% 단위 조절 불가)

### 적용 시점
- 항목 수가 적고 (< 100개) 대략적 가중치면 충분할 때
- A/B 테스트 없이 단순 가중치 선택이 필요할 때

---

## 3. Service Direct DB Pattern

### 문제
Repository 레이어를 거치면 의존성 복잡해짐 (FCM 백그라운드 핸들러에서 DI 불가)

### 해결
```dart
class EmotionScoreService {
  EmotionScoreService._();

  static SqliteLocalDataSource? _dataSource;

  @visibleForTesting
  static void setDataSource(SqliteLocalDataSource dataSource) {
    _dataSource = dataSource;
  }

  static Future<double?> getRecentAverageScore({int days = 7}) async {
    final dataSource = _dataSource ?? SqliteLocalDataSource();
    final allDiaries = await dataSource.getAllDiaries();
    // 필터링 및 계산...
  }
}
```

### 장점
- DI 컨테이너 없이 독립 실행 가능
- 백그라운드 핸들러, 알림 서비스 등에서 활용 용이
- 테스트에서 DataSource만 주입하면 됨

### 주의사항
- Clean Architecture 원칙 위반 (domain이 data 직접 참조)
- 특수한 경우에만 사용 (FCM, 백그라운드 작업 등)
- 가능하면 Repository 패턴 우선 사용

### 적용 시점
- Top-level 함수에서 DB 접근 필요 시
- Riverpod/DI가 초기화되지 않은 상태에서 실행되는 코드

---

## 4. Graceful Fallback Pattern

### 문제
감정 데이터가 없는 신규 사용자에게 개인화 불가

### 해결
```dart
static Future<void> _onForegroundMessage(RemoteMessage message) async {
  final avgScore = await EmotionScoreService.getRecentAverageScore();

  String title, body;

  if (avgScore != null) {
    // 감정 기반 메시지 (서버 메시지 무시)
    final emotionMessage = NotificationMessages.getMindcareMessageByEmotion(avgScore);
    final personalized = NotificationMessages.applyNameToMessage(emotionMessage, userName);
    title = personalized.title;
    body = personalized.body;
  } else {
    // 폴백: 서버 메시지 + 이름 개인화만
    title = NotificationMessages.applyNamePersonalization(
      message.notification?.title ?? 'MindLog',
      userName,
    );
    body = NotificationMessages.applyNamePersonalization(
      message.notification?.body ?? '',
      userName,
    );
  }
}
```

### 핵심 원칙
1. **데이터 유무 먼저 확인** - null 체크 필수
2. **최선 → 차선 → 기본값** 순서로 폴백
3. **사용자 경험 일관성** - 폴백도 자연스러워야 함

### 적용 시점
- 사용자 데이터 기반 개인화 기능
- 외부 API 의존 기능
- 점진적 기능 롤아웃

---

## EmotionLevel 분류 기준

| Level | 점수 범위 | 메시지 전략 | 가중치 |
|-------|----------|------------|--------|
| low | 1-3 | 위로/공감 우선 | 공감 80%, 자기돌봄 20% |
| medium | 4-6 | 균형 | 모든 카테고리 균등 |
| high | 7-10 | 격려/긍정 | 격려 60%, 긍정 40% |

---

## 관련 테스트 패턴

```dart
// 1. 시드 기반 결정적 테스트
NotificationMessages.setRandom(Random(42));

// 2. DataSource 주입 테스트
EmotionScoreService.setDataSource(mockDataSource);

// 3. 경계값 테스트 (감정 레벨)
expect(NotificationMessages.getEmotionLevel(3.0), EmotionLevel.low);
expect(NotificationMessages.getEmotionLevel(3.1), EmotionLevel.medium);

// 4. 폴백 시나리오 테스트
// - 일기 없음 → null
// - 분석 안 됨 → null
// - 7일 이전 → 제외
```

---

## 한계 및 향후 개선

### 현재 한계
- **백그라운드 알림**: FCM 제약으로 서버 메시지 그대로 표시
- **실시간 반영 불가**: 7일 평균 기반으로 즉각 반응 어려움

### 향후 개선 방향
1. Firebase Functions에서 개인별 발송 (Firestore 감정 요약 연동)
2. A/B 테스트로 가중치 최적화
3. 시간대 + 감정 조합 메시지

---

## 태그
`#flutter` `#fcm` `#notification` `#personalization` `#testing` `#weighted-selection` `#graceful-degradation`
