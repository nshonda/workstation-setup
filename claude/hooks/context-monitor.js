#!/usr/bin/env node
// Context Monitor — PostToolUse hook
// Injects advisory warnings when the context window is running low.
// Uses context_window.remaining_percentage from hook input if available;
// falls back to bridge file at /tmp/claude-ctx-{sessionId}.json.

const fs = require('fs');
const os = require('os');
const path = require('path');

const WARNING_THRESHOLD = 35;   // raw remaining_percentage
const CRITICAL_THRESHOLD = 25;
const DEBOUNCE_CALLS = 5;
const STALE_SECONDS = 60;
const AUTO_COMPACT_BUFFER_PCT = 16.5;

const DEBUG = process.env.CLAUDE_HOOK_DEBUG === '1';

function normalizeUsed(remaining) {
  const usable = Math.max(0,
    ((remaining - AUTO_COMPACT_BUFFER_PCT) / (100 - AUTO_COMPACT_BUFFER_PCT)) * 100
  );
  return Math.round(100 - usable);
}

let input = '';
const stdinTimeout = setTimeout(() => process.exit(0), 3000);
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  clearTimeout(stdinTimeout);
  try {
    const data = JSON.parse(input);

    if (DEBUG) {
      console.error('[ContextMonitor:DEBUG] Hook input keys:', Object.keys(data).join(', '));
      if (data.context_window) {
        console.error('[ContextMonitor:DEBUG] context_window:', JSON.stringify(data.context_window));
      }
    }

    // Primary: read directly from hook input
    let remaining = data.context_window?.remaining_percentage;

    // Fallback: bridge file written by statusline or external tool
    if (remaining == null) {
      const sessionId = data.session_id || 'default';
      const bridgePath = path.join(os.tmpdir(), `claude-ctx-${sessionId}.json`);
      if (fs.existsSync(bridgePath)) {
        try {
          const bridge = JSON.parse(fs.readFileSync(bridgePath, 'utf8'));
          const now = Math.floor(Date.now() / 1000);
          if (bridge.timestamp && (now - bridge.timestamp) <= STALE_SECONDS) {
            remaining = bridge.remaining_percentage;
          }
        } catch (e) { /* corrupted bridge file — ignore */ }
      }
    }

    if (remaining == null) {
      if (DEBUG) console.error('[ContextMonitor:DEBUG] No context data available — exiting');
      process.exit(0);
    }

    if (remaining > WARNING_THRESHOLD) {
      if (DEBUG) console.error(`[ContextMonitor:DEBUG] OK — ${remaining}% remaining`);
      process.exit(0);
    }

    const used = normalizeUsed(remaining);
    const isCritical = remaining <= CRITICAL_THRESHOLD;
    const currentLevel = isCritical ? 'critical' : 'warning';

    // Debounce
    const sessionId = data.session_id || 'default';
    const warnPath = path.join(os.tmpdir(), `claude-ctx-${sessionId}-monitor.json`);
    let warnData = { callsSinceWarn: 0, lastLevel: null };
    let firstWarn = true;

    if (fs.existsSync(warnPath)) {
      try {
        warnData = JSON.parse(fs.readFileSync(warnPath, 'utf8'));
        firstWarn = false;
      } catch (e) { /* reset on corruption */ }
    }

    warnData.callsSinceWarn = (warnData.callsSinceWarn || 0) + 1;
    const severityEscalated = currentLevel === 'critical' && warnData.lastLevel === 'warning';

    if (!firstWarn && warnData.callsSinceWarn < DEBOUNCE_CALLS && !severityEscalated) {
      if (DEBUG) {
        console.error(`[ContextMonitor:DEBUG] Suppressed ${currentLevel} — ${warnData.callsSinceWarn}/${DEBOUNCE_CALLS} calls since last warn`);
      }
      fs.writeFileSync(warnPath, JSON.stringify(warnData));
      process.exit(0);
    }

    // Fire warning
    warnData.callsSinceWarn = 0;
    warnData.lastLevel = currentLevel;
    fs.writeFileSync(warnPath, JSON.stringify(warnData));

    if (DEBUG) {
      console.error(`[ContextMonitor:DEBUG] Firing ${currentLevel} — ${remaining}% raw, ~${used}% normalized used`);
    }

    const message = isCritical
      ? `[CONTEXT CRITICAL] ~${used}% context used (${remaining}% remaining).\n` +
        'Context is nearly exhausted. Inform the user that context is low.\n' +
        'Ask whether to compact the session (/compact) or continue with reduced capacity.\n' +
        'Do NOT autonomously write handoff files or state files unless the user asks.'
      : `[CONTEXT WARNING] ~${used}% context used (${remaining}% remaining).\n` +
        'Avoid starting new exploratory work. Prefer completing the current task rather than expanding scope.\n' +
        'If the user\'s goal isn\'t met yet, prioritize finishing over adding new work.';

    process.stdout.write(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'PostToolUse',
        additionalContext: message
      }
    }));
  } catch (e) {
    if (DEBUG) console.error('[ContextMonitor:DEBUG] Error:', e.message);
    process.exit(0);
  }
});
