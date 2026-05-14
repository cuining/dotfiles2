#!/bin/bash
# setup.d/dotfiles.sh — 目录骨架、stow 部署、tmux/nvim 插件

# ─── 目录骨架 ───
_echo "creating directory skeleton"
ensure_dir "$MYHOME/.config"
ensure_dir "$MYHOME/.local"
ensure_dir "$MYHOME/.local/bin"
ensure_dir "$MYHOME/.local/docs"
ensure_dir "$MYHOME/.local/cache"
ensure_dir "$MYHOME/.local/lib"
ensure_dir "$MYHOME/.local/share"
ensure_dir "$MYHOME/.local/src"
ensure_dir "$MYHOME/.local/state"
ensure_dir "$MYHOME/.local/state/zsh"
_ok "目录骨架已创建"

# ─── Dotfiles clone + stow ───
_echo "setting up dotfiles"
if [[ ! -d "$DOTFILES_DIR" ]]; then
  git clone git@github.com:cuining/dotfiles.git "$DOTFILES_DIR"
fi
cd "$DOTFILES_DIR" &&
  stow bin fun git gpg ssh tmux neovim zsh -t "$MYHOME"
_ok "dotfiles stow 完成"

# ─── ZDOTDIR ───
_echo "setting up ZDOTDIR"
if [[ "$OS" == "macos" ]]; then
  ZSHENV_FILE="$MYHOME/.zshenv"
  if ! grep -q 'ZDOTDIR' "$ZSHENV_FILE" 2>/dev/null; then
    echo 'export ZDOTDIR="$HOME"/.config/zsh' >> "$ZSHENV_FILE"
  fi
else
  if ! grep -q 'ZDOTDIR' /etc/zsh/zshenv 2>/dev/null; then
    echo 'export ZDOTDIR="$HOME"/.config/zsh' >> /etc/zsh/zshenv
  fi
fi
_ok "ZDOTDIR 已配置"

# ─── Tmux 插件 ───
_echo "setting up tmux plugins"
TPM_DIR="$MYHOME/.config/tmux/plugins/tpm"
if [[ ! -d "$TPM_DIR" ]]; then
  ensure_dir "$MYHOME/.config/tmux/plugins"
  git clone --depth=1 https://github.com/tmux-plugins/tpm "$TPM_DIR"
fi
"$TPM_DIR/scripts/install_plugins.sh"

THUMBS_DIR="$MYHOME/.config/tmux/plugins/tmux-thumbs"
if [[ -d "$THUMBS_DIR" ]]; then
  cd "$THUMBS_DIR" &&
    expect -c "spawn ./tmux-thumbs-install.sh; send \"\r1\r\"; expect complete" 1>/dev/null
fi
_ok "tmux 插件就绪"

# ─── Neovim 插件 ───
_echo "setting up neovim plugins"
LAZY_DIR="$MYHOME/.local/share/nvim/lazy"
if [[ ! -d "$LAZY_DIR" ]]; then
  ensure_dir "$MYHOME/.local/share/nvim"
  git clone --filter=blob:none --single-branch https://github.com/folke/lazy.nvim.git "$LAZY_DIR"
fi
nvim --headless "+Lazy! sync" +qa 2>/dev/null
nvim --headless "+MasonInstallAll" +qa 2>/dev/null
_ok "neovim 插件就绪"

# ─── Clipmenu (Linux only) ───
if [[ "$OS" == "linux" ]]; then
  _echo "building clipmenu"
  if ! installed clipmenu; then
    CLIP_DIR="$MYHOME/.local/src/clipmenu"
    git clone --recurse-submodules git@github.com:xero/clipmenu.git "$CLIP_DIR" &&
      cd "$CLIP_DIR/clipnotify" &&
      make install && cd .. && make install
    systemctl --user daemon-reload 2>/dev/null
    systemctl --user restart clipmenud.service 2>/dev/null
  fi
  _ok "clipmenu 就绪"
fi
