#!/usr/bin/env bash
set -euo pipefail

echo "--- SSH setup ---"

SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate keys (idempotent)
generate_key() {
    local name="$1" comment="$2" type="$3"
    local path="$SSH_DIR/$name"
    if [ -f "$path" ]; then
        echo "Key $name already exists, skipping"
    else
        echo "Generating $name ($comment)..."
        ssh-keygen -t "$type" ${type:+$([ "$type" = "rsa" ] && echo "-b 4096")} -f "$path" -N "" -C "$comment"
    fi
}

generate_key id_rsa_mac       "personal GitHub"      rsa
generate_key id_rsa_basis_mac "work GitHub (Basis)"  rsa

# Write ~/.ssh/config (portable, no machine-specific paths)
cat > "$SSH_DIR/config" <<'EOF'
# Personal GitHub Account
Host github.com
    HostName github.com
    User git
    IdentitiesOnly yes
    # Key path specified in config.local (machine-specific)

# Basis Work GitHub Account
Host github.com-natalihonda-basis
    HostName github.com
    User git
    IdentitiesOnly yes
    # Key path specified in config.local (machine-specific)

# Pantheon
Host codeserver.dev.*.drush.in
    Port 2222
    IdentitiesOnly yes
    IdentityFile ~/.ssh/id_rsa_oneoff

# Common SSH settings
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3
    AddKeysToAgent yes

# Include machine-specific key mappings and server entries
Include ~/.ssh/config.local
EOF
chmod 600 "$SSH_DIR/config"

# Write ~/.ssh/config.local (machine-specific)
if [ ! -f "$SSH_DIR/config.local" ]; then
    if [ "$(uname -s)" = "Darwin" ]; then
        cat > "$SSH_DIR/config.local" <<'EOF'
# Personal GitHub - Mac key
Host github.com
    IdentityFile ~/.ssh/id_rsa_mac
    UseKeychain yes

# Basis GitHub - Mac key
Host github.com-natalihonda-basis
    IdentityFile ~/.ssh/id_rsa_basis_mac
    UseKeychain yes
EOF
    else
        cat > "$SSH_DIR/config.local" <<'EOF'
# Personal GitHub
Host github.com
    IdentityFile ~/.ssh/id_rsa_mac

# Basis GitHub
Host github.com-natalihonda-basis
    IdentityFile ~/.ssh/id_rsa_basis_mac
EOF
    fi
    chmod 600 "$SSH_DIR/config.local"
fi

# Add keys to ssh-agent
eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
for key in id_rsa_mac id_rsa_basis_mac; do
    KEY_PATH="$SSH_DIR/$key"
    [ -f "$KEY_PATH" ] || continue
    if [ "$(uname -s)" = "Darwin" ]; then
        ssh-add --apple-use-keychain "$KEY_PATH" 2>/dev/null || ssh-add "$KEY_PATH"
    else
        ssh-add "$KEY_PATH" 2>/dev/null || true
    fi
done

echo ""
echo "--- Public keys ---"
echo ""
for key in id_rsa_mac id_rsa_basis_mac; do
    [ -f "$SSH_DIR/${key}.pub" ] || continue
    echo "== $key =="
    cat "$SSH_DIR/${key}.pub"
    echo ""
done
echo "Add personal key: https://github.com/settings/ssh/new"
echo "Add work key:     https://github.com/settings/ssh/new (work account)"
echo ""
echo "--- SSH setup done ---"
