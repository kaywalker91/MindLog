# Context Optimization Verification Checklist

## Current Status

✅ **All optimizations are correctly applied:**
- 9 wallet agents archived to `~/.claude/agents/archived/ility-wallet-experts/`
- Playwright disabled in `.claude/settings.json`
- MEMORY.md compressed to 1,322 words

❌ **Current session**: 61,550 tokens (31%)
✅ **Expected after restart**: ~56,000 tokens (28%)

**Why?** This session started BEFORE the optimizations were applied. Configuration loads at startup only.

---

## What You Need To Do

### STEP 1: Exit Claude Code

Close this session completely.

---

### STEP 2: Start New Session

```bash
# Navigate to project
cd /Users/kaywalker/AndroidStudioProjects/mindlog

# Start fresh Claude Code session
claude-code
```

---

### STEP 3: Immediate Verification

In the **new session**, run these commands:

```bash
# 1. Verify Playwright disabled
cat .claude/settings.json | grep -A 5 disabledMcpServers

# 2. Confirm agents archived
ls -la ~/.claude/agents/archived/ility-wallet-experts/ | wc -l

# 3. Check memory file size
wc -w ~/.claude/projects/-Users-kaywalker-AndroidStudioProjects-mindlog/memory/MEMORY.md
```

**Expected outputs:**
- Settings: `"disabledMcpServers": ["playwright"]`
- Archived: `12` (9 agents + . + .. + README)
- Memory: `1322` words

---

### STEP 4: Measure Token Usage

Check the session stats UI or context indicator.

**Expected:** ~56,000 tokens (28%)

If you see this range, **optimization succeeded!** ✅

---

### STEP 5: Apply Documentation Updates

If verification succeeded (≤56k tokens):

```bash
# Read the prepared updates
cat .claude/verification-updates.md

# Tell Claude: "Apply verification updates with measured tokens: [YOUR_MEASURED_VALUE]k"
```

Claude will:
1. Update `.claude/optimization-report-2026-02-10.md`
2. Update `MEMORY.md`
3. Update `.claude/rules/workflow.md`
4. Clean up temporary files

---

### STEP 6: Commit Results

```bash
git add .claude/ docs/
git commit -m "docs(context): 검증 완료 — Phase 1-3 최적화 [MEASURED]k tokens 달성"
git push
```

---

## If Tokens Still >56k

**Unlikely, but if it happens:**

Tell Claude: "Context still shows [MEASURED]k tokens. Execute Phase 3 residual optimization."

Claude will:
1. Scan for verbose skill files (>500 lines)
2. Check for duplicate architecture rules
3. Verify skill catalog compression
4. Apply additional optimizations
5. Re-measure and document

---

## Success Criteria

| Check | Target | Status |
|-------|--------|--------|
| Total Context | ≤56k tokens (28%) | ⏳ Pending restart |
| MCP Servers | 5 active (no Playwright) | ⏳ Pending restart |
| Archived Agents | 9 files excluded | ✅ Verified |
| Memory File | ≤1,500 words | ✅ 1,322 words |
| Optimization Report | Updated with verification | ⏳ After verification |
| Workflow Docs | Session restart triggers added | ⏳ After verification |

---

## Quick Reference

**Files to check:**
- `.claude/settings.json` - MCP config
- `~/.claude/agents/archived/ility-wallet-experts/` - Archived agents
- `MEMORY.md` - Compressed memory (1,322 words)

**Files to update (after verification):**
- `.claude/optimization-report-2026-02-10.md` - Append verification section
- `MEMORY.md` - Add verification entry
- `.claude/rules/workflow.md` - Add session restart triggers

**Helper file:**
- `.claude/verification-updates.md` - Contains all update content

---

**Next Action:** Exit Claude Code → Restart → Run verification commands → Measure tokens

**Expected Result:** ~56k tokens (28%), 10k reduction achieved ✅
