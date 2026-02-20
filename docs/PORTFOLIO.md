# MindLog - AI 기반 감정 케어 다이어리

> Made with ❤️ for your mental health

## 📱 프로젝트 개요

**MindLog**는 AI 기술을 활용하여 사용자의 일상 감정을 분석하고, 개인화된 인사이트를 제공하는 멘탈 헬스케어 애플리케이션입니다. 매일의 감정을 부드럽게 기록하고, AI가 제공하는 따뜻한 피드백으로 마음의 건강을 관리할 수 있습니다.

### 🎯 핵심 가치

- **감정의 시각화**: 일상의 감정을 기록하고 패턴을 발견
- **AI 기반 분석**: LLM을 활용한 정교한 감정 분석 및 인사이트 제공
- **개인화된 케어**: 사용자 성향에 맞는 AI 캐릭터 선택 및 맞춤형 피드백
- **프라이버시 우선**: 로컬 SQLite 기반 데이터 저장으로 안전한 개인정보 관리

---

## ✨ 주요 기능

### 1️⃣ 감정 일기 작성

- **자유로운 텍스트 입력**: 최대 5,000자까지 오늘의 감정과 생각을 기록
- **사진 첨부**: 최대 5장의 사진으로 시각적 기록 가능
- **AI 분석**: Groq API (LLaMA 3.3 70B)를 활용한 실시간 감정 분석
- **해시태그 자동 생성**: AI가 일기 내용을 분석하여 핵심 키워드 추출

### 2️⃣ 감정 통계 & 인사이트

#### 📅 감정 캘린더
- 월별 감정 기록을 한눈에 확인
- 평균 감정 점수 및 연속 기록 일수 트래킹
- "마음의 정원" - 감정 성장 단계를 식물 이미지로 시각화

#### 📊 감정 추이 차트
- fl_chart 라이브러리를 활용한 시간별 감정 변화 그래프
- 최근 7일/30일/전체 기간 필터링 지원
- 감정 패턴 요약 제공
- **다크 모드 완전 지원**: `StatisticsThemeTokens` 디자인 토큰 시스템으로 Light/Dark 자동 전환

#### 🔑 키워드 분석
- AI가 추출한 감정 키워드 빈도 분석
- 대표 감정 및 자주 느낀 감정 순위 제공
- 키워드별 등장 비율 시각화

### 3️⃣ 개인화된 AI 캐릭터

사용자의 성향에 맞는 3가지 AI 캐릭터 중 선택 가능:

- **온이** (따뜻한 상담사): 부드럽고 따뜻한 공감 중심
- **쿠이** (현실적 코치): 명확하고 실행 중심의 조언
- **웃음이** (유쾌한 친구): 밝고 유쾌한 분위기의 위로

### 4️⃣ 스마트 알림 시스템

- **일기 리마인더**: 매일 지정한 시간에 일기 작성 알림
- **마음 케어 알림**: AI가 추천하는 따뜻한 메시지 푸시
- **개인화된 메시지**: 사용자 이름 기반 맞춤형 알림 문구

### 5️⃣ 비밀일기 (v1.4.44)

- **4자리 PIN 보호**: SHA-256(PIN + salt) 해시 저장, `flutter_secure_storage` 활용
- **인-메모리 세션 인증**: 앱이 백그라운드로 전환되면 자동 잠금
- **통계 완전 분리**: 비밀일기는 히트맵·차트·키워드 통계에서 제외
- **롱프레스 컨텍스트 메뉴**: 기존 일기 → 비밀일기 전환 / 해제 지원

---

## 🏗️ 기술 스택

### Frontend
- **Flutter** 3.38.9 / **Dart** 3.10.8
- **fvm** (Flutter Version Management)
- **Riverpod** 2.6.1 - 상태 관리
- **go_router** 17.0.1 - 선언적 라우팅
- **fl_chart** 0.68.0 - 데이터 시각화

### Backend & AI
- **Groq API** - LLaMA 3.3 70B Versatile 모델
  - 감정 분석, 키워드 추출, AI 캐릭터 응답 생성
- **Firebase**
  - Analytics 3.8.0+ - 사용자 행동 분석
  - Crashlytics - 안정성 모니터링
  - FCM (Firebase Cloud Messaging) - 푸시 알림

### Database & Storage
- **SQLite** (sqflite 2.3.3) - 로컬 데이터베이스
  - 감정 일기, 분석 결과, 사용자 설정 저장
  - 오프라인 우선 아키텍처

---

## 🎨 아키텍처 & 설계

### Clean Architecture

```
lib/
├── core/           # 공통: 에러, 설정, 서비스, 테마, 유틸리티
├── domain/         # 비즈니스 로직: Entity, Repository, UseCase
├── data/           # 데이터 레이어: Repository 구현, DataSource, DTO
├── presentation/   # UI 레이어: Provider, Screen, Widget
└── main.dart
```

### 핵심 설계 패턴

#### 1. Clean Architecture
- **레이어 분리**: Domain(순수 비즈니스) ↔ Data(구현) ↔ Presentation(UI)
- **의존성 역전**: Domain이 Data/Presentation에 의존하지 않음
- **테스트 용이성**: 각 레이어별 독립적인 단위 테스트 가능

#### 2. Riverpod 상태 관리
```dart
// UseCase를 통한 비즈니스 로직 실행
final diaryAnalysisProvider = AsyncNotifierProvider<DiaryAnalysisNotifier, DiaryAnalysis?>(
  DiaryAnalysisNotifier.new,
);

// 선언적 UI 렌더링
ref.watch(diaryAnalysisProvider).when(
  data: (analysis) => AnalysisResultCard(analysis),
  loading: () => LoadingIndicator(),
  error: (error, _) => ErrorView(error),
);
```

#### 3. Repository Pattern
```dart
// Domain Layer - Interface
abstract class DiaryRepository {
  Future<Either<Failure, List<Diary>>> getAllDiaries();
  Future<Either<Failure, Diary>> saveDiary(Diary diary);
}

// Data Layer - Implementation
class DiaryRepositoryImpl implements DiaryRepository {
  final DiaryLocalDataSource localDataSource;

  @override
  Future<Either<Failure, Diary>> saveDiary(Diary diary) async {
    try {
      final diaryDto = DiaryDto.fromEntity(diary);
      final result = await localDataSource.insertDiary(diaryDto);
      return Right(result.toEntity());
    } on DatabaseException {
      return Left(CacheFailure());
    }
  }
}
```

#### 4. Failure-based Error Handling
```dart
sealed class Failure {
  const Failure();
}

class NetworkFailure extends Failure {}
class ApiFailure extends Failure { final String message; }
class CacheFailure extends Failure {}
class SafetyBlockedFailure extends Failure {} // 위기 감지 시 차단
```

---

## 🔐 보안 & 프라이버시

### 데이터 보호
- **로컬 우선 저장**: 민감한 감정 데이터는 SQLite에만 저장
- **API Key 보안**: `--dart-define`을 통한 환경변수 주입
- **개인정보 처리방침**: GDPR/CCPA 준수 설계

### 위기 감지 시스템
```dart
// AI가 위험 신호 감지 시 SafetyBlockedFailure 반환
class SafetyBlockedFailure extends Failure {
  final String reason;
  const SafetyBlockedFailure(this.reason);
}

// 절대 수정/제거 금지 - 긴급 상황 탐지 핵심 로직
```

---

## 📊 성능 최적화

### 1. 렌더링 최적화
- **Provider .select()**: 필요한 상태만 구독하여 불필요한 리빌드 방지
- **const 위젯**: 불변 위젯에 const 키워드로 재생성 방지
- **ListView.builder**: 대량 데이터도 효율적으로 렌더링

### 2. 메모리 관리
- **이미지 캐싱**: `cacheWidth` 설정으로 메모리 사용량 최적화
- **정규식 캐싱**: 반복 사용되는 RegExp를 static final로 선언

### 3. API 호출 최적화
- **HTTP Timeout**: 30초 타임아웃으로 네트워크 지연 대응
- **에러 처리**: Exponential Backoff 패턴으로 재시도 전략

---

## 🧪 테스트 전략

### TDD (Test-Driven Development)

| 레이어 | TDD 요구 | 커버리지 목표 |
|--------|----------|--------------|
| **Domain** (UseCase, Entity) | **필수** | ≥ 80% |
| **Data** (Repository, DataSource) | **필수** | ≥ 80% |
| **Presentation** (Provider, Widget) | 권장 | ≥ 70% |

### 테스트 유형
```bash
# 단위 테스트 (Domain + Data)
flutter test test/domain/ test/data/

# 위젯 테스트 (Presentation)
flutter test test/presentation/widgets/

# 통합 테스트
flutter test integration_test/
```

### 품질 게이트
1. ✅ Syntax validation
2. ✅ Type checking (`flutter analyze`)
3. ✅ Lint/quality analysis (`flutter_lints`)
4. ✅ Security scan
5. ✅ Test coverage (unit ≥ 80%, widget ≥ 70%)
6. ✅ Performance check
7. ✅ Documentation validation
8. ✅ Integration testing

---

## 🚀 CI/CD 파이프라인

### GitHub Actions Workflows

#### CI Pipeline (`.github/workflows/ci.yml`)
```yaml
trigger: PR to main/develop
steps:
  1. flutter analyze (정적 분석)
  2. flutter test (전체 테스트)
  3. flutter build appbundle --debug (빌드 검증)
```

#### CD Pipeline (`.github/workflows/cd.yml`)
```yaml
trigger: push to main
steps:
  1. flutter test (테스트)
  2. flutter build appbundle --release (릴리스 빌드)
  3. Google Play Store Internal Track 배포
```

### 환경 변수 관리
```bash
# 프로덕션 빌드
flutter build appbundle --release \
  --dart-define=GROQ_API_KEY=${{ secrets.GROQ_API_KEY }} \
  --dart-define=ENVIRONMENT=production
```

---

## 📈 주요 성과

### 기술적 성과
- ✅ **테스트 지속 확장** — 비밀일기·통계 다크모드 테스트 포함 (단위/위젯/통합 전 레이어)
- ✅ **Clean Architecture** 기반 확장 가능한 구조
- ✅ **AI 통합**: Groq LLaMA 3.3 70B 모델 활용
- ✅ **성능 최적화**: HTTP timeout, 이미지 캐싱, Provider 최적화
- ✅ **ThemeExtension 패턴**: `StatisticsThemeTokens`로 통계 UI 전체를 단일 토큰 시스템으로 관리
- ✅ **비밀일기 보안**: SHA-256 PIN 해시 + flutter_secure_storage 이중 보호

### 사용자 경험
- 🎨 **Material 3 디자인 시스템** 적용 — 통계 탭 디자인 토큰 40종
- 🌙 **다크 모드** 완벽 지원 — ThemeExtension 기반 자동 색상 전환
- 📱 **반응형 레이아웃** (360px 이하 소형 디바이스 포함)
- 🔐 **비밀일기**: PIN 보호 + 백그라운드 자동 잠금
- ♿ **접근성** 고려 (Semantics 위젯, 스크린 리더 지원)

### 코드 품질
- 📐 **flutter_lints** 엄격한 린트 규칙 준수
- 📝 **Conventional Commits** 컨벤션
- 🔍 **코드 리뷰** 필수 (보안/성능/아키텍처 3단계)

---

## 🛠️ 개발 환경 설정

### Prerequisites
```bash
# Flutter Version Manager 설치
brew tap leoafarias/fvm
brew install fvm

# 프로젝트 Flutter 버전 설치
fvm install 3.38.9
fvm use 3.38.9
```

### 로컬 실행
```bash
# 의존성 설치
flutter pub get

# 앱 실행 (API Key 필요)
GROQ_API_KEY=your_api_key ./scripts/run.sh build-appbundle

# 품질 검사
./scripts/run.sh quality  # lint + format + test
```

---

---

## 🏆 핵심 역량 요약

### 1. Clean Architecture 설계
- Domain-Data-Presentation 레이어 분리
- SOLID 원칙 준수
- 테스트 가능한 구조 설계

### 2. 상태 관리 (Riverpod)
- Provider 중앙화 및 무효화 체인 설계
- 낙관적 업데이트 vs Invalidation 패턴 활용
- AsyncNotifier 기반 비동기 상태 관리

### 3. AI/LLM 통합
- Groq API 활용 감정 분석 파이프라인
- 프롬프트 엔지니어링 (한국어 최적화)
- 에러 핸들링 및 폴백 전략

### 4. 데이터베이스 설계
- SQLite 스키마 설계 및 마이그레이션
- 트랜잭션 기반 데이터 무결성 보장
- 복원 방어 로직 구현

### 5. DevOps & 자동화
- GitHub Actions CI/CD 파이프라인
- Play Store 자동 배포
- 버전 관리 및 체인지로그 자동화

---

## 📄 라이선스

Copyright © 2024 Kay Walker. All rights reserved.

---

## 📧 연락처

- **GitHub**: [@kaywalker](https://github.com/kaywalker)
- **Email**: your.email@example.com

---

**MindLog** - 오늘의 마음을 부드럽게 기록해요 ❤️
