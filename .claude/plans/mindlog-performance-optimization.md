# MindLog Flutter 성능 향상 계획서

> **100년차 플러터 전문가 브리핑**
> 작성일: 2026-01-26
> 대상: MindLog 감정 일기 앱

---

## 1. 현황 분석 요약

### 프로젝트 성능 현황

| 영역 | 현재 등급 | 주요 이슈 |
|------|----------|----------|
| **빌드 최적화** | B+ | const 사용 양호, IndexedStack 메모리 점유 |
| **데이터 레이어** | A- | 복합 인덱스 최적화 완료, 캐싱 부재 |
| **UI 렌더링** | C+ | RepaintBoundary 미사용 |
| **상태 관리** | B | ref.select() 미사용 |
| **이미지 처리** | C | UI 스레드 블로킹, 캐싱 없음 |
| **비동기 처리** | B- | Isolate 미사용, 순차 처리 |

### 발견된 핵심 병목

| 우선순위 | 이슈 | 파일 | 영향도 |
|----------|------|------|--------|
| **P0** | Base64 인코딩 UI 블로킹 | `image_service.dart` | 높음 |
| **P1** | RepaintBoundary 미사용 | 차트/그리드 위젯 5개 | 높음 |
| **P1** | Provider 전체 객체 watch | `statistics_screen.dart` 등 | 중간 |
| **P2** | 이미지 인코딩 순차 처리 | `image_service.dart` | 중간 |
| **P2** | 일기 목록 전체 로드 | `sqlite_local_datasource.dart` | 높음 |
| **P3** | 이미지 캐싱 없음 | `diary_image_gallery.dart` | 낮음 |

---

## 2. 설계 이유

### 왜 이렇게 설계했는가?

**1. P0 - Base64 인코딩 Isolate 처리**

- **문제점**: `encodeToBase64DataUrl()`이 UI 스레드에서 실행
  - 4MB 이미지 → Base64 ~5.3MB (33% 증가)
  - 인코딩 중 UI 프리징 발생

- **해결 전략**: `compute()` 함수로 별도 Isolate에서 실행
  - Flutter 공식 문서 권장 패턴 (Context7 확인)
  - `flutter_image_compress`는 이미 네이티브 비동기 → 추가 처리 불필요

- **대안 검토**:
  - `Isolate.spawn()` 직접 사용 → 과도한 복잡도
  - `compute()`가 단일 함수 실행에 최적

**2. P1 - RepaintBoundary 추가**

- **문제점**: 차트/그리드 위젯이 상위 위젯 rebuild 시 함께 repaint
  - `EmotionLineChart`: fl_chart의 CustomPaint
  - `ActivityHeatmap`: 168개 셀 (24주 × 7일)
  - `EmotionCalendar`: 42개 셀

- **해결 전략**: 렌더링 격리
  - RepaintBoundary로 감싸서 독립적 렌더링
  - 상위 위젯 변경 시에도 자식 repaint 방지

- **대안 검토**:
  - CustomPaint의 `shouldRepaint` 최적화 → fl_chart 수정 불가
  - RepaintBoundary가 가장 간단하고 효과적

**3. P1 - Provider select() 도입**

- **문제점**: 전체 객체 watch로 불필요한 rebuild
  ```dart
  // Before - 모든 필드 변경 시 rebuild
  final statistics = ref.watch(statisticsProvider);
  ```

- **해결 전략**: 필요한 필드만 select
  ```dart
  // After - 특정 필드 변경 시에만 rebuild
  final dailyEmotions = ref.watch(
    statisticsProvider.select((s) => s.dailyEmotions),
  );
  ```

- **대안 검토**:
  - 새로운 computed provider 생성 → 과도한 추상화
  - Consumer 위젯 분리 → select가 더 간단 (Context7 문서 확인)

---

## 3. 점검 알고리즘

```
알고리즘: VALIDATE_PERFORMANCE_PLAN
입력: 성능 최적화 계획 P
출력: 검증 결과 (PASS/FAIL + 수정사항)

FOR i = 1 TO 3:
  1. 우선순위 검증
     - 영향도 ∝ 우선순위 확인
     - 의존성 순서 확인 (P0 → P1 → P2 → P3)

  2. 대안 검토
     - 각 항목에 대해 더 나은 방법 탐색
     - Context7 최신 문서와 대조

  3. 실행 가능성 검증
     - 의존성 충돌 검사
     - 기존 테스트 영향도 분석
     - 점진적 적용 가능성 확인

  4. 위험 요소 식별
     - 롤백 용이성 평가
     - 성능 측정 가능성 확인

  IF 모든 항목 PASS:
    RETURN PASS
  ELSE:
    계획 수정 후 재검증
```

### 검증 결과

| 회차 | 검증 항목 | 결과 | 수정사항 |
|------|----------|------|----------|
| 1회차 | 우선순위 검증 | ✅ PASS | - |
| 1회차 | 대안 검토 | ⚠️ 수정 | 이미지 압축은 이미 비동기 |
| 1회차 | 실행 가능성 | ✅ PASS | - |
| 2회차 | 전체 재검증 | ✅ PASS | Base64만 Isolate 적용 |
| 3회차 | 최종 검증 | ✅ PASS | - |

**핵심 수정**: `flutter_image_compress`는 이미 네이티브 비동기 처리 → Base64 인코딩만 Isolate 필요

---

## 4. 단계별 실행 계획

### Phase 0: P0 - Base64 인코딩 Isolate 처리

#### Step 0.1: Top-level 함수 추가

**파일**: `lib/core/services/image_service.dart`

```dart
// Top-level function for Isolate (must be outside class)
Future<String> _encodeToBase64InIsolate(String imagePath) async {
  final file = File(imagePath);
  final bytes = await file.readAsBytes();
  final base64String = base64Encode(bytes);
  final extension = imagePath.toLowerCase().split('.').last;
  final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
  return 'data:$mimeType;base64,$base64String';
}
```

#### Step 0.2: compute() 적용

**파일**: `lib/core/services/image_service.dart`

```dart
// Before
Future<String> encodeToBase64DataUrl(String imagePath) async {
  final file = File(imagePath);
  final bytes = await file.readAsBytes();
  // ... 동기 처리
}

// After
Future<String> encodeToBase64DataUrl(String imagePath) async {
  return compute(_encodeToBase64InIsolate, imagePath);
}
```

#### Step 0.3: 검증

```bash
flutter test test/core/services/image_service_test.dart
# 시간 측정 로그 추가하여 성능 비교
```

---

### Phase 1: P1 - RepaintBoundary 추가

#### Step 1.1: EmotionLineChart 최적화

**파일**: `lib/presentation/widgets/emotion_line_chart.dart`

```dart
// Before
@override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: LineChart(...),
  );
}

// After
@override
Widget build(BuildContext context) {
  return RepaintBoundary(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(...),
    ),
  );
}
```

#### Step 1.2: ActivityHeatmap 최적화

**파일**: `lib/presentation/widgets/activity_heatmap.dart`

```dart
// _buildWeeksGrid 메서드 내 Row를 RepaintBoundary로 감싸기
Widget _buildWeeksGrid(List<List<DateTime>> weeks) {
  return Row(
    children: weeks.map((week) {
      return RepaintBoundary(  // 각 주별 격리
        child: _buildWeekColumn(week),
      );
    }).toList(),
  );
}
```

#### Step 1.3: EmotionGarden 최적화

**파일**: `lib/presentation/widgets/emotion_garden.dart`

동일 패턴 적용

#### Step 1.4: EmotionCalendar 최적화

**파일**: `lib/presentation/widgets/emotion_calendar/calendar_grid.dart`

```dart
// GridView.builder itemBuilder 내
return RepaintBoundary(
  child: DayCell(...),
);
```

#### Step 1.5: DiaryListScreen 카드 최적화

**파일**: `lib/presentation/screens/diary_list_screen.dart`

```dart
// ListView.separated itemBuilder 내
return RepaintBoundary(
  child: _buildDiaryCard(diary),
);
```

---

### Phase 2: P1 - Provider select() 도입

#### Step 2.1: StatisticsScreen 최적화

**파일**: `lib/presentation/screens/statistics_screen.dart`

```dart
// Before (Line ~41)
final statisticsAsync = ref.watch(statisticsProvider);

// After - 필요한 필드만 select
Widget _buildEmotionSection(WidgetRef ref) {
  final dailyEmotions = ref.watch(
    statisticsProvider.select((s) => s.value?.dailyEmotions),
  );
  // ...
}

Widget _buildActivitySection(WidgetRef ref) {
  final activityMap = ref.watch(
    statisticsProvider.select((s) => s.value?.activityMap),
  );
  // ...
}
```

#### Step 2.2: DiaryScreen 최적화

**파일**: `lib/presentation/screens/diary_screen.dart`

```dart
// Before (Line ~195)
final analysisState = ref.watch(diaryAnalysisControllerProvider);

// After
final isAnalyzing = ref.watch(
  diaryAnalysisControllerProvider.select((s) => s.isAnalyzing),
);
final analysisResult = ref.watch(
  diaryAnalysisControllerProvider.select((s) => s.analysisResult),
);
```

#### Step 2.3: MainScreen 탭 최적화

**파일**: `lib/presentation/screens/main_screen.dart`

```dart
// tabIndexProvider는 이미 단순 int라 select 불필요
// 하지만 Consumer로 범위 제한 가능
Consumer(
  builder: (context, ref, child) {
    final index = ref.watch(selectedTabIndexProvider);
    return IndexedStack(index: index, children: [...]);
  },
)
```

---

### Phase 3: P2 - 이미지 인코딩 병렬화

#### Step 3.1: Future.wait 적용

**파일**: `lib/core/services/image_service.dart`

```dart
// Before
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

// After
Future<List<String>> encodeMultipleToBase64DataUrls(
  List<String> imagePaths,
) async {
  return Future.wait(
    imagePaths.map((path) => encodeToBase64DataUrl(path)),
  );
}
```

---

### Phase 4: P2 - 일기 목록 Pagination (선택)

#### Step 4.1: DataSource 메서드 추가

**파일**: `lib/data/datasources/local/sqlite_local_datasource.dart`

```dart
Future<List<DiaryDTO>> getDiariesPaginated({
  required int limit,
  required int offset,
}) async {
  final db = await database;
  final result = await db.query(
    DiaryTable.tableName,
    orderBy: 'is_pinned DESC, created_at DESC',
    limit: limit,
    offset: offset,
  );
  return result.map(DiaryDTO.fromMap).toList();
}
```

#### Step 4.2: Repository 업데이트

**파일**: `lib/domain/repositories/diary_repository.dart`

```dart
Future<List<Diary>> getDiariesPaginated({
  required int limit,
  required int offset,
});
```

#### Step 4.3: UseCase 업데이트

추후 필요시 구현

---

### Phase 5: P3 - 이미지 캐싱 (선택)

#### Step 5.1: Image.file에 캐시 크기 추가

**파일**: `lib/presentation/widgets/diary_image_gallery.dart`

```dart
// Before
Image.file(File(imagePath), fit: BoxFit.cover)

// After
Image.file(
  File(imagePath),
  fit: BoxFit.cover,
  cacheWidth: 300,  // 목록용 썸네일 크기
  cacheHeight: 300,
)
```

---

## 5. 검증 방법

### 각 Phase 완료 후 실행

```bash
# 1. 정적 분석
flutter analyze --no-fatal-infos

# 2. 전체 테스트
flutter test

# 3. 성능 프로파일링
flutter run --profile
# DevTools > Performance 탭에서 프레임 드롭 확인

# 4. 메모리 프로파일링
# DevTools > Memory 탭에서 힙 사용량 확인

# 5. 빌드 확인
flutter build apk --debug
```

### 성능 측정 코드

```dart
// image_service.dart에 측정 로그 추가
Future<String> encodeToBase64DataUrl(String imagePath) async {
  final stopwatch = Stopwatch()..start();
  final result = await compute(_encodeToBase64InIsolate, imagePath);
  debugPrint('Base64 encoding: ${stopwatch.elapsedMilliseconds}ms');
  return result;
}
```

---

## 6. 수정 대상 파일 목록

### 핵심 수정 파일

| 파일 | Phase | 작업 |
|------|-------|------|
| `lib/core/services/image_service.dart` | 0, 3 | Isolate + 병렬화 |
| `lib/presentation/widgets/emotion_line_chart.dart` | 1 | RepaintBoundary |
| `lib/presentation/widgets/activity_heatmap.dart` | 1 | RepaintBoundary |
| `lib/presentation/widgets/emotion_garden.dart` | 1 | RepaintBoundary |
| `lib/presentation/widgets/emotion_calendar/calendar_grid.dart` | 1 | RepaintBoundary |
| `lib/presentation/screens/diary_list_screen.dart` | 1 | RepaintBoundary |
| `lib/presentation/screens/statistics_screen.dart` | 2 | Provider select |
| `lib/presentation/screens/diary_screen.dart` | 2 | Provider select |

### 선택적 수정 파일

| 파일 | Phase | 작업 |
|------|-------|------|
| `lib/data/datasources/local/sqlite_local_datasource.dart` | 4 | Pagination |
| `lib/presentation/widgets/diary_image_gallery.dart` | 5 | 이미지 캐싱 |

---

## 7. 제약사항 준수

| 제약 | 확인 방법 | 상태 |
|------|----------|------|
| SafetyBlockedFailure 수정 금지 | `failures.dart` 무변경 | ✅ 해당 없음 |
| is_emergency 필드 보존 | Entity/DTO 무변경 | ✅ 해당 없음 |
| 기존 테스트 통과 | `flutter test` 통과 | ✅ 계획됨 |
| 점진적 적용 | Phase별 독립 커밋 | ✅ 계획됨 |

---

## 8. 활용 도구 브리핑

| 도구 | 활용 시점 | 목적 |
|------|----------|------|
| **Explore Agent ×3** (병렬) | Phase 0 | 빌드/데이터/UI 레이어 동시 분석 |
| **Context7 MCP** | Phase 0 | Flutter Isolate, Riverpod select 최신 문서 확인 |
| **Sequential Thinking MCP** | Phase 0 | 3회 자체 검증 알고리즘 실행 |
| **Read Tool** | 분석 중 | 핵심 파일 직접 검증 |

### Context7 활용 내역

1. **Flutter 문서** (`/llmstxt/flutter_dev_llms_txt`)
   - Isolate 사용 패턴 확인
   - `compute()` 함수 권장 확인

2. **Riverpod 문서** (`/rrousselgit/riverpod`)
   - `ref.watch().select()` 패턴 확인
   - Consumer 위젯 최적화 패턴 확인

---

## 9. 예상 효과

| Phase | 작업 | 예상 효과 |
|-------|------|----------|
| Phase 0 | Base64 Isolate | UI 프리징 100% 해결 |
| Phase 1 | RepaintBoundary | 불필요한 repaint 70% 감소 |
| Phase 2 | Provider select | rebuild 50% 감소 |
| Phase 3 | 병렬화 | 다중 이미지 처리 3배 속도 향상 |
| Phase 4 | Pagination | 초기 로드 시간 50% 단축 |
| Phase 5 | 이미지 캐싱 | 메모리 사용량 30% 감소 |

---

## 10. 커밋 계획

```
perf(image): add Isolate processing for Base64 encoding
perf(ui): add RepaintBoundary to chart and grid widgets
perf(providers): introduce select() for optimized rebuilds
perf(image): parallelize multiple image encoding
perf(db): add pagination support for diary list
perf(image): add cache dimensions for thumbnails
```

---

## 11. 종합 평가

### 현재 코드 품질

MindLog는 이미 높은 수준의 코드 품질을 갖추고 있습니다:

✅ **우수한 부분**
- Clean Architecture 준수
- SQLite 복합 인덱스 최적화
- Circuit Breaker 패턴
- 접근성 (reduced motion) 지원
- DateFormat 인스턴스 재사용

⚠️ **개선 필요**
- 이미지 처리 UI 블로킹
- RepaintBoundary 미사용
- Provider 전체 객체 watch

### 최종 권장

| 우선순위 | 권장 실행 순서 |
|----------|---------------|
| **즉시** | Phase 0 (Isolate) → Phase 1 (RepaintBoundary) |
| **단기** | Phase 2 (Provider select) → Phase 3 (병렬화) |
| **중기** | Phase 4 (Pagination) - 일기 100개 이상 시 |
| **장기** | Phase 5 (이미지 캐싱) - 메모리 이슈 발생 시 |

---

**계획서 작성 완료**: 2026-01-26
**검증 횟수**: 3회 (모두 PASS)
**다음 단계**: 계획 승인 후 Phase 0 시작
