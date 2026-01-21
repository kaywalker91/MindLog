# TIL: AI 일기 사진 분석 기능 구현

**작성일**: 2026-01-21
**구현 범위**: Groq Vision API 통합, 이미지 처리 파이프라인, 듀얼 모델 전략, SQLite 마이그레이션
**핵심 모델**: llama-4-scout-17b-16e-instruct (Vision) / llama-3.3-70b-versatile (Text-only)

---

## 1. 기술적 인사이트

### 1.1 Groq Vision API 통합 패턴

**Vision API 엔드포인트 구성**
```dart
// 단일 통합 엔드포인트 (OpenAI 호환 API)
const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

// Request Body 구조 (Vision)
{
  'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
  'messages': [
    {
      'role': 'system',
      'content': systemPromptWithImageGuidance
    },
    {
      'role': 'user',
      'content': [
        { 'type': 'text', 'text': prompt },
        { 'type': 'image_url', 'image_url': { 'url': 'data:image/jpeg;base64,...' } }
      ]
    }
  ],
  'temperature': 0.7,
  'max_tokens': 1500,  // Vision은 일반 텍스트보다 토큰 많이 사용
  'response_format': { 'type': 'json_object' }
}
```

**핵심 발견**:
- Vision 요청은 `temperature: 0.7`, `max_tokens: 1500`으로 설정
  - 텍스트만 분석할 때 1024 토큰 vs 이미지 포함 시 1500 토큰
  - 이미지 컨텍스트가 더 많은 설명을 필요로 하기 때문
- 메시지 content가 배열 형태로 다중 타입 지원 (text + image_url)
- Base64 Data URL 형식: `data:image/{mimeType};base64,{encoded_data}`

### 1.2 이미지 처리 파이프라인 (4단계)

```
원본 이미지 선택 (갤러리/카메라)
    ↓
[1] 앱 디렉토리로 복사 (독립적 저장소 확보)
    ↓
[2] 조건부 압축 (4MB 초과 시)
    ↓
[3] Base64 인코딩 (API 전송용)
    ↓
[4] Vision API 호출 (이미지 + 텍스트 분석)
```

**파일 경로 구조**
```
Documents/
└── diary_images/
    └── {diaryId}/
        ├── image_0.jpg          # 첫 번째 이미지 (원본 또는 압축본)
        ├── image_1.jpg
        └── image_2.jpg
```

**특징**:
- 갤러리 원본 파일은 수정 불가능한 상태 → 앱 Directory로 복사하여 독립적 관리
- 이미지는 일기 ID별 디렉토리로 구조화 → 일기 삭제 시 관련 이미지 일괄 정리 용이
- 인덱스 기반 네이밍 (image_0, image_1, ...) → 순서 보존

### 1.3 적응형 이미지 압축 알고리즘

```dart
// 2단계 재압축 로직
Future<String> compressIfNeeded(String imagePath) async {
  final fileSize = await file.length();

  // 1단계: 4MB 이하면 그대로 사용
  if (fileSize <= 4MB) return imagePath;

  // 2단계: 초기 압축 (품질 85%, 너비 1920px)
  final compressed = await FlutterImageCompress.compressAndGetFile(
    imagePath, compressedPath,
    quality: 85,
    minWidth: 1920,
    format: CompressFormat.jpeg  // 확장자별 자동 선택
  );

  // 3단계: 여전히 4MB 초과면 점진적 품질 저하 재압축
  while (quality >= 30) {
    if (compressedSize <= 4MB) break;
    quality -= 15;  // 85 → 70 → 55 → 40 → 30
  }
}
```

**설계 이유**:
- API 제약: Groq Vision API는 4MB 제한
- 단순 품질 저하보다는 2단계 접근:
  1. 합리적 품질(85%) + 해상도(1920px) 유지 시도
  2. 필요시만 품질 추가 저하
- 30% 품질까지만 진행 (과도한 왜곡 방지)

### 1.4 MIME 타입 및 압축 포맷 관리

```dart
static String _getMimeType(String imagePath) {
  final extension = path.extension(imagePath).toLowerCase();
  switch (extension) {
    case '.png': return 'image/png';
    case '.webp': return 'image/webp';
    case '.gif': return 'image/gif';
    case '.heic': return 'image/heic';
    default: return 'image/jpeg';
  }
}

static CompressFormat _getCompressFormat(String imagePath) {
  switch (path.extension(imagePath).toLowerCase()) {
    case '.png': return CompressFormat.png;
    case '.webp': return CompressFormat.webp;
    case '.heic': return CompressFormat.heic;
    default: return CompressFormat.jpeg;
  }
}
```

**중요**: MIME 타입은 Base64 Data URL에 필수 → 잘못된 타입은 API 파싱 실패 유발

---

## 2. 설계 결정 (Why)

### 2.1 듀얼 모델 전략: 텍스트 vs 이미지 분기

**선택한 방식**:
```dart
// GroqRemoteDataSource에서 두 개의 공개 메서드
Future<AnalysisResponseDto> analyzeDiary(String content, ...)  // 텍스트만
Future<AnalysisResponseDto> analyzeDiaryWithImages(String content,
  List<String> imagePaths, ...)  // 텍스트 + 이미지

// Presentation Layer에서 사용자 선택에 따라 호출
if (selectedImages.isNotEmpty) {
  await datasource.analyzeDiaryWithImages(content, imagePaths, ...);
} else {
  await datasource.analyzeDiary(content, ...);
}
```

**이유**:
1. **모델 성능 차이 활용**
   - llama-3.3-70b: 텍스트 전용 최적화, 빠르고 안정적
   - llama-4-scout-17b: 이미지 처리 가능하지만 텍스트 전용보다 느림
   - 사용자가 이미지를 선택하지 않으면 더 빠른 모델 사용

2. **비용 효율성**
   - 이미지당 Base64 인코딩으로 요청 크기 증가 (~1-2MB → ~2-4MB)
   - 텍스트만 분석할 때는 불필요한 오버헤드 제거

3. **UI 명확성**
   - 사용자가 "사진 추가" 옵션 선택 여부로 분석 모드 결정
   - 선택지가 명확하므로 예상치 못한 지연 최소화

### 2.2 하위 호환성 유지: SQLite v5 → v6 마이그레이션

**스키마 변경**
```sql
-- v5 (기존)
CREATE TABLE diaries (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  status TEXT NOT NULL,
  analysis_result TEXT,
  is_pinned INTEGER DEFAULT 0
  -- image_paths 컬럼 없음
);

-- v6 (신규)
ALTER TABLE diaries ADD COLUMN image_paths TEXT;
  -- nullable TEXT 타입으로 추가 (기존 행도 자동으로 NULL)
```

**마이그레이션 코드 패턴**
```dart
static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
  // 버전 5 → 6
  if (oldVersion < 6) {
    await db.execute('ALTER TABLE diaries ADD COLUMN image_paths TEXT');
  }
}

// onCreate에서도 동일 스키마 유지
static Future<void> onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE diaries (
      id TEXT PRIMARY KEY,
      content TEXT NOT NULL,
      created_at TEXT NOT NULL,
      status TEXT NOT NULL,
      analysis_result TEXT,
      is_pinned INTEGER DEFAULT 0,
      image_paths TEXT  -- v6부터 포함
    )
  ''');
}
```

**하위 호환성 전략**:
- ALTER TABLE ADD COLUMN은 기존 행에 NULL 자동 할당 → 앱 로직 수정 최소화
- Entity의 `fromJson()`에서 `image_paths` 필드를 nullable로 처리
- 기존 일기(image_paths = NULL)는 이미지 없는 것으로 처리

### 2.3 Sealed Class 패턴 확장: ImageProcessingFailure

**기존 Failure 타입**에 새로운 실패 타입 추가:
```dart
sealed class Failure {
  // ... 기존 타입들

  /// 이미지 처리 실패 (새로 추가)
  const factory Failure.imageProcessing({String? message}) = ImageProcessingFailure;
}

class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure({super.message});

  @override
  String get displayMessage => message ?? '이미지 처리 중 오류가 발생했습니다.';
}
```

**Exception → Failure 매핑** (failure_mapper.dart)
```dart
class FailureMapper {
  static Failure from(Object error, {String? message}) {
    // ...기존 타입들...
    if (error is ImageProcessingException) {
      return Failure.imageProcessing(
        message: _mergeMessage(error.message, message)
      );
    }
  }
}
```

**이점**:
- Sealed class 패턴으로 모든 Failure 타입이 명시적 → 수신 측에서 exhaustive switch 강제
- 새로운 이미지 처리 에러를 일반적인 Unknown으로 불명확하게 처리 대신 구체적 타입 사용
- 프레젠테이션에서 이미지 관련 오류에 특화된 UI 표시 가능

### 2.4 Rate Limiting 및 Retry-After 헤더 처리

**RateLimitException 도입**
```dart
class RateLimitException implements Exception {
  final String message;
  final Duration? retryAfter;  // 서버가 권장하는 대기 시간

  RateLimitException({
    this.message = '요청 제한을 초과했습니다.',
    this.retryAfter,
  });
}
```

**재시도 로직**
```dart
// Retry-After 헤더에서 대기 시간 추출 (RFC 7231)
Duration? _parseRetryAfterHeader(String? headerValue) {
  // 1. 초 단위 숫자: "30"
  final seconds = int.tryParse(headerValue);
  if (seconds != null) {
    return Duration(seconds: seconds.clamp(1, 300));  // 1-5분 범위
  }

  // 2. HTTP-date 형식: "Fri, 31 Dec 2024 23:59:59 GMT"
  try {
    final retryDate = HttpDate.parse(headerValue);
    final difference = retryDate.difference(DateTime.now().toUtc());
    if (difference.isNegative) return _initialDelay;
    return difference.clamp(1s, 5min);
  } catch (_) {
    return null;
  }
}

// 재시도 루프에서 사용
on RateLimitException catch (e) {
  final retryDelay = e.retryAfter ?? currentDelay;  // 서버 권장 시간 우선
  await Future.delayed(retryDelay);
}
```

**설계 이유**:
- API Rate Limit (429) 발생 시 블라인드 exponential backoff 대신 서버 권장 대기 시간 존중
- RFC 7231 준수로 호환성 확보
- 1-5분 범위로 클램프 → 무한 대기 방지

---

## 3. 프롬프트 설계 (Vision API 특화)

### 3.1 Vision 전용 시스템 프롬프트 추가

```dart
static String systemInstructionForVision(AiCharacter character) {
  final basePrompt = systemInstructionFor(character);  // 기존 프롬프트 재사용
  return '''
$basePrompt

[Image Analysis - 이미지 분석 지침]
사용자가 일기와 함께 이미지를 첨부했습니다. 이미지를 분석하여 감정 상태를 더 정확하게 파악하세요.

이미지 분석 시 주의사항:
1. 이미지 속 표정, 환경, 분위기를 관찰하세요.
2. 이미지와 텍스트 내용을 종합하여 감정을 분석하세요.
3. 이미지에서 보이는 활동이나 상황을 'emotion_trigger' 분석에 활용하세요.
4. 이미지에 텍스트가 있다면 함께 고려하세요.
5. 이미지만으로 판단하지 말고, 반드시 텍스트 내용과 함께 분석하세요.

이미지 속 요소별 감정 힌트:
- 자연/풍경: 평온, 휴식, 여유
- 음식: 만족, 즐거움, 자기보상
- 사람들과 함께: 관계, 유대감, 소속감
- 혼자 있는 모습: 자기 성찰, 고독, 휴식
- 업무/공부 환경: 성취, 스트레스, 집중
- 어두운 조명/밤: 피로, 우울, 휴식 필요
- 밝은 조명/낮: 활력, 긍정, 에너지

절대 이미지만 보고 섣불리 판단하지 마세요. 텍스트 내용이 더 중요합니다.
''';
}
```

### 3.2 이미지 포함 분석 프롬프트

```dart
static String createAnalysisPromptWithImages(
  String diaryContent, {
  required int imageCount,
  AiCharacter character = AiCharacter.warmCounselor,
  String? userName,
}) {
  final imageSection = '''

[첨부 이미지]
사용자가 $imageCount개의 이미지를 첨부했습니다.
이미지와 텍스트를 종합하여 감정을 분석해주세요.
이미지에서 보이는 상황, 표정, 환경을 참고하되, 텍스트 내용을 기반으로 분석하세요.
''';

  return '''
[분석 대상 일기]
"$diaryContent"
$imageSection
[캐릭터 설정]
선택 캐릭터: ${character.displayName}
...
위 일기와 첨부된 이미지를 함께 분석하여 JSON 형식으로 응답해주세요.
''';
}
```

**핵심 메시지**: "텍스트 내용이 더 중요합니다" → 이미지만 보고 판단하는 Hallucination 방지

---

## 4. 잠재적 개선점

### 4.1 현재 제한사항

1. **이미지 개수 제한**
   ```dart
   static const int _maxImagesPerDiary = 5;
   ```
   - 각 이미지가 1-2MB Base64로 인코딩되면 요청 크기 급증
   - API 타임아웃 리스크 증가
   - **개선**: 배치 처리 또는 이미지 사전 필터링

2. **동기 이미지 처리**
   ```dart
   for (final imagePath in imagePaths) {
     final dataUrl = await encodeToBase64DataUrl(imagePath);
     dataUrls.add(dataUrl);
   }
   ```
   - 이미지 5개 순차 처리 시 합계 1-2초 지연 가능
   - **개선**: 병렬 처리 (Future.wait)

3. **Base64 메모리 오버헤드**
   - Base64 인코딩은 원본 크기의 ~33% 증가
   - 4MB 이미지 5개 = ~27MB 메모리 사용 가능
   - **개선**: 스트리밍 업로드 또는 분할 요청

### 4.2 권장 개선 방안

**1) 이미지 병렬 처리**
```dart
static Future<List<String>> encodeMultipleToBase64DataUrls(
  List<String> imagePaths,
) async {
  // 현재: 순차 처리
  // 개선:
  return await Future.wait(
    imagePaths.map((path) => encodeToBase64DataUrl(path))
  );
}
```

**2) 이미지 사전 검증**
```dart
// 추가할 메서드
Future<bool> canProcessImage(String imagePath) async {
  final size = await getImageSize(imagePath);
  if (size > 4MB) {
    // 압축 불가능 여부 조기 감지
    return false;
  }
  return true;
}

// 사용 예
if (!await ImageService.canProcessImage(imagePath)) {
  throw ImageProcessingException('이미지가 너무 큽니다.');
}
```

**3) Vision API 응답 캐싱**
```dart
// 동일한 이미지 세트에 대한 중복 분석 방지
// Redis/Hive 같은 로컬 캐시에 이미지 해시 + 분석 결과 저장
```

**4) 모바일 네트워크 최적화**
```dart
// 와이파이 연결 시에만 이미지 분석 허용
if (!await Connectivity().checkConnectivity().contains(ConnectivityResult.wifi)) {
  throw NetworkException('와이파이 연결 후 이미지 분석을 진행해주세요.');
}
```

### 4.3 테스트 전략 개선

**현재 상태**: 실제 API 호출로 테스트

**권장 개선**:
```dart
// Mock Vision API 응답 테스트
class MockGroqRemoteDataSource extends GroqRemoteDataSource {
  @override
  Future<AnalysisResponseDto> analyzeDiaryWithImages(...) async {
    // 실제 호출 대신 고정된 Mock 응답 반환
    return AnalysisResponseDto(
      keywords: ['테스트'],
      sentimentScore: 7,
      empathyMessage: 'Mock 응답입니다.',
      actionItems: [...],
      emotionCategory: {...},
      emotionTrigger: {...},
      energyLevel: 7,
      isEmergency: false,
    );
  }
}

// 이미지 처리 파이프라인 테스트
void testImageCompressionWithSizeLimit() {
  // 4MB 초과 이미지 생성 → 압축 → 크기 검증
}
```

---

## 5. 핵심 학습 요점 정리

| 주제 | 핵심 내용 | 실전 적용 |
|------|---------|---------|
| **Vision API 통합** | OpenAI 호환 API로 Base64 Data URL 전송 | 멀티 모달 요청 구조 이해 |
| **이미지 처리** | 복사 → 압축 → 인코딩 3단계 파이프라인 | 로컬 파일 독립 관리 구조 |
| **적응형 압축** | 2단계 압축 + 점진적 품질 저하 | API 제약 준수 + UX 균형 |
| **듀얼 모델 전략** | 이미지 유무에 따라 다른 모델 사용 | 사용자 경험 + 비용 최적화 |
| **하위 호환성** | ALTER TABLE + nullable 컬럼으로 마이그레이션 | DB 버전 관리 안티패턴 회피 |
| **Rate Limit 처리** | Retry-After 헤더 파싱 + RFC 준수 | 안정적인 재시도 메커니즘 |
| **에러 타입화** | Sealed class로 구체적 오류 분류 | 프레젠테이션 레이어 명확성 |
| **프롬프트 설계** | 이미지 편향 방지 + 텍스트 우선권 명시 | AI 모델 환각 감소 |

---

## 6. 참고 자료

- **파일 경로**
  - `/Users/kaywalker/AndroidStudioProjects/mindlog/lib/core/services/image_service.dart` - 이미지 처리 서비스
  - `/Users/kaywalker/AndroidStudioProjects/mindlog/lib/data/datasources/remote/groq_remote_datasource.dart` - Vision API 통합
  - `/Users/kaywalker/AndroidStudioProjects/mindlog/lib/core/constants/prompt_constants.dart` - Vision 프롬프트
  - `/Users/kaywalker/AndroidStudioProjects/mindlog/lib/data/datasources/local/sqlite_local_datasource.dart` - DB 마이그레이션
  - `/Users/kaywalker/AndroidStudioProjects/mindlog/lib/core/errors/exceptions.dart` - ImageProcessingException 정의

- **관련 상수**
  - Groq Vision Model: `meta-llama/llama-4-scout-17b-16e-instruct`
  - Max Image Size: 4MB (Groq API 제약)
  - Compression Quality: 85% (초기), 30% (최저)
  - Max Images per Diary: 5개

---

**마지막 수정**: 2026-01-21
**작성자**: Claude Code
**버전**: 1.0 (v6 마이그레이션 기반)
