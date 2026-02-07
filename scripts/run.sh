#!/bin/bash

# MindLog 개발/빌드 스크립트
# 환경 변수를 안전하게 주입하여 앱을 실행/빌드합니다.

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 현재 디렉토리가 프로젝트 루트인지 확인
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found. Run this script from project root.${NC}"
    exit 1
fi

require_api_key() {
    if [ -z "$GROQ_API_KEY" ]; then
        echo -e "${YELLOW}Error: GROQ_API_KEY not set.${NC}"
        echo "Set GROQ_API_KEY as an environment variable before running."
        echo ""
        echo "Example:"
        echo "  GROQ_API_KEY=your_api_key_here ./scripts/run.sh run"
        echo ""
        exit 1
    fi
}

# 명령어에 따른 분기
case "$1" in
    run)
        require_api_key
        echo -e "${GREEN}Running MindLog in debug mode...${NC}"
        flutter run \
            --dart-define=GROQ_API_KEY="${GROQ_API_KEY:-}" \
            --dart-define=ENVIRONMENT=development
        ;;
    
    build-apk)
        require_api_key
        echo -e "${GREEN}Building release APK...${NC}"
        flutter build apk --release \
            --dart-define=GROQ_API_KEY="${GROQ_API_KEY:-}" \
            --dart-define=ENVIRONMENT=production
        ;;
    
    build-ios)
        require_api_key
        echo -e "${GREEN}Building iOS release...${NC}"
        flutter build ios --release \
            --dart-define=GROQ_API_KEY="${GROQ_API_KEY:-}" \
            --dart-define=ENVIRONMENT=production
        ;;
    
    build-appbundle)
        require_api_key
        echo -e "${GREEN}Building release App Bundle...${NC}"
        flutter build appbundle --release \
            --dart-define=GROQ_API_KEY="${GROQ_API_KEY:-}" \
            --dart-define=ENVIRONMENT=production
        ;;

    # Development Commands (no API key required)
    test)
        echo -e "${GREEN}Running tests with coverage...${NC}"
        flutter test --coverage
        ;;

    test-unit)
        echo -e "${GREEN}Running unit tests only...${NC}"
        flutter test test/unit/ --coverage
        ;;

    test-widget)
        echo -e "${GREEN}Running widget tests only...${NC}"
        flutter test test/widget/ --coverage
        ;;

    test-affected)
        # Run only tests affected by current changes (vs origin/main)
        shift
        LIST_ONLY=false
        NO_ANALYZE=false
        for arg in "$@"; do
            case "$arg" in
                --list-only) LIST_ONLY=true ;;
                --no-analyze) NO_ANALYZE=true ;;
            esac
        done

        # 1. Detect changed Dart files
        CHANGED_FILES=$(git diff --name-only origin/main...HEAD -- '*.dart' 2>/dev/null || \
                        git diff --name-only HEAD~1...HEAD -- '*.dart' 2>/dev/null || \
                        echo "")

        # Include unstaged/staged changes too
        STAGED=$(git diff --cached --name-only -- '*.dart' 2>/dev/null || echo "")
        UNSTAGED=$(git diff --name-only -- '*.dart' 2>/dev/null || echo "")
        CHANGED_FILES=$(echo -e "$CHANGED_FILES\n$STAGED\n$UNSTAGED" | sort -u | grep -v '^$' || true)

        if [ -z "$CHANGED_FILES" ]; then
            echo -e "${GREEN}No Dart file changes detected. Nothing to test.${NC}"
            exit 0
        fi

        # 2. Classify changes
        LIB_CHANGES=$(echo "$CHANGED_FILES" | grep '^lib/' || true)
        TEST_CHANGES=$(echo "$CHANGED_FILES" | grep '_test\.dart$' || true)
        INFRA_CHANGES=$(echo "$CHANGED_FILES" | grep -E '^test/(mocks|fixtures|helpers)/' || true)

        # 3. Shared test infrastructure changed → run all tests
        if [ -n "$INFRA_CHANGES" ]; then
            echo -e "${YELLOW}Shared test infrastructure changed. Running all tests.${NC}"
            if [ "$LIST_ONLY" = true ]; then
                echo "(all tests)"
                exit 0
            fi
            if [ "$NO_ANALYZE" = false ]; then
                flutter analyze --fatal-infos || exit 1
            fi
            flutter test
            exit $?
        fi

        # 4. Build affected test list
        AFFECTED_TESTS=""

        # 4a. Mirror mapping: lib/X.dart → test/X_test.dart
        if [ -n "$LIB_CHANGES" ]; then
            while IFS= read -r src; do
                relative="${src#lib/}"
                mirror="test/${relative%.dart}_test.dart"
                if [ -f "$mirror" ]; then
                    AFFECTED_TESTS="$AFFECTED_TESTS $mirror"
                fi
            done <<< "$LIB_CHANGES"
        fi

        # 4b. Reverse import scan: find tests that import changed lib files
        if [ -n "$LIB_CHANGES" ]; then
            while IFS= read -r src; do
                relative="${src#lib/}"
                pkg_path="package:mindlog/${relative}"
                importers=$(grep -rl "$pkg_path" test/ --include='*_test.dart' 2>/dev/null || true)
                if [ -n "$importers" ]; then
                    AFFECTED_TESTS="$AFFECTED_TESTS $importers"
                fi
            done <<< "$LIB_CHANGES"
        fi

        # 4c. Include directly changed test files
        if [ -n "$TEST_CHANGES" ]; then
            while IFS= read -r t; do
                if [ -f "$t" ]; then
                    AFFECTED_TESTS="$AFFECTED_TESTS $t"
                fi
            done <<< "$TEST_CHANGES"
        fi

        # 5. Deduplicate
        AFFECTED_TESTS=$(echo "$AFFECTED_TESTS" | tr ' ' '\n' | sort -u | grep -v '^$' || true)
        TEST_COUNT=$(echo "$AFFECTED_TESTS" | grep -c '.' 2>/dev/null || echo "0")

        if [ "$TEST_COUNT" -eq 0 ]; then
            echo -e "${GREEN}No affected tests found for changed files.${NC}"
            exit 0
        fi

        # 6. List-only mode
        if [ "$LIST_ONLY" = true ]; then
            echo -e "${CYAN:-\033[0;36m}Affected tests ($TEST_COUNT):${NC}"
            echo "$AFFECTED_TESTS"
            exit 0
        fi

        # 7. If >15 tests, run all (faster than individual)
        if [ "$TEST_COUNT" -gt 15 ]; then
            echo -e "${YELLOW}$TEST_COUNT affected tests detected. Running full test suite.${NC}"
            if [ "$NO_ANALYZE" = false ]; then
                flutter analyze --fatal-infos || exit 1
            fi
            flutter test
            exit $?
        fi

        # 8. Run affected tests only
        echo -e "${GREEN}Running $TEST_COUNT affected test(s)...${NC}"
        echo "$AFFECTED_TESTS" | head -5
        if [ "$TEST_COUNT" -gt 5 ]; then
            echo "  ... and $((TEST_COUNT - 5)) more"
        fi
        echo ""

        if [ "$NO_ANALYZE" = false ]; then
            flutter analyze --fatal-infos || exit 1
        fi

        # Convert newline-separated list to space-separated args
        TEST_ARGS=$(echo "$AFFECTED_TESTS" | tr '\n' ' ')
        flutter test $TEST_ARGS
        ;;

    test-health)
        echo -e "${GREEN}Running test health report...${NC}"
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
        bash "$SCRIPT_DIR/test-health.sh"
        ;;

    setup-hooks)
        echo -e "${GREEN}Setting up git hooks...${NC}"
        SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
        bash "$SCRIPT_DIR/setup-hooks.sh"
        ;;

    lint)
        echo -e "${GREEN}Running static analysis...${NC}"
        flutter analyze --fatal-infos
        ;;

    format)
        echo -e "${GREEN}Formatting code...${NC}"
        dart format .
        ;;

    format-check)
        echo -e "${GREEN}Checking code format...${NC}"
        dart format --set-exit-if-changed .
        ;;

    quality)
        echo -e "${GREEN}Running full quality gates...${NC}"
        echo ""
        echo -e "${YELLOW}Step 1/3: Static analysis${NC}"
        flutter analyze --fatal-infos || exit 1
        echo ""
        echo -e "${YELLOW}Step 2/3: Format check${NC}"
        dart format --set-exit-if-changed . || exit 1
        echo ""
        echo -e "${YELLOW}Step 3/3: Tests${NC}"
        flutter test --coverage || exit 1
        echo ""
        echo -e "${GREEN}✓ All quality gates passed${NC}"
        ;;

    clean)
        echo -e "${GREEN}Cleaning build artifacts...${NC}"
        flutter clean
        flutter pub get
        ;;

    deps)
        echo -e "${GREEN}Installing dependencies...${NC}"
        flutter pub get
        ;;

    outdated)
        echo -e "${GREEN}Checking for outdated packages...${NC}"
        flutter pub outdated
        ;;

    *)
        echo "MindLog Build Script"
        echo ""
        echo "Usage: ./scripts/run.sh [command]"
        echo ""
        echo "Build Commands (require GROQ_API_KEY):"
        echo "  run             Run app in debug mode"
        echo "  build-apk       Build release APK"
        echo "  build-ios       Build iOS release"
        echo "  build-appbundle Build release App Bundle (Play Store)"
        echo ""
        echo "Development Commands:"
        echo "  test            Run all tests with coverage"
        echo "  test-unit       Run unit tests only"
        echo "  test-widget     Run widget tests only"
        echo "  test-affected   Run only tests affected by current changes"
        echo "                    --list-only   Show affected files without running"
        echo "                    --no-analyze  Skip flutter analyze"
        echo "  test-health     Run test health report (stale tests, coverage gaps)"
        echo "  lint            Run static analysis (flutter analyze)"
        echo "  format          Format all Dart code"
        echo "  format-check    Check code formatting without changes"
        echo "  quality         Run full quality gates (lint + format + test)"
        echo "  clean           Clean and reinstall dependencies"
        echo "  deps            Install dependencies (flutter pub get)"
        echo "  outdated        Check for outdated packages"
        echo ""
        echo "Setup Commands:"
        echo "  setup-hooks     Configure git pre-push hook for test automation"
        echo ""
        echo "Environment Variables:"
        echo "  GROQ_API_KEY           Required for build commands"
        echo "  MINDLOG_SKIP_TESTS=1   Skip pre-push test hook (emergency)"
        echo ""
        echo "Examples:"
        echo "  ./scripts/run.sh quality              # Run all quality checks"
        echo "  ./scripts/run.sh test                  # Run tests with coverage"
        echo "  ./scripts/run.sh test-affected         # Run affected tests only"
        echo "  ./scripts/run.sh setup-hooks           # Install git hooks"
        echo "  GROQ_API_KEY=xxx ./scripts/run.sh run  # Run app"
        ;;
esac
