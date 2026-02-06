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
