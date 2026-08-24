#!/usr/bin/env bash
set -euo pipefail

# Install portable tools and symlink dotfiles from this repo into $HOME
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
  mkdir -p "$user_bin"
  export PATH="$user_bin:$PATH"

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

  if command -v npm >/dev/null 2>&1 && ! command -v copilot >/dev/null 2>&1; then
    echo "==> Installing GitHub Copilot CLI for the current user..."
    if ! npm install --global --prefix "$TARGET_HOME/.local" @github/copilot; then
      echo "WARN: GitHub Copilot CLI installation failed." >&2
    fi
  fi

  echo "==> Installing Coder CLI..."
  if ! command -v coder >/dev/null 2>&1; then
    if ! curl -L https://coder.com/install.sh \
      | sh -s -- --method standalone --prefix "$TARGET_HOME/.local"; then
      echo "WARN: Coder CLI installation failed." >&2
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

link() {
  local src="$1" dst="$2"
  echo "Linking $dst -> $src"
  mkdir -p "$(dirname "$dst")"
  ln -sfn "$src" "$dst"
}

# Top-level dotfiles
link "$DOTFILES_DIR/home/.zshrc" "$TARGET_HOME/.zshrc"

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

    link "$tmp_gitcfg" "$TARGET_HOME/.gitconfig"
  else
    echo "Skipping Git config; existing ~/.gitconfig left untouched."
  fi
fi

if [[ -f "$DOTFILES_DIR/home/.p10k.zsh" ]]; then
  link "$DOTFILES_DIR/home/.p10k.zsh" "$TARGET_HOME/.p10k.zsh"
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
for dir in nvim lsd; do
  if [[ -d "$DOTFILES_DIR/config/$dir" ]]; then
    link "$DOTFILES_DIR/config/$dir" "$TARGET_HOME/.config/$dir"
  fi
done

echo "Done. Your dotfiles are now linked into $HOME from $DOTFILES_DIR."

install_tools_and_shell
install_fonts
