# resilience-expert

에러 처리 패턴, Circuit Breaker, 앱 복원력 설계 전문가 스킬

## 목표
- 견고한 에러 처리 체계 구축
- 네트워크 불안정 상황 대응
- 사용자 경험 보호

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "에러 처리 추가", "Failure 타입" 요청
- `/resilience [action]` 명령어
- 새 예외 상황 처리 필요 시
- Circuit Breaker 설정 조정 시

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `lib/core/errors/failures.dart` | Sealed Failure 클래스 정의 |
| `lib/core/errors/exceptions.dart` | Custom Exception 정의 |
| `lib/core/errors/failure_mapper.dart` | Exception → Failure 변환 |
| `lib/core/errors/error_boundary.dart` | 전역 에러 처리 |
| `lib/core/network/circuit_breaker.dart` | 서킷 브레이커 패턴 |
| `lib/data/repositories/repository_failure_handler.dart` | Repository 에러 처리 mixin |

## 현재 에러 처리 체계

### Failure 타입 (Sealed Class)
```dart
sealed class Failure {
  ├── NetworkFailure     // 네트워크 연결 실패
  ├── ApiFailure         // API 호출 실패 (statusCode 포함)
  ├── CacheFailure       // 로컬 DB 저장 실패
  ├── ServerFailure      // 서버 오류
  ├── DataNotFoundFailure // 데이터 미존재
  ├── ValidationFailure  // 입력 유효성 실패
  ├── SafetyBlockedFailure // 안전 필터 트리거
  └── UnknownFailure     // 알 수 없는 오류
}
```

### Exception 타입
```dart
├── NetworkException     // 네트워크 예외
├── ApiException         // API 예외 (statusCode 포함)
├── CacheException       // 캐시 예외
├── DataNotFoundException // 데이터 미존재 예외
├── SafetyBlockException // 안전 필터 예외
└── CircuitBreakerOpenException // 서킷 브레이커 열림
```

### FailureMapper 변환 규칙
```
SafetyBlockException     → SafetyBlockedFailure
DataNotFoundException    → DataNotFoundFailure
CacheException          → CacheFailure
NetworkException        → NetworkFailure
ApiException            → ApiFailure
CircuitBreakerOpenException → ServerFailure
TimeoutException        → NetworkFailure
FormatException         → ApiFailure
기타                     → UnknownFailure
```

### Circuit Breaker 설정
```dart
failureThreshold: 5      // 연속 실패 시 회로 열림
resetTimeout: 30초       // 열림 상태 유지 시간
successThreshold: 2      // 반열림에서 닫힘 전환 조건
```

## 프로세스

### Action 1: add-failure
새 Failure 타입 추가

```
Step 1: 요구사항 분석
  - 어떤 상황에서 발생하는지
  - 사용자에게 어떤 메시지를 보여줄지
  - 추가 정보가 필요한지 (예: statusCode)

Step 2: failures.dart 수정
  - sealed class에 factory 추가
  - 구현 클래스 정의
  - displayMessage 구현

Step 3: exceptions.dart 수정 (필요시)
  - 대응하는 Exception 추가

Step 4: failure_mapper.dart 수정
  - Exception → Failure 매핑 추가

Step 5: 테스트 작성
```

**Failure 추가 템플릿:**
```dart
// failures.dart - factory 추가
const factory Failure.{name}({String? message}) = {Name}Failure;

// 구현 클래스
class {Name}Failure extends Failure {
  const {Name}Failure({super.message});

  @override
  String get displayMessage => message ?? '기본 메시지';
}
```

### Action 2: add-exception
새 Exception 타입 추가

```
Step 1: 예외 상황 정의
  - 발생 조건
  - 포함할 정보

Step 2: exceptions.dart 수정
  - Exception 클래스 정의
  - 필요한 필드 추가

Step 3: failure_mapper.dart 수정
  - 매핑 규칙 추가

Step 4: 사용처에서 throw
```

**Exception 추가 템플릿:**
```dart
class {Name}Exception implements Exception {
  final String message;
  final {AdditionalType}? {field};

  {Name}Exception({
    required this.message,
    this.{field},
  });

  @override
  String toString() => '{Name}Exception: $message';
}
```

### Action 3: configure-circuit-breaker
Circuit Breaker 설정 조정

```
Step 1: 현재 설정 분석
  - failureThreshold
  - resetTimeout
  - successThreshold

Step 2: 요구사항에 맞게 조정
  - 민감한 서비스 → 낮은 threshold
  - 안정적인 서비스 → 높은 threshold

Step 3: 테스트 시나리오 작성
  - 연속 실패 → 회로 열림
  - 타임아웃 후 → 반열림
  - 성공 → 닫힘
```

**권장 설정:**
```dart
// 민감한 서비스 (결제, 인증)
CircuitBreakerConfig(
  failureThreshold: 3,
  resetTimeout: Duration(seconds: 60),
  successThreshold: 2,
)

// 일반 서비스 (API 호출)
CircuitBreakerConfig(
  failureThreshold: 5,
  resetTimeout: Duration(seconds: 30),
  successThreshold: 2,
)

// 안정적인 서비스 (캐시)
CircuitBreakerConfig(
  failureThreshold: 10,
  resetTimeout: Duration(seconds: 15),
  successThreshold: 1,
)
```

### Action 4: improve-error-message
사용자 친화적 에러 메시지 개선

```
Step 1: 현재 메시지 검토
  - 기술적 용어 식별
  - 해결 방법 누락 확인

Step 2: 메시지 개선
  - 원인 설명 (무엇이 잘못되었는지)
  - 해결 방법 제시 (어떻게 해결하는지)
  - 친근한 톤 유지

Step 3: displayMessage 업데이트
```

**좋은 에러 메시지 예시:**
```dart
// Before
'네트워크 오류'

// After
'인터넷 연결이 불안정해요. Wi-Fi나 데이터 연결을 확인해 주세요.'

// Before
'API 호출 실패'

// After
'서버와 연결하는 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.'
```

### Action 5: add-retry-strategy
재시도 전략 추가/수정

```
Step 1: 재시도 대상 예외 정의
  - SocketException (네트워크)
  - TimeoutException (타임아웃)
  - 429 (Rate Limit)

Step 2: 재시도 전략 설정
  - 최대 재시도 횟수
  - 초기 지연 시간
  - 백오프 전략 (지수, 선형)

Step 3: 구현
```

**Exponential Backoff 템플릿:**
```dart
int maxRetries = 3;
Duration initialDelay = Duration(seconds: 1);
double backoffMultiplier = 2.0;

Duration currentDelay = initialDelay;
for (int attempt = 0; attempt < maxRetries; attempt++) {
  try {
    return await action();
  } catch (e) {
    if (attempt == maxRetries - 1) rethrow;
    await Future.delayed(currentDelay);
    currentDelay = Duration(
      milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).round()
    );
  }
}
```

### Action 6: error-report
현재 에러 처리 상태 리포트

```
Step 1: Failure 타입 목록
Step 2: Exception 타입 목록
Step 3: 매핑 규칙 검증
Step 4: 누락된 처리 식별
Step 5: 권장 개선사항
```

## Repository 에러 처리 패턴

### guardFailure 사용법
```dart
class MyRepositoryImpl with RepositoryFailureHandler {
  Future<Data> getData() async {
    return guardFailure('데이터 조회 실패', () async {
      // 예외 발생 가능한 코드
      return await dataSource.fetchData();
    });
  }
}
```

### guardFailureWithHook 사용법 (고급)
```dart
Future<Data> getData() async {
  return guardFailureWithHook(
    '데이터 조회 실패',
    () async => await dataSource.fetchData(),
    onFailure: (failure) async {
      // 실패 시 추가 처리 (로깅, 분석 등)
      await analyticsService.logError(failure);
    },
    onUnknownFailure: (error, stackTrace) {
      // 알 수 없는 에러 시 Crashlytics 전송
      crashlyticsService.recordError(error, stackTrace);
    },
  );
}
```

## 출력 형식

```
🛡️ Resilience Expert 실행 결과

Action: [실행한 액션]

변경 사항:
├── 새 Failure: RateLimitFailure
├── 새 Exception: RateLimitException
└── FailureMapper 업데이트

사용자 메시지:
└── "요청이 너무 많아요. 1분 후 다시 시도해 주세요."

수정 파일:
├── lib/core/errors/failures.dart
├── lib/core/errors/exceptions.dart
└── lib/core/errors/failure_mapper.dart

테스트:
└── /test-unit-gen lib/core/errors/failure_mapper.dart
```

## 사용 예시

### Failure 추가
```
> "/resilience add-failure rate_limit"

AI 응답:
1. RateLimitFailure 정의
   - message: "요청이 너무 많습니다"
   - retryAfter: Duration (선택)
2. RateLimitException 정의
3. FailureMapper 매핑 추가
4. 테스트 생성 권장
```

### Circuit Breaker 조정
```
> "/resilience configure-circuit-breaker --threshold=3"

AI 응답:
1. 현재 설정: failureThreshold=5
2. 변경: failureThreshold=3
3. 영향:
   - 더 민감하게 반응
   - 빠른 장애 차단
   - 복구 시간 동일 (30초)
```

### 에러 메시지 개선
```
> "/resilience improve-error-message NetworkFailure"

AI 응답:
1. 현재: "네트워크 연결을 확인해주세요."
2. 개선안:
   - "인터넷 연결이 불안정해요. Wi-Fi나 모바일 데이터를 확인해 주세요."
   - 원인 + 해결 방법 포함
```

## 에러 처리 베스트 프랙티스

### 1. 계층별 책임
```
DataSource → Exception throw
Repository → Exception catch, Failure throw (guardFailure 사용)
UseCase → Failure catch, 비즈니스 로직 처리
Presentation → Failure catch, UI 표시
```

### 2. 에러 로깅 전략
```dart
// 개발 환경: 상세 로그
assert(() {
  debugPrint('Error: $error');
  return true;
}());

// 프로덕션: Crashlytics
CrashlyticsService.recordError(error, stackTrace);
```

### 3. 사용자 피드백
```dart
// 일시적 오류 → 재시도 버튼
// 영구적 오류 → 도움말 링크
// 치명적 오류 → 앱 재시작 안내
```

## 연관 스킬
- `/test-unit-gen` - Failure/Exception 테스트 생성
- `/groq` - API 에러 처리 최적화
- `/crashlytics-setup` - 에러 리포팅 설정

## 주의사항
- Sealed class 패턴 유지 (exhaustive switch 가능)
- displayMessage는 항상 사용자 친화적으로
- Circuit Breaker는 외부 서비스 호출에만 적용
- SafetyBlockedFailure는 절대 수정 금지 (안전 기능)
- 프로덕션에서 상세 에러 메시지 노출 금지
- Crashlytics로 UnknownFailure 모니터링 권장
