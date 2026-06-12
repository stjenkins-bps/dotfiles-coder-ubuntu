#!/usr/bin/env bash
set -euo pipefail

# Simple helper for colored messages
log()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[ERR ]\033[0m %s\n' "$*"; }

# 1. Sanity check: must be run as root or via sudo
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    err "Please run this script as root, e.g.: sudo $0"
    exit 1
fi

# 2. Variables
GHOSTTY_DIR="/opt/ghostty"
ZIG_DIR="/opt/zig"
ZIG_DOWNLOAD_DIR="/tmp/zig-download"
GHOSTTY_REPO="https://github.com/ghostty-org/ghostty.git"

export DEBIAN_FRONTEND=noninteractive

log "Updating package metadata..."
apt-get update -y

log "Installing build dependencies (Ubuntu)..."
apt-get install -y \
    git \
    gcc \
    clang \
    pkg-config \
    meson \
    ninja-build \
    gettext \
    libglib2.0-dev \
    libgtk-4-dev \
    libadwaita-1-dev \
    libxkbcommon-dev \
    libcairo2-dev \
    libpango1.0-dev \
    libfontconfig-dev \
    libfreetype-dev \
    libpng-dev \
    libgirepository1.0-dev \
    blueprint-compiler \
    libwayland-dev \
    xwayland

# 3. Clone or update Ghostty
if [[ -d "$GHOSTTY_DIR/.git" ]]; then
    log "Found existing Ghostty repo in $GHOSTTY_DIR, pulling latest..."
    git -C "$GHOSTTY_DIR" fetch --all --tags
    git -C "$GHOSTTY_DIR" pull --ff-only
else
    log "Cloning Ghostty into $GHOSTTY_DIR..."
    git clone "$GHOSTTY_REPO" "$GHOSTTY_DIR"
fi

cd "$GHOSTTY_DIR"

# 4. Determine required Zig version from build.zig.zon
if [[ ! -f "build.zig.zon" ]]; then
    err "build.zig.zon not found in $GHOSTTY_DIR. Repo layout may have changed."
    exit 1
fi

MIN_ZIG_VERSION="$(grep -E 'minimum_zig_version' build.zig.zon | sed -E 's/.*"([^"]+)".*/\1/')"

if [[ -z "$MIN_ZIG_VERSION" ]]; then
    err "Unable to determine minimum_zig_version from build.zig.zon."
    exit 1
fi

log "Ghostty requires Zig version: $MIN_ZIG_VERSION"

# 5. Download and unpack Zig
mkdir -p "$ZIG_DOWNLOAD_DIR"
cd "$ZIG_DOWNLOAD_DIR"

ZIG_TAR="zig-linux-x86_64-$MIN_ZIG_VERSION.tar.xz"
ZIG_URL="https://ziglang.org/download/$MIN_ZIG_VERSION/$ZIG_TAR"

log "Downloading Zig from: $ZIG_URL"
if ! curl -fL -o "$ZIG_TAR" "$ZIG_URL"; then
    err "Failed to download Zig from $ZIG_URL"
    err "You may need to check the Zig download page and adjust this script."
    exit 1
fi

log "Extracting Zig..."
rm -rf "$ZIG_DIR"
mkdir -p "$ZIG_DIR"
tar -xf "$ZIG_TAR" -C "$ZIG_DIR" --strip-components=1

ZIG_BIN="$ZIG_DIR/zig"
if [[ ! -x "$ZIG_BIN" ]]; then
    err "Zig binary not found at $ZIG_BIN after extraction."
    exit 1
fi

log "Using Zig at: $ZIG_BIN"
"$ZIG_BIN" version

# 6. Build and install Ghostty
cd "$GHOSTTY_DIR"

log "Building and installing Ghostty to /usr (ReleaseFast)..."
"$ZIG_BIN" build -p /usr -Doptimize=ReleaseFast

log "Ghostty build finished. Checking installation..."
if command -v ghostty >/dev/null 2>&1; then
    log "Ghostty installed successfully: $(command -v ghostty)"
    ghostty --version || true
else
    warn "Ghostty binary not found in PATH, but the build completed."
    warn "Check /usr/bin/ghostty or the Zig build output for details."
fi

log "Done."
