#!/usr/bin/env bash
# 테스트 통과 후에도 남으면 안 되는 side-effect 로그 패턴 검사
set -euo pipefail

LOG_FILE="${1:-}"
if [[ -z "$LOG_FILE" || ! -f "$LOG_FILE" ]]; then
  echo "Usage: check-test-log-leakage.sh <test-log-file>"
  exit 1
fi

PATTERNS=(
  'ProviderContainer that was already disposed'
  '\[DiaryAnalysis\] Emotion trend analysis failed'
  '\[DiaryAnalysis\] Emotion-aware Cheer Me reschedule failed'
  '\[DiaryAnalysis\] Post-analysis notification failed'
)

FAILED=0
for pattern in "${PATTERNS[@]}"; do
  if grep -qE "$pattern" "$LOG_FILE"; then
    echo "❌ Test log leakage detected: $pattern"
    grep -E "$pattern" "$LOG_FILE" | head -5
    FAILED=1
  fi
done

if [[ "$FAILED" -eq 1 ]]; then
  exit 1
fi

echo "✅ No test side-effect leakage patterns detected"