# TIL 색인: AI 일기 사진 분석 기능

**생성일**: 2026-01-21
**주제**: Groq Vision API 통합 학습 자료
**총 4개 문서 / ~12,000 단어**

---

## 📚 문서 구조

```
docs/til/
├── INDEX.md (이 문서)
├── AI_DIARY_IMAGE_ANALYSIS_TIL.md      [메인 학습 문서]
├── IMPLEMENTATION_CHECKLIST.md         [구현 체크리스트 & 회고]
├── TECHNICAL_REFERENCE.md              [기술 레퍼런스]
└── ANDROID_PHOTO_PICKER_POLICY_TIL.md  [Google Play 정책 대응]
```

---

## 1️⃣ AI_DIARY_IMAGE_ANALYSIS_TIL.md

**길이**: ~4,000 단어
**난이도**: 중급
**소요 시간**: 20-30분

### 주요 내용

**1장. 기술적 인사이트** (1,200 단어)
- Groq Vision API 엔드포인트 구성
- 이미지 처리 4단계 파이프라인
- 적응형 이미지 압축 알고리즘 (2단계)
- MIME 타입 및 압축 포맷 관리

**2장. 설계 결정** (1,500 단어)
- 듀얼 모델 전략 (텍스트 vs 이미지 분기)
- SQLite 마이그레이션 (v5 → v6)
- Sealed Class 패턴 확장
- Rate Limiting & Retry-After 처리

**3장. 프롬프트 설계** (800 단어)
- Vision 전용 시스템 프롬프트
- 이미지 포함 분석 프롬프트
- Hallucination 방지 지침

**4장. 잠재적 개선점** (500 단어)
- 현재 제한사항 (이미지 개수, 동기 처리, 메모리)
- 권장 개선 방안 (병렬 처리, 캐싱, 네트워크 최적화)
- 테스트 전략 개선

### 대상 독자
- 이미지 기반 AI 기능을 구현하려는 개발자
- Vision API 통합 경험이 없는 신입
- API 설계 패턴을 학습하려는 사람

### 빠른 네비게이션
```
핵심만 읽기: 1.1, 1.2, 2.1, 2.2 섹션 (10분)
완전 이해: 전체 (30분)
참고용: 4.2, 4.3 섹션 (5분)
```

---

## 2️⃣ IMPLEMENTATION_CHECKLIST.md

**길이**: ~3,500 단어
**난이도**: 초급~중급
**소요 시간**: 15-20분

### 주요 내용

**구현 완료 항목** (1,000 단어)
- ImageService 메서드 목록 (7개)
- GroqRemoteDataSource Vision 메서드 (5개)
- Rate Limiting & Retry (3개)
- 에러 처리 (3개)
- 데이터베이스 마이그레이션 (2개)
- 설정 및 상수 (6개)
- 통합 및 테스트 인프라 (2개)

**아키텍처 검증** (700 단어)
- Clean Architecture 계층 구조
- Exception → Failure 매핑 파이프라인
- 코드 품질 검사 (메모리, 보안, 성능)
- 테스트 가능성 검증

**호환성 검사** (500 단어)
- 기존 코드 영향도
- 하위 호환성
- 플랫폼 호환성

**배포 및 회고** (800 단어)
- 빌드 전 체크리스트
- 배포 후 모니터링
- 다음 단계 (P0~P2 개선사항)
- 회고 (잘한 점, 개선할 점, 배운 교훈)

### 대상 독자
- 프로젝트 매니저 (진행 상황 추적)
- QA 엔지니어 (테스트 체크리스트)
- 신규 팀원 (구현 범위 이해)
- 코드 리뷰어 (완성도 검증)

### 빠른 네비게이션
```
체크리스트만: 구현 완료 항목 섹션 (5분)
리뷰 전: 아키텍처 검증 + 호환성 검사 (10분)
배포 전: 배포 체크리스트 섹션 (3분)
회고: 마지막 섹션 (5분)
```

---

## 3️⃣ TECHNICAL_REFERENCE.md

**길이**: ~3,500 단어
**난이도**: 중급~고급
**소요 시간**: 30-45분 (필요시 참고)

### 주요 내용

**1장. Groq Vision API 스펙** (800 단어)
- API 엔드포인트
- 요청/응답 형식 (JSON 구조 상세)
- HTTP 상태 코드별 처리
- Rate Limit 처리

**2장. Base64 Data URL 표준** (600 단어)
- RFC 표준 형식
- 지원 MIME 타입
- 인코딩 예제 (Dart)
- 메모리 영향도

**3장. 이미지 압축 알고리즘** (700 단어)
- flutter_image_compress 라이브러리
- 메서드 시그니처
- CompressFormat 옵션
- 품질/너비 설정

**4장. SQLite 마이그레이션** (600 단어)
- 마이그레이션 패턴
- 코드 예제
- 하위 호환성 규칙
- 검증 쿼리

**5장. Sealed Class 에러 타입** (500 단어)
- Sealed class 패턴
- Pattern matching (Exhaustive switch)
- Exception → Failure 매핑

**6장. RFC 7231 Retry-After 파싱** (500 단어)
- 표준 규격
- 구현 예제
- 예제 시나리오
- Exponential backoff 결합

**7장. 프롬프트 엔지니어링** (400 단어)
- Vision API 지침 구조
- 토큰 절감 팁
- Few-shot learning

**8-10장. 성능/디버깅/트러블슈팅** (800 단어)
- 병렬 처리 최적화
- 캐싱 전략
- 디버깅 팁
- 일반적인 문제 해결

### 대상 독자
- 백엔드 엔지니어 (상세한 기술 스펙 필요)
- 성능 최적화 담당자
- API 통합 엔지니어
- 경험 많은 개발자

### 빠른 네비게이션
```
API 스펙만: 1장 (10분)
이미지 처리: 2, 3장 (15분)
DB 마이그레이션: 4장 (10분)
에러 처리: 5장 (10분)
성능 튜닝: 8장 (10분)
문제 해결: 10장 (필요시 참고)
```

---

## 4️⃣ ANDROID_PHOTO_PICKER_POLICY_TIL.md

**길이**: ~2,000 단어
**난이도**: 중급
**소요 시간**: 15-20분

### 주요 내용

**1장. 문제** (600 단어)
- Google Play Photo/Video Permissions 정책 (2024-2025)
- READ_MEDIA_IMAGES 권한 사용 제한
- Android 버전별 갤러리 접근 방식

**2장. 해결책** (800 단어)
- Android Photo Picker API 특징
- image_picker Flutter 패키지 내부 동작
- 하이브리드 권한 전략 (maxSdkVersion 활용)
- 버전별 동작 매트릭스

**3장. 핵심 교훈** (400 단어)
- 정책 우선 설계 (Policy-First Design)
- 플랫폼 API 진화 추적
- 패키지 버전 차이 인식
- 권한 최소화 원칙

**4장. 구현 체크리스트** (200 단어)
- AndroidManifest.xml 검증
- 패키지 버전 확인
- 테스트 매트릭스

### 대상 독자
- Google Play 출시를 준비하는 Flutter 개발자
- Android 권한 정책에 대한 이해가 필요한 개발자
- 사진/갤러리 기능을 구현하는 앱 개발자

### 빠른 네비게이션
```
문제만 이해: 1장 (5분)
해결책 적용: 2장 (10분)
핵심 교훈: 3장 (5분)
체크리스트: 4장 (3분)
```

---

## 🎯 사용 시나리오별 가이드

### 시나리오 1: "Vision API가 뭔가요?"
**추천**: AI_DIARY_IMAGE_ANALYSIS_TIL.md 섹션 1.1
**소요시간**: 5분
**내용**: API 엔드포인트 구성, 요청/응답 구조

### 시나리오 2: "이미지 처리 파이프라인을 설명해주세요"
**추천**: AI_DIARY_IMAGE_ANALYSIS_TIL.md 섹션 1.2 + TECHNICAL_REFERENCE.md 섹션 3
**소요시간**: 15분
**내용**: 복사 → 압축 → 인코딩 단계, 압축 알고리즘 상세

### 시나리오 3: "왜 텍스트와 이미지를 분리했나요?"
**추천**: AI_DIARY_IMAGE_ANALYSIS_TIL.md 섹션 2.1
**소요시간**: 10분
**내용**: 듀얼 모델 전략, 성능/비용 트레이드오프

### 시나리오 4: "기존 일기 데이터가 보존되나요?"
**추천**: AI_DIARY_IMAGE_ANALYSIS_TIL.md 섹션 2.2 + IMPLEMENTATION_CHECKLIST.md 호환성 검사
**소요시간**: 10분
**내용**: SQLite 마이그레이션, 하위 호환성 보장

### 시나리오 5: "4MB 초과 이미지는 어떻게 처리하나요?"
**추천**: TECHNICAL_REFERENCE.md 섹션 3 + 트러블슈팅 섹션
**소요시간**: 10분
**내용**: 적응형 압축, 문제 해결

### 시나리오 6: "Rate Limit이 발생했을 때는?"
**추천**: TECHNICAL_REFERENCE.md 섹션 6
**소요시간**: 10분
**내용**: Retry-After 헤더 파싱, RFC 표준

### 시나리오 7: "배포 전 마지막 체크리스트"
**추천**: IMPLEMENTATION_CHECKLIST.md 배포 체크리스트
**소요시간**: 5-10분
**내용**: 빌드, 테스트, 모니터링

### 시나리오 8: "왜 이렇게 설계했나요? (설계 리뷰)"
**추천**: AI_DIARY_IMAGE_ANALYSIS_TIL.md 전체 + IMPLEMENTATION_CHECKLIST.md 회고
**소요시간**: 45분
**내용**: 기술 인사이트 + 설계 결정 + 회고

### 시나리오 9: "Google Play에서 권한 정책 위반 경고를 받았어요"
**추천**: ANDROID_PHOTO_PICKER_POLICY_TIL.md
**소요시간**: 15분
**내용**: Photo Picker API, 권한 전략, maxSdkVersion 활용

### 시나리오 10: "READ_MEDIA_IMAGES 없이 갤러리 접근이 가능한가요?"
**추천**: ANDROID_PHOTO_PICKER_POLICY_TIL.md 섹션 2
**소요시간**: 10분
**내용**: Photo Picker 특징, image_picker 패키지 동작

---

## 📊 문서 통계

| 항목 | 값 |
|------|-----|
| 총 단어 수 | ~12,500 |
| 총 섹션 | 30+ |
| 코드 예제 | 50+ |
| 다이어그램 | 8+ |
| 표 | 15+ |
| 생성 시간 | 2026-01-21 |

---

## 🔗 외부 참고 자료

### RFC 표준
- [RFC 7231 (HTTP/1.1 Semantics - Retry-After)](https://tools.ietf.org/html/rfc7231#section-7.1.3)
- [RFC 4648 (Base64 Data Encodings)](https://tools.ietf.org/html/rfc4648)
- [RFC 2045 (MIME Part One - Format of Internet Message Bodies)](https://tools.ietf.org/html/rfc2045)

### API 문서
- [Groq API Documentation](https://console.groq.com/docs)
- [OpenAI Chat Completion API (호환 스펙)](https://platform.openai.com/docs/api-reference/chat/create)

### 라이브러리
- [flutter_image_compress 패키지](https://pub.dev/packages/flutter_image_compress)
- [sqflite 패키지](https://pub.dev/packages/sqflite)
- [http 패키지](https://pub.dev/packages/http)

### Dart 문서
- [Sealed Classes (Dart 3.0)](https://dart.dev/language/class-modifiers#sealed)
- [Base64 Encoding](https://api.dart.dev/stable/dart-convert/base64.html)
- [HttpDate Parsing](https://api.dart.dev/stable/dart-io/HttpDate-class.html)

---

## 📝 버전 히스토리

| 버전 | 날짜 | 변경사항 |
|------|------|---------|
| 1.0 | 2026-01-21 | 초기 생성 (3개 문서) |
| 1.1 | 2026-01-21 | Android Photo Picker 정책 TIL 추가 (4개 문서) |

---

## ✅ 품질 체크

- [x] 기술 정확성 검증 (코드 리뷰 완료)
- [x] 일관된 용어 사용
- [x] 예제 코드 테스트 (프로덕션 코드 기반)
- [x] 한국어 문법 검수
- [x] 링크 유효성 검증
- [x] 마크다운 형식 준수
- [x] 접근성 고려 (목차, 색인, 네비게이션)

---

## 💬 피드백 및 제안

**문서를 읽은 후 느낀 점**:
- 부족한 부분: 이슈 등록
- 오류 발견: 수정 요청
- 개선 제안: 토론

**예상 FAQ**:
1. "웹 기반 프론트엔드도 지원하나요?" → 현재 미지원 (이미지 처리 관련 네이티브 라이브러리 미사용)
2. "대량의 이미지를 처리할 수 있나요?" → 5개까지 권장 (배치 분할 고려 필요)
3. "오프라인에서 사용 가능한가요?" → 아니오, API 호출 필수

---

**다음 업데이트 예정**: 사용자 피드백 반영 후 Q1 2026
**담당자**: Claude Code
**최종 검수**: 2026-01-21
