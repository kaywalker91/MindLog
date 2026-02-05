<p align="center">
  <img src="assets/icon/app_icon.png" width="100" alt="MindLog"/>
</p>

<h1 align="center">MindLog (마음 로그)</h1>
<p align="center">
  <strong>AI가 당신의 마음을 읽고, 오늘 하루를 위로합니다</strong><br/>
  <em>AI-powered emotional care diary that understands and comforts you</em>
</p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.mindlog.app">
    <img src="https://img.shields.io/badge/Google%20Play-Download-green?logo=google-play" alt="Google Play"/>
  </a>
  <img src="https://img.shields.io/badge/Platform-Android-blue?logo=android" alt="Platform"/>
  <img src="https://img.shields.io/badge/Privacy-Local%20Only-success" alt="Privacy"/>
  <img src="https://img.shields.io/badge/AI-Groq%20Llama%203.3-purple" alt="AI"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="License"/>
</p>

---

## 소개 / About

**MindLog**는 일기를 작성하면 AI가 감정을 분석하고, 공감 메시지와 맞춤형 행동 지침을 제공하는 스마트 다이어리 앱입니다.

MindLog analyzes your diary entries with AI, providing empathetic messages and personalized action suggestions to support your emotional well-being.

---

## 주요 기능 / Features

| 기능 | Feature | 설명 |
|------|---------|------|
| **AI 감정 분석** | Emotion Analysis | Groq Llama 3.3 기반 실시간 감정 분석 |
| **공감 메시지** | Empathy Messages | AI 캐릭터(온이, 콕이, 웃음이)가 맞춤 위로 제공 |
| **마음 달력** | Emotion Calendar | 감정 점수를 식물 성장으로 시각화 |
| **감정 통계** | Statistics | 감정 추이 차트, 키워드 분석 |
| **이미지 첨부** | Image Attachment | Vision API로 사진 속 감정까지 분석 |
| **마음케어 알림** | Care Notifications | 아침/저녁 맞춤 응원 메시지 |

---

## 스크린샷 / Screenshots

<p align="center">
  <img src="assets/screenshots/v3/02_diary_list.jpeg" width="200" alt="일기 목록"/>
  <img src="assets/screenshots/v3/03_diary_write.jpeg" width="200" alt="일기 작성"/>
  <img src="assets/screenshots/v3/04_stats_calendar.jpeg" width="200" alt="마음 달력"/>
  <img src="assets/screenshots/v3/08_ai_character.jpeg" width="200" alt="AI 캐릭터"/>
</p>

---

## 프라이버시 / Privacy

> **당신의 마음은 당신만의 것입니다.** Your privacy matters.

| 항목 | 정책 | Policy |
|------|------|--------|
| 일기 저장 | 기기 내 SQLite만 사용 | Local SQLite only |
| 서버 전송 | AI 분석 시 익명 텍스트만 | Anonymous text for AI only |
| 클라우드 | 동기화 없음 | No cloud sync |
| 삭제 | 설정에서 즉시 완전 삭제 | Instant full deletion |

[개인정보 처리방침](docs/legal/privacy-policy.md)

---

## 다운로드 / Download

<a href="https://play.google.com/store/apps/details?id=com.mindlog.app">
  <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" width="200" alt="Get it on Google Play"/>
</a>

---

<details>
<summary><strong>개발자 가이드 / Developer Guide</strong></summary>

### 환경 설정 / Setup

```bash
# 1. 패키지 설치
flutter pub get

# 2. 앱 실행 (API 키 필수)
flutter run --dart-define=GROQ_API_KEY=your_key

# 또는 스크립트 사용
GROQ_API_KEY=your_key ./scripts/run.sh run
```

### 빌드 / Build

```bash
# Release APK
flutter build apk --release --dart-define=GROQ_API_KEY=your_key

# Release App Bundle
flutter build appbundle --release --dart-define=GROQ_API_KEY=your_key
```

### 테스트 / Test

```bash
# 전체 테스트
./scripts/run.sh test

# 품질 검사 (lint + format + test)
./scripts/run.sh quality
```

### API 키 발급 / Get API Key

1. [Groq Console](https://console.groq.com/)에서 계정 생성
2. API Keys 메뉴에서 키 발급
3. `--dart-define=GROQ_API_KEY=xxx` 또는 환경변수로 주입

</details>

---

<details>
<summary><strong>기술 스택 / Tech Stack</strong></summary>

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter / Dart | 3.38.x / ^3.10.1 |
| State | Riverpod | 2.6.1 |
| Database | SQLite (sqflite) | 2.3.3 |
| Firebase | Analytics, Crashlytics, FCM | 3.8.0+ |
| Routing | go_router | 17.0.1 |
| AI | Groq API | llama-3.3-70b-versatile |
| Chart | fl_chart | 0.68.0 |

</details>

---

<details>
<summary><strong>프로젝트 구조 / Project Structure</strong></summary>

```
lib/
├── core/           # 핵심 유틸리티, 테마, 상수
├── data/           # Repository 구현체, DataSources, DTOs
├── domain/         # 순수 Dart: 엔티티, 레포지토리 인터페이스, 유스케이스
├── presentation/   # Providers, Screens, Widgets
└── main.dart

Architecture: Clean Architecture + Riverpod
```

</details>

---

## 변경사항 / Changelog

전체 변경사항은 [CHANGELOG.md](CHANGELOG.md)를 참조하세요.

See [CHANGELOG.md](CHANGELOG.md) for full release notes.

---

## 기여 / Contributing

버그 리포트, 기능 제안, PR을 환영합니다!

Bug reports, feature requests, and pull requests are welcome!

---

## 라이선스 / License

MIT License - see [LICENSE](LICENSE) for details.
