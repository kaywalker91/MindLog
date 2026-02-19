# analytics-event-add

Firebase Analytics 이벤트를 프로젝트 패턴에 맞게 추가하는 스킬

## 목표
- 일관된 Analytics 이벤트 패턴 유지
- 이벤트 추적 코드 표준화
- 분석 데이터 품질 향상

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "분석 이벤트 추가", "analytics event" 요청
- `/analytics-event [event_name]` 명령어
- 새 기능에 사용자 행동 추적 필요 시

## 참조 템플릿
참조: `lib/core/services/analytics_service.dart`

```dart
/// {이벤트 설명} 이벤트
static Future<void> log{EventName}({
  required {ParamType} {paramName},
  // ... 필수 파라미터
  {OptionalType}? {optionalParam},
  // ... 선택 파라미터
}) async {
  await _instance()?.logEvent(
    name: '{event_name}',
    parameters: {
      '{param_key}': {paramValue},
      // ... 파라미터
    },
  );
  _debugLog('{event_name}', {
    '{param_key}': {paramValue},
  });
}
```

## 기존 이벤트 목록

| 이벤트명 | 메서드 | 파라미터 |
|---------|--------|----------|
| screen_view | logScreenView | screenName |
| app_open | logAppOpen | - |
| diary_created | logDiaryCreated | contentLength, aiCharacterId |
| diary_analyzed | logDiaryAnalyzed | aiCharacterId, sentimentScore, energyLevel |
| action_item_completed | logActionItemCompleted | actionItemText |
| ai_character_changed | logAiCharacterChanged | fromCharacterId, toCharacterId |
| statistics_viewed | logStatisticsViewed | period |

## 프로세스

### Step 1: 이벤트 정보 정의

| 항목 | 설명 | 예시 |
|------|------|------|
| 이벤트명 | snake_case | `diary_shared` |
| 메서드명 | camelCase | `logDiaryShared` |
| 파라미터 | 추적할 데이터 | `shareMethod`, `contentLength` |

### Step 2: AnalyticsService에 메서드 추가
파일: `lib/core/services/analytics_service.dart`

```dart
/// 일기 공유 이벤트
static Future<void> logDiaryShared({
  required String shareMethod,
  required int contentLength,
}) async {
  await _instance()?.logEvent(
    name: 'diary_shared',
    parameters: {
      'share_method': shareMethod,
      'content_length': contentLength,
    },
  );
  _debugLog('diary_shared', {
    'share_method': shareMethod,
    'content_length': contentLength,
  });
}
```

### Step 3: UI에서 이벤트 호출
```dart
// 공유 버튼 클릭 시
onPressed: () async {
  await Share.share(diary.content);
  AnalyticsService.logDiaryShared(
    shareMethod: 'native_share',
    contentLength: diary.content.length,
  );
}
```

## 이벤트 네이밍 규칙

### 이벤트명 (Firebase)
- snake_case 사용
- 동사_명사 형식
- 40자 이내

```
✅ diary_created, action_completed, screen_viewed
❌ DiaryCreated, diary-created, diary_was_created_by_user
```

### 파라미터명
- snake_case 사용
- 40자 이내
- 값은 100자 이내

```
✅ content_length, ai_character_id, share_method
❌ contentLength, aiCharacterId (Firebase 권장 아님)
```

## 출력 형식

```
📊 Analytics 이벤트 추가 완료

이벤트: diary_shared
메서드: logDiaryShared

파라미터:
├── share_method: String (필수)
└── content_length: int (필수)

📝 수정 파일:
   └─ lib/core/services/analytics_service.dart

🔧 UI 호출 예시:
   AnalyticsService.logDiaryShared(
     shareMethod: 'native_share',
     contentLength: content.length,
   );
```

## 이벤트 카테고리

### 사용자 행동
- `diary_created` - 일기 작성
- `diary_deleted` - 일기 삭제
- `diary_shared` - 일기 공유

### 기능 사용
- `ai_character_changed` - AI 캐릭터 변경
- `notification_enabled` - 알림 활성화
- `statistics_viewed` - 통계 조회

### 전환 (Conversion)
- `first_diary_completed` - 첫 일기 완료
- `streak_achieved` - 연속 작성 달성

## Firebase Console 설정

### 커스텀 정의 (Custom Definitions)
```
이벤트 파라미터:
- ai_character_id (텍스트)
- sentiment_score (숫자)
- energy_level (숫자)
- content_length (숫자)
```

### 전환 이벤트 등록
```
1. Firebase Console → Analytics → Events
2. 이벤트 옆 스위치 활성화
3. 전환 이벤트로 표시
```

## 사용 예시

```
> "/analytics-event diary_shared"

AI 응답:
1. 이벤트 정보:
   - 이벤트명: diary_shared
   - 메서드: logDiaryShared
   - 파라미터: shareMethod, contentLength

2. AnalyticsService 업데이트

3. UI 호출 예시 제공

4. Firebase Console 설정 안내
```

## 주의사항
- 개인정보는 파라미터에 포함하지 않음
- 이벤트명/파라미터명 40자 제한
- 파라미터 값 100자 제한
- debugPrint는 kDebugMode에서만 출력
- 이벤트 수집은 프로덕션에서만 활성화 권장
