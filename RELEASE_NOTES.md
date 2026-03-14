# MindLog v1.4.50

> AI 기반 감정 케어 다이어리

## 버그 수정 🐛

- **Cheer Me 알림 이름 표시 수정** — 이름 설정 후에도 알림 제목에 `{name}님의 응원 메시지`처럼 플레이스홀더 원문이 표시되던 문제 완전 해결. 정규식 2자 조사 미커버, API 개인화 미적용, AsyncLoading 중 reschedule 누락, stale 알림 갱신 차단 등 4개 복합 원인 동시 수정
- **AI 응원 메시지 자연스러움 개선** — KoreanTextFilter 경량 교정 경로에 중복 동사 패턴 제거 추가, length guard 우회로 짧은 교정 결과 차단 현상 해소

---
**업데이트 방법**: Google Play Store에서 자동 업데이트
