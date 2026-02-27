# TIL 색인: AI 일기 사진 분석 기능

**생성일**: 2026-01-21
**주제**: Groq Vision API 통합 학습 자료
**총 13개 문서 / ~19,500 단어**

---

## 📚 문서 구조

```
docs/til/
├── INDEX.md (이 문서)
├── AI_DIARY_IMAGE_ANALYSIS_TIL.md      [메인 학습 문서]
├── IMPLEMENTATION_CHECKLIST.md         [구현 체크리스트 & 회고]
├── TECHNICAL_REFERENCE.md              [기술 레퍼런스]
├── ANDROID_PHOTO_PICKER_POLICY_TIL.md  [Google Play 정책 대응]
├── CLEAN_ARCHITECTURE_VIOLATION_FIX_TIL.md [아키텍처 위반 수정]
├── FCM_IDEMPOTENCY_LOCK.md             [FCM 중복 발송 방지 Pre-lock 패턴]
├── FIREBASE_CLI_EXTENSIONS_BUG.md      [Firebase CLI Extensions API 403 버그 패치]
├── FLUTTER_TESTING_STATIC_OVERRIDE_PATTERN_TIL.md [플랫폼 서비스 정적 오버라이드 패턴]
├── TROUBLESHOOTING_SYSTEM_CLASSIFICATION_TIL.md [3-System 지식 분류 프레임워크]
├── COLOR_SYSTEM.md                              [MindLog 컬러 시스템 4-팔레트 레퍼런스]
├── A11Y_THEME_AWARE_COLOR_MIGRATION_PATTERN_TIL.md [접근성 theme-aware 색상 마이그레이션]
├── MEMORY_ARCHIVING_LIFECYCLE_TIL.md [메모리 7레이어 아카이빙 수명주기]
└── SESSION_WRAP_PROCESS_AUDIT_TIL.md [멀티 문서 동기화 갭 분석 방법론]
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

## 5️⃣ CLEAN_ARCHITECTURE_VIOLATION_FIX_TIL.md

**길이**: ~800 단어
**난이도**: 중급
**소요 시간**: 10분

### 주요 내용

**1장. 문제 상황**
- presentation → data 직접 import (P0 위반)
- 의존성 역전(DIP) 위반의 영향

**2장. 해결 전략**
- Repository 인터페이스 확장
- 구현체에 메서드 추가
- Provider DI 변경

**3장. 검증 방법**
- grep 기반 위반 검사
- 테스트 및 정적 분석

**4장. 핵심 교훈**
- Do/Don't 체크리스트
- 점진적 수정 전략

### 대상 독자
- Clean Architecture를 적용하는 Flutter 개발자
- 레이어 간 의존성 위반을 수정해야 하는 개발자
- 리팩토링 전략을 배우려는 개발자

### 빠른 네비게이션
```
문제 이해: 1장 (3분)
해결 적용: 2장 (5분)
검증: 3장 (2분)
```

---

## 7️⃣ FIREBASE_CLI_EXTENSIONS_BUG.md

**길이**: ~600 단어
**난이도**: 중급~고급
**소요 시간**: 10분

### 주요 내용

**문제** (150 단어)
- Firebase CLI 14.x (v13 포함): `--only functions`임에도 Extensions API 항상 호출
- IAM 권한과 독립적인 서비스 레벨 제한으로 403 반환
- `--except extensions`, `firebase.json` 설정 모두 우회 불가

**시도한 방법들** (100 단어)
- `--only functions`, `--except extensions`, `"extensions": {}` 모두 실패

**작동하는 해결책** (200 단어)
- `planner.js`의 `haveDynamic()` + `have()` 함수를 `return []`로 패치
- 패치 위치: `/opt/homebrew/lib/node_modules/firebase-tools/lib/deploy/extensions/planner.js`
- brew upgrade 시 원복 주의

**재적용 체크리스트** (100 단어)
- 업그레이드 후 재패치 절차 5단계

**핵심 교훈** (50 단어)
- IAM testIamPermissions 통과 != 실제 API 접근 가능
- CLI --only 플래그가 내부 모든 호출을 차단하지 않음

### 대상 독자
- Firebase Functions 배포 시 403 에러를 마주친 개발자
- `firebase-tools` CLI 내부 동작을 이해하려는 개발자

### 빠른 네비게이션
```
문제 파악: 문제 섹션 (3분)
해결 적용: 패치 내용 섹션 (5분)
재적용: 체크리스트 섹션 (2분)
```

---

## 6️⃣ FCM_IDEMPOTENCY_LOCK.md

**길이**: ~1,500 단어
**난이도**: 중급~고급
**소요 시간**: 15-20분

### 주요 내용

**1장. 문제** (300 단어)
- Firebase Functions retry + Firestore 부분 실패 → FCM 3회 중복 발송
- check-send-mark 패턴의 구조적 한계

**2장. 핵심 학습** (700 단어)
- Firestore `create()` 원자적 잠금 (vs `set()`)
- fail-open vs fail-safe 전략 비교
- iOS APNS alert vs background payload 차이
- lock-send-complete/release 패턴

**3장. 코드 패턴** (300 단어)
- Pre-lock 패턴 TypeScript 구현
- iOS data-only payload 구조

**4장. 교훈** (200 단어)
- 분산 시스템 멱등성 설계 원칙
- 알림 시스템의 fail-safe 원칙

### 대상 독자
- Firebase Functions + FCM 알림을 구현하는 개발자
- 분산 시스템 멱등성 패턴을 학습하려는 개발자
- iOS APNS payload 구조를 이해하려는 Flutter 개발자

### 빠른 네비게이션
```
문제만 이해: 문제 섹션 (3분)
핵심 패턴: 핵심 학습 1, 4 (10분)
iOS 이해: 핵심 학습 3 (5분)
코드 적용: 코드 패턴 섹션 (5분)
```

---

## 8️⃣ FLUTTER_TESTING_STATIC_OVERRIDE_PATTERN_TIL.md

**길이**: ~600 단어
**난이도**: 중급
**소요 시간**: 10분

### 주요 내용

**1장. 문제: CI 로그 노이즈 (Side Effect Leakage)**
- `LateInitializationError`, `UnknownFailure` 로그가 CI에 반복 출력 (테스트는 통과)
- 위젯 탭 → Controller → UseCase → 실제 플랫폼 서비스 체인 호출

**2장. 해결책: `@visibleForTesting static Function? override` 패턴**
- `EmotionTrendNotificationService` (1개 오버라이드)
- `NotificationSettingsService` (9개 오버라이드)
- setUp/tearDown에서 `resetForTesting()` 필수

**3장. 핵심 교훈**
- 로그 노이즈도 실패다
- `resetForTesting()`은 반드시 tearDown에 (leak 방지)
- 스택 트레이스 전체 추적 (표면 메시지 아닌 원인)

### 대상 독자
- 플랫폼 서비스를 사용하는 위젯 테스트 작성자
- CI 로그 노이즈 원인을 추적하는 개발자

### 빠른 네비게이션
```
문제 이해: 문제 섹션 (3분)
코드 적용: EmotionTrend 오버라이드 (2분) / NotificationSettings 오버라이드 (5분)
```

---

## 9️⃣ TROUBLESHOOTING_SYSTEM_CLASSIFICATION_TIL.md

**길이**: ~500 단어
**난이도**: 초급
**소요 시간**: 10분

### 주요 내용

**1장. 문제: 3-System 드리프트**
- troubleshooting.json / docs/til/ / tasks/lessons.md 역할 경계 불명확
- 정보가 한 곳에만 기록되고 나머지 누락

**2장. 핵심 학습: 3-System 분류 원칙**
- troubleshooting.json: 프로덕션 버그 검색 가이드 (외부 개발자 대상)
- docs/til/: 재현 가능 기술 HOW-TO (내부 개발자)
- tasks/lessons.md: AI 자기 수정 교훈 (Claude 전용)

**3장. 판단 트리 (Decision Tree)**
- 프로덕션 영향 → troubleshooting.json + lessons.md
- dev-time 패턴 → docs/til/ + lessons.md
- Claude 내부 실수 → lessons.md only

**4장. 자동화 연결 포인트**
- `/debug` pre-check, `continuous-improvement.md` 트리거, `/session-wrap` Step 5

### 대상 독자
- MindLog 지식 관리 시스템을 이해하려는 개발자
- 버그 기록 후 어디에 넣어야 할지 헷갈리는 개발자

### 빠른 네비게이션
```
분류 기준만: 3-System 표 + 판단 트리 (3분)
자동화 연결: 자동화 연결 포인트 섹션 (3분)
```

---

## 🔟 COLOR_SYSTEM.md

**길이**: ~800 단어
**난이도**: 초급~중급
**소요 시간**: 10분

### 주요 내용

**1장. 4개 팔레트 역할 및 범위**
- `AppColors` — 앱 전역 기본 팔레트 (`lib/core/theme/app_colors.dart`)
- `StatisticsThemeTokens` — 통계 화면 전용 `ThemeExtension` (라이트/다크 완전 분리)
- `HealingColorSchemes` — Cheer Me 모달 전용 `ColorScheme` (라이트 전용, 개선 필요)
- `CheerMeSectionPalette` — Cheer Me 섹션별 컬러 세부 관리

**2장. 팔레트 간 관계도**
- AppColors(전역) → StatisticsThemeTokens(통계) / HealingColorSchemes(모달) / CheerMeSectionPalette(섹션)

**3장. 신규 기능 개발 시 팔레트 선택 기준**
- 전역 공통 → AppColors / 화면 전용 라이트·다크 → ThemeExtension 신규 생성
- 모달 전용 → HealingColorSchemes / 다크 변형 → `*Dark` suffix 또는 ThemeExtension 전환

**4장. 다크 모드 대응 현황 (2026-02-24)**
- ✅ StatisticsThemeTokens, textTheme / ⚠️ HealingColorSchemes (라이트 전용) / ❌ AppColors, CheerMeSectionPalette (Phase 2 마이그레이션 대상)

### 대상 독자
- 새 화면/위젯에 색상을 추가해야 하는 개발자
- 다크 모드 대응 시 어떤 팔레트를 써야 할지 결정해야 하는 개발자

### 빠른 네비게이션
```
팔레트 선택: 3장 선택 기준 표 (2분)
다크 모드 현황: 4장 (2분)
전체 이해: 1~4장 (10분)
```

---

## 1️⃣1️⃣ A11Y_THEME_AWARE_COLOR_MIGRATION_PATTERN_TIL.md

**주제**: Flutter 접근성 색상 마이그레이션 패턴 (Colors.* → colorScheme 의미론적 매핑)
**분량**: ~1,000 단어 | **난이도**: 초급~중급 | **소요**: 15분

| 항목 | 내용 |
|------|------|
| 핵심 매핑 | Colors.black87 → scrim, Colors.white → onSurface, Colors.grey[900] → surfaceContainerLowest |
| AccessibilityWrapper | return AccessibilityWrapper(screenTitle: '화면명', child: Scaffold(...)) |
| 적용 범위 | 14개 화면 Sprint 1+2 완료 |
| 참조 파일 | lib/core/theme/app_colors.dart, lib/core/accessibility/app_accessibility.dart |

---

## 1️⃣2️⃣ MEMORY_ARCHIVING_LIFECYCLE_TIL.md

**주제**: Claude 세션 메모리 7레이어 구조 + 아카이빙 정책 설계 패턴
**분량**: ~700 단어 | **난이도**: 초급 | **소요**: 10분

| 항목 | 내용 |
|------|------|
| 7레이어 | CLAUDE.md → rules/ → MEMORY.md → memory/ → lessons.md → tasks.md → progress/ |
| 아카이빙 기준 | SUPERSEDED+3세션, 90일, 200줄 한도 |
| 자동화 | session-wrap Step 5.5 통합 |
| 참조 파일 | memory/archiving-policy.md, .claude/skills/session-wrap.md |

---

## 1️⃣3️⃣ SESSION_WRAP_PROCESS_AUDIT_TIL.md

**주제**: 멀티 문서 동기화 파이프라인 갭 분석 방법론 (session-wrap G-1~G-7)
**분량**: ~800 단어 | **난이도**: 중급 | **소요**: 15분

| 항목 | 내용 |
|------|------|
| 갭 프레임워크 | 심각도 x 구현비용 x ROI 3차원 평가 |
| G-1~G-7 | commands 불일치(P0), MEMORY.md 전파(P1), progress 동기화(P1), TIL INDEX(P2) |
| Last-Mile 패턴 | 자동화 파이프라인에서 인덱스 파일 갱신 누락 안티패턴 |
| 참조 파일 | .claude/skills/session-wrap.md, memory/archiving-policy.md |

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

### 시나리오 11: "presentation에서 data를 직접 import하면 안 되나요?"
**추천**: CLEAN_ARCHITECTURE_VIOLATION_FIX_TIL.md
**소요시간**: 10분
**내용**: DIP 위반 문제점, Repository 확장 패턴, DI 변경 방법

### 시나리오 12: "FCM 알림이 여러 번 발송돼요"
**추천**: FCM_IDEMPOTENCY_LOCK.md
**소요시간**: 15분
**내용**: Firestore pre-lock 패턴, retry + 부분 실패 원인 분석

### 시나리오 13: "iOS에서 data-only 푸시는 어떻게 보내나요?"
**추천**: FCM_IDEMPOTENCY_LOCK.md 핵심 학습 3 + 코드 패턴
**소요시간**: 10분
**내용**: APNS alert vs background, content-available 설정

### 시나리오 14: "firebase deploy --only functions가 403으로 실패해요"
**추천**: FIREBASE_CLI_EXTENSIONS_BUG.md
**소요시간**: 10분
**내용**: Extensions planner.js 패치, IAM vs 서비스 레벨 제한 차이, 재적용 체크리스트

### 시나리오 15: "테스트는 통과하는데 CI 로그에 에러가 계속 찍혀요"
**추천**: FLUTTER_TESTING_STATIC_OVERRIDE_PATTERN_TIL.md
**소요시간**: 10분
**내용**: 정적 오버라이드 패턴, setUp/tearDown 설정, `resetForTesting()` 필수 적용

### 시나리오 16: "버그를 lessons.md에 기록했는데 troubleshooting.json에도 넣어야 하나요?"
**추천**: TROUBLESHOOTING_SYSTEM_CLASSIFICATION_TIL.md
**소요시간**: 10분
**내용**: 3-System 분류 원칙 (troubleshooting.json / docs/til/ / lessons.md), 판단 트리, 자동화 연결 포인트

### 시나리오 17: "새 화면에 색상을 추가할 때 어떤 팔레트를 써야 하나요?"
**추천**: COLOR_SYSTEM.md 3장 선택 기준 표
**소요시간**: 5분
**내용**: AppColors vs ThemeExtension vs HealingColorSchemes 선택 기준, 다크 모드 대응 현황

### 시나리오 18: "화면에 하드코딩 색상(Colors.*)이 있는데 다크 모드에서 깨져요"
**추천**: A11Y_THEME_AWARE_COLOR_MIGRATION_PATTERN_TIL.md
**소요시간**: 15분
**내용**: Colors.* → colorScheme 매핑 테이블, AccessibilityWrapper 패턴, Colors.white 맥락별 교체

### 시나리오 19: "메모리 파일이 너무 많아졌어요, 어떻게 관리하나요?"
**추천**: MEMORY_ARCHIVING_LIFECYCLE_TIL.md
**소요시간**: 10분
**내용**: 7레이어 메모리 구조, 아카이빙 3원칙, MEMORY.md 200줄 한도 관리, session-wrap 자동화

### 시나리오 20: "session-wrap이 제대로 동작하는지 확인하고 싶어요"
**추천**: SESSION_WRAP_PROCESS_AUDIT_TIL.md
**소요시간**: 15분
**내용**: G-1~G-7 갭 분석 결과, Last-Mile 파일 누락 안티패턴, 갭 발견 방법론

---

## 📊 문서 통계

| 항목 | 값 |
|------|-----|
| 총 단어 수 | ~15,400 |
| 총 섹션 | 45+ |
| 코드 예제 | 62+ |
| 다이어그램 | 8+ |
| 표 | 22+ |
| 생성 시간 | 2026-01-21 |
| 최종 업데이트 | 2026-02-27 (v1.8) |

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
| 1.2 | 2026-01-26 | Clean Architecture 위반 수정 TIL 추가 (5개 문서) |
| 1.3 | 2026-02-27 | FCM 멱등성 Pre-lock 패턴 TIL 추가 (6개 문서) |
| 1.4 | 2026-02-27 | Firebase CLI Extensions API 403 버그 패치 TIL 추가 (7개 문서) |
| 1.5 | 2026-02-27 | Flutter 플랫폼 서비스 정적 오버라이드 패턴 TIL 추가 (8개 문서) |
| 1.6 | 2026-02-27 | 트러블슈팅 시스템 분류 프레임워크 TIL 추가 (9개 문서) |
| 1.7 | 2026-02-27 | COLOR_SYSTEM.md 색인 추가, FLUTTER_TESTING·TROUBLESHOOTING 누락 섹션 보완 (10개 문서) |
| 1.8 | 2026-02-27 | TIL 3개 추가 (A11Y/MEMORY/SESSION_WRAP, 총 13개 문서, 20 시나리오) |

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
