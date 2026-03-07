#!/usr/bin/env node
// Cross-project memory search via grep across all MEMORY.md files.
// Surfaces relevant learnings from OTHER projects on each user prompt.
// Current project's MEMORY.md is already loaded by Claude Code automatically.

const { execFileSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const PROJECTS_DIR = path.join(process.env.HOME, '.claude', 'projects');

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
    if (!fs.existsSync(PROJECTS_DIR)) process.exit(0);

    const data = JSON.parse(input);
    const prompt = data.user_prompt || '';
    // Higher threshold to avoid noisy matches on short/trivial prompts
    if (prompt.length < 50) process.exit(0);

    // Extract keywords
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

    const pattern = keywords.slice(0, 8).join('|');

    // Grep across all MEMORY.md files
    let result;
    try {
      result = execFileSync('grep', [
        '-r', '-i', '-n', '--include=MEMORY.md',
        '-E', pattern,
        PROJECTS_DIR
      ], { encoding: 'utf8', timeout: 3000 }).trim();
    } catch (e) {
      // grep returns exit code 1 when no matches
      process.exit(0);
    }

    if (!result) process.exit(0);

    // Determine current project to exclude (already in context)
    const cwd = process.cwd();

    const lines = result.split('\n').filter(l => l.trim());
    const matches = [];
    const seenContent = new Set();

    for (const line of lines) {
      const pathMatch = line.match(/projects\/([^/]+)\/memory/);
      if (!pathMatch) continue;

      // Derive readable project name from encoded path
      const encoded = pathMatch[1];
      const project = encoded
        .replace(/-Users-natalihonda-workstation-(?:personal|work)-/, '')
        .replace(/-/g, '/');

      // Skip current project's memories (already loaded via auto-memory)
      if (cwd && encoded.includes(path.basename(cwd))) continue;

      // Extract content after filepath:linenum:
      const content = line.replace(/^[^:]+:\d+:/, '').trim();
      if (!content || content.startsWith('#') || content.length < 10) continue;
      if (seenContent.has(content)) continue;
      seenContent.add(content);

      matches.push({ project, content });
      if (matches.length >= 5) break;
    }

    if (matches.length > 0) {
      console.error('[CrossProject] ' + matches.length + ' relevant memory(s) from other projects:');
      for (const m of matches) {
        console.error('  - [' + m.project + '] ' + m.content.substring(0, 200));
      }
    }
  } catch (e) {
    // Silently fail
  }
  process.exit(0);
});
