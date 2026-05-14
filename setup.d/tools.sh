#!/bin/bash
# setup.d/tools.sh — 跨平台工具安装（rust, starship, neovim, mosh, nvm, python）

# ─── Rust ───
_echo "setting up rust"
if ! installed "$CARGO_HOME/bin/cargo"; then
  curl https://sh.rustup.rs -sSf | CARGO_HOME="$CARGO_HOME" RUSTUP_HOME="$RUSTUP_HOME" sh -s -- -y --default-toolchain stable --profile default
fi
export PATH="$CARGO_HOME/bin:$PATH"

CARGO_HOME="$CARGO_HOME" RUSTUP_HOME="$RUSTUP_HOME" cargo install cargo-quickinstall 2>/dev/null
CARGO_HOME="$CARGO_HOME" RUSTUP_HOME="$RUSTUP_HOME" cargo quickinstall lolcat stylua
_ok "rust 工具链就绪"

# ─── Starship (Linux only, macOS via brew) ───
if [[ "$OS" == "linux" ]]; then
  _echo "setting up starship"
  if [[ "$ARCH_NORMALIZED" == "arm64" ]]; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  else
    CARGO_HOME="$CARGO_HOME" RUSTUP_HOME="$RUSTUP_HOME" cargo quickinstall starship
  fi
  _ok "starship 已安装"
fi

# ─── Neovim ───
_echo "setting up neovim"
if [[ "$OS" == "linux" ]]; then
  if ! installed nvim; then
    git clone --depth=1 https://github.com/neovim/neovim.git -b stable "$MYHOME/.local/src/neovim" &&
      cd "$MYHOME/.local/src/neovim" &&
      CMAKE_BUILD_TYPE=RelWithDebInfo make &&
      sudo make install
    cd "$DOTFILES_DIR" 2>/dev/null || cd "$MYHOME"
  fi
  _ok "neovim 编译安装完成"
else
  _ok "neovim 已通过 brew 安装"
fi

# ─── Mosh ───
_echo "setting up mosh"
if [[ "$OS" == "linux" ]]; then
  if ! installed mosh-server; then
    git clone --depth=1 https://github.com/mobile-shell/mosh.git "$MYHOME/.local/src/mosh" &&
      cd "$MYHOME/.local/src/mosh" &&
      git fetch origin && git checkout mosh-1.4.0 &&
      ./autogen.sh &&
      ./configure &&
      make &&
      sudo make install
    cd "$DOTFILES_DIR" 2>/dev/null || cd "$MYHOME"
  fi
  _ok "mosh 编译安装完成"
else
  _ok "mosh 已通过 brew 安装"
fi

# ─── nvm + Node.js ───
_echo "setting up nvm and node"
if [[ ! -d "$NVM_DIR" ]]; then
  ensure_dir "$NVM_DIR"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | NVM_DIR="$NVM_DIR" PROFILE=/dev/null bash
fi
export NVM_DIR="$NVM_DIR"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

npm i -g \
  neovim \
  sofancy
_ok "nvm + node LTS 就绪"

# ─── Python pip ───
_echo "setting up python pip packages"
pip3 install --upgrade pip 2>/dev/null

PIP_PACKAGES=(
  cryptography
  docutils
  emoji-fzf
  greynoise
  "https://github.com/PaulSec/API-dnsdumpster.com/archive/master.zip"
  json-spec
  mycli
  neovim
  pgcli
  six
  urllib3
  wcwidth
)

pip3 install --no-warn-script-location "${PIP_PACKAGES[@]}"
_ok "python pip 包安装完成"
