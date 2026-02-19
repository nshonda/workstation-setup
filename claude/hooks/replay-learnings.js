#!/usr/bin/env node
// Auto-surface relevant pro-workflow learnings on each user prompt.
// Reads user_prompt from stdin JSON, extracts keywords, queries SQLite FTS5.
// Output goes to stderr so it appears as hook context in the conversation.

const { execFileSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const DB = path.join(process.env.HOME, '.pro-workflow', 'data.db');

const STOP_WORDS = new Set([
  'the','a','an','is','are','was','were','be','been','being','have','has','had',
  'do','does','did','will','would','shall','should','may','might','must','can',
  'could','i','you','he','she','it','we','they','me','him','her','us','them',
  'my','your','his','its','our','their','this','that','these','those','what',
  'which','who','whom','to','of','in','for','on','with','at','by','from','as',
  'into','about','between','and','but','or','not','no','if','then','else','when',
  'up','out','so','just','also','make','want','need','use','like','get','how',
  'please','let','fix','add','sure','check','look','try','change','update',
  'create','new','all','any','some','now','here','there','where','why','much',
  'many','each','every','own','same','other','going','been','being','back',
  'help','think','know','see','tell','show','run','thing','work','way','take',
  'question','yes','no','ok','okay','thanks','thank','hey','hi','hello'
]);

let input = '';
process.stdin.on('data', c => input += c);
process.stdin.on('end', () => {
  try {
    if (!fs.existsSync(DB)) process.exit(0);

    const data = JSON.parse(input);
    const prompt = data.user_prompt || '';

    // Skip short or trivial prompts
    if (prompt.length < 20) process.exit(0);

    // Extract keywords: lowercase, alpha + digits + hyphens/underscores, skip stop words
    const words = prompt.toLowerCase().match(/[a-z][a-z0-9_-]{2,}/g) || [];
    const seen = new Set();
    const keywords = [];
    for (const w of words) {
      if (!STOP_WORDS.has(w) && !seen.has(w)) {
        seen.add(w);
        keywords.push(w);
      }
    }
    if (keywords.length === 0) process.exit(0);

    // Build FTS5 MATCH query — sanitize to alphanumeric/hyphens only, wrap in quotes
    const ftsTerms = keywords
      .slice(0, 8)
      .map(k => k.replace(/[^a-z0-9_-]/g, ''))
      .filter(k => k.length > 2)
      .map(k => '"' + k + '"')
      .join(' OR ');

    if (!ftsTerms) process.exit(0);

    const sql = [
      'SELECT l.category, l.rule, l.mistake',
      'FROM learnings l',
      'JOIN learnings_fts ON l.id = learnings_fts.rowid',
      "WHERE learnings_fts MATCH '" + ftsTerms + "'",
      'ORDER BY bm25(learnings_fts)',
      'LIMIT 5;'
    ].join(' ');

    const result = execFileSync('sqlite3', [DB, sql], {
      encoding: 'utf8',
      timeout: 3000
    }).trim();

    if (result) {
      const lines = result.split('\n').filter(l => l.trim());
      if (lines.length > 0) {
        console.error('[ProWorkflow] ' + lines.length + ' relevant learning(s) found:');
        for (const line of lines) {
          const parts = line.split('|');
          const category = parts[0] || '';
          const rule = parts[1] || '';
          const mistake = parts[2] || '';
          console.error('  - [' + category + '] ' + rule);
          if (mistake) console.error('    Mistake: ' + mistake);
        }
      }
    }
  } catch (e) {
    // Silently fail — never block the user's prompt
  }
  process.exit(0);
});
