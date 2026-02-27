#!/bin/bash
# MindLog Design Audit Script
# Detects hardcoded colors and missing design tokens
# Usage: ./scripts/design-audit.sh [path]
# Default path: lib/presentation/
# Lines with "design-ok" comment are excluded (escape hatch)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SEARCH_PATH="${1:-lib/presentation/}"

echo -e "${YELLOW}Design Audit: ${SEARCH_PATH}${NC}"
echo ""

TOTAL_VIOLATIONS=0

# ──────────────────────────────────────────────
# Pattern 1: Colors.white / Colors.black
# ──────────────────────────────────────────────
echo -e "${YELLOW}[1/3] Colors.white / Colors.black${NC}"
PATTERN1_COUNT=0
while IFS= read -r line; do
  echo -e "  ${RED}$line${NC}"
  PATTERN1_COUNT=$((PATTERN1_COUNT + 1))
done < <(grep -rn "Colors\.\(white\|black\)" "$SEARCH_PATH" \
           --include="*.dart" \
           | grep -v "design-ok" \
           | grep -v "app_colors\.dart")

if [ "$PATTERN1_COUNT" -eq 0 ]; then
  echo -e "  ${GREEN}No violations${NC}"
fi
TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + PATTERN1_COUNT))
echo ""

# ──────────────────────────────────────────────
# Pattern 2: Inline Color(0xXXXXXXXX)
# ──────────────────────────────────────────────
echo -e "${YELLOW}[2/3] Inline Color(0x...) hex literals${NC}"
PATTERN2_COUNT=0
while IFS= read -r line; do
  echo -e "  ${RED}$line${NC}"
  PATTERN2_COUNT=$((PATTERN2_COUNT + 1))
done < <(grep -rn "Color(0x[0-9A-Fa-f]\{8\})" "$SEARCH_PATH" \
           --include="*.dart" \
           | grep -v "design-ok" \
           | grep -v "app_colors\.dart")

if [ "$PATTERN2_COUNT" -eq 0 ]; then
  echo -e "  ${GREEN}No violations${NC}"
fi
TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + PATTERN2_COUNT))
echo ""

# ──────────────────────────────────────────────
# Pattern 3: Direct AppColors.primary as text color
# ──────────────────────────────────────────────
echo -e "${YELLOW}[3/3] Direct AppColors.primary as text color${NC}"
PATTERN3_COUNT=0
while IFS= read -r line; do
  echo -e "  ${RED}$line${NC}"
  PATTERN3_COUNT=$((PATTERN3_COUNT + 1))
done < <(grep -rn "color: AppColors\.primary[^D]" "$SEARCH_PATH" \
           --include="*.dart" \
           | grep -v "design-ok")

if [ "$PATTERN3_COUNT" -eq 0 ]; then
  echo -e "  ${GREEN}No violations${NC}"
fi
TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + PATTERN3_COUNT))
echo ""

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────
echo "violations=$TOTAL_VIOLATIONS"

if [ "$TOTAL_VIOLATIONS" -eq 0 ]; then
  echo -e "${GREEN}✓ Design audit passed${NC}"
  exit 0
else
  echo -e "${RED}✗ Design audit failed ($TOTAL_VIOLATIONS violation(s))${NC}"
  exit 1
fi
