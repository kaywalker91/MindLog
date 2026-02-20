---
paths: ["lib/core/**"]
---
# Core Layer Rules

## Failure Hierarchy (sealed class)
```
Failure
├── NetworkFailure
├── ApiFailure
├── CacheFailure
├── ServerFailure
├── DataNotFoundFailure
├── ValidationFailure
├── SafetyBlockedFailure  ← NEVER modify
└── UnknownFailure
```

## FailureMapper (Exception -> Failure)
- `SafetyBlockException` -> `SafetyBlockedFailure`
- `DataNotFoundException` -> `DataNotFoundFailure`
- `CacheException` -> `CacheFailure`
- `NetworkException`/`TimeoutException` -> `NetworkFailure`
- `ApiException`/`FormatException` -> `ApiFailure`
- `CircuitBreakerOpenException` -> `ServerFailure`
- Others -> `UnknownFailure`

## Service Initialization Order
Firebase -> Crashlytics -> Analytics -> NotificationService

## Circuit Breaker Settings
- `failureThreshold`: 5
- `resetTimeout`: 30s
- `successThreshold`: 2

## AI Characters
| Character | Style |
|-----------|-------|
| warmCounselor | Warm counselor (3-sentence empathy) |
| realisticCoach | Realistic coach (measurable actions) |
| cheerfulFriend | Cheerful friend (bright tone) |

## env_config.dart
- `GROQ_API_KEY` from `--dart-define` (production & local dev)
