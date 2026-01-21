# 기술 레퍼런스: Vision API 통합

**대상 독자**: 백엔드 엔지니어, AI/ML 엔지니어, 신입 개발자
**난이도**: 중급~고급
**마지막 업데이트**: 2026-01-21

---

## 1. Groq Vision API 기술 스펙

### 1.1 API 엔드포인트

```
프로토콜: HTTPS
URL: https://api.groq.com/openai/v1/chat/completions
메서드: POST
인증: Authorization: Bearer {GROQ_API_KEY}
```

### 1.2 요청 형식 (Vision)

```json
{
  "model": "meta-llama/llama-4-scout-17b-16e-instruct",
  "messages": [
    {
      "role": "system",
      "content": "string (시스템 프롬프트)"
    },
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "string (사용자 프롬프트)"
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "data:image/{mimeType};base64,{encodedData}"
          }
        }
      ]
    }
  ],
  "temperature": 0.7,
  "max_tokens": 1500,
  "response_format": {
    "type": "json_object"
  }
}
```

### 1.3 응답 형식

```json
{
  "id": "chatcmpl-...",
  "object": "chat.completion",
  "created": 1234567890,
  "model": "meta-llama/llama-4-scout-17b-16e-instruct",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "{...json formatted analysis result...}"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 1024,
    "completion_tokens": 256,
    "total_tokens": 1280
  }
}
```

### 1.4 HTTP 상태 코드별 처리

| 상태 코드 | 의미 | 처리 | 재시도 |
|---------|------|------|--------|
| 200 | 성공 | 응답 파싱 | X |
| 400 | 잘못된 요청 | 요청 형식 검증 | X |
| 401 | 인증 실패 | API 키 확인 | X |
| 403 | 권한 없음 | API 할당량 확인 | X |
| 429 | Rate Limit | Retry-After 헤더 준수 | O |
| 500 | 서버 오류 | 재시도 권고 | O |
| 502 | Bad Gateway | 네트워크 문제 | O |
| 503 | Service Unavailable | 서비스 점검 | O |

**Rate Limit (429) 처리**:
```dart
if (response.statusCode == 429) {
  final retryAfter = _parseRetryAfterHeader(response.headers['retry-after']);
  throw RateLimitException(
    message: '요청 제한을 초과했습니다.',
    retryAfter: retryAfter,
  );
}
```

---

## 2. Base64 Data URL 표준

### 2.1 형식

```
data:[<mediatype>][;base64],<data>
```

**구성 요소**:
- `data:` - 프리픽스 (필수)
- `<mediatype>` - MIME 타입 (필수, 예: `image/jpeg`)
- `;base64` - 인코딩 표시 (필수)
- `,<data>` - Base64 인코딩된 데이터 (필수)

### 2.2 예제

```
data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEA...
data:image/png;base64,iVBORw0KGgoAAAANSU...
data:image/webp;base64,UklGRiYAAABXRUJQ...
```

### 2.3 지원하는 MIME 타입

```dart
{
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.heic': 'image/heic',
}
```

### 2.4 인코딩 예제 (Dart)

```dart
import 'dart:convert';
import 'dart:io';

// 방법 1: 파일에서 읽어서 인코딩
final bytes = await File(imagePath).readAsBytes();
final base64String = base64Encode(bytes);
final dataUrl = 'data:image/jpeg;base64,$base64String';

// 방법 2: List<int>에서 직접 인코딩
List<int> imageBytes = [...];
final encoded = base64.encode(imageBytes);
final dataUrl = 'data:image/jpeg;base64,${String.fromCharCodes(encoded)}';

// 방법 3: 스트리밍 (대용량 이미지)
final bytes = await file.readAsBytes();  // 내부적으로 스트리밍
final encoded = base64Encode(bytes);
```

### 2.5 메모리 영향도

```
원본 이미지: 4MB
↓ (Base64 인코딩: 33% 증가)
Base64 문자열: ~5.3MB
↓ (JSON 직렬화)
최종 요청: ~5.5MB
```

**최적화 팁**:
- 이미지 5개 이상 전송 시 배치 분할 고려
- 와이파이 연결 확인 후 전송 (모바일 네트워크 절약)

---

## 3. 이미지 압축 알고리즘 상세

### 3.1 flutter_image_compress 라이브러리

```yaml
dependencies:
  flutter_image_compress: ^2.3.3
```

### 3.2 압축 메서드 시그니처

```dart
Future<XFile?> compressAndGetFile(
  String srcPath,        // 원본 이미지 경로
  String destPath,       // 압축된 이미지 저장 경로
  {
    int quality = 85,           // 0-100 (낮을수록 용량 작음)
    int minWidth = 1920,        // 최소 너비 (픽셀)
    int minHeight = 1920,       // 최소 높이 (픽셀)
    CompressFormat format = CompressFormat.jpeg,
    int rotate = 0,             // 회전 각도
  }
) -> Future<XFile?>
```

### 3.3 CompressFormat 옵션

```dart
enum CompressFormat {
  jpeg,   // 손실 압축, 가장 널리 사용, 크기 작음
  png,    // 무손실 압축, 투명도 지원, 크기 큼
  webp,   // 현대적 포맷, jpeg + png 장점, 브라우저 호환성 변함
  heic,   // iOS 기본 포맷, 크기 매우 작음, 안드로이드 호환성 낮음
}
```

### 3.4 품질 레벨별 크기 추정

```
원본 (HEIC): 3MB
↓
Quality 85 (JPEG): 800KB
Quality 70 (JPEG): 500KB
Quality 55 (JPEG): 300KB
Quality 40 (JPEG): 200KB
Quality 30 (JPEG): 150KB
```

### 3.5 너비 설정의 영향

```
minWidth = 2560 (원본 해상도 유지)
↓
minWidth = 1920 (FHD, 권장)
↓
minWidth = 1280 (HD)
↓
minWidth = 640 (mobile)
```

**권장값**: 1920px (FHD 기준, 대부분의 모바일 화면에서 충분)

---

## 4. SQLite 마이그레이션 기술

### 4.1 마이그레이션 패턴

**Before (v5)**
```sql
CREATE TABLE diaries (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  status TEXT NOT NULL,
  analysis_result TEXT,
  is_pinned INTEGER DEFAULT 0
);
```

**After (v6)**
```sql
ALTER TABLE diaries ADD COLUMN image_paths TEXT;
```

### 4.2 마이그레이션 코드

```dart
class SqliteLocalDataSource {
  static const int _currentVersion = 6;  // 버전 증가

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion
  ) async {
    // 점진적 마이그레이션 (누적 가능)
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE diaries ADD COLUMN image_paths TEXT');
    }
  }
}
```

### 4.3 하위 호환성 유지

**규칙**:
1. 기존 컬럼 절대 제거 (DROP 금지)
2. 새 컬럼은 nullable 타입 또는 DEFAULT 값 필수
3. 기존 행 데이터는 NULL 또는 DEFAULT 값으로 채워짐

**예시**:
```sql
-- Good ✅
ALTER TABLE diaries ADD COLUMN image_paths TEXT;  -- nullable
ALTER TABLE diaries ADD COLUMN created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Bad ❌
ALTER TABLE diaries DROP COLUMN analysis_result;  -- 기존 데이터 손실
ALTER TABLE diaries ADD COLUMN age INTEGER NOT NULL;  -- DEFAULT 없음
```

### 4.4 마이그레이션 검증 쿼리

```sql
-- 1. 테이블 구조 확인
PRAGMA table_info(diaries);

-- 2. 인덱스 확인
PRAGMA index_list(diaries);

-- 3. 기존 데이터 보존 확인
SELECT COUNT(*) FROM diaries;  -- 마이그레이션 전후 동일해야 함

-- 4. 새 컬럼 NULL 확인
SELECT COUNT(*) FROM diaries WHERE image_paths IS NULL;  -- 모두 NULL이어야 함
```

---

## 5. Sealed Class 에러 타입

### 5.1 Sealed Class 패턴

```dart
sealed class Failure {
  final String? message;
  const Failure({this.message});

  // 팩토리 생성자로 구체적 타입 지정
  const factory Failure.network({String? message}) = NetworkFailure;
  const factory Failure.imageProcessing({String? message}) = ImageProcessingFailure;
  // ...기타 타입들...

  String get displayMessage;
}

// 구체적 구현
class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure({super.message});

  @override
  String get displayMessage => message ?? '이미지 처리 중 오류가 발생했습니다.';
}
```

### 5.2 패턴 매칭 (Exhaustive Switch)

```dart
// Dart 3.0+ Switch Expressions with Sealed Class
String handleFailure(Failure failure) {
  return switch (failure) {
    NetworkFailure(:final message) => '네트워크: $message',
    ApiFailure(:final statusCode) => 'API 오류 ($statusCode)',
    ImageProcessingFailure(:final message) => '이미지: $message',
    SafetyBlockedFailure() => '안전상의 이유로 차단됨',
    _ => '알 수 없는 오류',
  };
}
```

### 5.3 Exception → Failure 매핑

```dart
// Exception 정의
class ImageProcessingException implements Exception {
  final String? message;
  ImageProcessingException([this.message]);
}

// FailureMapper
class FailureMapper {
  static Failure from(Object error, {String? message}) {
    if (error is ImageProcessingException) {
      return Failure.imageProcessing(
        message: _mergeMessage(error.message, message)
      );
    }
    // ...기타 타입들...
  }
}

// 사용 예
try {
  await imageService.compress(path);
} catch (e) {
  final failure = FailureMapper.from(e, message: '압축 실패');
  print(failure.displayMessage);  // "이미지: ..."
}
```

---

## 6. RFC 7231 Retry-After 헤더 파싱

### 6.1 표준 규격

**RFC 7231 Section 7.1.3**:
```
Retry-After = HTTP-date / delay-seconds

HTTP-date = <RFC 5322 datetime format>
            예: "Fri, 31 Dec 2024 23:59:59 GMT"

delay-seconds = 1*DIGIT
                예: "30", "120"
```

### 6.2 구현

```dart
Duration? _parseRetryAfterHeader(String? headerValue) {
  if (headerValue == null || headerValue.isEmpty) return null;

  // 1. 초 단위 숫자 형식 시도
  final seconds = int.tryParse(headerValue);
  if (seconds != null) {
    // 클램프: 1초 ~ 5분 (악의적 무한 대기 방지)
    final clampedSeconds = seconds.clamp(1, 300);
    return Duration(seconds: clampedSeconds);
  }

  // 2. HTTP-date 형식 시도
  try {
    final retryDate = HttpDate.parse(headerValue);
    final now = DateTime.now().toUtc();
    final difference = retryDate.difference(now);

    // 과거 날짜면 기본값 사용
    if (difference.isNegative) return _initialDelay;

    // 미래 날짜면 그 시간만큼 대기 (5분 MAX)
    if (difference.inSeconds > 300) return const Duration(minutes: 5);

    return difference;
  } catch (_) {
    // 파싱 실패면 기본값 사용
    return null;
  }
}
```

### 6.3 예제

```
서버 응답:
HTTP/1.1 429 Too Many Requests
Retry-After: 60

처리:
Duration.seconds = 60 → 60초 대기

---

서버 응답:
HTTP/1.1 429 Too Many Requests
Retry-After: Fri, 31 Dec 2024 23:59:59 GMT

처리:
HttpDate.parse() → DateTime
difference = retryDate - now
클라이언트가 자동으로 계산된 시간만큼 대기
```

### 6.4 Exponential Backoff와 결합

```dart
Future<AnalysisResponseDto> analyzeDiaryWithRetry(...) async {
  int attempt = 0;
  Duration currentDelay = const Duration(seconds: 1);

  while (attempt < 3) {
    try {
      return await _analyzeDiaryOnce(...);
    } on RateLimitException catch (e) {
      attempt++;
      if (attempt >= 3) rethrow;

      // Retry-After 헤더 우선, 없으면 exponential backoff
      final retryDelay = e.retryAfter ?? currentDelay;
      await Future.delayed(retryDelay);

      // 다음 exponential backoff 계산
      currentDelay = Duration(
        milliseconds: (currentDelay.inMilliseconds * 2.0).round()
      );
    }
  }
}
```

---

## 7. 프롬프트 엔지니어링 베스트 프랙티스

### 7.1 Vision API 지침 구조

```
[기본 지침]
- 역할/페르소나 명시
- 제약사항 명시

[이미지 분석 섹션]
- 이미지 분석 규칙
- 이미지-텍스트 종합 방법
- 주의사항

[Hallucination 방지]
- "텍스트 내용이 더 중요합니다"
- "이미지만 보고 판단하지 마세요"

[이미지 속성별 감정 힌트]
- 자연/풍경 → 평온, 휴식
- 음식 → 만족, 즐거움
- 업무/공부 → 성취, 스트레스

[출력 형식]
- JSON 구조 명시
- 각 필드 제약사항 기술
```

### 7.2 토큰 절감 팁

**Before** (불필요한 반복):
```
"반드시 JSON 형식으로만 응답하십시오.
JSON 형식으로 응답해주세요.
JSON으로 응답해주세요.
응답은 JSON이어야 합니다."
```

**After** (간결화):
```
"반드시 JSON 포맷으로만 응답하십시오."
```

**절감 효과**: ~5-10% 토큰 절감

### 7.3 Few-Shot Learning

```
[Examples]

예시 1 - 업무 스트레스:
일기: "데드라인이 내일인데 코드 리뷰가 밀려있다..."
분석:
{
  "sentiment_score": 4,
  "emotion_category": {
    "primary": "불안",
    "secondary": "시간 압박"
  },
  "action_items": [
    "🚀 심호흡 3번 하기",
    "☀️ 1시간 몰입하기",
    "📅 내일 계획 정리하기"
  ]
}
```

---

## 8. 성능 튜닝

### 8.1 병렬 이미지 처리

```dart
// 순차 처리 (현재)
Future<List<String>> encodeMultipleToBase64DataUrls(
  List<String> imagePaths,
) async {
  final dataUrls = <String>[];
  for (final imagePath in imagePaths) {
    final dataUrl = await encodeToBase64DataUrl(imagePath);
    dataUrls.add(dataUrl);
  }
  return dataUrls;
}
// 시간: O(n) - 5개 이미지 ~1-2초

// 병렬 처리 (개선)
Future<List<String>> encodeMultipleToBase64DataUrls(
  List<String> imagePaths,
) => Future.wait(
  imagePaths.map((path) => encodeToBase64DataUrl(path))
);
// 시간: O(1) - 5개 이미지 ~200-400ms (5배 빠름)
```

### 8.2 캐싱 전략

```dart
// 이미지 해시를 키로 사용한 로컬 캐시
class VisionAnalysisCache {
  final Map<String, AnalysisResponseDto> _cache = {};

  Future<AnalysisResponseDto?> getByImageHash(String imageHash) async {
    return _cache[imageHash];
  }

  Future<void> put(String imageHash, AnalysisResponseDto result) async {
    _cache[imageHash] = result;
  }

  // 이미지 배열의 해시
  String _computeImagesHash(List<String> imagePaths) {
    final combined = imagePaths.join('|');
    return sha256.convert(utf8.encode(combined)).toString();
  }
}
```

### 8.3 메모리 프로파일링

```bash
# Android
adb shell dumpsys meminfo com.example.mindlog

# 출력 예
TOTAL        5,432K
 System      1,200K
 Native      1,800K
 Dart        2,432K  <- Base64 이미지가 여기 누적
```

---

## 9. 디버깅 팁

### 9.1 Vision API 응답 로깅

```dart
// 프로덕션에서는 출력 안 함 (민감 정보 보호)
assert(() {
  debugPrint('🖼️ [DEBUG] Vision API response:');
  debugPrint(messageContent);
  return true;
}());
```

### 9.2 Base64 검증

```dart
// Base64 문자열 유효성 검사
bool isValidBase64(String? str) {
  if (str == null || str.isEmpty) return false;
  try {
    base64.decode(str);
    return true;
  } catch (_) {
    return false;
  }
}

// 사용 예
final dataUrl = 'data:image/jpeg;base64,${isValidBase64(base64String) ? base64String : 'INVALID'}';
```

### 9.3 네트워크 요청/응답 모니터링

```dart
// http.Client 확장으로 모든 요청 로깅
class LoggingHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    debugPrint('→ ${request.method} ${request.url}');
    debugPrint('  Headers: ${request.headers}');

    final response = await super.send(request);
    debugPrint('← ${response.statusCode}');

    return response;
  }
}

// GroqRemoteDataSource에 주입
final dataSource = GroqRemoteDataSource(
  apiKey,
  client: LoggingHttpClient(),
);
```

---

## 10. 트러블슈팅

### 문제: "이미지 압축 후에도 4MB 초과"

**원인**: HEIC 포맷 → JPEG 변환 시 크기 증가

**해결**:
```dart
// 품질 추가 저하
if (compressedSize > 4MB) {
  return _recompressWithLowerQuality(
    compressedFile.path,
    startQuality: 70,  // 85 → 70부터 시작
  );
}
```

### 문제: "Vision API 응답이 텍스트 분석과 다름"

**원인**: 이미지 컨텍스트로 인한 감정 분석 편향

**해결**:
```
프롬프트에 추가:
"절대 이미지만 보고 섣불리 판단하지 마세요.
텍스트 내용이 더 중요합니다."
```

### 문제: "Rate Limit 429 에러 반복 발생"

**원인**: 너무 빠른 재시도

**해결**:
```dart
// Retry-After 헤더 존중
final retryDelay = e.retryAfter ?? exponentialBackoff;
await Future.delayed(retryDelay);  // 서버 권장 시간 대기
```

---

**참고 자료**:
- RFC 7231: https://tools.ietf.org/html/rfc7231
- Base64 RFC 4648: https://tools.ietf.org/html/rfc4648
- Groq API Docs: https://console.groq.com/docs

**마지막 수정**: 2026-01-21
