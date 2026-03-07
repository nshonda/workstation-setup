---
name: clipboard
description: Copy commands to system clipboard for pasting into other terminals (e.g., SSH sessions). Auto-triggers when suggesting multi-line or multiple commands for the user to run manually. Also invocable via /clip.
---

# Clipboard

Copy commands directly to the system clipboard so the user can paste them cleanly into another terminal (SSH sessions, other shells, etc).

## When to Use

- **Auto-trigger:** When you are about to suggest 2+ commands or any multi-line command that the user needs to run outside of Claude Code (not via the Bash tool). Instead of just printing the commands, copy them to clipboard.
- **On demand:** User invokes `/clip` — copy the most recent command(s) from the conversation to clipboard.

## How It Works

1. Detect the clipboard command for the current platform:

```
if command -v pbcopy &>/dev/null; then
  # macOS
  CLIP_CMD="pbcopy"
elif command -v clip.exe &>/dev/null; then
  # WSL (Windows clipboard)
  CLIP_CMD="clip.exe"
elif command -v wl-copy &>/dev/null; then
  # Linux Wayland
  CLIP_CMD="wl-copy"
elif command -v xclip &>/dev/null; then
  # Linux X11
  CLIP_CMD="xclip -selection clipboard"
elif command -v xsel &>/dev/null; then
  # Linux X11 fallback
  CLIP_CMD="xsel --clipboard --input"
else
  echo "No clipboard tool found" >&2
  exit 1
fi
```

2. Pipe the commands into the clipboard tool using the Bash tool:

```bash
echo '<commands here>' | $CLIP_CMD
```

3. After copying, tell the user briefly: "Copied to clipboard" with a one-line summary of what was copied. Do NOT repeat the full command block — the user already saw it or can paste it.

## Rules

- **Newline-separated:** When copying multiple commands, separate them with newlines so they paste as a clean block. Do not join with `&&` or `;` unless the user asks.
- **No extra formatting:** Do not include markdown fences, comments, or prompts (`$`) in what gets copied. Only the raw commands.
- **Still show the commands:** Display the commands in your response (in a code block) so the user can see what was copied. Then copy to clipboard.
- **Single commands:** For simple one-liners, just print them normally — no need to auto-copy. Only auto-trigger for multi-line or multiple commands.
- **Platform detection:** Always detect the platform at runtime. Do not hardcode `pbcopy`.
