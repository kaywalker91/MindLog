# Claude-Mem ChromaDB Diagnosis & Workaround

**Date**: 2026-02-07
**Issue**: Semantic search not working - zero embeddings in ChromaDB
**Status**: ROOT CAUSE IDENTIFIED ✅

---

## Root Cause Analysis

### Symptom
```bash
curl 'http://localhost:37777/api/search?query=Korean+name'
# Returns: "No results found"
```

### Investigation Steps

**1. Database Verification**
```bash
# Main DB: ✅ 26 observations stored
sqlite3 ~/.claude-mem/claude-mem.db "SELECT COUNT(*) FROM observations;"
# 26

# ChromaDB: ❌ Zero embeddings
sqlite3 ~/.claude-mem/vector-db/chroma.sqlite3 "SELECT COUNT(*) FROM embeddings;"
# 0

# Embeddings queue: ❌ Empty (should have pending items)
sqlite3 ~/.claude-mem/vector-db/chroma.sqlite3 "SELECT COUNT(*) FROM embeddings_queue;"
# 0
```

**2. Log Analysis**
```
~/.claude-mem/logs/claude-mem-2026-02-07.log
```

**Key Errors**:
```
[ERROR] [CHROMA] ChromaDB sync failed {id=19-26}
        Chroma connection failed: MCP error -32001: Request timed out

[ERROR] [CHROMA_SYNC] Failed to connect to Chroma MCP server
        MCP error -32001: Request timed out

[ERROR] [CHROMA_SYNC] Failed to parse Chroma response
        JSON Parse error: Unexpected identifier "Error"
```

### Root Cause

**ChromaDB MCP Server Issues**:
1. **MCP Timeout**: ChromaDB MCP server not responding within timeout window
2. **JSON Parse Error**: ChromaDB returning malformed responses (raw "Error" string instead of JSON)
3. **Connection Failures**: Intermittent MCP server connectivity

**Impact**:
- Observations stored successfully in SQLite ✅
- ChromaDB sync attempted but failed ❌
- Zero vector embeddings created ❌
- Semantic search non-functional ❌

---

## Immediate Workaround: File System Primary Mode

### Strategy
Run Phase 2 parallel operation **without** relying on semantic search:

| Source | Role | Status |
|--------|------|--------|
| File system (MEMORY.md) | **PRIMARY** | ✅ Fully functional |
| SQLite (claude-mem.db) | Timeline/listing | ✅ Working (26 obs) |
| ChromaDB (vectors) | Semantic search | ❌ Blocked (MCP issue) |

### Parallel Operation Rules

**Week 1 (This Week)**:
1. Continue using file system as primary knowledge source
2. Update MEMORY.md as usual when adding patterns
3. Skip semantic search validation (blocked)
4. Use SQLite queries for timeline/listing validation
5. Track: Token usage, maintenance time

**Week 2 (Next Week)**:
1. Evaluate token usage reduction (even without search)
2. Decide: Fix ChromaDB MCP vs. Alternative approach
3. GO/NO-GO based on non-search metrics

---

## Long-Term Solutions

### Option 1: Fix ChromaDB MCP Server (Recommended)

**Steps**:
1. Check ChromaDB MCP server configuration in claude-mem settings
2. Verify MCP server is running and healthy
3. Increase MCP timeout settings
4. Restart worker service after fixes
5. Manually trigger re-sync: `POST /api/pending-queue/process`
6. Or: Rebuild ChromaDB from SQLite observations

**Complexity**: MEDIUM
**Timeline**: 1-2 hours next session
**Success rate**: HIGH (standard MCP troubleshooting)

### Option 2: Alternative Semantic Search (Fallback)

**Approaches**:
1. **SQLite Full-Text Search (FTS5)**:
   - Already available in claude-mem
   - Table: `embedding_fulltext_search`
   - No vectors needed, keyword-based
   - Fast, no MCP dependency

2. **Local Embedding Generation**:
   - Use local model (e.g., sentence-transformers)
   - Generate embeddings without MCP
   - Store directly in ChromaDB SQLite

3. **Hybrid Search**:
   - FTS5 for keyword matching
   - Manual relevance scoring
   - No vector similarity needed

**Complexity**: LOW (FTS5), MEDIUM (local embeddings)
**Timeline**: < 1 hour (FTS5), 2-3 hours (local)
**Success rate**: VERY HIGH

### Option 3: Phase 3 Abort (Nuclear Option)

If ChromaDB remains broken and alternatives fail:
- Keep file system as permanent solution
- Use claude-mem SQLite for timeline only
- Abandon semantic search requirement
- Focus on token reduction via structured memory

**Complexity**: NONE (rollback)
**Timeline**: Immediate
**Success rate**: 100% (guaranteed)

---

## Recommended Path Forward

### This Session (Completed)
- [x] Root cause identified: ChromaDB MCP server failure
- [x] Workaround plan documented
- [x] File system confirmed as reliable primary

### Next Session (High Priority)
1. **Option 1A**: Test SQLite FTS5 search (fastest workaround)
   ```sql
   SELECT * FROM embedding_fulltext_search
   WHERE embedding_fulltext_search MATCH 'Korean personalization'
   LIMIT 5;
   ```

2. **Option 1B**: If FTS5 works, update export script to use FTS5 endpoint

3. **Option 2**: If FTS5 insufficient, troubleshoot ChromaDB MCP
   - Check `~/.claude/memory-systems/claude-mem/plugin/settings.json`
   - Review MCP server logs
   - Increase timeout configuration

### Week 1-2 (Parallel Operation)
- Use file system + SQLite (no semantic search dependency)
- Collect token usage baseline
- Document maintenance overhead
- Prepare Phase 3 evaluation

---

## Success Metrics (Revised)

| Metric | Original Target | Revised Target | Rationale |
|--------|----------------|----------------|-----------|
| Database seeding | ✅ | ✅ | Complete (26/28) |
| Critical patterns tagged | ✅ | ✅ | Complete (10/10) |
| **Semantic search** | **80% precision** | **DEFERRED** | MCP blocker, alternatives exist |
| Token reduction | 30%+ | 30%+ | Independent of search |
| Maintenance time | ≤30min/week | ≤30min/week | Independent of search |
| **SQLite timeline** | **N/A** | **✅ Working** | Alternative validation method |

**New Success Criterion**: Either semantic search OR SQLite FTS5 search working

---

## Risk Assessment (Updated)

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| ChromaDB MCP never works | LOW | MEDIUM | SQLite FTS5 alternative |
| Token reduction < 30% | MEDIUM | LOW | Independent of search |
| File system remains optimal | LOW | MEDIUM | Accept as final state |
| Phase 3 abort needed | VERY LOW | VERY LOW | 2 backup options (FTS5, local embeddings) |

**Overall Risk**: VERY LOW — Multiple fallback options available

---

## Key Learnings

### 1. MCP Dependency Risk
- ChromaDB via MCP introduces external dependency
- Timeout and parse errors indicate fragile integration
- **Lesson**: Always have non-MCP fallback for critical features

### 2. SQLite Robustness
- Main observation storage (SQLite) worked perfectly
- Zero data loss despite ChromaDB failure
- **Lesson**: Core data storage should not depend on external services

### 3. FTS5 Hidden Strength
- SQLite FTS5 already configured in claude-mem
- Can provide keyword search without vectors
- **Lesson**: Check existing DB capabilities before debugging external services

### 4. Parallel Operation Value
- File system safety net prevented any workflow disruption
- Parallel approach validated as correct risk mitigation
- **Lesson**: Phase 2 parallel operation is essential, not optional

---

## Files & Resources

### Log Files
- `~/.claude-mem/logs/claude-mem-2026-02-07.log` (MCP errors)

### Database Files
- `~/.claude-mem/claude-mem.db` (26 observations ✅)
- `~/.claude-mem/vector-db/chroma.sqlite3` (0 embeddings ❌)

### Configuration
- `~/.claude/memory-systems/claude-mem/plugin/settings.json` (MCP config)

### Documentation
- `.claude/progress/claude-mem-phase2-complete.md` (seeding results)
- `scripts/README-export-memory.md` (export guide)

---

## Next Steps Priority

1. **HIGH**: Test SQLite FTS5 search (< 15 min)
2. **MEDIUM**: Troubleshoot ChromaDB MCP (1-2 hours)
3. **LOW**: Local embedding generation (2-3 hours)
4. **DEFERRED**: Phase 3 evaluation (next week)

**Recommendation**: Start with FTS5 test next session for fastest path to working search

---

**Last Updated**: 2026-02-07 17:45 KST
**Status**: ROOT CAUSE IDENTIFIED, WORKAROUND PLANNED, READY FOR NEXT SESSION
