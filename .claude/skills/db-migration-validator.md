# db-migration-validator

SQLite 마이그레이션 검증 자동화 (`/db-migrate-validate [action]`)

## 목표
- DB 마이그레이션 스크립트 사전 검증
- 스키마 버전 일관성 보장
- 데이터 무결성 확인
- 롤백 가능성 검증

## 트리거 조건
- `/db-migrate-validate [action]` 명령어
- DB 스키마 변경 시
- 마이그레이션 버전 업데이트 시
- 릴리스 전 DB 검증 필요 시

## 핵심 파일

| 파일 | 역할 |
|------|------|
| `lib/data/datasources/local/database_helper.dart` | DB 초기화 |
| `lib/data/datasources/local/diary_local_datasource.dart` | 일기 DAO |
| `test/data/datasources/local/` | DB 테스트 |

## 현재 스키마

```sql
-- Version: 3

CREATE TABLE diaries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  content TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT,

  -- Analysis fields
  keywords TEXT,
  sentiment_score INTEGER,
  empathy_message TEXT,
  action_items TEXT,
  emotion_category TEXT,
  emotion_trigger TEXT,
  energy_level INTEGER,
  is_emergency INTEGER DEFAULT 0,

  -- Metadata
  character_type TEXT,
  is_analyzed INTEGER DEFAULT 0
);

CREATE INDEX idx_diaries_created_at ON diaries(created_at);
```

## Actions

### validate
마이그레이션 스크립트 검증
1. 현재 버전 확인
2. 마이그레이션 스크립트 문법 검사
3. _onCreate와 _onUpgrade 동기화 확인
4. 인덱스 무결성 검사

```bash
> /db-migrate-validate validate

검증 결과:
├── 현재 버전: 3
├── 문법 검사: ✅ PASS
├── onCreate/onUpgrade 동기화: ✅ PASS
├── 인덱스: 1개 정상
└── DROP 사용: 없음 ✅
```

### dry-run [version]
마이그레이션 시뮬레이션
1. 인메모리 DB 생성 (이전 버전)
2. 테스트 데이터 삽입
3. 마이그레이션 실행
4. 데이터 무결성 확인

```dart
// Dry-run 테스트 예시
Future<void> testMigrationV2ToV3() async {
  // 1. Create v2 schema
  final db = await openDatabase(':memory:', version: 2);

  // 2. Insert test data
  await db.insert('diaries', testDiaryV2);

  // 3. Migrate to v3
  await db.close();
  final migratedDb = await openDatabase(':memory:', version: 3,
    onUpgrade: _onUpgrade,
  );

  // 4. Verify data integrity
  final result = await migratedDb.query('diaries');
  expect(result.first['new_column'], isNotNull);
}
```

### compare [version1] [version2]
버전 간 스키마 비교
1. 두 버전의 스키마 추출
2. 컬럼 추가/삭제/변경 비교
3. 인덱스 변경 비교
4. 호환성 분석

```
> /db-migrate-validate compare 2 3

스키마 비교 (v2 → v3):
├── 추가된 컬럼: emotion_trigger (TEXT)
├── 삭제된 컬럼: 없음
├── 변경된 컬럼: 없음
├── 추가된 인덱스: 없음
└── 호환성: BACKWARD_COMPATIBLE ✅
```

### generate-test
마이그레이션 테스트 자동 생성
1. 현재 버전 분석
2. 이전 버전 → 현재 버전 테스트 생성
3. Edge case 테스트 추가
4. 롤백 테스트 생성

```dart
// 자동 생성된 테스트 예시
group('Migration v2 to v3', () {
  test('should preserve existing data', () async {
    // ... 자동 생성
  });

  test('should add new columns with defaults', () async {
    // ... 자동 생성
  });

  test('should handle null values gracefully', () async {
    // ... 자동 생성
  });
});
```

### audit-history
마이그레이션 히스토리 감사
1. 모든 버전의 마이그레이션 추적
2. 각 버전의 변경 사항 문서화
3. 롤백 가능성 분석
4. 데이터 손실 위험 평가

## 마이그레이션 가이드라인

### 안전한 마이그레이션

```dart
// ✅ 안전한 패턴

// 1. 컬럼 추가 (nullable)
await db.execute('ALTER TABLE diaries ADD COLUMN new_field TEXT');

// 2. 컬럼 추가 (with default)
await db.execute(
  'ALTER TABLE diaries ADD COLUMN new_int INTEGER DEFAULT 0'
);

// 3. 인덱스 추가
await db.execute(
  'CREATE INDEX IF NOT EXISTS idx_new ON diaries(new_field)'
);
```

### 위험한 패턴 (피해야 함)

```dart
// ❌ 위험한 패턴

// 1. 테이블 DROP
await db.execute('DROP TABLE diaries'); // 데이터 손실!

// 2. 컬럼 삭제 (SQLite는 직접 지원 안 함)
// SQLite는 ALTER TABLE DROP COLUMN을 지원하지 않음

// 3. NOT NULL 컬럼 추가 (기존 데이터 문제)
await db.execute(
  'ALTER TABLE diaries ADD COLUMN required TEXT NOT NULL' // 실패!
);
```

### 복잡한 마이그레이션

```dart
// 컬럼 타입 변경 또는 삭제가 필요한 경우
Future<void> complexMigration(Database db) async {
  // 1. 새 테이블 생성
  await db.execute('''
    CREATE TABLE diaries_new (
      id INTEGER PRIMARY KEY,
      content TEXT NOT NULL,
      -- 새로운 스키마
    )
  ''');

  // 2. 데이터 복사
  await db.execute('''
    INSERT INTO diaries_new (id, content)
    SELECT id, content FROM diaries
  ''');

  // 3. 이전 테이블 삭제
  await db.execute('DROP TABLE diaries');

  // 4. 새 테이블 이름 변경
  await db.execute('ALTER TABLE diaries_new RENAME TO diaries');
}
```

## 버전 관리 규칙

| 변경 유형 | 버전 증가 | 예시 |
|----------|----------|------|
| 컬럼 추가 | +1 | v2 → v3 |
| 인덱스 추가 | +1 | v3 → v4 |
| 테이블 추가 | +1 | v4 → v5 |
| 스키마 재구성 | +1 | v5 → v6 |

## 출력 형식

```
DB 마이그레이션 검증 결과
========================

📊 현재 상태:
├── 스키마 버전: 3
├── 테이블: 1개 (diaries)
├── 컬럼: 14개
├── 인덱스: 1개
└── 마지막 마이그레이션: v2 → v3

✅ 검증 통과:
├── [SYNTAX] SQL 문법 검사
├── [SYNC] onCreate/onUpgrade 동기화
├── [INTEGRITY] 인덱스 무결성
├── [SAFETY] DROP 문 미사용
└── [COMPAT] 하위 호환성

📋 권장 사항:
1. 새 마이그레이션 추가 시 테스트 필수
2. 프로덕션 배포 전 dry-run 실행

다음 단계:
└── /db-migrate-validate dry-run 4
```

## 연관 스킬
- `/db [action]` - DB 스키마 관리
- `/db-state-recovery` - DB 복원 테스트
- `/defensive-recovery-gen` - 방어적 복구 코드

## 주의사항
- 프로덕션 DB 마이그레이션은 신중히 진행
- DROP 문은 절대 사용 금지 (하위 호환성)
- 마이그레이션 테스트 없이 릴리스 금지
- _onCreate와 _onUpgrade는 항상 동기화 유지

---

## Skill Metadata

| Property | Value |
|----------|-------|
| Priority | P2 |
| Category | database / testing |
| Dependencies | database-expert, db-state-recovery |
| Created | 2025-02-03 |
| Updated | 2025-02-03 |
