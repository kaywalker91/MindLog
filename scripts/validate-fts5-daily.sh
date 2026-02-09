#!/bin/bash
# Daily FTS5 validation for Phase 3 parallel operation
# Usage: ./scripts/validate-fts5-daily.sh

set -e

DB=~/.claude-mem/claude-mem.db
DATE=$(date +%Y-%m-%d)
LOG_DIR=".claude/progress/fts5-logs"
LOG="$LOG_DIR/fts5-validation-$DATE.log"

# Create log directory if not exists
mkdir -p "$LOG_DIR"

echo "=== FTS5 Daily Validation: $DATE ===" > "$LOG"
echo "" >> "$LOG"

# Check if database exists
if [ ! -f "$DB" ]; then
  echo "❌ ERROR: Database not found at $DB" >> "$LOG"
  cat "$LOG"
  exit 1
fi

# Query 1: Korean personalization (한글 개인화)
echo -n "1. Korean personalization: " >> "$LOG"
RESULT=$(sqlite3 "$DB" "SELECT title FROM observations_fts WHERE title MATCH '개인화' LIMIT 1;" 2>&1)
if [ -n "$RESULT" ] && [ "$RESULT" != "" ]; then
  echo "✅ Found" >> "$LOG"
  echo "   → $RESULT" >> "$LOG"
  FOUND_1=1
else
  echo "❌ NOT FOUND" >> "$LOG"
  FOUND_1=0
fi

# Query 2: SafetyBlocked (search in narrative)
echo -n "2. SafetyBlocked: " >> "$LOG"
RESULT=$(sqlite3 "$DB" "SELECT title FROM observations_fts WHERE narrative MATCH 'SafetyBlocked*' LIMIT 1;" 2>&1)
if [ -n "$RESULT" ] && [ "$RESULT" != "" ]; then
  echo "✅ Found" >> "$LOG"
  echo "   → $RESULT" >> "$LOG"
  FOUND_2=1
else
  echo "❌ NOT FOUND" >> "$LOG"
  FOUND_2=0
fi

# Query 3: flutter_animate
echo -n "3. flutter_animate: " >> "$LOG"
RESULT=$(sqlite3 "$DB" "SELECT title FROM observations_fts WHERE title MATCH 'flutter_animate' LIMIT 1;" 2>&1)
if [ -n "$RESULT" ] && [ "$RESULT" != "" ]; then
  echo "✅ Found" >> "$LOG"
  echo "   → $RESULT" >> "$LOG"
  FOUND_3=1
else
  echo "❌ NOT FOUND" >> "$LOG"
  FOUND_3=0
fi

# Query 4: Provider invalidation (search in title and narrative)
echo -n "4. Provider invalidation: " >> "$LOG"
RESULT=$(sqlite3 "$DB" "SELECT title FROM observations_fts WHERE narrative MATCH 'Provider AND invalidation' LIMIT 1;" 2>&1)
if [ -n "$RESULT" ] && [ "$RESULT" != "" ]; then
  echo "✅ Found" >> "$LOG"
  echo "   → $RESULT" >> "$LOG"
  FOUND_4=1
else
  echo "❌ NOT FOUND" >> "$LOG"
  FOUND_4=0
fi

# Query 5: Agent Teams (search in title)
echo -n "5. Agent Teams: " >> "$LOG"
RESULT=$(sqlite3 "$DB" "SELECT title FROM observations_fts WHERE title MATCH 'Agent' LIMIT 1;" 2>&1)
if [ -n "$RESULT" ] && [ "$RESULT" != "" ]; then
  echo "✅ Found" >> "$LOG"
  echo "   → $RESULT" >> "$LOG"
  FOUND_5=1
else
  echo "❌ NOT FOUND" >> "$LOG"
  FOUND_5=0
fi

# Summary
echo "" >> "$LOG"
TOTAL_FOUND=$((FOUND_1 + FOUND_2 + FOUND_3 + FOUND_4 + FOUND_5))
TOTAL=5
PRECISION=$((TOTAL_FOUND * 100 / TOTAL))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOG"
echo "Precision: $TOTAL_FOUND/$TOTAL ($PRECISION%)" >> "$LOG"
echo "Target: ≥75% (4/5 minimum)" >> "$LOG"

if [ $PRECISION -ge 75 ]; then
  echo "Status: ✅ PASS" >> "$LOG"
  EXIT_CODE=0
else
  echo "Status: ❌ FAIL (below target)" >> "$LOG"
  EXIT_CODE=1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOG"
echo "" >> "$LOG"
echo "Log saved: $LOG" >> "$LOG"

# Display results
cat "$LOG"

exit $EXIT_CODE
