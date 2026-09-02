#!/usr/bin/env bash
set -euo pipefail

# Install portable tools and manage dotfiles from this repo with GNU Stow
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine which user/home to configure (supports running via sudo)
if [[ -n "${SUDO_USER-}" && "${SUDO_USER}" != "root" ]]; then
  TARGET_USER="$SUDO_USER"
  TARGET_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6 || echo "/home/$SUDO_USER")"
else
  TARGET_USER="${USER:-$LOGNAME}"
  TARGET_HOME="${HOME:-/home/$TARGET_USER}"
fi

install_tools_and_shell() {
  local user_bin="$TARGET_HOME/.local/bin"
  local npm_global="$TARGET_HOME/.npm-global"
  mkdir -p "$user_bin" "$npm_global/bin"
  export PATH="$npm_global/bin:$user_bin:$PATH"

  echo "==> Installing NVM, Node, and GitHub Copilot CLI (if needed)..."
  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    if [[ -n "${NVM_DIR:-}" && -s "$NVM_DIR/nvm.sh" ]]; then
      . "$NVM_DIR/nvm.sh"
    elif [[ -s "$TARGET_HOME/.nvm/nvm.sh" ]]; then
      export NVM_DIR="$TARGET_HOME/.nvm"
      . "$NVM_DIR/nvm.sh"
    elif [[ -s /usr/local/nvm/nvm.sh ]]; then
      export NVM_DIR=/usr/local/nvm
      . "$NVM_DIR/nvm.sh"
    else
      export NVM_DIR="$TARGET_HOME/.nvm"
      curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh \
        | PROFILE=/dev/null NVM_DIR="$NVM_DIR" bash
      . "$NVM_DIR/nvm.sh"
    fi
  fi

  if command -v npm >/dev/null 2>&1; then
    echo "==> Using npm prefix $npm_global for user-scoped global installs..."

    if ! command -v copilot >/dev/null 2>&1; then
      echo "==> Installing GitHub Copilot CLI for the current user..."
      if ! npm --prefix "$npm_global" install -g @github/copilot; then
        echo "WARN: GitHub Copilot CLI installation failed." >&2
      fi
    fi

    if ! npm --prefix "$npm_global" list -g --depth=0 @earendil-works/pi-coding-agent >/dev/null 2>&1; then
      echo "==> Installing pi-coding-agent for the current user..."
      if ! npm --prefix "$npm_global" install -g @earendil-works/pi-coding-agent; then
        echo "WARN: pi-coding-agent installation failed." >&2
      fi
    fi

    if ! npm --prefix "$npm_global" list -g --depth=0 @tobilu/qmd >/dev/null 2>&1; then
      echo "==> Installing qmd for pi-memory search..."
      if ! npm --prefix "$npm_global" install -g @tobilu/qmd; then
        echo "WARN: qmd installation failed." >&2
      fi
    fi

    if command -v qmd >/dev/null 2>&1; then
      local pi_memory_dir="$TARGET_HOME/.pi/agent/memory"
      mkdir -p "$pi_memory_dir/daily" "$pi_memory_dir/recovery"
      touch "$pi_memory_dir/MEMORY.md" "$pi_memory_dir/SCRATCHPAD.md"

      echo "==> Initializing qmd collection for pi-memory..."
      qmd collection add "$pi_memory_dir" --name pi-memory >/dev/null 2>&1 || true
      qmd context add /daily "Daily append-only work logs organized by date" -c pi-memory >/dev/null 2>&1 || true
      qmd context add / "Curated long-term memory: decisions, preferences, facts, lessons" -c pi-memory >/dev/null 2>&1 || true

      echo "==> Building initial pi-memory embeddings (may take a minute on first run)..."
      qmd embed -c pi-memory >/dev/null 2>&1 || true
    fi
  fi

  echo "==> Installing Coder CLI..."
  if ! command -v coder >/dev/null 2>&1; then
    if ! curl -L https://coder.com/install.sh \
      | sh -s -- --method standalone --prefix "$TARGET_HOME/.local"; then
      echo "WARN: Coder CLI installation failed." >&2
    fi
  fi

  echo "==> Installing Herdr..."
  if ! command -v herdr >/dev/null 2>&1; then
    if ! curl -fsSL https://herdr.dev/install.sh \
      | HERDR_INSTALL_DIR="$user_bin" sh; then
      echo "WARN: Herdr installation failed." >&2
    fi
  fi

  echo "==> Installing Helm..."
  if ! command -v helm >/dev/null 2>&1; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
      | HELM_INSTALL_DIR="$user_bin" USE_SUDO=false bash || true
  fi

  echo "==> Installing Azure AKS CLI..."
  if command -v az >/dev/null 2>&1 \
    && { ! command -v kubectl >/dev/null 2>&1 || ! command -v kubelogin >/dev/null 2>&1; }; then
    az aks install-cli \
      --install-location "$user_bin/kubectl" \
      --kubelogin-install-location "$user_bin/kubelogin" || true
  fi

  echo "==> Installing talosctl..."
  if ! command -v talosctl >/dev/null 2>&1; then
    curl -sL https://talos.dev/install | INSTALLPATH="$user_bin" sh || true
  fi

  echo "==> Installing zsh plugins (powerlevel10k, zsh-vi-mode)..."
  if [[ ! -d "$TARGET_HOME/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$TARGET_HOME/powerlevel10k" || true
  fi
  if [[ ! -d "$TARGET_HOME/.zsh-vi-mode" ]]; then
    git clone https://github.com/jeffreytse/zsh-vi-mode.git "$TARGET_HOME/.zsh-vi-mode" || true
  fi

  if command -v zsh >/dev/null 2>&1; then
    local zsh_path
    zsh_path="$(command -v zsh)"
    echo -n "Set default shell to $zsh_path for user $TARGET_USER? [y/N]: "
    read -r ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      echo "==> Changing default shell to $zsh_path for $TARGET_USER (you may be prompted for your password)..."
      local shell_changed=0
      if chsh -s "$zsh_path" "$TARGET_USER" 2>/dev/null; then
        shell_changed=1
      elif command -v sudo >/dev/null 2>&1 && sudo chsh -s "$zsh_path" "$TARGET_USER"; then
        shell_changed=1
      else
        echo "WARN: Failed to change default shell; run 'chsh -s $zsh_path $TARGET_USER' (or with sudo) manually." >&2
      fi
      echo "Starting a new zsh login shell..."
      exec "$zsh_path" -l
    else
      echo "Skipping default shell change; you can run 'chsh -s $zsh_path' later."
    fi
  fi
}

install_fonts() {
  echo "==> Installing Hack Nerd Font (nerd font for terminal + icons)..."
  local font_dir="$TARGET_HOME/.local/share/fonts"
  mkdir -p "$font_dir"
  if ! ls "$font_dir"/*Hack*Nerd*Font* >/dev/null 2>&1; then
    local tmpdir
    tmpdir="$(mktemp -d)"
    if curl -fLo "$tmpdir/Hack.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip; then
      unzip -o "$tmpdir/Hack.zip" -d "$font_dir" >/dev/null 2>&1 || true
    fi
    rm -rf "$tmpdir"
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f "$font_dir" || true
    fi
  fi
}

require_stow() {
  if ! command -v stow >/dev/null 2>&1; then
    echo "ERROR: GNU Stow is required to link dotfiles from this repo." >&2
    echo "Install packages from os-requirements.txt first (including stow), then rerun install.sh." >&2
    exit 1
  fi
}

stow_package() {
  local package_dir="$1" target_dir="$2"
  shift 2
  echo "Stowing $package_dir into $target_dir"
  mkdir -p "$target_dir"
  stow --dir="$DOTFILES_DIR" --target="$target_dir" --restow "$@" "$package_dir"
}

link() {
  local src="$1" dst="$2"
  echo "Linking $dst -> $src"
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
}

require_stow

# Stow tracked home dotfiles except optional/special-case entries
stow_package home "$TARGET_HOME" --ignore='^\.gitconfig$|^\.ssh($|/)|^\.zshrc\.bak\..*$'

# Optional Git config
if [[ -f "$DOTFILES_DIR/home/.gitconfig" ]]; then
  echo -n "Configure global Git for this user from this repo? [y/N]: "
  read -r ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    echo -n "  Git user.name  (e.g. jdoe): "
    read -r git_name
    echo -n "  Git user.email (e.g. jdoe@example.com): "
    read -r git_email

    tmp_gitcfg="$(mktemp)"
    cp "$DOTFILES_DIR/home/.gitconfig" "$tmp_gitcfg"

    git config -f "$tmp_gitcfg" user.name "$git_name"
    git config -f "$tmp_gitcfg" user.email "$git_email"

    mkdir -p "$TARGET_HOME"
    cp "$tmp_gitcfg" "$TARGET_HOME/.gitconfig"
    rm -f "$tmp_gitcfg"
  else
    echo "Skipping Git config; existing ~/.gitconfig left untouched."
  fi
fi

# SSH config (GitHub-only config, no keys)
if [[ -f "$DOTFILES_DIR/home/.ssh/config" ]]; then
  echo -n "Apply SSH config for GitHub (~/.ssh/config) from this repo? [y/N]: "
  read -r ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    link "$DOTFILES_DIR/home/.ssh/config" "$TARGET_HOME/.ssh/config"
  else
    echo "Skipping SSH config; existing ~/.ssh/config left untouched."
  fi
fi

# ~/.config subdirectories
if [[ -d "$DOTFILES_DIR/config" ]]; then
  stow_package config "$TARGET_HOME/.config"
fi

echo "Done. Your dotfiles are now linked into $HOME from $DOTFILES_DIR using GNU Stow."

install_tools_and_shell
install_fonts
