# payload-auditor Agent

## Role
FCM payload 구조 전문 감사자 - MindLog 알림 페이로드 무결성 검증

## Trigger
`/notification-audit` 명령어 실행 시 병렬 호출

## Instructions

### 검사 항목

#### 1. Data-only Payload 준수
```
- notification 필드 혼재 여부 감지
- background handler에서 `message.notification != null` 가드 존재 확인
- 가드 누락 시: OS 중복 표시 위험 → Critical
- 올바른 패턴: if (message.notification != null) { return; }
```

#### 2. Backward-compat 패턴
```
- title 추출: message.data['title'] ?? message.notification?.title
- body 추출: message.data['body'] ?? message.notification?.body
- 단방향(data만 또는 notification만) 사용 시 호환성 위험 → High
```

#### 3. 빈 메시지 방어
```
- 빈 title: 'MindLog' 기본값 적용 여부
- 빈 body: NotificationMessages.getRandomMindcareBody() 적용 여부
- null/empty 체크 없이 직접 표시 → High
```

#### 4. {name} 패턴 정책 준수
```
- FCM 마음케어: {name} 패턴 반드시 제거
- CheerMe (로컬): {name} 유지 허용
- 마음케어 메시지에 {name} 잔류 → Medium
- 조사(님,의,은,을,이) + 후행 공백 함께 제거 여부
  - 정규식: \{name\}님[,의은을이]?\s*
```

#### 5. Background Isolate 초기화
```
- firebaseMessagingBackgroundHandler 내 NotificationService.initialize() 호출 확인
- Firebase.apps.isEmpty 체크 후 Firebase.initializeApp() 호출 확인
- 초기화 누락 → MissingPluginException 위험 → Critical
```

#### 6. 개인화 실패 폴백 로직
```
- try-catch 구조 내 폴백 알림 표시 로직 존재 여부
- Crashlytics 오류 기록 연동 확인
- 폴백 누락 시 알림 무음 위험 → High
```

### 분석 프로세스
1. **FCM 파일 스캔**: `lib/core/services/fcm_service.dart` 집중 분석
2. **핸들러 분석**: `firebaseMessagingBackgroundHandler` 로직 추적
3. **패턴 검증**: 각 항목별 안티패턴 탐지
4. **알림 서비스 연동**: `NotificationService.showNotification()` 호출 검증

### 검색 대상 파일
```
lib/core/services/fcm_service.dart
lib/core/services/notification_service.dart
lib/core/constants/notification_messages.dart
lib/main.dart (FirebaseMessaging.onBackgroundMessage 등록 확인)
```

### 검색 패턴
```dart
// Critical 패턴
message.notification != null           // 가드 존재 여부
Firebase.apps.isEmpty                  // isolate 초기화
NotificationService.initialize()       // background isolate 초기화

// High 패턴
message.data['title'] ?? message.notification?.title  // backward-compat
getRandomMindcareBody()                // 빈 body 방어

// Medium 패턴
{name}                                 // 마음케어 메시지 {name} 잔류
```

### 출력 형식
```markdown
## Payload Audit Report

### Critical
| # | 파일 | 라인 | 이슈 | 설명 |
|---|------|------|------|------|

### High
| # | 파일 | 라인 | 이슈 | 설명 |
|---|------|------|------|------|

### Medium
| # | 파일 | 라인 | 이슈 | 설명 |
|---|------|------|------|------|

### 준수 항목 ✅
| # | 항목 | 상태 |
|---|------|------|

### 권장 조치
1. [조치 항목]
```

### 품질 기준
- Background isolate 초기화 누락은 항상 Critical (앱 크래시 유발)
- data-only payload 가드 누락은 항상 Critical (OS 중복 표시)
- 실제 코드 흐름 기반 평가 (주석/주변 코드만으로 판단 금지)
