#!/bin/bash

# MindLog Test Health Report
# Detects stale tests, coverage gaps, and reports overall test health.

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Find project root
ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$ROOT_DIR"

if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found. Run from project root.${NC}"
    exit 1
fi

# OS-specific file modification date
get_file_date() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f '%Sm' -t '%Y%m%d' "$1" 2>/dev/null || echo "00000000"
    else
        stat -c '%y' "$1" 2>/dev/null | cut -d' ' -f1 | tr -d '-' || echo "00000000"
    fi
}

echo -e "${CYAN}=== MindLog Test Health Report ===${NC}"
echo ""

# Collect source files (exclude generated/l10n)
SOURCE_FILES=()
while IFS= read -r f; do
    SOURCE_FILES+=("$f")
done < <(find lib -name '*.dart' \
    ! -name '*.g.dart' \
    ! -name '*.freezed.dart' \
    ! -path '*/l10n/*' \
    ! -path '*/generated/*' \
    -type f 2>/dev/null | sort)

# Collect test files
TEST_FILES=()
while IFS= read -r f; do
    TEST_FILES+=("$f")
done < <(find test -name '*_test.dart' -type f 2>/dev/null | sort)

TOTAL_SOURCE=${#SOURCE_FILES[@]}
TOTAL_TESTS=${#TEST_FILES[@]}
STALE_COUNT=0
GAP_COUNT=0
MIRROR_COUNT=0

# --- 1. Stale Test Detection ---
echo -e "${YELLOW}[1/3] Stale Test Detection${NC}"
echo "  Source file modified after its mirror test → may be out of sync"
echo ""

STALE_LIST=()
for src in "${SOURCE_FILES[@]}"; do
    # Mirror mapping: lib/X.dart → test/X_test.dart
    relative="${src#lib/}"
    test_mirror="test/${relative%.dart}_test.dart"

    if [ -f "$test_mirror" ]; then
        MIRROR_COUNT=$((MIRROR_COUNT + 1))
        src_date=$(get_file_date "$src")
        test_date=$(get_file_date "$test_mirror")

        if [[ "$src_date" > "$test_date" ]]; then
            STALE_COUNT=$((STALE_COUNT + 1))
            STALE_LIST+=("  STALE: $src (${src_date}) > $test_mirror (${test_date})")
        fi
    fi
done

if [ ${#STALE_LIST[@]} -gt 0 ]; then
    for line in "${STALE_LIST[@]}"; do
        echo -e "${YELLOW}$line${NC}"
    done
else
    echo -e "  ${GREEN}No stale tests detected.${NC}"
fi
echo ""

# --- 2. Coverage Gap Detection ---
echo -e "${YELLOW}[2/3] Coverage Gap Detection${NC}"
echo "  Source file with no mirror test AND not imported by any test"
echo ""

GAP_LIST=()
for src in "${SOURCE_FILES[@]}"; do
    relative="${src#lib/}"
    test_mirror="test/${relative%.dart}_test.dart"

    if [ ! -f "$test_mirror" ]; then
        # Check if any test imports this file
        pkg_path="package:mindlog/${relative}"
        if ! grep -rql "$pkg_path" test/ --include='*_test.dart' 2>/dev/null; then
            GAP_COUNT=$((GAP_COUNT + 1))
            GAP_LIST+=("  NO COVERAGE: $src")
        fi
    fi
done

if [ ${#GAP_LIST[@]} -gt 0 ]; then
    # Show first 20
    shown=0
    for line in "${GAP_LIST[@]}"; do
        echo -e "${RED}$line${NC}"
        shown=$((shown + 1))
        if [ $shown -ge 20 ] && [ ${#GAP_LIST[@]} -gt 20 ]; then
            echo -e "  ${YELLOW}... and $((${#GAP_LIST[@]} - 20)) more${NC}"
            break
        fi
    done
else
    echo -e "  ${GREEN}All source files have test coverage.${NC}"
fi
echo ""

# --- 3. Summary ---
MIRROR_RATE=0
if [ "$TOTAL_SOURCE" -gt 0 ]; then
    MIRROR_RATE=$((MIRROR_COUNT * 100 / TOTAL_SOURCE))
fi

echo -e "${CYAN}=== Summary ===${NC}"
echo "  Source files:    $TOTAL_SOURCE"
echo "  Test files:      $TOTAL_TESTS"
echo "  Mirror matches:  $MIRROR_COUNT / $TOTAL_SOURCE ($MIRROR_RATE%)"
echo "  Stale tests:     $STALE_COUNT"
echo "  Coverage gaps:   $GAP_COUNT"
echo ""

if [ "$STALE_COUNT" -eq 0 ] && [ "$GAP_COUNT" -eq 0 ]; then
    echo -e "${GREEN}Test health: GOOD${NC}"
elif [ "$STALE_COUNT" -le 5 ] && [ "$GAP_COUNT" -le 10 ]; then
    echo -e "${YELLOW}Test health: FAIR${NC}"
else
    echo -e "${RED}Test health: NEEDS ATTENTION${NC}"
fi
