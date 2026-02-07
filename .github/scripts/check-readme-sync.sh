#!/bin/bash
# Check that README.md and README.ko.md have matching heading structure.
# This prevents content drift between English and Korean versions.

set -euo pipefail

EN="README.md"
KO="README.ko.md"

if [ ! -f "$EN" ] || [ ! -f "$KO" ]; then
  echo "ERROR: $EN or $KO not found."
  exit 1
fi

# Extract ## headings (level 2 only — section structure)
en_count=$(grep -c '^## ' "$EN" || true)
ko_count=$(grep -c '^## ' "$KO" || true)

echo "README.md    — $en_count sections (## headings)"
echo "README.ko.md — $ko_count sections (## headings)"

if [ "$en_count" -ne "$ko_count" ]; then
  echo ""
  echo "WARNING: Section count mismatch!"
  echo ""
  echo "README.md sections:"
  grep '^## ' "$EN" | nl
  echo ""
  echo "README.ko.md sections:"
  grep '^## ' "$KO" | nl
  exit 1
fi

# Badge count check (warning only)
en_badges=$(grep -c 'img.shields.io' "$EN" || true)
ko_badges=$(grep -c 'img.shields.io' "$KO" || true)

if [ "$en_badges" -ne "$ko_badges" ]; then
  echo ""
  echo "WARNING: Badge count differs ($en_badges vs $ko_badges) — please verify."
fi

echo ""
echo "README sync check passed."
