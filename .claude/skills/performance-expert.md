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

### Action 8: audit-http-timeouts
HTTP 호출 타임아웃 누락 자동 감사

```
Step 1: 코드베이스 스캔
  - lib/data/datasources/remote/ 디렉토리 대상
  - http.Client의 .post(), .get(), .put(), .delete() 호출 탐색
  - .timeout() 체인이 없는 호출 식별

Step 2: 위험도 분류
  - 🔴 P0: 사용자 대면 API (분석, 저장 등) — 무한 대기 → UX 블로킹
  - 🟡 P1: 백그라운드 API (FCM, 업데이트 체크) — 리소스 누수
  - 🟢 P2: 초기화 API (설정 로드) — 앱 시작 지연

Step 3: 자동 수정 적용
  - .post(url, ...) → .post(url, ...).timeout(Duration(seconds: 30))
  - 기존 TimeoutException 핸들러 확인 → 없으면 추가 필요 경고

Step 4: 검증
  - 기존 테스트 실행 확인
  - TimeoutException 핸들러 존재 여부 확인
```

**스캔 명령어:**
```bash
# 타임아웃 누락 HTTP 호출 찾기
grep -rn "\.post\|\.get\|\.put\|\.delete" lib/data/datasources/remote/ \
  --include="*.dart" | grep -v "timeout"
```

**수정 패턴:**
```dart
// ❌ 타임아웃 없음 — 무한 대기 가능
final response = await _client.post(uri, headers: h, body: b);

// ✅ 30초 타임아웃 적용
static const Duration _httpTimeout = Duration(seconds: 30);
final response = await _client.post(uri, headers: h, body: b)
    .timeout(_httpTimeout);
```

**중요 규칙:**
- 기존 retry 로직의 `on TimeoutException` 핸들러가 `.timeout()`과 연동됨
- `.timeout()` 없이는 `TimeoutException`이 발생하지 않음 — 핸들러 무용지물
- 클래스 상수로 `_httpTimeout` 정의 (테스트에서 조정 가능)

---

### Action 9: audit-image-cache
이미지 cacheWidth/cacheHeight 누락 자동 감사

```
Step 1: 코드베이스 스캔
  - Image.file(), Image.asset(), Image.network() 사용처 탐색
  - cacheWidth/cacheHeight 미설정 위젯 식별

Step 2: 표시 크기 분석
  - width/height 속성에서 표시 크기 추출
  - 없으면 컨텍스트에서 추론 (Container 부모, GridView 등)

Step 3: 캐시 크기 계산 및 적용
  - 고정 크기: displaySize × 3 (최대 DPR 대응)
  - 동적 크기: MediaQuery.of(context).devicePixelRatio 활용
  - 테스트 환경 guard: rawSize > 0 ? rawSize : null

Step 4: 검증
  - 위젯 테스트 실행 (MediaQuery.size == 0 assertion 체크)
  - DevTools "Invert Oversized Images"로 시각적 확인
```

**스캔 명령어:**
```bash
# cacheWidth 누락 이미지 찾기
grep -rn "Image\.\(file\|asset\|network\)" lib/presentation/ \
  --include="*.dart" | grep -v "cacheWidth"
```

**수정 패턴 — 고정 크기:**
```dart
// ❌ 44x44 표시에 원본(수천 px) 로드
Image.asset(path, width: 44, height: 44, fit: BoxFit.cover)

// ✅ 3x DPR 대응 캐시 크기 (44 × 3 = 132)
Image.asset(path, width: 44, height: 44,
    cacheWidth: 132, cacheHeight: 132, fit: BoxFit.cover)
```

**수정 패턴 — 동적 크기 (그리드/리스트):**
```dart
// MediaQuery 기반 DPR-aware 캐시 크기
final mq = MediaQuery.of(context);
final rawSize = (displayWidth * mq.devicePixelRatio).toInt();
final cacheSize = rawSize > 0 ? rawSize : null;  // 테스트 환경 guard

Image.file(file, cacheWidth: cacheSize, cacheHeight: cacheSize,
    fit: BoxFit.cover)
```

**캐시 크기 참조표:**
| 표시 크기 | cacheWidth | 절감율 | 용도 |
|-----------|-----------|--------|------|
| 44×44 | 132 | ~95% | 아이콘, 썸네일 |
| 80×80 | 240 | ~93% | 미리보기 타일 |
| 화면 절반 | DPR 계산 | ~80% | 그리드 갤러리 |
| 전체 화면 (줌) | **미적용** | 0% | FullscreenViewer (4x 줌) |

**주의사항:**
- `cacheWidth`/`cacheHeight`는 **반드시 > 0** (Flutter assertion)
- 테스트 환경: `MediaQuery.of(context).size.width == 0` → null guard 필수
- 전체화면 이미지 뷰어(InteractiveViewer): 줌 지원 시 캐시 미적용 권장
- Image.asset의 경우 에셋 자체가 작으면 효과 제한적 (번들 해상도 확인)

---

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

### 자동 감사 (Automated Audits)
```
□ HTTP 호출 .timeout() 설정 (audit-http-timeouts)
□ Image cacheWidth/cacheHeight 설정 (audit-image-cache)
□ 테스트 환경 MediaQuery.size guard
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
