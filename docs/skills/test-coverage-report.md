# test-coverage-report

테스트 커버리지를 분석하고 리포트를 생성하는 스킬

## 목표
- 테스트 커버리지 가시화
- 미커버 영역 식별
- 커버리지 트렌드 추적

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "커버리지 확인", "coverage report" 요청
- `/coverage` 명령어
- PR 리뷰 시
- 테스트 커버리지 분석 필요 시

## 현재 테스트 현황
참조: `test/` 디렉토리

```
test/
├── widget_test.dart
├── core/
│   ├── constants/ (2개)
│   ├── config/ (1개)
│   └── utils/ (1개)
├── data/
│   ├── dto/ (1개)
│   └── repositories/ (1개)
└── domain/
    └── usecases/ (1개)

총 테스트 파일: 8개
```

## 프로세스

### Step 1: 커버리지 데이터 수집
```bash
# 커버리지와 함께 테스트 실행
flutter test --coverage

# 결과 파일
# coverage/lcov.info
```

### Step 2: 커버리지 분석
```bash
# lcov 요약
lcov --summary coverage/lcov.info
```

### Step 3: HTML 리포트 생성 (선택)
```bash
# genhtml 사용
genhtml coverage/lcov.info -o coverage/html

# 브라우저에서 열기
open coverage/html/index.html
```

### Step 4: 리포트 생성

```markdown
## 테스트 커버리지 리포트

### 요약
| 메트릭 | 값 | 목표 |
|--------|-----|-----|
| 라인 커버리지 | 45.2% | 80% |
| 함수 커버리지 | 52.1% | 70% |
| 브랜치 커버리지 | 38.7% | 60% |

### 레이어별 커버리지

| 레이어 | 커버리지 | 상태 |
|--------|---------|------|
| domain/usecases | 85% | ✅ |
| domain/entities | 100% | ✅ |
| data/repositories | 62% | ⚠️ |
| data/dto | 45% | ❌ |
| presentation | 12% | ❌ |

### 미커버 영역 (상위 5개)

| 파일 | 미커버 라인 | 우선순위 |
|------|-----------|---------|
| lib/presentation/screens/main_screen.dart | 120/180 | P1 |
| lib/data/repositories/diary_repository_impl.dart | 45/120 | P1 |
| lib/presentation/widgets/result_card.dart | 35/60 | P2 |
| lib/core/services/analytics_service.dart | 30/50 | P2 |
| lib/presentation/screens/settings_screen.dart | 25/40 | P3 |
```

## 출력 형식

```
📊 테스트 커버리지 리포트

전체 커버리지: 45.2%

레이어별:
├── domain/usecases: 85% ✅
├── domain/entities: 100% ✅
├── data/repositories: 62% ⚠️
├── data/dto: 45% ❌
└── presentation: 12% ❌

미커버 상위 파일:
├── main_screen.dart (67% 미커버)
├── diary_repository_impl.dart (38% 미커버)
└── result_card.dart (58% 미커버)

🎯 권장 사항:
   └─ /test-unit-gen lib/data/repositories/diary_repository_impl.dart
```

## CI 연동

```yaml
# .github/workflows/ci.yml
- name: Run Tests with Coverage
  run: flutter test --coverage

- name: Upload Coverage to Codecov
  uses: codecov/codecov-action@v4
  with:
    files: coverage/lcov.info
```

## 커버리지 목표

| 레이어 | 목표 | 설명 |
|--------|-----|------|
| domain/usecases | ≥80% | 비즈니스 로직 핵심 |
| domain/entities | ≥90% | 도메인 모델 |
| data/repositories | ≥70% | 데이터 액세스 |
| presentation | ≥50% | UI 로직 |

## 사용 예시

```
> "/coverage"

AI 응답:
1. flutter test --coverage 실행
2. 커버리지 데이터 분석
3. 리포트 생성:
   - 전체: 45.2%
   - domain: 85% ✅
   - data: 62% ⚠️
   - presentation: 12% ❌
4. 미커버 영역 5개 식별
5. 테스트 생성 권장 목록 제공
```

## 연관 스킬
- `/test-unit-gen [파일]` - 미커버 파일에 테스트 생성
- `/mock [repository]` - Mock 클래스 생성

## 주의사항
- `*.g.dart`, `*.freezed.dart`는 커버리지 계산에서 제외
- 위젯 테스트는 별도 실행 필요 (integration_test)
- Codecov 토큰은 GitHub Secrets에 저장
