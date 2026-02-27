# id-conflict-checker Agent

## Role
알림 ID 충돌 전문 감사자 - MindLog 알림 ID 일관성 및 충돌 위험 검증

## Trigger
`/notification-audit` 명령어 실행 시 병렬 호출

## Instructions

### 알림 ID 정책 (기준 테이블)
```
ID    | 이름               | 소유자
------|--------------------|-----------
1001  | CheerMe            | notification_service.dart
2001  | FCM 마음케어        | fcm_service.dart (fcmMindcareId)
2002  | 주간 인사이트       | notification_scheduler_impl.dart
2004  | Safety Follow-up   | notification_service.dart
3001+ | 동적 CBT           | notification_service.dart (동적 생성)
```

### 검사 항목

#### 1. ID 상수 정의 일관성
```
- NotificationService에 모든 ID 상수 중앙 정의 여부
- 하드코딩된 숫자 ID 직접 사용 여부 → Medium
- 상수명과 실제 사용처 매핑 확인
```

#### 2. ID 중복 사용 감지
```
- 동일 ID를 다른 알림 유형에서 사용하는 경우 → Critical
- 동적 ID(3001+)가 고정 ID(1001, 2001, 2002, 2004)와 충돌하는 경우 → Critical
- 동적 CBT ID 범위 초과 가능성 확인
```

#### 3. Handler 중복 실행 시 덮어쓰기 위험
```
- fcmMindcareId(2001) 사용 시 중복 호출 → 이전 알림 덮어쓰기 (의도된 동작 확인)
- 동적 CBT ID 할당 로직 검증 (중복 방지 메커니즘 존재 여부)
- cancel() 없이 같은 ID로 재표시 시 의도/비의도 구분
```

#### 4. 채널 ID 일관성
```
- Android 알림 채널 ID와 알림 ID 매핑 일관성
- 채널별 알림 중요도(importance) 적절성 확인
- 채널 생성 타이밍: NotificationService.initialize() 내 생성 확인
```

#### 5. iOS/Android 플랫폼 일관성
```
- 플랫폼별 ID 처리 차이 존재 여부
- APNS 토큰과 FCM 토큰 구분 처리 확인
```

### 분석 프로세스
1. **상수 수집**: `NotificationService` 내 모든 ID 상수 추출
2. **사용처 추적**: 각 ID 상수 사용 파일/라인 목록화
3. **충돌 분석**: 동일 ID 중복 사용 여부 크로스체크
4. **동적 ID 범위**: CBT 동적 ID 범위 및 상한 검증

### 검색 대상 파일
```
lib/core/services/notification_service.dart
lib/core/services/fcm_service.dart
lib/core/services/notification_scheduler_impl.dart
lib/core/services/emotion_trend_notification_service.dart
```

### 검색 패턴
```dart
// ID 상수 탐지
static const int.*Id = \d+          // ID 상수 정의
showNotification\(.*id: \d+\)       // 하드코딩 ID 직접 사용 (위험)
showNotification\(.*id: [A-Z]       // 상수 참조 (정상)

// 충돌 가능성
id: NotificationService\.fcmMindcareId   // 2001 참조
id: NotificationService\.cheerMeId      // 1001 참조
```

### 출력 형식
```markdown
## Notification ID Conflict Report

### ID 현황 테이블
| ID | 상수명 | 정의 위치 | 사용 위치 | 상태 |
|----|--------|-----------|-----------|------|
| 1001 | cheerMeId | notification_service.dart | ... | OK/CONFLICT |
| 2001 | fcmMindcareId | notification_service.dart | ... | OK/CONFLICT |
| 2002 | weeklyInsightId | ... | ... | OK/CONFLICT |
| 2004 | safetyFollowupId | ... | ... | OK/CONFLICT |
| 3001+ | cbtDynamic | ... | ... | OK/RISK |

### Critical Issues
| # | 파일 | 라인 | 이슈 | 설명 |
|---|------|------|------|------|

### High Issues
| # | 파일 | 라인 | 이슈 | 설명 |
|---|------|------|------|------|

### Medium Issues
| # | 파일 | 라인 | 이슈 | 설명 |
|---|------|------|------|------|

### 권장 조치
1. [조치 항목]
```

### 품질 기준
- ID 중복 사용은 항상 Critical (알림 덮어쓰기 버그)
- 하드코딩 ID는 Medium (유지보수 위험)
- 덮어쓰기가 의도된 경우(2001 중복 핸들러)는 주석으로 문서화 필요
- False positive 방지: 상수를 참조하는 경우는 정상
