# performance-expert

Flutter 앱 성능 분석, 최적화, 프로파일링 전문가 스킬

## 목표
- 앱 성능 병목 식별
- 렌더링 최적화
- 메모리 및 CPU 사용량 개선

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "성능 최적화", "performance 개선" 요청
- `/performance [action]` 명령어
- 렌더링/빌드 성능 이슈 발생 시
- 메모리 누수 의심 시

## 핵심 파일
| 파일 | 역할 |
|------|------|
| `lib/presentation/screens/*.dart` | 화면 위젯 |
| `lib/presentation/widgets/*.dart` | 재사용 위젯 |
| `lib/presentation/providers/*.dart` | 상태 관리 |
| `lib/data/datasources/local/*.dart` | 로컬 DB 접근 |
| `lib/data/datasources/remote/*.dart` | API 호출 |

## 성능 측정 도구

### Flutter DevTools
```
주요 탭:
├── Flutter Inspector - 위젯 트리 분석
├── Performance - 프레임 렌더링 분석
├── CPU Profiler - 함수 실행 시간
├── Memory - 메모리 사용량 추적
└── Network - 네트워크 요청 분석
```

### 프로파일 빌드
```bash
# 프로파일 모드로 실행
flutter run --profile

# DevTools 연결
flutter pub global run devtools
```

## 프로세스

### Action 1: analyze-rendering
렌더링 성능 분석

```
Step 1: 프로파일 모드 빌드
  - flutter run --profile

Step 2: Performance Overlay 활성화
  - DevTools → Performance

Step 3: 프레임 분석
  - 16ms 초과 프레임 식별
  - Build/Layout/Paint 단계 분석

Step 4: 문제 위젯 식별
  - 불필요한 리빌드
  - 복잡한 레이아웃
  - 오버드로우

Step 5: 최적화 적용
```

**리빌드 최적화 패턴:**
```dart
// ❌ 전체 리빌드
Consumer<DiaryListNotifier>(
  builder: (context, notifier, _) {
    return ListView.builder(...);
  },
)

// ✅ 선택적 리빌드 (select 사용)
Consumer<DiaryListNotifier>(
  builder: (context, notifier, child) {
    final count = ref.watch(diaryListProvider.select((s) => s.diaries.length));
    return Text('$count items');
  },
)
```

### Action 2: optimize-build
위젯 빌드 최적화

```
Step 1: 불필요한 리빌드 식별
  - Consumer/Watch 범위 검토
  - const 생성자 활용 여부

Step 2: const 위젯 적용
  - 정적 위젯에 const 추가
  - 리터럴 위젯 분리

Step 3: RepaintBoundary 적용
  - 독립적으로 그려지는 영역 분리
  - 애니메이션 영역 격리

Step 4: shouldRepaint/shouldRebuild 구현
  - CustomPainter 최적화
  - Selector 활용

Step 5: 결과 측정
```

**const 최적화:**
```dart
// ❌ 매번 새 인스턴스
Widget build(BuildContext context) {
  return Padding(
    padding: EdgeInsets.all(16),  // 매번 새 EdgeInsets
    child: Text('Hello'),         // 매번 새 Text
  );
}

// ✅ const 인스턴스 재사용
Widget build(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Hello'),
  );
}
```

### Action 3: optimize-list
리스트 렌더링 최적화

```
Step 1: ListView 유형 확인
  - ListView() vs ListView.builder()
  - 아이템 수에 따른 선택

Step 2: itemExtent 설정
  - 고정 높이 아이템에 적용
  - 스크롤 성능 향상

Step 3: cacheExtent 조정
  - 선렌더링 범위 설정
  - 메모리 vs 부드러움 트레이드오프

Step 4: 아이템 위젯 최적화
  - const 생성자
  - 불필요한 상태 제거

Step 5: 지연 로딩 구현
  - 페이지네이션
  - 무한 스크롤
```

**리스트 최적화 패턴:**
```dart
// ❌ 느린 리스트
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)

// ✅ 최적화된 리스트
ListView.builder(
  itemCount: items.length,
  itemExtent: 72.0,  // 고정 높이
  cacheExtent: 500.0,  // 캐시 범위
  itemBuilder: (context, index) {
    return const ItemWidget(item: items[index]);
  },
)
```

### Action 4: analyze-memory
메모리 사용량 분석

```
Step 1: Memory 탭 열기
  - DevTools → Memory

Step 2: 힙 스냅샷 촬영
  - 특정 시점 메모리 상태

Step 3: 메모리 누수 감지
  - 증가 추세 확인
  - dispose 누락 검사

Step 4: 대형 객체 식별
  - 이미지 캐시
  - 리스트 데이터

Step 5: 최적화 적용
  - 캐시 정책 조정
  - 리소스 해제
```

**메모리 누수 방지:**
```dart
class _MyWidgetState extends State<MyWidget> {
  StreamSubscription? _subscription;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _subscription = stream.listen((_) {});
    _timer = Timer.periodic(duration, (_) {});
  }

  @override
  void dispose() {
    _subscription?.cancel();  // ✅ 구독 취소
    _timer?.cancel();          // ✅ 타이머 취소
    super.dispose();
  }
}
```

### Action 5: optimize-images
이미지 로딩 최적화

```
Step 1: 이미지 크기 분석
  - 원본 vs 표시 크기
  - 불필요한 고해상도

Step 2: 캐싱 전략 설정
  - CachedNetworkImage 사용
  - 캐시 크기 제한

Step 3: 이미지 포맷 최적화
  - WebP 사용 고려
  - 적절한 압축률

Step 4: 지연 로딩 구현
  - 뷰포트 내 이미지만 로드
  - 플레이스홀더 사용

Step 5: 메모리 해제
  - 화면 이탈 시 이미지 해제
  - LRU 캐시 정책
```

**이미지 캐싱 패턴:**
```dart
// CachedNetworkImage 사용
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  memCacheWidth: 200,  // 메모리 캐시 크기 제한
  memCacheHeight: 200,
)
```

### Action 6: optimize-async
비동기 작업 최적화

```
Step 1: 병렬 실행 기회 식별
  - 독립적인 Future들
  - Future.wait 활용

Step 2: 불필요한 await 제거
  - fire-and-forget 패턴
  - 비동기 초기화

Step 3: compute/isolate 활용
  - CPU 집약적 작업
  - JSON 파싱 분리

Step 4: 디바운스/스로틀 적용
  - 검색 입력
  - 스크롤 이벤트

Step 5: 캐시 전략
  - 메모이제이션
  - 결과 캐싱
```

**병렬 실행 패턴:**
```dart
// ❌ 순차 실행
final result1 = await fetchData1();
final result2 = await fetchData2();
final result3 = await fetchData3();

// ✅ 병렬 실행
final results = await Future.wait([
  fetchData1(),
  fetchData2(),
  fetchData3(),
]);
```

### Action 7: performance-report
성능 분석 리포트 생성

```
Step 1: 현재 성능 지표 수집
  - 프레임 레이트
  - 빌드 시간
  - 메모리 사용량

Step 2: 병목 지점 식별
  - 느린 위젯
  - 무거운 연산
  - 과도한 리빌드

Step 3: 최적화 우선순위
  - 사용자 체감 영향도
  - 구현 난이도

Step 4: 권장 조치 목록
  - 즉시 적용 가능
  - 리팩토링 필요
```

## 성능 체크리스트

### 렌더링 성능
```
□ const 생성자 활용
□ 불필요한 리빌드 제거
□ RepaintBoundary 적용
□ ListView.builder 사용
□ itemExtent 설정
□ 애니메이션 최적화
```

### 메모리 관리
```
□ dispose에서 리소스 해제
□ 이미지 캐시 크기 제한
□ 스트림 구독 취소
□ 대형 리스트 페이지네이션
□ 불필요한 객체 생성 제거
```

### 비동기 최적화
```
□ Future.wait로 병렬 실행
□ compute/isolate 활용
□ 디바운스/스로틀 적용
□ 결과 캐싱
□ 에러 핸들링
```

## 출력 형식

```
⚡ Performance Expert 분석 결과

Action: [실행한 액션]

성능 지표:
├── 평균 프레임 시간: 12ms (60fps ✅)
├── 빌드 시간: 8ms (목표: <16ms ✅)
├── 메모리 사용: 120MB (목표: <200MB ✅)
└── 느린 프레임: 3개/분 (목표: <5개 ✅)

발견된 이슈:
├── 🔴 P1: DiaryCard 과도한 리빌드 (12회/초)
├── 🟡 P2: ListView 전체 렌더링
└── 🟢 P3: 이미지 캐시 미설정

최적화 제안:
├── DiaryCard에 const 생성자 적용
├── ListView.builder로 변경
└── CachedNetworkImage 도입

수정 파일:
├── lib/presentation/widgets/diary_card.dart
└── lib/presentation/screens/diary_list_screen.dart

예상 개선:
└── 프레임 시간 30% 감소, 메모리 20% 절감
```

## 사용 예시

### 렌더링 분석
```
> "/performance analyze-rendering"

AI 응답:
1. DiaryListScreen 분석
2. 발견된 이슈:
   - DiaryCard 과도한 리빌드
   - 전체 ListView 렌더링
3. 최적화 적용:
   - const 생성자 추가
   - ListView.builder 변환
4. 결과: 프레임 시간 40% 감소
```

### 메모리 최적화
```
> "/performance optimize-memory"

AI 응답:
1. 메모리 사용량 분석
2. 발견된 이슈:
   - 이미지 캐시 무제한
   - 스트림 구독 미해제
3. 최적화 적용:
   - 캐시 크기 제한
   - dispose 메서드 수정
4. 결과: 메모리 25% 절감
```

## 연관 스킬
- `/db optimize-query` - DB 쿼리 최적화
- `/groq optimize-tokens` - AI 호출 최적화
- `/lint-fix` - 코드 품질 개선

## 주의사항
- 프로파일 모드에서만 정확한 성능 측정 가능
- 디버그 모드는 성능이 저하되므로 참고용
- 과도한 최적화는 코드 가독성 저하
- 사용자 체감 성능 중심으로 우선순위 결정
- 성능 테스트는 실제 디바이스에서 수행
- 최적화 전후 측정으로 효과 검증 필수
