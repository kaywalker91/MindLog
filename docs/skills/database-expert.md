# database-expert

SQLite 스키마 관리 및 마이그레이션 (`/db [action]`)

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `lib/data/datasources/local/sqlite_local_datasource.dart` | SQLite 접근 |
| `lib/domain/entities/diary.dart` | Diary, AnalysisResult |
| `lib/data/repositories/diary_repository_impl.dart` | Repository 구현 |

## 현재 스키마
```sql
-- Database: mindlog.db, Version: 3
CREATE TABLE diaries (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,  -- ISO8601
  status TEXT NOT NULL,      -- pending, analyzed, failed, safetyBlocked
  analysis_result TEXT,      -- JSON (nullable)
  is_pinned INTEGER DEFAULT 0
);

-- Indexes
CREATE INDEX idx_diaries_created_at ON diaries(created_at);
CREATE INDEX idx_diaries_status ON diaries(status);
CREATE INDEX idx_diaries_status_created_at ON diaries(status, created_at);
CREATE INDEX idx_diaries_is_pinned ON diaries(is_pinned);
```

## Actions

### add-column
새 컬럼 추가 마이그레이션
1. `_currentVersion` 증가
2. `_onUpgrade`에 ALTER TABLE 추가
3. `_onCreate` 스키마 업데이트
4. Entity 업데이트 (fromJson/toJson)

```dart
// 마이그레이션 템플릿
if (oldVersion < N+1) {
  await db.execute('ALTER TABLE diaries ADD COLUMN {col} {type} DEFAULT {val}');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_diaries_{col} ON diaries({col})');
}
```

### add-table
새 테이블 추가 (CREATE TABLE IF NOT EXISTS + 인덱스 + Entity 생성)

### optimize-query
쿼리 성능 최적화 (EXPLAIN QUERY PLAN → 인덱스 추가/제거)

### schema-report
현재 스키마 상태 리포트 (테이블, 컬럼, 인덱스, 데이터 통계)

## 인덱스 설계
- WHERE/ORDER BY에 자주 사용되는 컬럼
- 복합 인덱스: 선택도 높은 컬럼 먼저 (예: status + created_at)
- boolean 컬럼은 카디널리티가 낮아 인덱스 효과 제한적

## 주의사항
- 마이그레이션은 하위 호환성 유지 (DROP 금지)
- `_currentVersion`은 1씩 증가
- `_onCreate`와 `_onUpgrade` 동기화 필수
- `resetForTesting()` 메서드로 테스트 격리
