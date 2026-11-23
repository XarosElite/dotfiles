# Dotfiles Home

Neovim + tmux config, plus a NixOS configuration.

## Install (any Linux distro)

```
git clone git@github.com:XarosElite/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

One command sets up everything:

1. **System packages** with your distro's package manager (asks for sudo):
   git, curl, unzip, gcc/make, ripgrep, fd, python3 (+venv), nodejs/npm, tmux.
   Supported: Debian/Ubuntu (incl. WSL), Arch and derivatives, Fedora/RHEL, openSUSE.
2. **Neovim** — always the same pinned release (see `NVIM_VERSION` in
   `install.sh`), downloaded from GitHub, checksum-verified, installed to
   `~/.local`. Distro Neovim versions vary too much to rely on.
3. **tte** for the animated dashboard header (Python venv in `~/.local/opt`).
4. **Links** `~/.config/nvim` → `nvim/` and `~/.config/tmux` → `tmux/`.
   Anything already there is moved to `*.bak-<date>`, never deleted.
5. **Neovim plugins** at the exact versions in `nvim/lazy-lock.json`, then LSP
   servers, formatters and treesitter parsers (listed in `nvim/lua/tools.lua`).

Re-run it any time — it skips what's already done, so it also repairs a broken
setup. Use `--no-packages` to skip the sudo/package step.

Make sure `~/.local/bin` is on your `PATH` (the installer warns if it isn't).

Optional: a [Nerd Font](https://www.nerdfonts.com/) in your terminal for the
icons inside Neovim. The tmux theme works with any font.

## NixOS Setup
```
git clone git@github.com:XarosElite/dotfiles.git
sudo nixos-rebuild switch -I nixos-config=/home/$USER/dotfiles/nixos/configuration.nix
```
