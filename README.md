# dotfiles

WezTerm + PATH setup for a Linux VM.

Everything is installed under your home folder, so it all persists:

| What | Where |
|---|---|
| WezTerm (extracted AppImage, no FUSE needed) | `~/.local/opt/wezterm-<version>/` |
| `wezterm` command | `~/.local/bin/wezterm` |
| App menu entry + icon | `~/.local/share/applications/`, `~/.local/share/icons/` |
| WezTerm config | `~/.config/wezterm` → symlink to `wezterm/` in this repo |
| PATH setup | `~/.config/shell/path.sh` → symlink to `shell/path.sh`, sourced from `~/.profile` and `~/.bashrc` |

## Install

```sh
git clone <your-remote>/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Then open WezTerm from the app menu, or run `wezterm` in a new terminal.

`install.sh` is idempotent: run it again whenever something looks off and it only fixes what is missing. Because the configs are symlinks, editing `~/.config/wezterm/wezterm.lua` edits the file in this repo, so `git commit` picks it up.

## No internet on the VM?

Download `WezTerm-20240203-110809-5046fc22-Ubuntu20.04.AppImage` from the
[WezTerm releases page](https://github.com/wezterm/wezterm/releases/tag/20240203-110809-5046fc22),
get it onto the VM, and put it in `~/Downloads` (picked up automatically) or run:

```sh
WEZTERM_APPIMAGE=/path/to/WezTerm-...AppImage ./install.sh
```

The checksum is verified either way.

## Troubleshooting

- **PATH is gone after a restart.** Check whether the hook survived: `grep dotfiles ~/.bashrc`. If it's missing, the VM resets your rc files at boot; rerun `./install.sh` and find another startup hook that persists (e.g. `~/.config/autostart`).
- **Black window or crash on start.** No usable GPU. Try `WEZTERM_SOFTWARE=1 wezterm`; if that works, uncomment `config.front_end = "Software"` in `wezterm/wezterm.lua`.
- **Different WezTerm version.** `WEZTERM_VERSION=<tag> ./install.sh --force`. The old version is removed.
