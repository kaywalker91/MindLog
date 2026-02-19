# api-doc-gen

프로젝트에서 사용하는 API 엔드포인트 문서를 자동 생성하는 스킬

## 목표
- API 사용 문서화 자동화
- 외부 서비스 연동 정보 일원화
- 개발자 온보딩 시간 단축

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "API 문서 생성", "api doc" 요청
- `/api-doc` 명령어
- 새 API 연동 추가 후
- 프로젝트 문서화 시

## 현재 API 목록
참조: `lib/data/datasources/remote/`

| API | 용도 | 인증 |
|-----|------|------|
| Groq API | AI 일기 분석 | API Key (dart-define) |
| Firebase Analytics | 사용자 행동 추적 | Firebase SDK |
| Firebase Crashlytics | 에러 리포팅 | Firebase SDK |
| Firebase Cloud Messaging | 푸시 알림 | Firebase SDK |

## 프로세스

### Step 1: API 사용처 분석
```dart
// lib/data/datasources/remote/ 디렉토리 스캔
// API 호출 패턴 분석
```

### Step 2: 엔드포인트 정보 수집

| 항목 | 설명 |
|------|------|
| Base URL | API 기본 URL |
| Endpoint | 엔드포인트 경로 |
| Method | HTTP 메서드 |
| Headers | 필수 헤더 |
| Request | 요청 본문 스키마 |
| Response | 응답 본문 스키마 |
| Error Codes | 에러 코드 목록 |

### Step 3: 문서 생성
파일: `docs/api/API_REFERENCE.md`

```markdown
# MindLog API Reference

## 개요
이 문서는 MindLog 앱에서 사용하는 모든 외부 API를 설명합니다.

---

## 1. Groq API (AI 분석)

### 기본 정보
| 항목 | 값 |
|------|-----|
| Base URL | `https://api.groq.com/openai/v1` |
| 인증 | Bearer Token |
| 모델 | `llama-3.3-70b-versatile` |

### Chat Completions

**Endpoint:** `POST /chat/completions`

**Headers:**
```
Authorization: Bearer {GROQ_API_KEY}
Content-Type: application/json
```

**Request Body:**
```json
{
  "model": "llama-3.3-70b-versatile",
  "messages": [
    {"role": "system", "content": "..."},
    {"role": "user", "content": "..."}
  ],
  "temperature": 0.7,
  "max_tokens": 2048
}
```

**Response:**
```json
{
  "id": "chatcmpl-xxx",
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "..."
      }
    }
  ],
  "usage": {
    "prompt_tokens": 100,
    "completion_tokens": 200,
    "total_tokens": 300
  }
}
```

**Error Codes:**
| Code | 설명 | 처리 |
|------|------|------|
| 401 | Invalid API Key | API 키 확인 |
| 429 | Rate limit exceeded | 재시도 대기 |
| 500 | Server error | 재시도 |

---

## 2. Firebase Services

### Analytics
- **용도**: 사용자 행동 추적
- **설정**: `firebase_options.dart`
- **참조**: `lib/core/services/analytics_service.dart`

### Crashlytics
- **용도**: 에러 리포팅
- **설정**: 자동 (Firebase SDK)
- **참조**: `lib/core/services/crashlytics_service.dart`

### Cloud Messaging
- **용도**: 푸시 알림
- **설정**: FCM 토큰 기반
- **참조**: `lib/core/services/fcm_service.dart`
```

## 출력 형식

```
📄 API 문서 생성 완료

✅ docs/api/API_REFERENCE.md

문서 내용:
├── Groq API
│   ├── Chat Completions endpoint
│   ├── Request/Response 스키마
│   └── Error codes
├── Firebase Analytics
│   └── 이벤트 목록 (analytics-event-add 참조)
├── Firebase Crashlytics
│   └── 에러 리포팅 메서드
└── Firebase Cloud Messaging
    └── 토큰 및 메시지 핸들링

📝 업데이트 필요 시:
   └─ /api-doc --update
```

## Groq API 상세

### 환경 설정
```dart
// lib/core/config/env_config.dart
class EnvConfig {
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );
}
```

### 빌드 시 주입
```bash
# 로컬 빌드
GROQ_API_KEY=your_key flutter run --dart-define=GROQ_API_KEY=your_key

# CI/CD
flutter build --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }}
```

### API 호출 패턴
```dart
// lib/data/datasources/remote/groq_api_service.dart
class GroqApiService {
  static const String baseUrl = 'https://api.groq.com/openai/v1';

  Future<AnalysisResult> analyzeContent(String content) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${EnvConfig.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [/* ... */],
      }),
    );
    // ...
  }
}
```

## 사용 예시

```
> "/api-doc"

AI 응답:
1. API 사용처 스캔:
   - Groq API (1개 엔드포인트)
   - Firebase Services (3개)

2. 문서 생성:
   - docs/api/API_REFERENCE.md

3. 내용:
   - Groq Chat Completions API
   - Firebase Analytics 이벤트
   - Firebase Crashlytics 메서드
   - Firebase Cloud Messaging 설정
```

## 연관 스킬
- `/analytics-event` - Firebase Analytics 이벤트 추가
- `/architecture-doc` - 전체 아키텍처 문서

## 주의사항
- API 키는 문서에 포함하지 않음
- 민감한 엔드포인트는 보안 주의 표시
- 버전 변경 시 문서 업데이트 필요
- 실제 Response 예시는 더미 데이터 사용
