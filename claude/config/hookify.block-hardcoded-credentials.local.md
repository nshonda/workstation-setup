---
name: block-hardcoded-credentials
enabled: true
event: file
action: block
conditions:
  - field: new_text
    operator: regex_match
    pattern: (?:API_KEY|SECRET_KEY|PRIVATE_KEY|api_key|secret_key|private_key)\s*=\s*['"][a-zA-Z0-9_\-]{16,}|sk-[a-zA-Z0-9]{20,}|AKIA[0-9A-Z]{16}|Bearer\s+[a-zA-Z0-9_\-\.]{20,}|password\s*=\s*['"][^'"]{8,}
---

**BLOCKED: Hardcoded credential detected in file**

Your global CLAUDE.md says credentials must be stored in the system credential store (macOS Keychain / gnome-keyring), never hardcoded.

What was detected looks like a hardcoded secret, API key, or password. To resolve this:
- Consider using environment variables via direnv (`.envrc`)
- Pull from the system credential store
- Reference via `$VARIABLE_NAME` instead of inline values
- If this is example/placeholder text, use obviously fake values like `your-api-key-here`
