#!/usr/bin/env bash
# tmux-session-kit uninstaller
set -euo pipefail

BIN_DIR="$HOME/.local/bin"
TMUX_CONF="$HOME/.tmux.conf"
CONFIG_DIR="$HOME/.config/tmux-session-kit"
MARK_BEGIN="# >>> tmux-session-kit >>>"
MARK_END="# <<< tmux-session-kit <<<"

rm -f "$BIN_DIR/tmux-sessions" "$BIN_DIR/dev-launcher" "$BIN_DIR/ts"
echo "✓ Removed executables"

if [[ -f "$TMUX_CONF" ]] && grep -qF "$MARK_BEGIN" "$TMUX_CONF"; then
  sed -i "/^$MARK_BEGIN\$/,/^$MARK_END\$/d" "$TMUX_CONF"
  echo "✓ Removed tmux.conf binding"
  if tmux info >/dev/null 2>&1; then
    tmux unbind-key -n M-q 2>/dev/null || true
    echo "✓ Unbound M-q on the running tmux server"
  fi
fi

rm -rf "$CONFIG_DIR"
echo "✓ Removed config directory"

echo "Done."
