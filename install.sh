#!/usr/bin/env bash
# Installs WezTerm and the shell PATH setup entirely under $HOME, so it all
# survives on a VM where only the home folder persists.
#
# Safe to run as many times as you like: anything already in place is left alone.
#
#   ./install.sh              install / repair everything
#   ./install.sh --force      re-extract WezTerm even if it is already installed
#
# Offline or blocked network: download the AppImage somewhere else, copy it to the
# VM, then either drop it in ~/Downloads or run
#   WEZTERM_APPIMAGE=/path/to/WezTerm-....AppImage ./install.sh
set -euo pipefail

WEZTERM_VERSION="${WEZTERM_VERSION:-20240203-110809-5046fc22}"
# sha256 of WezTerm-<version>-Ubuntu20.04.AppImage for the pinned version above.
# If you change WEZTERM_VERSION, the checksum is fetched from the release instead.
PINNED_SHA256="34010a07076d2272c4d4f94b5e0dae608a679599e8d729446323f88f956c60f0"

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPT="$HOME/.local/opt"
BIN="$HOME/.local/bin"
APPS="$HOME/.local/share/applications"
ICONS="$HOME/.local/share/icons/hicolor"
WEZ_DIR="$OPT/wezterm-$WEZTERM_VERSION"
ASSET="WezTerm-$WEZTERM_VERSION-Ubuntu20.04.AppImage"
URL="https://github.com/wezterm/wezterm/releases/download/$WEZTERM_VERSION/$ASSET"
MARK="# >>> dotfiles >>>"
MARK_END="# <<< dotfiles <<<"

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '    \033[32mok\033[0m %s\n' "$*"; }
warn() { printf '    \033[33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# Replace $1 with a symlink to $2. A real file/dir already there is moved aside, never deleted.
link() {
  local dest="$1" src="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    ok "$dest"
    return
  fi
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    local bak
    bak="$dest.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$bak"
    warn "moved existing $dest to $bak"
  fi
  ln -sfn "$src" "$dest"
  ok "$dest -> $src"
}

mkdir -p "$OPT" "$BIN" "$APPS" "$HOME/.config/shell"

# ---------------------------------------------------------------- WezTerm
say "WezTerm $WEZTERM_VERSION"
if [[ -x "$WEZ_DIR/usr/bin/wezterm" && $FORCE -eq 0 ]]; then
  ok "already installed in $WEZ_DIR"
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  appimage=""
  if [[ -n "${WEZTERM_APPIMAGE:-}" ]]; then
    [[ -f "$WEZTERM_APPIMAGE" ]] || die "WEZTERM_APPIMAGE=$WEZTERM_APPIMAGE does not exist"
    appimage="$WEZTERM_APPIMAGE"
  elif [[ -f "$HOME/Downloads/$ASSET" ]]; then
    appimage="$HOME/Downloads/$ASSET"
  fi

  if [[ -n "$appimage" ]]; then
    ok "using local file $appimage"
  else
    command -v curl >/dev/null || die "curl not found; download $ASSET manually and set WEZTERM_APPIMAGE"
    ok "downloading $URL"
    curl -fL --progress-bar -o "$tmp/$ASSET" "$URL" \
      || die "download failed. Get $ASSET another way, put it in ~/Downloads and re-run."
    appimage="$tmp/$ASSET"
  fi

  # Verify checksum
  expected=""
  if [[ "$WEZTERM_VERSION" == "20240203-110809-5046fc22" ]]; then
    expected="$PINNED_SHA256"
  else
    expected="$(curl -fsSL "$URL.sha256" 2>/dev/null | awk '{print $1}')" || true
  fi
  actual="$(sha256sum "$appimage" | awk '{print $1}')"
  if [[ -z "$expected" ]]; then
    warn "no checksum available for $WEZTERM_VERSION, skipping verification"
  elif [[ "$expected" != "$actual" ]]; then
    die "checksum mismatch for $appimage (expected $expected, got $actual)"
  else
    ok "sha256 verified"
  fi

  # Always extract instead of running the AppImage directly: no FUSE needed,
  # and it starts faster. The binaries find their bundled libs via $ORIGIN/../lib.
  cp "$appimage" "$tmp/wezterm.AppImage"
  chmod +x "$tmp/wezterm.AppImage"
  (cd "$tmp" && ./wezterm.AppImage --appimage-extract >/dev/null) \
    || die "extracting the AppImage failed"
  rm -rf "$WEZ_DIR"
  mv "$tmp/squashfs-root" "$WEZ_DIR"
  ok "extracted to $WEZ_DIR"

  # Clean up older versions
  for old in "$OPT"/wezterm-*; do
    if [[ "$old" != "$WEZ_DIR" && -d "$old" ]]; then
      rm -rf "$old"
      ok "removed old $old"
    fi
  done
fi

link "$OPT/wezterm" "$WEZ_DIR"
link "$BIN/wezterm" "$OPT/wezterm/usr/bin/wezterm"

# App menu entry + icons (absolute paths: .desktop files don't expand ~ or $HOME)
while IFS= read -r icon; do
  rel="${icon#"$OPT/wezterm/usr/share/icons/hicolor/"}"
  mkdir -p "$ICONS/$(dirname "$rel")"
  cp -f "$icon" "$ICONS/$rel"
done < <(find -L "$OPT/wezterm/usr/share/icons/hicolor" -type f -name 'org.wezfurlong.wezterm.*' 2>/dev/null)
# A hand-made wezterm.desktop from earlier would show up as a duplicate entry
if [[ -f "$APPS/wezterm.desktop" ]]; then
  mv "$APPS/wezterm.desktop" "$APPS/wezterm.desktop.bak.$(date +%Y%m%d%H%M%S)"
  warn "moved old $APPS/wezterm.desktop aside"
fi
cat > "$APPS/org.wezfurlong.wezterm.desktop" <<EOF
[Desktop Entry]
Name=WezTerm
Comment=Wez's Terminal Emulator
Keywords=shell;prompt;command;commandline;cmd;terminal;
Icon=org.wezfurlong.wezterm
StartupWMClass=org.wezfurlong.wezterm
TryExec=$BIN/wezterm
Exec=$BIN/wezterm start --cwd .
Type=Application
Categories=System;TerminalEmulator;Utility;
Terminal=false
EOF
command -v update-desktop-database >/dev/null && update-desktop-database "$APPS" 2>/dev/null || true
ok "app menu entry $APPS/org.wezfurlong.wezterm.desktop"

# ---------------------------------------------------------------- Config
say "Config"
mkdir -p "$HOME/.config"
link "$HOME/.config/wezterm" "$REPO/wezterm"
link "$HOME/.config/shell/path.sh" "$REPO/shell/path.sh"

# ---------------------------------------------------------------- Shell hooks
say "Shell hooks"
hook_block="$MARK
[ -f \"\$HOME/.config/shell/path.sh\" ] && . \"\$HOME/.config/shell/path.sh\"
$MARK_END"

add_hook() {
  local rc="$1"
  if [[ -f "$rc" ]] && grep -qF "$MARK" "$rc"; then
    ok "$rc"
  else
    printf '\n%s\n' "$hook_block" >> "$rc"
    ok "$rc (hook added)"
  fi
}
add_hook "$HOME/.profile"   # login / desktop session, so GUI apps get PATH too
add_hook "$HOME/.bashrc"    # interactive bash in terminals
# If ~/.bash_profile exists, bash login shells read it *instead of* ~/.profile
[[ -f "$HOME/.bash_profile" ]] && add_hook "$HOME/.bash_profile"
if [[ -f "$HOME/.zshrc" || "${SHELL:-}" == */zsh ]]; then
  add_hook "$HOME/.zshenv"
fi

# ---------------------------------------------------------------- Done
say "Done"
"$BIN/wezterm" --version
case ":$PATH:" in
  *":$BIN:"*) ;;
  *) warn "open a new terminal (or run: . ~/.config/shell/path.sh) so ~/.local/bin is on PATH" ;;
esac
