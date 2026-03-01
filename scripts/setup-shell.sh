#!/usr/bin/env bash
set -euo pipefail

# Shell Environment Setup
# Installs zsh, Oh My Zsh, Spaceship theme, nvm, Nerd Font
# Configures .zshrc with all sources and PATH entries

echo "=== Shell Environment Setup ==="
echo ""

# ---------- 1. Platform detection ----------

OS="$(uname -s)"
case "$OS" in
    Darwin) PLATFORM="mac" ;;
    Linux)  PLATFORM="linux" ;;
    *)      echo "Unsupported platform: $OS"; exit 1 ;;
esac

# ---------- Helper: ensure_block ----------
# Appends a block to a file if the marker comment is not already present.
# Usage: ensure_block <file> <marker> <block>
ensure_block() {
    local file="$1"
    local marker="$2"
    local block="$3"
    if ! grep -qF "$marker" "$file" 2>/dev/null; then
        printf '\n%s\n%s\n' "$marker" "$block" >> "$file"
        echo "  Added: $marker"
    else
        echo "  Already present: $marker"
    fi
}

# ---------- 2. zsh ----------

echo "--- zsh ---"
if [[ "$PLATFORM" == "mac" ]]; then
    echo "zsh already default on macOS"
else
    if ! dpkg -s zsh &>/dev/null; then
        echo "Installing zsh..."
        sudo apt-get install -y -qq zsh
    else
        echo "zsh already installed"
    fi
    if [[ "$(basename "$SHELL")" != "zsh" ]]; then
        echo "Setting zsh as default shell..."
        if ! chsh -s "$(command -v zsh)" 2>/dev/null; then
            echo "WARNING: Could not change default shell to zsh."
            echo "  Run manually: chsh -s \$(command -v zsh)"
        else
            echo "Default shell changed to zsh (takes effect on next login)"
        fi
    else
        echo "zsh already set as default shell"
    fi
fi

# ---------- 3. Oh My Zsh ----------

echo ""
echo "--- Oh My Zsh ---"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo "Oh My Zsh installed"
else
    echo "Oh My Zsh already installed"
fi

# ---------- 4. Spaceship theme ----------

echo ""
echo "--- Spaceship theme ---"
SPACESHIP_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship-prompt"
if [[ ! -d "$SPACESHIP_DIR" ]]; then
    echo "Installing Spaceship theme..."
    git clone --depth=1 https://github.com/spaceship-prompt/spaceship-prompt.git "$SPACESHIP_DIR"
    ln -sf "$SPACESHIP_DIR/spaceship.zsh-theme" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship.zsh-theme"
    echo "Spaceship theme installed"
else
    echo "Spaceship theme already installed"
    # Ensure symlink exists even if dir was already cloned
    ln -sf "$SPACESHIP_DIR/spaceship.zsh-theme" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/spaceship.zsh-theme"
fi

# ---------- 5. nvm ----------

echo ""
echo "--- nvm ---"
if [[ ! -d "$HOME/.nvm" ]]; then
    echo "Installing nvm..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | PROFILE=/dev/null bash
    echo "nvm installed"
else
    echo "nvm already installed"
fi

# ---------- 6. JetBrainsMono Nerd Font ----------

echo ""
echo "--- JetBrainsMono Nerd Font ---"
if [[ "$PLATFORM" == "mac" ]]; then
    if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null 2>&1; then
        echo "JetBrainsMono Nerd Font already installed"
    else
        echo "Installing JetBrainsMono Nerd Font..."
        brew install --cask font-jetbrains-mono-nerd-font
        echo "JetBrainsMono Nerd Font installed"
    fi
else
    FONT_DIR="$HOME/.local/share/fonts"
    if ls "$FONT_DIR"/JetBrainsMonoNerdFont*.ttf &>/dev/null 2>&1; then
        echo "JetBrainsMono Nerd Font already installed"
    else
        echo "Installing JetBrainsMono Nerd Font..."
        for dep in unzip fontconfig; do
            if ! dpkg -s "$dep" &>/dev/null; then
                sudo apt-get install -y -qq "$dep"
            fi
        done
        FONT_VERSION="3.3.0"
        FONT_ZIP="/tmp/JetBrainsMono-nerd-font.zip"
        curl -fsSL -o "$FONT_ZIP" \
            "https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/JetBrainsMono.zip"
        mkdir -p "$FONT_DIR"
        unzip -o "$FONT_ZIP" -d "$FONT_DIR" '*.ttf'
        rm -f "$FONT_ZIP"
        fc-cache -f
        echo "JetBrainsMono Nerd Font installed (Linux)"
    fi
    # Copy fonts to Windows if running under WSL
    if [[ -d "/mnt/c" ]]; then
        WIN_USER="$(cmd.exe /C "echo %USERNAME%" 2>/dev/null | tr -d '\r')"
        if [[ -n "$WIN_USER" ]]; then
            WIN_FONT_DIR="/mnt/c/Users/${WIN_USER}/AppData/Local/Microsoft/Windows/Fonts"
            if [[ ! -f "$WIN_FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]]; then
                echo "Copying fonts to Windows..."
                mkdir -p "$WIN_FONT_DIR"
                cp "$FONT_DIR"/JetBrainsMonoNerdFont*.ttf "$WIN_FONT_DIR/" 2>/dev/null || true
                echo "Fonts copied to $WIN_FONT_DIR"
                echo "Set 'JetBrainsMono Nerd Font' in Windows Terminal → Settings → Profile → Appearance → Font"
            else
                echo "Fonts already present in Windows"
            fi
        else
            echo "WARNING: Could not detect Windows username. Install fonts manually on Windows."
        fi
    fi
fi

# ---------- 7. Configure .zshrc ----------

echo ""
echo "--- Configuring .zshrc ---"

ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

# Oh My Zsh base config
ensure_block "$ZSHRC" "# >>> oh-my-zsh config >>>" \
'export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="spaceship"
plugins=(git)
source "$ZSH/oh-my-zsh.sh"
# <<< oh-my-zsh config <<<'

# nvm source
ensure_block "$ZSHRC" "# >>> nvm config >>>" \
'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
# <<< nvm config <<<'

# pnpm PATH (platform-aware)
if [[ "$PLATFORM" == "mac" ]]; then
    PNPM_HOME_VAL='$HOME/Library/pnpm'
else
    PNPM_HOME_VAL='$HOME/.local/share/pnpm'
fi
ensure_block "$ZSHRC" "# >>> pnpm config >>>" \
"export PNPM_HOME=\"${PNPM_HOME_VAL}\"
case \":\$PATH:\" in
  *\":\$PNPM_HOME:\"*) ;;
  *) export PATH=\"\$PNPM_HOME:\$PATH\" ;;
esac
# <<< pnpm config <<<"

# ~/.local/bin PATH
ensure_block "$ZSHRC" "# >>> local-bin path >>>" \
'export PATH="$HOME/.local/bin:$PATH"
# <<< local-bin path <<<'

# ---------- 8. Summary ----------

echo ""
echo "=== Shell Environment Setup Complete ==="
echo ""
echo "Installed:"
echo "  - zsh (default shell)"
echo "  - Oh My Zsh"
echo "  - Spaceship theme"
echo "  - nvm (Node Version Manager)"
echo "  - JetBrainsMono Nerd Font"
echo ""
echo "Configured in ~/.zshrc:"
echo "  - Oh My Zsh + Spaceship theme"
echo "  - nvm source"
echo "  - pnpm PATH"
echo "  - ~/.local/bin PATH"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. Install Node LTS:  nvm install --lts"
echo "  3. Enable pnpm:       corepack enable pnpm"
echo "  4. Set terminal font to 'JetBrainsMono Nerd Font'"
