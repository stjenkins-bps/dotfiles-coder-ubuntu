# dotfiles-coder-ubuntu

Reusable dotfiles and config for my Coder Ubuntu workspace environment.

## Layout
- `home/` – files that live directly in `$HOME` (e.g. `.zshrc`, `.gitconfig`, `.p10k.zsh`, `.ssh/config`, `.pi/...`).
- `config/` – subdirectories that map to `$HOME/.config` (e.g. `nvim`, `lsd`).
- `os-requirements.txt` – OS-managed packages and tools expected by this setup.

## Usage
Clone this repo, `cd` into it and run:

```bash
bash install.sh
```

This will:
- install portable tools (AKS CLI, Coder CLI, Helm, Herdr, talosctl, NVM + GitHub Copilot CLI, pi-coding-agent, qmd, zsh plugins),
- install npm global packages into `~/.npm-global` using per-command `npm --prefix` installs,
- install Hack Nerd Font into your user font directory for terminal/icons, and
- manage the tracked dotfiles into your `$HOME` and `~/.config` with GNU Stow, including Pi agent settings under `~/.pi`.

Install the packages in `os-requirements.txt` with the system package manager first. This includes `stow`, which `install.sh` uses to link the tracked dotfiles. Portable binaries are installed in `~/.local/bin` without `sudo`.

## Pi agent
Tracked Pi config in `home/.pi/` currently includes:
- `~/.pi/agent/settings.json`
  - default provider/model
  - installed Pi packages: `pi-web-access`, `pi-subagents`, `pi-memory`, `@sting8k/pi-vcc`
- `~/.pi/agent/pi-vcc-config.json`
- `~/.pi/web-search.json`

The installer also bootstraps `qmd` for `pi-memory` so keyword/semantic/deep search is available right away by:
- installing `@tobilu/qmd` globally
- creating the `pi-memory` qmd collection for `~/.pi/agent/memory`
- prebuilding initial embeddings