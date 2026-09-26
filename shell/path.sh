# Sourced from ~/.profile, ~/.bashrc (and ~/.zshenv) by install.sh.
# POSIX sh so every shell can read it. Add your own dirs to the list.
for d in \
  "$HOME/.local/bin" \
  "$HOME/bin" \
  "$HOME/go/bin" \
  "$HOME/.cargo/bin"
do
  case ":$PATH:" in
    *":$d:"*) ;;
    *) [ -d "$d" ] && PATH="$d:$PATH" ;;
  esac
done
unset d
export PATH

# Other environment that should survive restarts goes here too, e.g.
# export EDITOR=nvim
