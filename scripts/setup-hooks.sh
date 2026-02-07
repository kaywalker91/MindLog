#!/bin/bash

# MindLog Git Hooks Setup
# Configures git to use version-controlled hooks from scripts/githooks/
# Safe to run multiple times (idempotent).

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Find project root
ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$ROOT_DIR" ]; then
    echo -e "${RED}Error: Not a git repository.${NC}"
    exit 1
fi

cd "$ROOT_DIR"

# Ensure hooks directory and files exist
if [ ! -f "scripts/githooks/pre-push" ]; then
    echo -e "${RED}Error: scripts/githooks/pre-push not found.${NC}"
    exit 1
fi

# Make hooks executable
chmod +x scripts/githooks/pre-push

# Set git to use our hooks directory
git config core.hooksPath scripts/githooks

echo -e "${GREEN}Git hooks configured successfully.${NC}"
echo ""
echo "  hooks path: scripts/githooks/"
echo "  pre-push:   enabled (runs affected tests)"
echo ""
echo -e "${YELLOW}To disable:${NC} git config --unset core.hooksPath"
