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
