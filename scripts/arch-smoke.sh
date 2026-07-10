#!/bin/bash

# MindLog 아키텍처 스모크 게이트 (refactor-plan §0-B 고정)
#
# 두 종류의 검사:
#   [불변식] 지금 반드시 성립 — 위반 시 즉시 실패 (exit 1)
#   [S2목표] 리팩토링으로 0을 향하는 지표 — 현재 위반 카운트를 보고만 함 (실패 아님)
#
# 사용:
#   ./scripts/run.sh arch-smoke        # run.sh 경유
#   bash scripts/arch-smoke.sh         # 직접
#
# 옵션:
#   --strict   [S2목표] 항목도 위반 시 실패로 처리 (S2 완료 후 게이트 승격용)
#
# 주의: 이 스크립트는 #!/bin/bash 로 실행되므로 대화형 zsh 의 rg 함수를
#       사용할 수 없다. 모든 검색은 POSIX grep(실바이너리)로 수행한다.

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

STRICT=false
for arg in "$@"; do
    [ "$arg" = "--strict" ] && STRICT=true
done

# 프로젝트 루트로 이동 (스크립트 위치 기준)
cd "$(cd "$(dirname "$0")/.." && pwd)" || exit 1

FAIL=0

fail()  { echo -e "${RED}FAIL${NC}: $1"; FAIL=1; }
ok()    { echo -e "${GREEN}OK${NC}: $1"; }
warn()  { echo -e "${YELLOW}WARN${NC}: $1"; }

# grep -E, --include, -r 은 GNU/BSD 공통. \s 미지원(BSD) → [[:space:]] 사용.
has()   { grep -rqE "$1" "$2" --include='*.dart' 2>/dev/null; }

echo "=== MindLog 아키텍처 스모크 ==="
echo ""

# ─────────────────────────────────────────────────────────────
# [불변식] 1) domain 레이어 Flutter import 0
# ─────────────────────────────────────────────────────────────
if has "package:flutter" lib/domain; then
    fail "domain 레이어에 Flutter import 존재 (순수 Dart 위반)"
    grep -rnE "package:flutter" lib/domain --include='*.dart'
else
    ok "domain 순수 Dart (Flutter import 0)"
fi

# ─────────────────────────────────────────────────────────────
# [불변식] 4) SafetyBlockedFailure 존재
# ─────────────────────────────────────────────────────────────
if has "class SafetyBlockedFailure" lib/core/errors; then
    ok "SafetyBlockedFailure 존재"
else
    fail "SafetyBlockedFailure 미존재 (위기 감지 핵심 손상)"
fi

# ─────────────────────────────────────────────────────────────
# [불변식] 5) safetyFollowupId 값 2004 + SafetyFollowupService 연결 유지
# ─────────────────────────────────────────────────────────────
if grep -qE "safetyFollowupId[[:space:]]*=[[:space:]]*2004" lib/core/services/notification_service.dart 2>/dev/null; then
    ok "safetyFollowupId = 2004 유지"
else
    fail "safetyFollowupId 값이 2004 아님 (SafetyFollowup 단절 위험)"
fi

if grep -qE "NotificationService\.safetyFollowupId" lib/core/services/safety_followup_service.dart 2>/dev/null; then
    ok "SafetyFollowupService → NotificationService.safetyFollowupId 참조 경로 유지"
else
    fail "SafetyFollowupService의 safetyFollowupId 참조 경로 단절"
fi

# ─────────────────────────────────────────────────────────────
# [불변식] 6) Cheer Me ID 헬퍼 유지
# ─────────────────────────────────────────────────────────────
if grep -qE "static bool isCheerMeId" lib/core/services/notification_service.dart 2>/dev/null; then
    ok "NotificationService.isCheerMeId 헬퍼 유지"
else
    fail "isCheerMeId 헬퍼 미존재 (diagnostic 카운트 버그 재발 위험)"
fi

echo ""
echo "--- [S2 목표] presentation → data 결합 지표 ---"

# ─────────────────────────────────────────────────────────────
# [S2목표] 2) presentation → data 직접 import
# ─────────────────────────────────────────────────────────────
DATA_FILES=$(grep -rlE "package:mindlog/data/" lib/presentation --include='*.dart' 2>/dev/null)
DATA_COUNT=$(printf '%s\n' "$DATA_FILES" | grep -c . )
if [ "$DATA_COUNT" -eq 0 ]; then
    ok "presentation → data import 0"
elif [ "$STRICT" = true ]; then
    fail "presentation → data import ${DATA_COUNT}개 파일 (strict)"
    printf '%s\n' "$DATA_FILES" | sed 's/^/    /'
else
    warn "presentation → data import ${DATA_COUNT}개 파일 (S2에서 0 목표)"
    printf '%s\n' "$DATA_FILES" | sed 's/^/    /'
fi

# ─────────────────────────────────────────────────────────────
# [S2목표] 3) PreferencesLocalDataSource 직접 인스턴스화 0
# ─────────────────────────────────────────────────────────────
PREFS_HITS=$(grep -rnE "PreferencesLocalDataSource\(\)" lib/presentation --include='*.dart' 2>/dev/null)
PREFS_COUNT=$(printf '%s\n' "$PREFS_HITS" | grep -c . )
if [ "$PREFS_COUNT" -eq 0 ]; then
    ok "PreferencesLocalDataSource() 직접 생성 0"
elif [ "$STRICT" = true ]; then
    fail "PreferencesLocalDataSource() 직접 생성 ${PREFS_COUNT}건 (strict)"
    printf '%s\n' "$PREFS_HITS" | sed 's/^/    /'
else
    warn "PreferencesLocalDataSource() 직접 생성 ${PREFS_COUNT}건 (S2에서 0 목표)"
    printf '%s\n' "$PREFS_HITS" | sed 's/^/    /'
fi

echo ""
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}✓ 아키텍처 불변식 통과${NC}"
    exit 0
else
    echo -e "${RED}✗ 아키텍처 불변식 위반${NC}"
    exit 1
fi
