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
    
    *)
        echo "MindLog Build Script"
        echo ""
        echo "Usage: ./scripts/run.sh [command]"
        echo ""
        echo "Commands:"
        echo "  run             Run app in debug mode"
        echo "  build-apk       Build release APK"
        echo "  build-ios       Build iOS release"
        echo "  build-appbundle Build release App Bundle (Play Store)"
        echo ""
        echo "Environment Variables:"
        echo "  GROQ_API_KEY    Required - Groq API key"
        echo ""
        echo "Set these as environment variables before running the script."
        ;;
esac
