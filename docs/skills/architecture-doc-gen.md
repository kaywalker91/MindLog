# architecture-doc-gen

Clean Architecture 프로젝트 구조와 데이터 흐름을 문서화하는 스킬

## 목표
- 프로젝트 아키텍처 시각화
- 레이어별 책임과 의존성 문서화
- 신규 개발자 온보딩 지원

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "아키텍처 문서", "architecture doc" 요청
- `/architecture-doc` 명령어
- 프로젝트 구조 설명 필요 시
- 신규 팀원 온보딩 시

## 프로젝트 구조
참조: `lib/` 디렉토리

```
lib/
├── core/                    # 공통 유틸리티
│   ├── constants/           # 상수 정의
│   ├── config/              # 환경 설정
│   ├── errors/              # Failure, Exception
│   ├── network/             # HTTP 클라이언트
│   ├── services/            # Firebase 서비스
│   └── utils/               # 유틸리티 함수
│
├── domain/                  # 비즈니스 로직 (순수 Dart)
│   ├── entities/            # 도메인 엔티티
│   ├── repositories/        # Repository 인터페이스
│   └── usecases/            # UseCase 클래스
│
├── data/                    # 데이터 레이어
│   ├── repositories/        # Repository 구현체
│   ├── datasources/
│   │   ├── local/           # SQLite, SharedPreferences
│   │   └── remote/          # API 클라이언트
│   └── dto/                 # Data Transfer Objects
│
└── presentation/            # UI 레이어
    ├── providers/           # Riverpod Providers
    ├── screens/             # 화면 위젯
    └── widgets/             # 공통 위젯
```

## 프로세스

### Step 1: 프로젝트 구조 분석
```bash
# 디렉토리 구조 스캔
# 파일 의존성 분석
# 레이어별 컴포넌트 매핑
```

### Step 2: 아키텍처 다이어그램 생성

```
┌─────────────────────────────────────────────────────────────┐
│                     Presentation Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Screens   │  │   Widgets   │  │   Riverpod          │  │
│  │             │◄─│             │◄─│   Providers         │  │
│  └─────────────┘  └─────────────┘  └──────────┬──────────┘  │
│                                                │              │
└────────────────────────────────────────────────┼──────────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────┐
│                       Domain Layer                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Entities   │  │  UseCases   │  │   Repository        │  │
│  │             │◄─│             │◄─│   Interfaces        │  │
│  └─────────────┘  └─────────────┘  └──────────┬──────────┘  │
│                                                │              │
└────────────────────────────────────────────────┼──────────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────┐
│                        Data Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Repository  │  │    DTOs     │  │    DataSources      │  │
│  │    Impl     │──│             │──│  Local │   Remote   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌──────────────────────────────────────────────────────────────┐
│                        Core Layer                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │ Constants│  │  Config  │  │  Errors  │  │   Services   │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────┘  │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### Step 3: 데이터 흐름 문서화

```markdown
## 일기 분석 데이터 흐름

1. **UI 트리거**
   - `DiaryScreen` → 저장 버튼 클릭

2. **Provider 호출**
   - `DiaryAnalysisController.analyze(content)`

3. **UseCase 실행**
   - `AnalyzeDiaryUseCase.execute(diary)`
   - 입력 유효성 검사
   - Repository 호출

4. **Repository 처리**
   - `DiaryRepositoryImpl.analyzeDiary(diary)`
   - Remote DataSource 호출

5. **API 통신**
   - `GroqApiService.analyzeContent(content)`
   - Groq API 호출
   - 응답 파싱 → DTO → Entity 변환

6. **결과 반환**
   - Entity → Provider 상태 업데이트
   - UI 갱신
```

### Step 4: 문서 생성
파일: `docs/ARCHITECTURE.md`

## 출력 형식

```
📐 아키텍처 문서 생성 완료

✅ docs/ARCHITECTURE.md

문서 내용:
├── 프로젝트 개요
├── 레이어 구조
│   ├── Presentation Layer
│   ├── Domain Layer
│   ├── Data Layer
│   └── Core Layer
├── 의존성 규칙
├── 데이터 흐름
│   ├── 일기 작성 흐름
│   ├── AI 분석 흐름
│   └── 통계 조회 흐름
├── 디렉토리 구조
└── 주요 컴포넌트 설명

📊 시각화:
   └─ ASCII 아키텍처 다이어그램 포함
```

## 레이어별 책임

### Presentation Layer
| 컴포넌트 | 책임 |
|---------|------|
| Screens | 화면 UI 렌더링 |
| Widgets | 재사용 가능한 UI 컴포넌트 |
| Providers | 상태 관리 (Riverpod) |

### Domain Layer
| 컴포넌트 | 책임 |
|---------|------|
| Entities | 비즈니스 도메인 모델 |
| UseCases | 비즈니스 로직 실행 |
| Repository Interfaces | 데이터 접근 추상화 |

### Data Layer
| 컴포넌트 | 책임 |
|---------|------|
| Repository Impl | Repository 구현 |
| DTOs | 데이터 전송 객체 |
| DataSources | 외부 데이터 소스 접근 |

### Core Layer
| 컴포넌트 | 책임 |
|---------|------|
| Constants | 앱 전역 상수 |
| Config | 환경 설정 |
| Errors | Failure 타입 정의 |
| Services | Firebase 서비스 래퍼 |

## 의존성 규칙

```
✅ 허용된 의존성:
   presentation → domain → (없음)
   data → domain
   모든 레이어 → core

❌ 금지된 의존성:
   domain → data
   domain → presentation
   data → presentation
```

## 사용 예시

```
> "/architecture-doc"

AI 응답:
1. 프로젝트 구조 분석:
   - 4개 레이어 확인
   - 컴포넌트 매핑

2. 문서 생성:
   - docs/ARCHITECTURE.md

3. 포함 내용:
   - ASCII 아키텍처 다이어그램
   - 레이어별 책임 설명
   - 주요 데이터 흐름 3개
   - 의존성 규칙
```

## 연관 스킬
- `/feature-scaffold` - Clean Architecture 기능 생성
- `/api-doc` - API 문서 생성

## 주의사항
- 문서는 코드 변경 시 수동 업데이트 필요
- Mermaid 다이어그램은 GitHub에서 자동 렌더링
- 복잡한 흐름은 시퀀스 다이어그램 권장
- 정기적인 문서 검토 필요
