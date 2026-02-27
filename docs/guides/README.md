# MindLog Guides

> 설정, 배포, 기술 가이드 문서

## Documents

| Guide | Description |
|-------|-------------|
| [Deployment](./deployment.md) | 앱 빌드 및 배포 가이드 (APK, App Bundle, Play Store) |
| [Firebase Setup](./firebase-setup.md) | Firebase 통합 구현 계획 (Analytics, Crashlytics, FCM) |
| [Skills Creation](./skills-creation.md) | Claude Skills 작성 및 최적화 가이드 |
| [PRD](./prd.md) | Product Requirements Document - AI 기반 감정 케어 다이어리 MVP |
| [Flutter Official](./flutter_official.md) | Context7 + Memories 하이브리드 공식 문서 활용 가이드 |
| [Dart/Flutter MCP Setup](./dart-flutter-mcp-setup.md) | MCP 서버 설정 및 DTD URI 관리 (Dart VM Service 연동) |
| [AI 에이전트 팀 구성](./AI%20에이전트%20팀%20구성.md) | Claude Code Agent Teams 구성 패턴 및 협업 전략 |
| [Peter의 AI 코딩 10가지 원칙](./Peter의%20AI%20코딩%2010가지%20원칙.md) | AI 페어 프로그래밍 핵심 원칙 |
| [실리콘밸리 Claude Code × Flutter 워크플로우](./실리콘밸리%20Claude%20Code%20×%20Flutter%20개발%20워크플로우.md) | 실리콘밸리식 AI-협업 개발 워크플로우 통합 가이드 |

## Quick Links

### Deployment

```bash
# 로컬 APK 빌드
./scripts/run.sh build-apk

# App Bundle 빌드 (Play Store)
GROQ_API_KEY=your_key ./scripts/run.sh build-appbundle
```

### Firebase

- **Analytics**: `lib/core/services/analytics_service.dart`
- **Crashlytics**: `lib/core/services/crashlytics_service.dart`
- **FCM**: `lib/core/services/fcm_service.dart`

### Related Skills

- [/crashlytics-setup](../skills/crashlytics-setup.md) - Crashlytics 설정
- [/fcm-setup](../skills/fcm-setup.md) - FCM 푸시 알림 설정
- [/analytics-event](../skills/analytics-event-add.md) - Analytics 이벤트 추가
