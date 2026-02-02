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
        echo "  lint            Run static analysis (flutter analyze)"
        echo "  format          Format all Dart code"
        echo "  format-check    Check code formatting without changes"
        echo "  quality         Run full quality gates (lint + format + test)"
        echo "  clean           Clean and reinstall dependencies"
        echo "  deps            Install dependencies (flutter pub get)"
        echo "  outdated        Check for outdated packages"
        echo ""
        echo "Environment Variables:"
        echo "  GROQ_API_KEY    Required for build commands"
        echo ""
        echo "Examples:"
        echo "  ./scripts/run.sh quality           # Run all quality checks"
        echo "  ./scripts/run.sh test              # Run tests with coverage"
        echo "  GROQ_API_KEY=xxx ./scripts/run.sh run  # Run app"
        ;;
esac
