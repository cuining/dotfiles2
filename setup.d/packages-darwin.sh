#!/bin/bash
# setup.d/packages-darwin.sh — macOS Homebrew 包安装

_echo "checking xcode command line tools"
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  _warn "安装 Xcode CLT 后重新运行此脚本"
  exit 1
fi
_ok "xcode CLT 已安装"

_echo "checking homebrew"
if ! installed brew; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
_ok "homebrew 就绪"

_echo "installing homebrew packages"
BREW_FORMULAE=(
  # 核心
  coreutils
  findutils
  gnu-sed
  gawk
  curl
  git
  stow

  # shell
  zsh-syntax-highlighting
  starship

  # 编辑器
  neovim

  # 终端
  tmux
  mosh

  # 搜索
  fzf
  ripgrep
  the_silver_searcher
  tree

  # 语言
  go
  lua
  luajit
  luarocks
  python3

  # 网络
  openconnect
  nmap
  socat
  proxychains-ng

  # 构建工具
  cmake
  ninja
  automake
  autoconf
  libtool
  pkg-config

  # 工具
  jq
  htop
  shellcheck
  expect

  # 美化
  figlet
  toilet
  cmatrix
)

brew install "${BREW_FORMULAE[@]}"
_ok "homebrew 包安装完成"
