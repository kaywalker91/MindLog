# Claude Skills Index

> MindLog 프로젝트 Claude Code 자동화 스킬 전체 목록

## P0 - Core Development (핵심)

| Skill | Trigger | Purpose |
|-------|---------|---------|
| [feature-scaffold](./feature-scaffold.md) | `/scaffold [name]` | Clean Architecture 전체 구조 생성 |
| [test-unit-gen](./test-unit-gen.md) | `/test-unit-gen [file]` | UseCase/Repository 단위 테스트 생성 |

## P1 - Release Pipeline (릴리스)

| Skill | Trigger | Purpose |
|-------|---------|---------|
| [version-bump](./version-bump.md) | `/version-bump [type]` | Semantic Versioning 버전 업데이트 |
| [changelog-update](./changelog-update.md) | `/changelog` | Keep a Changelog 형식 CHANGELOG 작성 |
| [release-notes](./release-notes.md) | `/release-notes` | GitHub Release 노트 생성 |

## P1 - Code Quality (품질)

| Skill | Trigger | Purpose |
|-------|---------|---------|
| [lint-fix](./lint-fix.md) | `/lint-fix` | Dart 린트 위반 자동 수정 |
| [pre-commit-setup](./pre-commit-setup.md) | `/pre-commit` | Git pre-commit hook 설정 |
| [test-coverage-report](./test-coverage-report.md) | `/coverage` | 테스트 커버리지 분석 리포트 |

## P1 - Testing (테스트)

| Skill | Trigger | Purpose |
|-------|---------|---------|
| [mock-gen](./mock-gen.md) | `/mock [RepoName]` | Repository Mock 클래스 생성 |
| [usecase-gen](./usecase-gen.md) | `/usecase [action_entity]` | UseCase 클래스 생성 |
| [widget-test-gen](./widget-test-gen.md) | `/widget-test [file]` | Flutter Widget 테스트 생성 |

## P2 - Firebase

| Skill | Trigger | Purpose |
|-------|---------|---------|
| [crashlytics-setup](./crashlytics-setup.md) | `/crashlytics-setup` | Firebase Crashlytics 설정 |
| [fcm-setup](./fcm-setup.md) | `/fcm-setup` | Firebase Cloud Messaging 설정 |
| [analytics-event-add](./analytics-event-add.md) | `/analytics-event [name]` | Firebase Analytics 이벤트 추가 |

## P2 - Documentation (문서화)

| Skill | Trigger | Purpose |
|-------|---------|---------|
| [api-doc-gen](./api-doc-gen.md) | `/api-doc` | API 엔드포인트 문서 생성 |
| [architecture-doc-gen](./architecture-doc-gen.md) | `/architecture-doc` | 아키텍처 문서 생성 |

---

## Skill Dependencies Graph

```
feature-scaffold
    ├── usecase-gen
    │   └── test-unit-gen
    │       └── mock-gen
    └── widget-test-gen

version-bump
    └── changelog-update
        └── release-notes

lint-fix
    └── pre-commit-setup

crashlytics-setup ─┬─ fcm-setup
                   └─ analytics-event-add
```

---

## Priority Levels

| Level | Description | When to Use |
|-------|-------------|-------------|
| **P0** | 핵심 개발 | 새 기능 개발 시 필수 |
| **P1** | 릴리스/품질 | 릴리스 준비, 코드 리뷰 시 |
| **P2** | Firebase/문서 | 설정 및 문서화 필요 시 |

---

## Creating New Skills

새 스킬을 추가하려면 [SKILL_TEMPLATE.md](./SKILL_TEMPLATE.md) 템플릿을 참조하세요.

### 필수 섹션
1. **목표** - 스킬의 목적 (2-3줄)
2. **트리거 조건** - 언제 실행되는지
3. **프로세스** - Step-by-step 실행 과정
4. **출력 형식** - 결과물 포맷
5. **사용 예시** - 실제 사용 예
6. **주의사항** - 주의할 점
7. **연관 스킬** - 함께 사용하는 스킬

---

## Related

- [Quick Reference](../QUICK_REFERENCE.md) - 1페이지 치트시트
- [Skill Template](./SKILL_TEMPLATE.md) - 새 스킬 작성 가이드
