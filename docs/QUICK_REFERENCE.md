# MindLog Quick Reference

> 자주 사용하는 Claude Skills 빠른 참조

## P0 - Core Development

```bash
# 새 기능 Clean Architecture 구조 생성
/scaffold [feature_name]

# UseCase 단위 테스트 생성
/test-unit-gen [file_path]
```

## P1 - Release Pipeline

```bash
# 버전 업데이트 (patch/minor/major)
/version-bump patch

# CHANGELOG.md 업데이트
/changelog

# 릴리스 노트 생성
/release-notes
```

## P1 - Code Quality

```bash
# 린트 오류 자동 수정
/lint-fix

# 테스트 커버리지 리포트
/coverage

# Git pre-commit hook 설정
/pre-commit
```

## P1 - Testing

```bash
# Mock 클래스 생성
/mock [RepositoryName]

# UseCase 생성
/usecase [action_entity]

# 위젯 테스트 생성
/widget-test [file_path]
```

## P2 - Firebase

```bash
# Crashlytics 설정
/crashlytics-setup

# FCM 푸시 알림 설정
/fcm-setup

# Analytics 이벤트 추가
/analytics-event [event_name]
```

## P2 - Documentation

```bash
# API 문서 생성
/api-doc

# 아키텍처 문서 생성
/architecture-doc
```

---

## Common Workflows

### 새 기능 개발
```
/scaffold reminder
  └── /usecase create_reminder
      └── /test-unit-gen lib/domain/usecases/create_reminder_usecase.dart
          └── /mock ReminderRepository
```

### 릴리스 준비
```
/version-bump patch
  └── /changelog
      └── /release-notes
```

### 코드 품질 검사
```
/lint-fix
  └── /coverage
      └── git commit
```

---

## Skill Dependencies

```
feature-scaffold ─┬─ usecase-gen ─── test-unit-gen ─── mock-gen
                  └─ widget-test-gen

version-bump ─── changelog-update ─── release-notes
```

---

## Links

- [Full Skills Index](./skills/README.md)
- [Deployment Guide](./guides/deployment.md)
- [Firebase Setup](./guides/firebase-setup.md)
