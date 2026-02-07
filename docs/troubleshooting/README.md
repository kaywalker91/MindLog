# MindLog Troubleshooting

> 알려진 이슈 및 해결책 문서 — 2-Layer Retrieval Memory

## Architecture

```
docs/troubleshooting.json          ← Layer 1: 검색 인덱스 (빠른 매칭)
docs/troubleshooting/{id}.md       ← Layer 2: 상세 문서 (진단/해결/교훈)
docs/troubleshooting/README.md     ← 이 파일: 사람이 읽는 목차
```

## Known Issues

| Issue | Status | Severity | Category | Root Cause | Platform |
|-------|--------|----------|----------|------------|----------|
| [예약 알림 미작동 (Release)](./notification-not-firing-release.md) | resolved | critical | notification | environment | android |

## By Root Cause Type

### environment (환경 차이)
- [예약 알림 미작동 (Release)](./notification-not-firing-release.md) — R8 난독화로 인한 알림 실패

### config (설정/구성 오류)
- (이슈 없음)

### timing (비동기/레이스 컨디션)
- (이슈 없음)

### state (상태 관리 버그)
- (이슈 없음)

### dependency (외부 패키지 이슈)
- (이슈 없음)

### platform (플랫폼 특이 동작)
- (이슈 없음)

### logic (비즈니스 로직 오류)
- (이슈 없음)

### data (데이터 무결성 오류)
- (이슈 없음)

### integration (컴포넌트 통합 이슈)
- (이슈 없음)

### ui (레이아웃/렌더링 이슈)
- (이슈 없음)

---

## Quick Diagnosis

### 알림이 작동하지 않음
```
1. Debug vs Release 환경 확인
2. Release면 → proguard-rules.pro 확인
3. flutter_local_notifications keep 규칙 추가
4. 참조: troubleshooting.json → symptoms 검색
```

### 빌드 실패
```
1. flutter clean
2. flutter pub get
3. flutter analyze
```

### Firebase 연결 실패
```
1. google-services.json 위치 확인
2. Firebase 프로젝트 설정 확인
3. 네트워크 연결 확인
```

### Provider 상태 이상
```
1. ref.watch() vs ref.read() 사용 위치 확인
2. invalidation chain 추적
3. 참조: /provider-invalidation-audit
```

---

## How to Add New Issues

`/troubleshoot-save [id]` 스킬을 사용하거나 수동으로 다음을 수행합니다:

1. `docs/troubleshooting.json`의 `issues[]`에 엔트리 추가
2. `docs/troubleshooting/{id}.md` 상세 문서 생성
3. 이 README의 Known Issues 테이블 + Root Cause 섹션에 항목 추가

스키마 상세: `docs/skills/troubleshoot-save.md` 참조

---

## Related

- [Skills Index](../skills/README.md) — 자동화 스킬
- [Systematic Debugging](../skills/systematic-debugging.md) — `/debug` 4단계 프로세스
- [Troubleshoot Save](../skills/troubleshoot-save.md) — 메모리화 스킬
