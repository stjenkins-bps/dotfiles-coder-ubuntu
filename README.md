# dotfiles-coder-ubuntu

Reusable dotfiles and config for my Coder Ubuntu workspace environment.

## Layout
- `home/` – files that live directly in `$HOME` (e.g. `.zshrc`, `.gitconfig`, `.p10k.zsh`, `.ssh/config`).
- `config/` – subdirectories that map to `$HOME/.config` (e.g. `nvim`, `lsd`).
- `os-requirements.txt` – OS-managed packages and tools expected by this setup.

## Usage
Clone this repo, `cd` into it and run:

```bash
bash install.sh
```

This will:
- install portable tools (AKS CLI, Coder CLI, Helm, Herdr, talosctl, NVM + GitHub Copilot CLI, zsh plugins),
- install Hack Nerd Font into your user font directory for terminal/icons, and
- (re)symlink the tracked dotfiles into your `$HOME` and `~/.config` based on this repo's contents.

Install the packages in `os-requirements.txt` with the system package manager first. Portable binaries are installed in `~/.local/bin` without `sudo`.