# MEMORY.md to Claude-Mem Export Script

Exports MindLog project memory (`MEMORY.md`) to claude-mem observations for semantic search and timeline-based retrieval.

## Prerequisites

- Node.js 18+
- claude-mem worker service running on `localhost:37777`
- `MEMORY.md` at `~/.claude/projects/-Users-kaywalker-AndroidStudioProjects-mindlog/memory/MEMORY.md`

## Usage

### Dry-run (preview output)
```bash
node scripts/export-memory-to-claude-mem.js --dry-run
```

**Output**:
- First 3 observations (JSON preview)
- Total observation count
- Unique tags summary
- Date distribution
- **Critical patterns summary** (10 patterns)

### Export full JSON (for validation)
```bash
node scripts/export-memory-to-claude-mem.js --dry-run --json > /tmp/observations.json
```

### Actual export (seed database)
```bash
# Ensure worker service is running first
curl http://localhost:37777/health

# Run export
node scripts/export-memory-to-claude-mem.js
```

## Features

### 1. Date Extraction
Extracts dates from section titles:
- Pattern: `(YYYY-MM-DD)` or `YYYY年M月D日`
- Default: `2026-02-05` for historical entries without dates

### 2. Tag Extraction

#### Critical Patterns (10 patterns from Phase 1 assessment)
1. **Korean Name Personalization**: 한글, Korean, 조사, 개인화
2. **SafetyBlockedFailure**: SafetyBlockedFailure, SafetyFollowup, 절대 수정 금지
3. **FCM Constraint**: FCM + (알림 | notification | 개인화)
4. **flutter_animate**: flutter_animate, pumpAndSettle
5. **Private Widget**: Private Widget, _AccentSettingsCard, IntrinsicHeight
6. **Cheer Me**: Cheer Me, getCheerMeTitle
7. **Provider Invalidation**: Provider + (invalidation | reschedule)
8. **Emotion Trend**: EmotionTrend, gap > steady
9. **EmotionAware**: emotionAware, 가중치
10. **Agent Teams**: Agent Teams, 7-Gate, 병렬 감사

#### Category Tags
- `testing` — 테스트, Test, Widget, flutter_animate
- `architecture` — Architecture, Clean Architecture
- `performance` — Performance, 성능
- `ui` — UI, UX, Widget
- `state-management` — Provider, Riverpod
- `notification` — 알림, Notification
- `debugging` — Debug, 디버깅

#### Observation Type Tags
- `pattern` — 패턴, Pattern
- `constraint` — 제약, Constraint
- `decision` — 결정, Decision
- `discovery` — 발견, Discovery

### 3. Metadata
Each observation includes:
- `id`: `memory-N` (0-indexed)
- `timestamp`: ISO 8601 date string
- `title`: Section title
- `content`: Section body
- `tags`: Array of extracted tags
- `metadata`:
  - `source`: "MEMORY.md"
  - `category`: kebab-case section name
  - `level`: Header level (2-4)
  - `startLine`: Line number in original file

## Expected Output (dry-run)

```
📖 Reading MEMORY.md...
🔍 Parsing sections...
   Found 29 sections
📦 Converting to observations...

📋 DRY RUN - Output (first 3 observations):
[
  { ... }
]

   Total observations: 28

🏷️  Tags (15 unique):
   agent-teams, architecture, critical, debugging, decision, discovery, i18n, korean, notification, pattern, performance, safety, testing, ui, workflow

📅 Date distribution:
   2026-02-05: 13 observations
   2026-02-06: 12 observations
   2026-02-07: 3 observations

🚨 Critical patterns (10 observations):
   - 한글 이름 개인화 패턴 (2026-02-06)
   - FCM 알림 개인화 불가 아키텍처 제약 (2026-02-06)
   - 알림 제목 개인화 패턴 (2026-02-06)
   - 알림 차별화 프로젝트 (2026-02-06)
   - Phase 2 핵심 패턴 (2026-02-06)
   - Testing Insights
   - flutter_animate 위젯 테스트 (2026-02-06)
   - Private Widget 테스트 & 뷰포트 패턴 (2026-02-07)
   - IntrinsicHeight for Accent Stripes
   - Agent Teams 병렬 감사 패턴 (2026-02-07)
```

## Phase 2 Validation Queries

After successful export, test these queries to verify critical patterns are retrievable:

```bash
# 1. Korean personalization
curl -X POST http://localhost:37777/api/search -H "Content-Type: application/json" \
  -d '{"query": "Korean name personalization regex pattern", "limit": 5}'

# 2. SafetyBlocked
curl -X POST http://localhost:37777/api/search -H "Content-Type: application/json" \
  -d '{"query": "SafetyBlockedFailure never modify emergency", "limit": 5}'

# 3. FCM constraint
curl -X POST http://localhost:37777/api/search -H "Content-Type: application/json" \
  -d '{"query": "FCM notification personalization background constraint", "limit": 5}'

# 4. flutter_animate
curl -X POST http://localhost:37777/api/search -H "Content-Type: application/json" \
  -d '{"query": "flutter_animate pumpAndSettle forbidden", "limit": 5}'

# 5. Private widget
curl -X POST http://localhost:37777/api/search -H "Content-Type: application/json" \
  -d '{"query": "private widget testing structural markers", "limit": 5}'
```

**Success criteria**: All 5 queries return relevant results with precision >= 80%

## Troubleshooting

### Worker service not running
```bash
Error: Failed to send observation: fetch failed
```
**Solution**: Start worker service:
```bash
cd ~/.claude/memory-systems/claude-mem
bun run plugin/scripts/worker-service.cjs start
```

### Permission denied
```bash
Error: EACCES: permission denied
```
**Solution**: Check file permissions:
```bash
chmod +x scripts/export-memory-to-claude-mem.js
```

### JSON parse error
```bash
SyntaxError: Unexpected token
```
**Solution**: Ensure MEMORY.md has valid UTF-8 encoding:
```bash
file ~/.claude/projects/.../memory/MEMORY.md
```

## Rollback

If export fails or Phase 2 validation fails, data can be deleted:
```bash
# Stop worker service
cd ~/.claude/memory-systems/claude-mem
bun run plugin/scripts/worker-service.cjs stop

# Delete database (nuclear option)
rm ~/.claude-mem/claude-mem.db

# Restart worker (will reinitialize empty DB)
bun run plugin/scripts/worker-service.cjs start
```

Backup is preserved at:
- Git tag: `pre-claude-mem-migration-2026-02-07`
- Directory: `~/.claude/projects/.../memory-backup-2026-02-07/`

## Next Steps

After successful export and validation:
1. Begin 1-week parallel operation (file + claude-mem)
2. Daily validation: Run 5 critical queries
3. Track token usage (baseline vs claude-mem)
4. Phase 3: GO/NO-GO decision based on success criteria
