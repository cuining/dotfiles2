#!/bin/bash
# setup.d/ascii-art.sh — figlet-fonts, tdfgo

# ─── figlet-fonts ───
_echo "setting up figlet fonts"
if [[ "$OS" == "macos" ]]; then
  FIGLET_DIR="$(brew --prefix)/share/figlet"
else
  FIGLET_DIR="/usr/share/figlet"
fi

if [[ -d "$FIGLET_DIR/.git" ]]; then
  cd "$FIGLET_DIR" && git pull --ff-only 2>/dev/null
else
  sudo rm -rf "$FIGLET_DIR"
  sudo git clone --depth=1 https://github.com/xero/figlet-fonts.git "$FIGLET_DIR"
fi
_ok "figlet-fonts 已安装"

# ─── tdfgo ───
_echo "setting up tdfgo"
TDFGO_DIR="$MYHOME/.local/src/tdfgo"
if [[ ! -f "$MYHOME/.local/bin/tdfgo" ]]; then
  if [[ ! -d "$TDFGO_DIR" ]]; then
    git clone --depth=1 https://github.com/digitallyserviced/tdfgo.git "$TDFGO_DIR"
  fi
  cd "$TDFGO_DIR" &&
    GOPATH="$GOPATH" go build &&
    mv ./tdfgo "$MYHOME/.local/bin/tdfgo" &&
    chmod +x "$MYHOME/.local/bin/tdfgo" &&
    ensure_dir "$MYHOME/.config/tdfgo" &&
    [[ -d ./fonts ]] && mv ./fonts "$MYHOME/.config/tdfgo/fonts"
fi
_ok "tdfgo 已安装"
