# resilience-expert

에러 처리 패턴 및 앱 복원력 설계 (`/resilience [action]`)

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `lib/core/errors/failures.dart` | Sealed Failure 클래스 |
| `lib/core/errors/exceptions.dart` | Custom Exception |
| `lib/core/errors/failure_mapper.dart` | Exception → Failure 변환 |
| `lib/core/network/circuit_breaker.dart` | 서킷 브레이커 |
| `lib/data/repositories/repository_failure_handler.dart` | Repository mixin |

## Failure 타입 (Sealed Class)
```dart
sealed class Failure {
  NetworkFailure, ApiFailure, CacheFailure, ServerFailure,
  DataNotFoundFailure, ValidationFailure, SafetyBlockedFailure, UnknownFailure
}
```

## FailureMapper 변환
```
SafetyBlockException → SafetyBlockedFailure
DataNotFoundException → DataNotFoundFailure
CacheException → CacheFailure
NetworkException/TimeoutException → NetworkFailure
ApiException/FormatException → ApiFailure
CircuitBreakerOpenException → ServerFailure
기타 → UnknownFailure
```

## Circuit Breaker
```dart
failureThreshold: 5   // 연속 실패 시 회로 열림
resetTimeout: 30초    // 열림 상태 유지
successThreshold: 2   // 반열림 → 닫힘 전환
```

## Actions

### add-failure
새 Failure 타입 추가
1. `failures.dart`에 factory + 구현 클래스
2. `exceptions.dart`에 대응 Exception
3. `failure_mapper.dart`에 매핑 추가

```dart
// 템플릿
const factory Failure.{name}({String? message}) = {Name}Failure;
class {Name}Failure extends Failure {
  const {Name}Failure({super.message});
  @override String get displayMessage => message ?? '기본 메시지';
}
```

### configure-circuit-breaker
설정 조정 (민감 서비스 → 낮은 threshold)

### add-retry-strategy
Exponential Backoff 재시도 전략
```dart
for (int attempt = 0; attempt < maxRetries; attempt++) {
  try { return await action(); }
  catch (e) {
    if (attempt == maxRetries - 1) rethrow;
    await Future.delayed(currentDelay);
    currentDelay *= backoffMultiplier;
  }
}
```

## Repository 패턴
```dart
class MyRepositoryImpl with RepositoryFailureHandler {
  Future<Data> getData() => guardFailure('조회 실패', () async {
    return await dataSource.fetchData();
  });
}
```

## 계층별 책임
- DataSource → Exception throw
- Repository → Exception catch, Failure throw (guardFailure)
- UseCase → Failure catch, 비즈니스 로직
- Presentation → Failure catch, UI 표시

## 주의사항
- Sealed class 패턴 유지 (exhaustive switch)
- SafetyBlockedFailure 절대 수정 금지
- Circuit Breaker는 외부 서비스 호출에만 적용
