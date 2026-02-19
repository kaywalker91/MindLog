# pre-commit-setup

Git pre-commit 훅을 설정하여 커밋 전 자동 검증을 수행하는 스킬

## 목표
- 커밋 품질 자동 보장
- CI 실패 사전 방지
- 일관된 코드 스타일 유지

## 트리거 조건
다음 상황에서 이 스킬을 실행합니다:
- "pre-commit 설정", "훅 설정" 요청
- `/pre-commit` 명령어
- 프로젝트 초기 설정 시

## 프로세스

### Step 1: pre-commit 스크립트 생성
파일: `.git/hooks/pre-commit`

```bash
#!/bin/bash

echo "🔍 Pre-commit checks starting..."

# 1. 포맷팅 검사
echo "→ Checking formatting..."
dart format --output=none --set-exit-if-changed lib/ test/
if [ $? -ne 0 ]; then
    echo "❌ Formatting issues found. Run: dart format ."
    exit 1
fi

# 2. 정적 분석
echo "→ Running static analysis..."
flutter analyze --fatal-infos
if [ $? -ne 0 ]; then
    echo "❌ Analysis issues found. Run: flutter analyze"
    exit 1
fi

# 3. 단위 테스트 (선택)
echo "→ Running tests..."
flutter test --no-pub
if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Run: flutter test"
    exit 1
fi

echo "✅ All checks passed!"
exit 0
```

### Step 2: 실행 권한 부여
```bash
chmod +x .git/hooks/pre-commit
```

### Step 3: 팀 공유용 스크립트 생성
파일: `scripts/install-hooks.sh`

```bash
#!/bin/bash

# Git hooks 설치 스크립트
echo "Installing git hooks..."

cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo "✅ Git hooks installed successfully!"
```

### Step 4: lefthook 설정 (대안)
파일: `lefthook.yml`

```yaml
pre-commit:
  parallel: true
  commands:
    format:
      glob: "*.dart"
      run: dart format --output=none --set-exit-if-changed {staged_files}

    analyze:
      glob: "*.dart"
      run: flutter analyze {staged_files}

    test:
      run: flutter test --no-pub
```

## 검증 항목

| 순서 | 검사 | 명령어 | 실패 시 |
|-----|------|--------|---------|
| 1 | 포맷팅 | `dart format --set-exit-if-changed` | 커밋 차단 |
| 2 | 정적 분석 | `flutter analyze --fatal-infos` | 커밋 차단 |
| 3 | 단위 테스트 | `flutter test --no-pub` | 커밋 차단 (선택) |

## 출력 형식

```
📦 Pre-commit 설정 완료

생성된 파일:
├── .git/hooks/pre-commit (훅 스크립트)
└── scripts/install-hooks.sh (팀 공유용)

검증 항목:
├── ✅ dart format (포맷팅)
├── ✅ flutter analyze (정적 분석)
└── ✅ flutter test (단위 테스트)

🔧 팀원 설치:
   └─ ./scripts/install-hooks.sh
```

## 커밋 시 동작

```
$ git commit -m "feat: add new feature"

🔍 Pre-commit checks starting...
→ Checking formatting... ✅
→ Running static analysis... ✅
→ Running tests... ✅
✅ All checks passed!

[main abc1234] feat: add new feature
 3 files changed, 45 insertions(+)
```

## 훅 우회 (긴급 시)
```bash
git commit --no-verify -m "hotfix: urgent fix"
```

## 사용 예시

```
> "/pre-commit"

AI 응답:
1. pre-commit 훅 스크립트 생성
2. 실행 권한 부여
3. 팀 공유용 install-hooks.sh 생성
4. 검증 테스트:
   - dart format ✅
   - flutter analyze ✅
   - flutter test ✅
5. 설정 완료
```

## 주의사항
- `.git/hooks/`는 Git 추적 대상이 아님
- 팀 공유를 위해 `scripts/` 디렉토리에 복사본 유지
- 테스트가 느린 경우 pre-push로 이동 고려
- lefthook 사용 시 `lefthook install` 실행 필요
