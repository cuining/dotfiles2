#!/bin/bash
# setup.d/common.sh — 辅助函数和共享变量

# 平台与架构
PLATFORM="$(uname -s)"
ARCH="$(uname -m)"

case "$PLATFORM" in
  Darwin) OS="macos" ;;
  Linux)  OS="linux" ;;
  *)      _err "不支持的平台: $PLATFORM"; exit 1 ;;
esac

case "$ARCH" in
  arm64|aarch64) ARCH_NORMALIZED="arm64" ;;
  x86_64|amd64)  ARCH_NORMALIZED="amd64" ;;
  *)             _err "不支持的架构: $ARCH"; exit 1 ;;
esac

# 用户变量
if [[ "$OS" == "linux" ]]; then
  ME="${ME:-$(whoami)}"
  MYHOME="${MYHOME:-$HOME}"
else
  ME="$(whoami)"
  MYHOME="$HOME"
fi

# 目录变量
DOTFILES_DIR="${DOTFILES_DIR:-$MYHOME/.local/src/dotfiles}"
CARGO_HOME="$MYHOME/.local/lib/cargo"
RUSTUP_HOME="$MYHOME/.local/lib/rustup"
GOPATH="$MYHOME/.local/lib/go"
NVM_DIR="$MYHOME/.local/lib/nvm"

# 输出辅助
function _echo() {
  printf "\n╓───── %s \n╙────────────────────────────────────── ─ ─ \n" "$1"
}

function _ok() {
  printf "  \033[32m✓\033[0m %s\n" "$1"
}

function _warn() {
  printf "  \033[33m!\033[0m %s\n" "$1"
}

function _err() {
  printf "  \033[31m✗\033[0m %s\n" "$1" >&2
}

# 工具函数
function installed() {
  command -v "$1" &>/dev/null
}

function ensure_dir() {
  mkdir -p "$1"
  [[ -n "${2:-}" ]] && chown "$2" "$1"
}
