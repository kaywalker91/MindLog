# MindLog (마음 로그) 🧠📝

**AI 기반 감정 케어 다이어리**

MindLog는 사용자의 일기를 분석하여 감정 상태를 파악하고, 위로의 메시지와 맞춤형 행동 지침을 제공하는 스마트 다이어리 앱입니다.

## ✨ 주요 기능

*   **일기 작성 및 저장:** 로컬 데이터베이스(SQLite)에 안전하게 저장됩니다.
*   **AI 감정 분석:** 
    *   초고속 **Groq API (Llama 3.3)** 를 사용하여 실시간에 가까운 분석을 제공합니다. (기존 Gemini에서 업그레이드됨)
    *   감정 키워드 추출, 감정 점수 산출, 공감 메시지 및 추천 행동 제안.
*   **감정 통계:** (예정) 분석된 데이터를 시각화하여 보여줍니다.

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

### v1.0.1 (Current)
*   **AI 모델 변경:** Google Gemini (`gemini-1.5-flash`)의 속도 제한 및 응답 지연 문제를 해결하기 위해 **Groq (`llama-3.3-70b-versatile`)** 로 전면 교체하였습니다.
*   **응답 속도 개선:** 분석 대기 시간이 획기적으로 단축되었습니다.
*   **보안 강화:** API Key를 소스 코드에서 분리하여 `.env` 파일로 관리하도록 수정하였습니다.

## 📚 기술 스택

*   **Framework:** Flutter
*   **Language:** Dart
*   **State Management:** Riverpod
*   **Local DB:** SQLite (sqflite)
*   **AI API:** Groq (Llama 3.3) / Google Generative AI (Optional)
