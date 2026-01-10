# database-expert

SQLite 스키마 설계, 마이그레이션, 쿼리 최적화 전문가 스킬

## 목표
- 스키마 마이그레이션 자동화
- 쿼리 성능 최적화
- 데이터 무결성 보장

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "스키마 변경", "DB 마이그레이션" 요청
- `/db [action]` 명령어
- 새 엔티티 필드 추가 시
- 쿼리 성능 이슈 발생 시

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `lib/data/datasources/local/sqlite_local_datasource.dart` | SQLite 접근 레이어 |
| `lib/domain/entities/diary.dart` | Diary, AnalysisResult 엔티티 |
| `lib/domain/entities/statistics.dart` | Statistics 엔티티 |
| `lib/domain/entities/notification_settings.dart` | NotificationSettings 엔티티 |
| `lib/data/repositories/diary_repository_impl.dart` | Repository 구현체 |

## 현재 스키마 구성

### Database 정보
```
Database: mindlog.db
Current Version: 3
Location: Application Documents Directory
```

### Tables

#### diaries
```sql
CREATE TABLE diaries (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,  -- ISO8601 형식
  status TEXT NOT NULL,      -- pending, analyzed, failed, safetyBlocked
  analysis_result TEXT,      -- JSON (nullable)
  is_pinned INTEGER DEFAULT 0
);
```

### Indexes
```sql
-- Version 1
CREATE INDEX idx_diaries_created_at ON diaries(created_at);
CREATE INDEX idx_diaries_status ON diaries(status);

-- Version 2
CREATE INDEX idx_diaries_status_created_at ON diaries(status, created_at);

-- Version 3
CREATE INDEX idx_diaries_is_pinned ON diaries(is_pinned);
```

### 마이그레이션 히스토리
| Version | 변경 내용 |
|---------|----------|
| 1 | 초기 테이블 생성, 기본 인덱스 |
| 2 | 복합 인덱스 추가 (통계 쿼리 최적화) |
| 3 | is_pinned 컬럼 + 인덱스 추가 |

## 프로세스

### Action 1: add-column
새 컬럼 추가 및 마이그레이션

```
Step 1: 요구사항 분석
  - 컬럼명, 타입, 기본값 정의
  - nullable 여부 결정

Step 2: _currentVersion 증가
  - sqlite_local_datasource.dart 수정

Step 3: _onUpgrade 로직 추가
  - ALTER TABLE 문 작성
  - 인덱스 추가 (필요시)

Step 4: _onCreate 스키마 업데이트
  - 새 설치 시 포함되도록

Step 5: 엔티티 업데이트
  - domain/entities/ 수정
  - fromJson/toJson 추가

Step 6: Repository 메서드 추가
  - CRUD 로직 확장

Step 7: 테스트 작성
```

**마이그레이션 템플릿:**
```dart
// 버전 N → N+1: 설명
if (oldVersion < N+1) {
  await db.execute('ALTER TABLE diaries ADD COLUMN {column} {type} DEFAULT {value}');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_diaries_{column} ON diaries({column})');
}
```

### Action 2: add-table
새 테이블 추가

```
Step 1: 테이블 설계
  - 컬럼 정의
  - PK, FK 관계
  - 인덱스 전략

Step 2: _currentVersion 증가

Step 3: _onCreate에 CREATE TABLE 추가

Step 4: _onUpgrade에 마이그레이션 추가
  - CREATE TABLE IF NOT EXISTS
  - 인덱스 생성

Step 5: 엔티티 생성
  - domain/entities/{table}.dart

Step 6: DataSource 메서드 추가
  - CRUD 메서드

Step 7: Repository 업데이트
  - 인터페이스 + 구현체
```

**새 테이블 템플릿:**
```dart
// _onCreate 내부
await db.execute('''
  CREATE TABLE {table_name} (
    id TEXT PRIMARY KEY,
    {column1} {type1} NOT NULL,
    {column2} {type2},
    created_at TEXT NOT NULL
  )
''');
await db.execute('CREATE INDEX idx_{table}_{column} ON {table}({column})');
```

### Action 3: optimize-query
쿼리 성능 최적화

```
Step 1: 현재 쿼리 분석
  - SELECT 문 검토
  - WHERE 조건 확인
  - ORDER BY 확인

Step 2: EXPLAIN QUERY PLAN 분석
  - 인덱스 사용 여부
  - Full Table Scan 감지

Step 3: 인덱스 최적화
  - 누락된 인덱스 추가
  - 복합 인덱스 고려
  - 불필요한 인덱스 제거

Step 4: 쿼리 리팩토링
  - 필요한 컬럼만 SELECT
  - LIMIT 활용
  - 서브쿼리 최적화

Step 5: 성능 테스트
```

**인덱스 설계 가이드:**
```
✅ 좋은 인덱스:
- WHERE 절에 자주 사용되는 컬럼
- ORDER BY에 사용되는 컬럼
- 복합 조건 (status + created_at)

❌ 피해야 할 인덱스:
- 카디널리티가 낮은 컬럼 (boolean)
- 자주 업데이트되는 컬럼
- 테이블 크기가 작은 경우
```

### Action 4: backup-restore
데이터 백업/복원 로직

```
Step 1: 백업 전략 결정
  - 전체 DB 파일 복사
  - JSON export

Step 2: 백업 메서드 구현
  - 파일 경로 결정
  - 백업 실행

Step 3: 복원 메서드 구현
  - 무결성 검증
  - 롤백 전략

Step 4: 자동 백업 스케줄 (선택)
```

### Action 5: schema-report
현재 스키마 상태 리포트

```
Step 1: 테이블 목록 조회
Step 2: 각 테이블 컬럼 정보
Step 3: 인덱스 목록
Step 4: 데이터 통계
  - 레코드 수
  - 저장 공간
Step 5: 마이그레이션 히스토리
```

## 인덱스 설계 원칙

### 단일 인덱스 vs 복합 인덱스
```
단일 인덱스:
- 단일 컬럼 조건에 효과적
- WHERE created_at > ?

복합 인덱스:
- 여러 컬럼 동시 조건
- WHERE status = ? AND created_at > ?
- 순서 중요: 선택도 높은 컬럼 먼저
```

### 현재 쿼리 패턴 분석
```sql
-- 모든 일기 조회 (빈도: 높음)
SELECT * FROM diaries ORDER BY is_pinned DESC, created_at DESC;
→ idx_diaries_is_pinned, idx_diaries_created_at

-- 분석된 일기 날짜 범위 조회 (빈도: 높음)
SELECT * FROM diaries WHERE status IN ('analyzed', 'safetyBlocked') AND created_at >= ? AND created_at <= ?;
→ idx_diaries_status_created_at (복합 인덱스)

-- 오늘 일기 조회 (빈도: 중간)
SELECT * FROM diaries WHERE created_at >= ?;
→ idx_diaries_created_at
```

## 출력 형식

```
🗄️ Database Expert 실행 결과

Action: [실행한 액션]

변경 사항:
├── Version: 3 → 4
├── 새 컬럼: is_archived (INTEGER DEFAULT 0)
└── 새 인덱스: idx_diaries_is_archived

마이그레이션 코드:
```dart
if (oldVersion < 4) {
  await db.execute('ALTER TABLE diaries ADD COLUMN is_archived INTEGER DEFAULT 0');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_diaries_is_archived ON diaries(is_archived)');
}
```

수정 파일:
├── lib/data/datasources/local/sqlite_local_datasource.dart
├── lib/domain/entities/diary.dart
└── lib/data/repositories/diary_repository_impl.dart

다음 단계:
└── /test-unit-gen lib/data/datasources/local/sqlite_local_datasource.dart
```

## 사용 예시

### 컬럼 추가
```
> "/db add-column is_favorite"

AI 응답:
1. 요구사항: 즐겨찾기 기능
2. 컬럼: is_favorite INTEGER DEFAULT 0
3. 마이그레이션:
   - Version 3 → 4
   - ALTER TABLE + INDEX
4. 엔티티 업데이트: Diary.isFavorite
5. 테스트 생성 권장
```

### 쿼리 최적화
```
> "/db optimize-query getAnalyzedDiariesInRange"

AI 응답:
1. 현재 쿼리 분석
2. EXPLAIN QUERY PLAN 결과
3. 권장사항:
   - 복합 인덱스 이미 존재 ✅
   - LIMIT 추가로 페이지네이션 고려
4. 최적화 불필요
```

### 스키마 리포트
```
> "/db schema-report"

AI 응답:
테이블: diaries
├── id: TEXT (PK)
├── content: TEXT (NOT NULL)
├── created_at: TEXT (NOT NULL)
├── status: TEXT (NOT NULL)
├── analysis_result: TEXT (nullable)
└── is_pinned: INTEGER (DEFAULT 0)

인덱스:
├── idx_diaries_created_at
├── idx_diaries_status
├── idx_diaries_status_created_at
└── idx_diaries_is_pinned

데이터:
├── 레코드 수: 150
└── 평균 크기: ~2KB/레코드
```

## 연관 스킬
- `/test-unit-gen` - 마이그레이션 테스트 생성
- `/scaffold` - 새 기능 전체 구조 생성
- `/resilience` - DB 에러 처리

## 주의사항
- 마이그레이션은 항상 하위 호환성 유지 (DROP 금지)
- `_currentVersion`은 반드시 1씩 증가
- `_onCreate`와 `_onUpgrade` 동기화 필수
- 테스트 환경에서 마이그레이션 검증 필수
- JSON 컬럼 (analysis_result)은 별도 파싱 로직 필요
- `resetForTesting()` 메서드로 테스트 격리
