<p align="center">
  <a href="README.md">🇺🇸 English</a>
</p>

<p align="center">
  <img src="assets/icons/icon_mind_log.png" width="100" alt="MindLog"/>
</p>

<h1 align="center">MindLog (마음 로그)</h1>
<p align="center">
  <strong>AI가 당신의 마음을 읽고, 오늘 하루를 위로합니다</strong>
</p>

<p align="center">
  <a href="https://github.com/kaywalker91/MindLog/actions/workflows/ci.yml">
    <img src="https://github.com/kaywalker91/MindLog/actions/workflows/ci.yml/badge.svg" alt="CI"/>
  </a>
  <a href="https://play.google.com/store/apps/details?id=com.mindlog.app">
    <img src="https://img.shields.io/badge/Google%20Play-다운로드-green?logo=google-play" alt="Google Play"/>
  </a>
  <img src="https://img.shields.io/badge/Platform-Android-blue?logo=android" alt="Platform"/>
  <img src="https://img.shields.io/badge/Privacy-Local%20Only-success" alt="Privacy"/>
  <img src="https://img.shields.io/badge/AI-Groq%20Llama%203.3-purple" alt="AI"/>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
  </a>
</p>

---

## 주요 기능

- 🧠 **AI 감정 분석** — Groq Llama 3.3 기반 실시간 감정 분석
- 💬 **공감 AI 캐릭터** — 온이, 콕이, 웃음이가 당신만의 위로 메시지를 전합니다
- 🌱 **마음 달력** — 감정 점수가 식물의 성장으로 피어납니다
- 📊 **감정 통계** — 감정 추이 차트, 키워드 분석, 주간 인사이트
- 📸 **이미지 분석** — Vision API로 사진 속 감정까지 읽어냅니다
- 🔔 **스마트 알림** — 아침 응원(Cheer Me) & 저녁 마음케어, 2채널 맞춤 알림
- 🔒 **프라이버시 우선** — 100% 기기 내 저장, 클라우드 동기화 없음, 서버 전송 없음

---

## 최신 업데이트 (v1.4.39)

- ✅ **1,384개 테스트 모두 통과** — 철저한 테스트 커버리지로 앱 안정성 보장
- 🔧 **CI/CD 강화** — 테스트 실패 자동 감지 및 품질 게이트 시스템
- 📊 **배포 전 감사 시스템** — 릴리스마다 7단계 검증 자동 실행
- 🛠️ **빌드 스크립트 개선** — 환경별 설정 자동 주입으로 배포 프로세스 간소화

<details>
<summary>이전 업데이트 (v1.4.38)</summary>

- 📬 **주간 인사이트** — 매주 일요일 저녁, 한 주간의 감정을 돌아보는 알림
- 🧠 **인지 패턴 감지** — AI가 흑백사고 등 인지 왜곡 감지 후 CBT 메시지 전송
- 🎯 **감정 기반 메시지** — 최근 감정 상태와 비슷한 메시지 우선 전달
- 💙 **안전 팔로업** — 위기 감지 후 24시간 뒤 안부 확인
- 📈 **감정 트렌드 분석** — 기록이 뜸하거나 감정 변화가 있을 때 자동 알림

</details>

---

## 스크린샷

<p align="center">
  <img src="assets/screenshots/v3/02_diary_list.jpeg" width="200" alt="일기 목록"/>
  <img src="assets/screenshots/v3/03_diary_write.jpeg" width="200" alt="일기 작성"/>
  <img src="assets/screenshots/v3/04_stats_calendar.jpeg" width="200" alt="마음 달력"/>
  <img src="assets/screenshots/v3/08_ai_character.jpeg" width="200" alt="AI 캐릭터"/>
</p>

---

## 프라이버시

> **당신의 마음은 당신만의 것입니다.**

| 항목 | 정책 |
|------|------|
| 저장 | 기기 내 SQLite만 사용 — 외부 서버 전송 없음 |
| AI 분석 | 익명 텍스트만 Groq API로 전송, 개인정보 미포함 |
| 클라우드 | 동기화 없음 — 계정 없음, 서버 없음 |
| 삭제 | 설정에서 즉시 완전 삭제 |

자세한 내용은 [개인정보 처리방침](docs/legal/privacy-policy.md)을 참조하세요.

---

## 기술 스택

| 분류 | 기술 | 버전 |
|------|------|------|
| 프레임워크 | Flutter / Dart | 3.38.x / ^3.10.1 |
| 상태 관리 | Riverpod | 2.6.1 |
| 데이터베이스 | SQLite (sqflite) | 2.3.3 |
| Firebase | Analytics, Crashlytics, FCM | 3.8.0+ |
| 라우팅 | go_router | 17.0.1 |
| AI | Groq API | llama-3.3-70b-versatile |
| 차트 | fl_chart | 0.68.0 |

---

## 아키텍처

```
┌──────────────────────────────────────────┐
│              Presentation                │
│     Providers (Riverpod) + Widgets       │
├────────────────────┬─────────────────────┤
│                    ▼                     │
│               Domain                     │
│    Entities, UseCases, Repo Interfaces   │
├────────────────────┬─────────────────────┤
│                    ▲                     │
│                Data                      │
│   Repo Impl, DataSources, DTOs          │
└──────────────────────────────────────────┘

레이어 규칙: presentation → domain ← data
(domain은 외부 의존성 없음)
```

---

## 시작하기

### 사전 요구사항

- Flutter 3.38.x / Dart 3.10.x
- [Groq API 키](https://console.groq.com/)

### 설정

```bash
# 클론
git clone https://github.com/kaywalker91/MindLog.git
cd MindLog

# 의존성 설치
flutter pub get

# 코드 생성 (freezed, json_serializable 등)
dart run build_runner build --delete-conflicting-outputs

# 실행
flutter run --dart-define=GROQ_API_KEY=your_key
```

### 빌드

```bash
# Release App Bundle
flutter build appbundle --release --dart-define=GROQ_API_KEY=your_key

# Release APK
flutter build apk --release --dart-define=GROQ_API_KEY=your_key
```

---

## 프로젝트 구조

```
lib/
├── core/           # 설정, 서비스, 테마, 상수, 유틸리티
├── data/           # Repository 구현체, DataSources, DTOs
├── domain/         # 순수 Dart: 엔티티, 레포지토리 인터페이스, 유스케이스
├── presentation/   # Providers, Screens, Widgets
└── main.dart
```

---

## 테스트

```bash
# 커버리지 포함 전체 테스트
./scripts/run.sh test

# 전체 품질 검사 (lint + format + test)
./scripts/run.sh quality
```

커버리지 목표: 단위 테스트 ≥ 80%, 위젯 테스트 ≥ 70%

---

## 기여하기

버그 리포트, 기능 제안, Pull Request를 환영합니다!

가이드라인은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참조해 주세요.

---

## 변경사항

전체 변경사항은 [CHANGELOG.md](CHANGELOG.md)를 참조하세요.

---

## 라이선스

[MIT License](LICENSE) — Copyright (c) 2024 kaywalker91
