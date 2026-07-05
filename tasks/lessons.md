# Lessons Learned

수정 요청 수신 시 자동 기록. 세션 시작 시 검토 후 구현 진행.

**TRIGGER**: 사용자 수정 요청 수신 즉시 (구현 전) 이 파일에 기록.

**분류**: 프로덕션 앱 동작에 영향 있으면 → `/troubleshoot-save` 도 함께 실행 (troubleshooting.json + 상세 MD 생성)

---

<!-- 형식:
## [날짜] - [교훈 제목]
**무엇이 잘못됐나**: [설명]
**근본 원인**: [분석]
**해결책**: [솔루션]
**예방 규칙**: [다음 번에 어떻게 피할지]
-->

## 2026-02 - flutter_animate + pumpAndSettle 충돌
**무엇이 잘못됐나**: flutter_animate 사용 위젯 테스트에서 `pumpAndSettle()` 사용 → 무한 루프로 타임아웃
**근본 원인**: flutter_animate의 무한 반복 애니메이션이 `pumpAndSettle`의 "모든 프레임 처리" 조건을 영원히 충족시키지 못함
**해결책**: `pump(const Duration(milliseconds: 500))` × 4회 + `setUpAll(() { Animate.restartOnHotReload = false; })`
**예방 규칙**: flutter_animate 사용 위젯 테스트에서 `pumpAndSettle` 절대 금지. MEMORY.md Testing Patterns 참조.

## 2026-02 - FCM 알림 body 빈 문자열 금지
**무엇이 잘못됐나**: FCM 마음케어 알림에 빈 body 전달 → 알림 표시 안 됨
**근본 원인**: `notification` payload의 body가 비어있으면 Android/iOS에서 알림 무시
**해결책**: `NotificationMessages.getRandomMindcareBody()` 사용 강제화
**예방 규칙**: FCM body는 항상 `NotificationMessages.*` 상수에서 가져올 것. 빈 문자열 리터럴 금지.

## 2026-07 - 알림 ID 분산 정의 위험 (P1-3/P1-4)
**무엇이 잘못됐나**: weekly(2002), safety(2004), CBT(3001+) ID가 서비스별 하드코딩 또는 로컬 const → 중복/충돌 위험, 유지보수 어려움.
**근본 원인**: ID 정책이 NotificationService에 중앙화되지 않고, 동적 ID 생성에 pending 검사 없음. partial schedule 실패 시 전체 중단.
**해결책**: NotificationService에 모든 ID 상수 + generateCbt... 헬퍼. scheduleNextMorning에 getPending + 충돌 회피. _applyCheerMeQueueDiff per-item try/catch resilience. mindcare {name} 금지 + 경계 테스트 보강.
**예방 규칙**: 새 알림 타입 추가 시 반드시 NotificationService 상수 + ID 범위 문서화. 큐 apply 로직은 항상 per-item 실패 허용 + 로깅. notification-audit 스킬 주기적 실행.

## 2026-02-27 - 테스트 플랫폼 서비스 side effect 미가드 → CI 로그 노이즈
**무엇이 잘못됐나**: 위젯/프로바이더 테스트에서 플랫폼 서비스(FlutterLocalNotificationsPlugin, NotificationSettingsService) 오버라이드 없이 실제 호출 → `LateInitializationError`, `UnknownFailure` 로그가 CI에 반복 출력 (테스트는 통과)
**근본 원인**: 위젯 탭이 Controller → UseCase → 실제 플랫폼 서비스 체인을 타는데, 테스트 setUp에서 해당 서비스의 override를 설정하지 않음
**해결책**: `Service.methodOverride = ({...}) async {};` in setUp + `Service.resetForTesting();` in tearDown. 각 서비스의 `@visibleForTesting static Function? override` 필드 전부 설정 필요
**예방 규칙**: 위젯 탭이나 Provider 상태 변경을 테스트할 때, 호출 체인 끝의 플랫폼 서비스 오버라이드도 setUp에 포함할 것. `docs/til/FLUTTER_TESTING_STATIC_OVERRIDE_PATTERN_TIL.md` 참조.

## 2026-02-27 - session-wrap 시 tasks/lessons.md 누락
**무엇이 잘못됐나**: session-wrap 실행 시 TIL 파일(`docs/til/`)만 생성하고 `tasks/lessons.md` 업데이트를 빠뜨림
**근본 원인**: session-wrap 스킬이 TIL 생성에 집중되어 있고, continuous-improvement 규칙의 `tasks/lessons.md` 기록 의무를 별도로 체크하지 않음
**해결책**: session-wrap 완료 후 항상 `tasks/lessons.md` 업데이트 수행
**예방 규칙**: session-wrap 마지막 단계에 `tasks/lessons.md` 기록을 명시적 체크 항목으로 추가.

## 2026-02-27 - TIL 경로 오인 (tasks/ vs docs/til/)
**무엇이 잘못됐나**: MEMORY.md Memory Index에서 TIL 파일 경로를 `tasks/til-*.md`로 잘못 인식
**근본 원인**: 프로젝트에 `tasks/` 디렉토리가 있고 TIL과 무관한 파일들이 있어 혼동 발생
**해결책**: 실제 TIL 경로는 `docs/til/` (INDEX.md + 9개 파일). `docs/til/INDEX.md` MEMORY.md에 참조 추가
**예방 규칙**: TIL 검색 시 `docs/til/INDEX.md` 먼저 확인. `tasks/` 폴더는 TODO/lessons 전용.

## 2026-02-27 - A11y 색상 마이그레이션: theme-aware 매핑 패턴 확립
**무엇이 잘못됐나**: N/A (신규 패턴 정립)
**근본 원인**: Colors.black/white/grey 하드코딩 → dark mode에서 대비 불일치
**해결책**: 의미론적 colorScheme 토큰으로 대체 (scrim/shadow/onSurface/onSurfaceVariant/surfaceContainerLowest)
**예방 규칙**: 오버레이 배경→scrim, 반투명 어두운 bg→shadow, 텍스트on어두운배경→onSurface, 보조텍스트→onSurfaceVariant, 오류컨테이너bg→surfaceContainerLowest. `Color.lerp(..., Colors.white)` → colorScheme.surface 사용.

## 2026-02-27 - AccessibilityWrapper 병렬 서브에이전트 처리 주의사항
**무엇이 잘못됐나**: 서브에이전트가 14개 화면 처리 중 일부(secret_diary_unlock, secret_pin_setup)를 먼저 완료했는데, 내가 grep 할 때 아직 파일이 쓰이지 않은 시점이라 0건으로 오독
**근본 원인**: 비동기 서브에이전트 완료 전 grep 실행 → 결과 불일치
**해결책**: 서브에이전트 완료 알림(task-notification) 받은 후 검증 실행
**예방 규칙**: 백그라운드 에이전트 결과는 notification 확인 후 검증. 중간 점검은 "아직 진행 중" 전제 하에 해석.

## 2026-02-27 - Flutter Zone mismatch: binding 초기화 위치 오류
**무엇이 잘못됐나**: `MarionetteBinding.ensureInitialized()`를 `runZonedGuarded` 외부(root zone)에서 호출 → binding이 root zone에 등록됨. 이후 `runApp()`은 `runZonedGuarded` 내부 zone에서 실행 → Zone mismatch assertion.
**근본 원인**: Flutter binding은 초기화된 zone을 기억함. `runApp()`은 동일 zone에서 호출해야 하는데, `MarionetteBinding.ensureInitialized()`가 `runZonedGuarded` 바깥에 있어 다른 zone에 등록됨.
**해결책**: `ErrorBoundary.runAppWithErrorHandling`에 `bindingInitializer` 파라미터 추가. `main()`에서 `MarionetteBinding.ensureInitialized`를 `bindingInitializer`로 전달 → `runZonedGuarded` 내부에서 올바른 zone으로 초기화.
**예방 규칙**: `runZonedGuarded` + `runApp` 패턴 사용 시, 모든 binding 초기화(WidgetsFlutterBinding, MarionetteBinding 등)는 반드시 같은 zone 내에서 호출. 커스텀 binding이 있으면 `bindingInitializer` 콜백 패턴 사용.

## 2026-02-27 - 디자인 토큰 통일: 이중 primary 제거
**무엇이 잘못됐나**: AppColors.primary(보라 #6B5B95)와 AppTheme.primaryColor(하늘 #7EC8E3)가 공존 — 브랜드 아이덴티티 불일치
**근본 원인**: 통계 화면 추가 시 새 하늘색 primary를 AppColors가 아닌 AppTheme에만 추가, 기존 보라색을 제거하지 않음
**해결책**: AppColors.primary → #87CEEB(파스텔 하늘), primaryDark → #4A90B8(텍스트용, WCAG AA), background → #F0F8FF
**예방 규칙**: primary 계열은 AppColors 단일 출처 원칙. 텍스트용(primaryDark)과 아이콘/강조선용(primary) 분리. design-token-rules.md 5-step decision 트리 먼저 확인.

## 2026-02-27 - 서브에이전트 Write 권한: .claude/ 신규 파일 생성 불가
**무엇이 잘못됐나**: 백그라운드 서브에이전트가 `.claude/rules/`, `.claude/skills/`, `.claude/commands/` 하위 신규 파일 Write 권한을 얻지 못해 차단됨
**근본 원인**: 서브에이전트 기본 권한에서 `.claude/` 경로 내 신규 파일 생성은 허용 안 됨 (보안 정책)
**해결책**: 서브에이전트는 기존 파일 편집(Edit)만 위임. 신규 파일(Write)은 메인 에이전트가 직접 생성
**예방 규칙**: Task 위임 시 "신규 파일 생성"은 메인 에이전트 몫. 서브에이전트 프롬프트에서 `.claude/` 내 Write 작업 제거.

## 2026-02-27 - Flutter loose constraint 전파: Stack → Column 수평 정렬 버그
**무엇이 잘못됐나**: Stack 내 Column(mainAxisSize.min)이 좌측 정렬처럼 보임 — crossAxisAlignment: center 명시에도 불구
**근본 원인**: Stack이 non-positioned 자식에게 loose 제약(0~maxWidth) 전달. SingleChildScrollView가 이를 그대로 하위에 전달(copyWith(maxHeight: ∞)). Column이 loose width 받으면 가장 넓은 자식 너비로 수축 → Padding 좌측 끝에 붙음.
**해결책**: Column 위에 `SizedBox(width: double.infinity)` 래퍼 추가. Loose 제약 안에서 double.infinity는 max값(screenWidth-48)으로 클램핑되어 Column에 tight 제약 전달.
**예방 규칙**: Stack 내 SingleChildScrollView + Column(mainAxisSize.min) 패턴 사용 시 Column을 반드시 SizedBox(width: double.infinity)로 감싸야 정상 중앙 정렬. Responsive layout pattern 참조.

## 2026-02-28 - KoreanTextFilter length guard가 짧은 교정 결과를 차단
**무엇이 잘못됐나**: `filterMessage()` 내 `filtered.length < 10` 가드가 "30분간 산책하기"(9자) 같은 정상 교정 결과를 차단하고 원문을 반환함
**근본 원인**: 외국어 오염 감지 시 적용하는 최소 길이 가드가, 중복 동사 패턴처럼 경미한 오류 교정에는 부적합
**해결책**: `_redundantDoPattern`을 `hasIssue` 트리거에서 제외하고, `!hasIssue` 경량 교정 브랜치에 `_removeRedundantVerbPattern()` 추가 → length 가드 우회
**예방 규칙**: `filterMessage` 경량 브랜치(`!hasIssue`)는 항상 안전하게 반환. 새 교정 로직 추가 시 length 가드가 있는 `processKoreanText` 경로를 타는지 확인할 것.

## 2026-03-14 - Cheer Me {name} 플레이스홀더 미치환: 4개 근본 원인
**무엇이 잘못됐나**: Cheer Me 알림 제목에 `{name}님의 응원 메시지` 리터럴이 그대로 표시됨
**근본 원인**: (D) 정규식 `[,의은을이]?`가 2자 조사 `에게`/`께` 미커버 → `님에게` 잔류. (C) `getRandomReminderTitle()`이 개인화 미적용. (B) `valueOrNull ?? []` = AsyncLoading 시 null → reschedule 스킵. (A) `hasReminder=true` 조기반환이 stale `{name}` 알림 무시
**해결책**: (D) 정규식 → `(?:[,의은을이]|에게|께)?`. (C) optional userName 파라미터 추가. (B) `await selfEncouragementProvider.future`로 로딩 완료 대기. (A) `hasPlaceholder` 체크 추가 → `{name}` 포함 시 강제 재스케줄
**예방 규칙**: character class `[...]`는 1글자만 매칭 — 2자 이상 패턴은 반드시 `(?:...|...)` alternation. `valueOrNull`은 AsyncLoading = null 반환 → 로딩 대기 필요 시 `.future` await 사용

## 2026-03-16 - mocktail when() 클로저가 카운팅 Mock을 선 증가시킴
**무엇이 잘못됐나**: `_CountingMock` 테스트에서 `expect(callCount, 1)`이 actual 2로 실패
**근본 원인**: `when(() => mock.execute(...))` 호출 시 클로저가 한 번 실행됨 → `_CountingMock.execute()` 내 `callCount++` 가 stub 등록 시점에 선행 실행
**해결책**: `when(...).thenThrow(...)` 이후 `mock.callCount = 0;` 리셋 추가
**예방 규칙**: 호출 횟수를 카운팅하는 Mock 사용 시, `when()` 설정 후 반드시 카운터를 0으로 리셋할 것. `when()` 클로저는 "등록"이 아니라 "실행"이다.

## 2026-03-15 - mocktail 전환: thenThrow vs thenAnswer 패턴 선택
**무엇이 잘못됐나**: Phase 2 mocktail 전환 중 3가지 패턴으로 테스트 실패 발생
**근본 원인**:
- (1) non-async UseCase + thenThrow: `execute()` 비동기 아님 → thenThrow 동기 throw → `expectLater`에 전달할 Future 없음
- (2) mocktail verify 소비: `verify(any, any).called(n)` 후 인터랙션 [VERIFIED] 마킹 → 이후 specific verify 실패
- (3) extends Mock 기본 동작 없음: 수동 Mock에 있던 sort 로직 미포함
**해결책**:
- (1) `thenAnswer((_) async => throw SomeFailure())` 사용
- (2) generic `any()` verify 제거, specific argument verify만 남김
- (3) `_sort()` 헬퍼 메서드를 `_fetchDiaries()` 내부에서 호출
**예방 규칙**: Non-async UseCase Failure 테스트는 `thenAnswer(async throw)` 강제. verify 체인 시 generic verify 제거 필수.

## 2026-03-16 - freezed toString은 camelCase 필드명 그대로 출력
**무엇이 잘못됐나**: `DailyEmotion` freezed 전환 후 `contains('score: 8.0')` 테스트 실패
**근본 원인**: 원래 커스텀 toString은 `score: $averageScore` (소문자 별칭)를 사용. freezed 생성 toString은 필드명 그대로 `averageScore: 8.0` (camelCase S 대문자) 출력
**해결책**: 테스트를 `contains('averageScore: 8.0')` / `contains('diaryCount: 2')` 로 수정
**예방 규칙**: freezed 전환 시 커스텀 toString에 별칭(score:, count: 등)이 있으면 반드시 테스트 기대값을 freezed 필드명 형식으로 업데이트할 것.

## 2026-03-16 - @Freezed(copyWith: false)로 clamp 등 커스텀 copyWith 보존
**무엇이 잘못됐나**: freezed 기본 생성 copyWith은 clamping 같은 사이드 로직을 수행하지 않음
**근본 원인**: freezed 표준 copyWith은 단순 필드 교체만 수행 — 검증/변환 로직 불포함
**해결책**: `@Freezed(copyWith: false)` + `const ClassName._()` 패턴으로 직접 copyWith 구현. 기존 clamp 로직 그대로 유지
**예방 규칙**: copyWith에 검증/변환 로직이 있는 엔티티는 반드시 `@Freezed(copyWith: false)` 사용. `@Assert`와 달리 기존 const 생성자 호환성 유지됨.

## 2026-03-16 - freezed clear* 플래그 → nullable copyWith(field: null) 마이그레이션
**무엇이 잘못됐나**: `copyWith(clearAnalysisResult: true)` 패턴이 freezed 표준 API에 없음
**근본 원인**: 기존 수작업 copyWith의 `clear*` boolean flag 패턴은 freezed에서 불필요 — freezed v2+는 nullable 필드에 null 직접 전달 지원
**해결책**: `copyWith(clearAnalysisResult: true)` → `copyWith(analysisResult: null)` 로 일괄 치환. 테스트도 동일하게 수정
**예방 규칙**: freezed 마이그레이션 시 `clear*` 플래그 패턴은 전부 `copyWith(field: null)` 으로 교체. 프로덕션 코드 사용처도 반드시 확인할 것.

## 2026-03-15 - hydrated_riverpod는 AsyncNotifier와 호환 불가
**무엇이 잘못됐나**: Phase 3-2 계획에서 `hydrated_riverpod`로 `UserNameController` 상태 영속화를 시도하려 했음
**근본 원인**: `hydrated_riverpod`는 동기 `HydratedNotifier<T>`만 제공. `HydratedAsyncNotifier` 미존재. SharedPreferences.getInstance()는 Future 반환 → 동기 래핑 불가
**해결책**: Phase 3-2 드롭. 현재 `AsyncNotifier<String?>` 유지 (SharedPrefs 단일 소스, 수 ms 접근, 실질적 문제 없음)
**예방 규칙**: hydrated_riverpod 도입 시 대상 Notifier가 동기인지 먼저 확인. AsyncNotifier가 필요한 경우 대안 없음 (패키지 미지원). 복잡한 객체(NotificationSettings 등)에만 유의미.

## 2026-07-02 - mocktail 시그니처 확장 시 미갱신 stub은 조용히 통과할 수 있음
**무엇이 잘못됐나**: `AnalyzeDiaryUseCase.execute()`에 `entryDate` named param 추가 후, `_CountingMock` stub 1곳이 matcher 미갱신 상태로도 테스트가 통과함
**근본 원인**: mocktail은 stub의 named args와 실제 호출의 named args가 다르면 조용히 미매칭 → MissingStubError가 프로덕션 catch 경로(DiaryAnalysisError)에 흡수되어 테스트가 "기대한 에러 상태"를 우연히 만족
**해결책**: mock 대상 메서드 시그니처 확장 시 해당 mock의 모든 when/verify 호출부를 grep으로 전수 수정 (`grep -rn "\.execute(" test/`)
**예방 규칙**: named param 추가 = 모든 stub에 `any(named: '...')` 추가가 세트. 에러 경로 테스트는 `isA<특정Failure>()`로 단언해 MissingStubError 흡수를 구분할 것.

## 2026-07-05 - Groq qwen3.6-27b Vision 마이그레이션 400 오류 (v1.4.57 회귀)
**무엇이 잘못됐나**: v1.4.57 배포 후 이미지 첨부 일기 분석이 전부 400 실패 ("잘못된 요청 형식"). 마이그레이션 문서에는 "실 API 검증 완료"로 기록됐으나 Vision 경로는 실제로 검증되지 않았음
**근본 원인**: ① qwen3.6은 기본 thinking 모드 — 추론 토큰이 `max_completion_tokens: 2048`을 소진해 최종 JSON이 빈 문자열 → `json_object` 검증 실패 (`json_validate_failed`, `failed_generation:""`). 파라미터 미확정이라 보수적으로 뺀 `reasoning_effort`가 오히려 필수였음 ② qwen3.6은 이미지 3장 제한 (구 llama-4-scout는 5장) — 4~5장 첨부 시 400 "Too many images"
**해결책**: Vision 요청에 `reasoning_effort: 'none'` 추가 + `maxImagesPerVisionRequest = 3` 클램프 + 413 사용자 메시지. 에뮬레이터 실검증(1장 200 성공) + 유닛 테스트 2건 추가
**예방 규칙**: 모델 마이그레이션 검증 체크리스트에 "각 경로(텍스트/비전)를 실제 요청 파라미터 그대로" 실행 필수. reasoning 모델 + `response_format` 조합은 반드시 reasoning 출력 억제 방법을 먼저 확정. Groq 413 = 단일 요청 TPM 초과(재시도 무의미)로 해석할 것

## 2026-07-05 - flutter attach hot reload는 attach 이전 수정분을 적용하지 않음
**무엇이 잘못됐나**: 디버그 로그를 코드에 추가 → `flutter attach` → 'r' 리로드 → "Reloaded 3 of 2281" 성공 메시지에도 로그가 전혀 출력되지 않아 2회 헛수고
**근본 원인**: attach의 초기 "Syncing files"가 현재 디스크 소스를 리로드 baseline으로 잡음 → attach 시작 전에 이미 수정된 파일은 delta에 포함되지 않음 (기기는 여전히 APK 원본 커널 실행)
**해결책**: attach 시작 → (연결 후) 파일 수정/재저장 → 'r' 순서로 변경하니 즉시 적용
**예방 규칙**: 설치된 디버그 APK(dart-define 키 내장)에 attach로 코드를 주입할 때는 반드시 attach 연결 이후에 파일을 수정할 것. 기존 수정분만 있으면 trivial edit(공백 추가)로 파일을 다시 dirty 상태로 만든 뒤 리로드

## 2026-07-05 - unawaited post-analysis hook + tearDown dispose race (CI 로그 노이즈)
**무엇이 잘못됐나**: CI에서 테스트는 전부 ✅인데 `[DiaryAnalysis] ProviderContainer disposed` ×7, `UnknownFailure` ×7이 반복 출력
**근본 원인**: `analyzeDiary()` 성공 시 `unawaited(_triggerPostAnalysisNotifications)`가 fire-and-forget 실행 → 테스트 tearDown `container.dispose()`가 먼저 완료 → async 콜백이 disposed Ref에서 `read()` 시도. `notificationSettingsProvider` mock 누락으로 UnknownFailure도 동반
**해결책**: `notification_test_helpers.dart` (9개 NotificationSettings mock + drain) + `settingsRepositoryProvider` stub + tearDown에서 `drainPostAnalysisSideEffects()` 후 dispose. 프로덕션: `StateNotifier.mounted` 가드. CI: `check-test-log-leakage.sh`
**예방 규칙**: `unawaited()` 후처리가 있는 Notifier 테스트는 (1) 플랫폼 서비스 static override (2) provider mock (3) tearDown drain 3종 세트. `Ref.mounted`는 Riverpod 2.6.1에 없음 — `StateNotifier.mounted` 사용. 통과한 테스트의 에러 로그도 실패로 취급할 것
