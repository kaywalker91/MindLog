# /notification-audit - 알림 시스템 종합 감사

## Purpose
MindLog 알림 시스템(FCM, 로컬 알림, 스케줄러)의 페이로드 무결성, ID 충돌, 테스트 커버리지를 병렬 에이전트로 종합 감사.

## Usage
```
/notification-audit [path]
```

## Arguments
- `path` (optional) - 감사 대상 경로 (기본값: `lib/core/services/`, `test/core/services/`)

## 트리거 조건
- FCM 관련 버그 수정 후
- 알림 기능 추가/변경 전후
- 테스트 실패 원인이 알림 관련일 때
- 배포 전 알림 시스템 안전성 검증

## 실행 방식 (3-Agent 병렬)

```
/notification-audit 실행 시:
┌─────────────────────────────────────────────────────┐
│                  notification-tester                 │
│                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────┐ │
│  │payload-      │  │id-conflict-  │  │scenario-  │ │
│  │auditor       │  │checker       │  │tester     │ │
│  │              │  │              │  │           │ │
│  │FCM payload   │  │알림 ID 충돌  │  │테스트 시  │ │
│  │구조 검증     │  │중복 감지     │  │나리오 완  │ │
│  │              │  │              │  │전성 검증  │ │
│  └──────────────┘  └──────────────┘  └───────────┘ │
│         ↓                ↓                ↓         │
│              통합 감사 리포트 생성                    │
└─────────────────────────────────────────────────────┘
```

## 에이전트별 담당 영역

### payload-auditor
- FCM data-only payload 준수 검증
- background isolate 초기화 확인
- 빈 메시지 방어 로직 확인
- `{name}` 패턴 정책 준수 확인
- 개인화 실패 폴백 로직 검증

### id-conflict-checker
- 알림 ID 상수 중앙 정의 확인
- ID 중복 사용 크로스체크
- 하드코딩 ID 탐지
- 동적 CBT ID 범위 검증

### scenario-tester
- FCM 감정 점수별 테스트 커버리지
- timezone TZDateTime 패턴 준수
- pumpAndSettle() 안티패턴 탐지
- static service tearDown reset 확인
- 알림 ID 상수 고정 테스트 확인

## 알림 ID 정책 참조
```
1001  → CheerMe (로컬)
2001  → FCM 마음케어 (fcmMindcareId)
2002  → 주간 인사이트
2004  → Safety Follow-up
3001+ → 동적 CBT (동적 생성)
```

## 주요 알림 파일
```
lib/core/services/fcm_service.dart
lib/core/services/notification_service.dart
lib/core/services/notification_scheduler_impl.dart
lib/core/services/notification_settings_service.dart
lib/core/constants/notification_messages.dart
test/core/services/fcm_service_test.dart
```

## 출력
각 에이전트 리포트를 통합하여 다음 형식으로 출력:
```markdown
# Notification System Audit Report

## Executive Summary
| 영역 | 상태 | Critical | High | Medium |
|------|------|----------|------|--------|
| Payload 구조 | PASS/WARN/FAIL | 0 | 0 | 0 |
| ID 관리 | PASS/WARN/FAIL | 0 | 0 | 0 |
| 테스트 커버리지 | PASS/WARN/FAIL | 0 | 0 | 0 |

## 즉시 조치 필요 항목 (Critical)
...

## 상세 에이전트 리포트
[payload-auditor 결과]
[id-conflict-checker 결과]
[scenario-tester 결과]
```

## 관련 스킬
- `/notification-enum-gen [feature]` — 알림 Enum 코드 생성
- `/crisis-check [action]` — 위기 감지 알림 검증
- `/test-unit-gen [file]` — 알림 서비스 단위 테스트 생성
