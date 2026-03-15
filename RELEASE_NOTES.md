# MindLog v1.4.51

> AI 기반 감정 케어 다이어리

## 개선사항 🔧

- **CD 파이프라인 경로 수정**: Fastlane `Dir.chdir("..")` 오류로 인한 `pubspec.yaml` 미발견 버그 수정. `PROJECT_ROOT` 절대경로 상수 도입으로 CWD 무관하게 안정적인 빌드 환경 확보
- **도메인 엔티티 freezed 전환**: `Statistics`, `NotificationSettings`, `Diary`, `SelfEncouragementMessage` 4개 엔티티 freezed 패턴 전환 완료 (Phase 3-1)
- **접근성 Sprint 3 착수**: `AppAccessibility` L1 유틸 코드베이스 전반 점진적 도입 시작
- **테스트 인프라 개선**: mocktail `extends Mock` 전환 + talker 기반 로깅 인프라 추가
- **riverpod 코드젠 의존성 추가**: `riverpod_annotation` + `riverpod_generator` 신규 코드 전용 도입

---
**업데이트 방법**: Google Play Store에서 자동 업데이트
