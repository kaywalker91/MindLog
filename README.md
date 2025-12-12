# MindLog (마음 로그) 🧠📝

**AI 기반 감정 케어 다이어리**

MindLog는 사용자의 일기를 분석하여 감정 상태를 파악하고, 위로의 메시지와 맞춤형 행동 지침을 제공하는 스마트 다이어리 앱입니다.

## ✨ 주요 기능

### 📝 일기 작성 및 저장
- 로컬 데이터베이스(SQLite)에 안전하게 저장
- 날짜별 일기 관리 및 조회

### 🤖 AI 감정 분석
- 초고속 **Groq API (Llama 3.3)** 를 사용하여 실시간에 가까운 분석 제공
- 감정 키워드 추출 및 감정 점수 산출 (0~100)
- 공감 메시지 및 맞춤형 추천 행동 제안
- 강화된 분석 프롬프트로 정확도 향상

### 📊 감정 통계 대시보드
- **감정 추이 차트**: 시간에 따른 감정 점수 변화를 라인 차트로 시각화
- **활동 히트맵**: 일기 작성 빈도를 캘린더 형태로 표시
- **키워드 태그 클라우드**: 자주 등장하는 감정 키워드 시각화
- 주간/월간 통계 요약

### ⚙️ 설정
- 알림 설정
- 테마 설정 (다크모드 지원 예정)
- 데이터 관리

## 🚀 시작하기 (Setup)

### 1. 환경 변수 설정 (.env)

프로젝트 루트 경로에 `.env` 파일을 생성하고 아래와 같이 API 키를 설정해야 합니다.

```env
# Groq API Key (권장 - 속도 빠름)
# 키 발급: https://console.groq.com/keys
GROQ_API_KEY=your_groq_api_key_here

# (선택 사항) Gemini API Key (구버전 호환용)
GEMINI_API_KEY=your_gemini_api_key_here
```

### 2. 패키지 설치

```bash
flutter pub get
```

### 3. 앱 실행

```bash
flutter run
```

## 🛠 변경 사항 (Changelog)

### v1.1.0 (Current)
*   **통계 기능 추가:** 감정 통계 대시보드 신규 구현
    *   감정 추이 라인 차트 (`fl_chart`)
    *   활동 히트맵 캘린더
    *   키워드 태그 클라우드
*   **새로운 화면:** 메인 화면, 설정 화면, 통계 화면 추가
*   **UI/UX 대폭 개선:** ResultCard 위젯 리뉴얼로 분석 결과 가독성 향상
*   **분석 정확도 향상:** AI 프롬프트 및 응답 파서 강화
*   **아키텍처 개선:** Clean Architecture 패턴 강화
*   **테스트 추가:** 핵심 로직 단위 테스트 구현

### v1.0.1
*   **AI 모델 변경:** Google Gemini (`gemini-1.5-flash`)의 속도 제한 및 응답 지연 문제를 해결하기 위해 **Groq (`llama-3.3-70b-versatile`)** 로 전면 교체하였습니다.
*   **응답 속도 개선:** 분석 대기 시간이 획기적으로 단축되었습니다.
*   **보안 강화:** API Key를 소스 코드에서 분리하여 `.env` 파일로 관리하도록 수정하였습니다.

## 🏗 프로젝트 구조

```
lib/
├── core/                    # 핵심 유틸리티 및 상수
│   └── constants/           # 프롬프트, 안전 상수
├── data/                    # 데이터 레이어
│   ├── datasources/         # 로컬/원격 데이터 소스
│   ├── dto/                 # 데이터 전송 객체
│   └── repositories/        # Repository 구현체
├── domain/                  # 도메인 레이어
│   ├── entities/            # 비즈니스 엔티티
│   ├── repositories/        # Repository 인터페이스
│   └── usecases/            # 비즈니스 로직
└── presentation/            # 프레젠테이션 레이어
    ├── providers/           # Riverpod 프로바이더
    ├── screens/             # 화면 위젯
    └── widgets/             # 재사용 위젯
```

## 📚 기술 스택

*   **Framework:** Flutter
*   **Language:** Dart
*   **State Management:** Riverpod
*   **Local DB:** SQLite (sqflite)
*   **AI API:** Groq (Llama 3.3) / Google Generative AI (Optional)
*   **Charts:** fl_chart
*   **Architecture:** Clean Architecture
