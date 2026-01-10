# MindLog Documentation

> AI 기반 감정 케어 다이어리 - 개발 문서

## Quick Navigation

| 문서 | 설명 |
|------|------|
| [Quick Reference](./QUICK_REFERENCE.md) | 1분 가이드 - 자주 쓰는 스킬 빠른 참조 |
| [Skills Index](./skills/README.md) | Claude Code 자동화 스킬 전체 목록 |
| [Guides](./guides/README.md) | 설정, 배포, Firebase 가이드 |
| [Troubleshooting](./troubleshooting/README.md) | 알려진 이슈 및 해결책 |

## Directory Structure

```
docs/
├── skills/           # Claude Code 자동화 스킬 정의
├── guides/           # 설정, 배포, Firebase 가이드
├── troubleshooting/  # 알려진 이슈 및 해결책
├── ui/               # UI/UX 디자인 가이드라인
├── assets/           # 이미지, 스타일 등 정적 리소스
├── legal/            # 개인정보처리방침 등 법적 문서
└── archive/          # 구버전 파일 보관
```

## For Developers

### 새 기능 개발 시
1. `/scaffold [feature_name]` - Clean Architecture 구조 생성
2. `/usecase [action_entity]` - UseCase 생성
3. `/test-unit-gen [file]` - 단위 테스트 생성

### 릴리스 시
1. `/version-bump [type]` - 버전 업데이트
2. `/changelog` - CHANGELOG.md 업데이트
3. `/release-notes` - 릴리스 노트 생성

### 코드 품질
- `/lint-fix` - 린트 오류 수정
- `/coverage` - 테스트 커버리지 리포트
- `/pre-commit` - Git hooks 설정

## Related Files

- [CLAUDE.md](../CLAUDE.md) - Claude Code 프로젝트 설정
- [pubspec.yaml](../pubspec.yaml) - Flutter 의존성
- [analysis_options.yaml](../analysis_options.yaml) - Dart 린트 규칙
