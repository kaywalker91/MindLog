#!/usr/bin/env node
/**
 * Export MEMORY.md to claude-mem observations
 *
 * Usage:
 *   node scripts/export-memory-to-claude-mem.js [--dry-run]
 *
 * Options:
 *   --dry-run    Print JSON output without calling API
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Path to claude-managed memory directory
const MEMORY_PATH = path.join(
  process.env.HOME,
  '.claude/projects/-Users-kaywalker-AndroidStudioProjects-mindlog/memory/MEMORY.md'
);
const CLAUDE_MEM_API = 'http://localhost:37777/api/memory/save';
const PROJECT_NAME = 'mindlog';

// Date extraction regex patterns
const DATE_PATTERNS = [
  /\((\d{4}-\d{2}-\d{2})\)/,  // (2026-02-06)
  /(\d{4}年\d{1,2}月\d{1,2}日)/,  // Korean date format
];

/**
 * Extract date from section title and content
 */
function extractDate(title, content) {
  // Try to extract from title first
  const fullText = title + ' ' + content;

  for (const pattern of DATE_PATTERNS) {
    const match = fullText.match(pattern);
    if (match) {
      const dateStr = match[1].replace(/年|月/g, '-').replace(/日/g, '');
      const date = new Date(dateStr + 'T00:00:00Z');
      if (!isNaN(date.getTime())) {
        return date.toISOString();
      }
    }
  }

  // Default to a baseline date for historical entries
  // Use 2026-02-05 as default for older entries without explicit dates
  return new Date('2026-02-05T00:00:00Z').toISOString();
}

/**
 * Extract tags from section title and content
 */
function extractTags(title, content) {
  const tags = new Set();
  const fullText = title + ' ' + content;

  // Critical patterns (from claude-mem-critical-patterns.md - 10 patterns)
  // 1. Korean Name Personalization
  if (fullText.includes('한글') || fullText.includes('Korean') || fullText.includes('조사') || fullText.includes('개인화')) {
    tags.add('critical');
    tags.add('korean');
    tags.add('i18n');
  }
  // 2. SafetyBlockedFailure Invariant
  if (fullText.includes('SafetyBlockedFailure') || fullText.includes('SafetyFollowup') || fullText.includes('절대 수정 금지')) {
    tags.add('critical');
    tags.add('safety');
  }
  // 3. FCM Architectural Constraint
  if (fullText.includes('FCM') && (fullText.includes('알림') || fullText.includes('notification') || fullText.includes('개인화'))) {
    tags.add('critical');
    tags.add('notification');
  }
  // 4. flutter_animate Test Pattern
  if (fullText.includes('flutter_animate') || fullText.includes('pumpAndSettle')) {
    tags.add('critical');
    tags.add('testing');
  }
  // 5. Private Widget Testing
  if (fullText.includes('Private Widget') || fullText.includes('_AccentSettingsCard') || fullText.includes('IntrinsicHeight')) {
    tags.add('critical');
    tags.add('testing');
  }
  // 6. Cheer Me Title Personalization
  if (fullText.includes('Cheer Me') || fullText.includes('getCheerMeTitle')) {
    tags.add('notification');
  }
  // 7. Provider Invalidation Chain
  if (fullText.includes('Provider') && (fullText.includes('invalidation') || fullText.includes('reschedule'))) {
    tags.add('state-management');
    tags.add('pattern');
  }
  // 8. Emotion Trend Priority
  if (fullText.includes('EmotionTrend') || fullText.includes('gap > steady > recovering')) {
    tags.add('notification');
    tags.add('pattern');
  }
  // 9. EmotionAware Weighted Random
  if (fullText.includes('emotionAware') || fullText.includes('가중치')) {
    tags.add('notification');
    tags.add('pattern');
  }
  // 10. Agent Teams Audit
  if (fullText.includes('Agent Teams') || fullText.includes('7-Gate') || fullText.includes('병렬 감사')) {
    tags.add('critical');
    tags.add('agent-teams');
    tags.add('workflow');
  }

  // General notification tagging
  if (fullText.includes('알림') || fullText.includes('notification')) {
    tags.add('notification');
  }

  // Category tags
  if (title.includes('테스트') || title.includes('Test') || content.includes('flutter_animate')) {
    tags.add('testing');
  }
  if (title.includes('Architecture') || content.includes('Clean Architecture')) {
    tags.add('architecture');
  }
  if (title.includes('Performance') || title.includes('성능')) {
    tags.add('performance');
  }
  if (title.includes('UI') || title.includes('UX') || title.includes('Widget')) {
    tags.add('ui');
  }
  if (title.includes('Provider') || content.includes('Riverpod')) {
    tags.add('state-management');
  }
  if (title.includes('알림') || title.includes('Notification')) {
    tags.add('notification');
  }
  if (title.includes('Debug') || title.includes('디버깅')) {
    tags.add('debugging');
  }
  if (title.includes('Agent Teams') || title.includes('병렬')) {
    tags.add('agent-teams');
    tags.add('workflow');
  }

  // Observation type tags
  if (content.includes('패턴') || content.includes('Pattern')) {
    tags.add('pattern');
  }
  if (content.includes('제약') || content.includes('Constraint')) {
    tags.add('constraint');
  }
  if (content.includes('결정') || content.includes('Decision')) {
    tags.add('decision');
  }
  if (content.includes('발견') || content.includes('Discovery')) {
    tags.add('discovery');
  }

  return Array.from(tags);
}

/**
 * Parse MEMORY.md into structured sections
 */
function parseMemory(content) {
  const sections = [];
  const lines = content.split('\n');
  let currentSection = null;
  let currentLevel = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Detect headers
    const headerMatch = line.match(/^(#{1,4})\s+(.+)$/);
    if (headerMatch) {
      const level = headerMatch[1].length;
      const title = headerMatch[2].trim();

      // Save previous section
      if (currentSection) {
        sections.push(currentSection);
      }

      // Start new section
      currentSection = {
        level,
        title,
        content: '',
        startLine: i,
      };
      currentLevel = level;
    } else if (currentSection) {
      // Accumulate content
      currentSection.content += line + '\n';
    }
  }

  // Save last section
  if (currentSection) {
    sections.push(currentSection);
  }

  return sections;
}

/**
 * Convert section to observation
 */
function sectionToObservation(section, index) {
  const timestamp = extractDate(section.title, section.content);
  const tags = extractTags(section.title, section.content);

  // Determine category from section title
  let category = 'general';
  if (section.level === 2) {
    category = section.title.toLowerCase()
      .replace(/\s+/g, '-')
      .replace(/[^a-z0-9-가-힣]/g, '');
  }

  return {
    id: `memory-${index}`,
    timestamp,
    title: section.title,
    content: section.content.trim(),
    tags,
    metadata: {
      source: 'MEMORY.md',
      category,
      level: section.level,
      startLine: section.startLine,
    },
  };
}

/**
 * Send observation to claude-mem API
 */
async function sendObservation(observation) {
  // Convert observation to claude-mem API format
  // API expects: { text: string, title?: string, project?: string }
  const payload = {
    text: observation.content,
    title: observation.title,
    project: PROJECT_NAME,
  };

  const response = await fetch(CLAUDE_MEM_API, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Failed to send observation: ${error}`);
  }

  return response.json();
}

/**
 * Main export function
 */
async function exportMemory(dryRun = false, fullJson = false) {
  console.log('📖 Reading MEMORY.md...');
  const content = fs.readFileSync(MEMORY_PATH, 'utf8');

  console.log('🔍 Parsing sections...');
  const sections = parseMemory(content);
  console.log(`   Found ${sections.length} sections`);

  console.log('📦 Converting to observations...');
  const observations = sections
    .filter(section => section.level >= 2) // Skip top-level title
    .map((section, index) => sectionToObservation(section, index));

  if (dryRun) {
    if (fullJson) {
      // Output full JSON for validation
      console.log(JSON.stringify(observations, null, 2));
      return;
    }

    console.log('\n📋 DRY RUN - Output (first 3 observations):');
    console.log(JSON.stringify(observations.slice(0, 3), null, 2));
    console.log(`\n   Total observations: ${observations.length}`);

    // Print tag summary
    const allTags = new Set();
    observations.forEach(obs => obs.tags.forEach(tag => allTags.add(tag)));
    console.log(`\n🏷️  Tags (${allTags.size} unique):`);
    console.log(`   ${Array.from(allTags).sort().join(', ')}`);

    // Print timestamp distribution
    console.log(`\n📅 Date distribution:`);
    const dateCount = {};
    observations.forEach(obs => {
      const date = obs.timestamp.split('T')[0];
      dateCount[date] = (dateCount[date] || 0) + 1;
    });
    Object.entries(dateCount).sort().forEach(([date, count]) => {
      console.log(`   ${date}: ${count} observations`);
    });

    // Print critical patterns summary
    const criticalObs = observations.filter(obs => obs.tags.includes('critical'));
    console.log(`\n🚨 Critical patterns (${criticalObs.length} observations):`);
    criticalObs.forEach(obs => {
      console.log(`   - ${obs.title}`);
    });

    return;
  }

  console.log('🚀 Sending observations to claude-mem...');
  let successCount = 0;
  let failCount = 0;

  for (const obs of observations) {
    try {
      await sendObservation(obs);
      successCount++;
      process.stdout.write(`\r   ✓ ${successCount}/${observations.length}`);
    } catch (error) {
      failCount++;
      console.error(`\n   ✗ Failed to send observation "${obs.title}": ${error.message}`);
    }
  }

  console.log('\n\n✅ Export complete!');
  console.log(`   Success: ${successCount}`);
  console.log(`   Failed: ${failCount}`);

  // Print tag summary
  const allTags = new Set();
  observations.forEach(obs => obs.tags.forEach(tag => allTags.add(tag)));
  console.log(`\n🏷️  Tags (${allTags.size} unique):`);
  console.log(`   ${Array.from(allTags).sort().join(', ')}`);
}

// CLI execution
const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run');
const fullJson = args.includes('--json');

exportMemory(dryRun, fullJson)
  .catch(error => {
    console.error('❌ Export failed:', error.message);
    process.exit(1);
  });
