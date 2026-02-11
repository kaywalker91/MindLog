# 배포 전 최종 검증 가이드

## 검증 레벨 선택

| 레벨 | 소요 시간 | 적합 상황 |
|------|----------|-----------|
| **Critical Path** | ~5분 | Hotfix, 긴급 배포 |
| **간결 버전** | ~10분 | 일반 배포 |
| **스킬 기반** | ~15분 | 자동화 선호 시 |
| **8-Gate 상세** | ~20분 | Major release, 감사 필요 시 |

## 프롬프트 사용법

### 1. Critical Path (빠른 검증)
```
배포 전 Critical Path만 빠르게 검증해줘:

1. `flutter analyze` — 에러 0개 확인
2. `flutter test` — 전체 테스트 통과 확인
3. `git status` — staged changes 확인
4. `pubspec.yaml` + `CHANGELOG.md` 버전 일치 확인
5. `flutter build appbundle --release --dart-define=GROQ_API_KEY=dummy` — 빌드 성공 확인

5단계 모두 통과 시 "✅ 배포 가능", 실패 시 차단 사항 리포트해줘.
```

### 2. 간결 버전 (권장)
```
배포 전 최종 검증을 실행해줘. 다음을 순서대로 확인:

1. Git 상태 및 버전 확인
2. 전체 테스트 실행 + 커버리지
3. 린트 및 정적 분석
4. 릴리스 빌드 검증 (Android)
5. CHANGELOG 및 문서 확인
6. 배포 체크리스트 검증

각 단계별 결과를 요약하고, 배포 가능 여부를 최종 판단해줘.
```

### 3. 스킬 기반 자동화
```
다음 스킬 체인을 순서대로 실행하여 배포 전 검증을 완료해줘:

1. `/lint-fix` — 자동 수정 가능한 린트 위반 처리
2. `./scripts/run.sh quality` — 전체 품질 게이트 실행
3. `/coverage` — 테스트 커버리지 리포트 생성
4. `/version-bump patch` (필요 시) — 버전 업데이트
5. `/changelog` — CHANGELOG.md 업데이트
6. Git 상태 확인 및 릴리스 빌드 검증

각 단계 완료 후 결과를 요약하고, 실패한 단계가 있으면 수정 방법을 제안해줘.
최종적으로 배포 가능 여부를 판단해줘.
```

### 4. 8-Gate 상세 검증 (Major Release)
```
SuperClaude 8-Gate Quality Gates를 기준으로 배포 전 최종 검증을 실행해줘:

**Gate 1-2: Syntax & Type Validation**
- `flutter analyze` 실행 (warnings 0개 목표)
- Dart 타입 체크 통과 확인

**Gate 3-4: Lint & Security**
- `./scripts/run.sh lint` 실행
- 보안 취약점 스캔 (특히 GROQ_API_KEY 노출, SafetyBlockedFailure 무결성)

**Gate 5: Test Coverage**
- `./scripts/run.sh test` 실행
- Unit >= 80%, Widget >= 70% 확인
- 실패 테스트 0개 확인

**Gate 6: Performance Check**
- HTTP timeout 패턴 검증
- Image cacheWidth 패턴 검증
- Provider invalidation chain 검증

**Gate 7: Documentation Validation**
- CHANGELOG.md 업데이트 확인
- pubspec.yaml 버전 확인
- Git commit 메시지 규칙 준수 확인

**Gate 8: Integration Testing**
- `flutter build appbundle --release --dry-run` 실행
- CI/CD 파이프라인 구성 검증

**최종 체크리스트:**
- [ ] Git status clean (staged changes only)
- [ ] All tests passing
- [ ] No lint warnings
- [ ] Version bumped
- [ ] CHANGELOG updated
- [ ] Release build successful
- [ ] No hardcoded secrets
- [ ] SafetyBlockedFailure integrity maintained

각 게이트별 통과/실패 여부를 요약하고, 배포 가능 여부를 최종 판단해줘.
```

## 검증 실패 시 대응

### 테스트 실패
```
/debug analyze
```

### 린트 위반
```
/lint-fix
```

### 커버리지 부족
```
/test-unit-gen [file]
/coverage
```

### 버전/CHANGELOG 불일치
```
/version-bump [patch|minor|major]
/changelog
```

## 배포 워크플로우

```
1. 검증 실행 (위 프롬프트 중 하나 선택)
2. 실패 항목 수정
3. 재검증
4. Git commit + push
5. GitHub Actions CD 워크플로우 확인
6. Play Store 내부 테스트 트랙 확인
```

## MindLog 특수 검증 항목

### 필수 무결성 체크
- `SafetyBlockedFailure` 절대 수정 금지 확인
- `is_emergency` 필드 보존 확인
- 한글 개인화 패턴 정규식 유지 확인

### Firebase 설정 검증
- FCM 알림 ID 충돌 없음 확인 (1001, 2001, 2002, 2004, 3001+)
- 채널 ID 유지 확인 (`mindlog_cheerme`, `mindlog_mindcare`)

### 알림 브랜딩 검증
- CheerMe accent: #FFA726
- MindCare accent: #26A69A
- 브랜드 컬러 일관성 확인

## 참고 파일
- `.claude/rules/workflow.md` — Session Completion Checklist
- `scripts/run.sh` — Build/Test/Quality 스크립트
- `.github/workflows/cd.yml` — 배포 파이프라인
