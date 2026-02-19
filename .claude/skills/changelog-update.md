# changelog-update

CHANGELOG.md를 Keep a Changelog 형식에 맞게 자동 업데이트하는 스킬

## 목표
- 일관된 변경 이력 관리
- 릴리스 준비 자동화
- 변경사항 추적 용이

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "체인지로그 업데이트", "changelog 작성" 요청
- `/changelog` 명령어
- 버전 bump 후

## Keep a Changelog 형식
참조: https://keepachangelog.com/ko/1.1.0/

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [1.4.9] - 2026-01-07

### Added
- 새로 추가된 기능

### Changed
- 변경된 기존 기능

### Deprecated
- 곧 삭제될 기능

### Removed
- 삭제된 기능

### Fixed
- 버그 수정

### Security
- 보안 관련 수정
```

## 프로세스

### Step 1: Git 커밋 히스토리 분석
```bash
# 마지막 태그 이후 커밋 조회
git log v1.4.8..HEAD --oneline
```

### Step 2: 커밋 분류
| 접두사 | 카테고리 |
|--------|----------|
| feat: | Added |
| fix: | Fixed |
| refactor: | Changed |
| perf: | Changed |
| docs: | Changed |
| security: | Security |
| BREAKING: | 주요 변경 표시 |

### Step 3: CHANGELOG.md 업데이트
파일: `CHANGELOG.md` (프로젝트 루트)

```markdown
## [Unreleased]

## [1.4.9] - 2026-01-07

### Added
- 개별 일기 삭제 기능 (스와이프 제스처)

### Changed
- AI 분석 결과 UI 개선

### Fixed
- CI 빌드 에러 수정 (dev_api_keys 의존성)
```

### Step 4: 링크 섹션 업데이트
```markdown
[Unreleased]: https://github.com/user/mindlog/compare/v1.4.9...HEAD
[1.4.9]: https://github.com/user/mindlog/compare/v1.4.8...v1.4.9
[1.4.8]: https://github.com/user/mindlog/releases/tag/v1.4.8
```

## 출력 형식

```
📋 CHANGELOG 업데이트 완료

버전: 1.4.9
날짜: 2026-01-07

변경사항:
├── Added (1)
│   └─ 개별 일기 삭제 기능
├── Changed (1)
│   └─ AI 분석 결과 UI 개선
└── Fixed (1)
    └─ CI 빌드 에러 수정

📝 업데이트 파일:
   └─ CHANGELOG.md
```

## CHANGELOG.md 초기 생성

파일이 없는 경우 다음 템플릿으로 생성:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.4.9] - 2026-01-07

### Added
- 초기 버전
```

## 사용 예시

```
> "/changelog"

AI 응답:
1. 마지막 태그: v1.4.8
2. 새 커밋 분석: 5개
3. 카테고리별 분류:
   - feat: 2개 → Added
   - fix: 2개 → Fixed
   - refactor: 1개 → Changed
4. CHANGELOG.md 업데이트 완료
```

## 주의사항
- 날짜 형식: YYYY-MM-DD (ISO 8601)
- Unreleased 섹션 항상 유지
- 최신 버전이 상단에 위치
- 커밋 메시지가 Conventional Commits 형식을 따르면 더 정확한 분류 가능
