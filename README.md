# Dotfiles Home

Neovim + tmux config, set up with Nix + Home Manager on macOS, any Linux
distro and NixOS. A plain shell installer is kept as a backup for machines
without Nix.

| File | What it is |
|---|---|
| `flake.nix` | Pins nixpkgs + Home Manager; Home Manager config per platform, NixOS config |
| `home.nix` | Packages (Neovim, tmux, LSP servers, formatters, ...) and config links |
| `shell/` | bash + zsh: aliases, prompt, zoxide, fzf, ... (`default.nix`), shared functions (`functions.sh`) |
| `setup.sh` | **New machine**: installs Nix, turns on flakes, then runs `switch.sh` |
| `switch.sh` | Applies `home.nix` with Home Manager — re-run after changes |
| `install.sh` | **Backup installer** for machines without Nix (Homebrew / apt / pacman / dnf / zypper) |
| `nixos/configuration.nix` | NixOS system config |

## Install (macOS, any Linux distro, NixOS)

```
git clone git@github.com:XarosElite/dotfiles.git ~/dotfiles
~/dotfiles/setup.sh
```

That's the only command. It explains and asks before each step (`--yes` to
accept everything); re-running it skips what's done:

1. **Nix** — installs the latest release with the official installer
   (nixos.org) if it's missing. Needs sudo; creates `/nix` and a `nix-daemon`
   service (single-user install where there's no systemd, e.g. WSL).
2. **Flakes** — this repo is a flake, which Nix still labels an
   "experimental feature". Turns it on for good by adding
   `experimental-features = nix-command flakes` to `~/.config/nix/nix.conf`
   (on NixOS, `nixos/configuration.nix` sets it).
3. **Shell** — explains that Home Manager takes over `~/.bashrc`, `~/.zshrc`
   etc. (see [Shell](#shell-bash--zsh)); your current ones are moved to
   `*.backup-<date>` and listed.
4. **`switch.sh`** — Home Manager doesn't need installing; this runs the
   version pinned in `flake.lock`:
   - installs everything in `home.nix` at the versions pinned in
     `flake.lock`, the same on every machine: Neovim 0.11.7, tmux, git,
     ripgrep, fd, a C compiler, tte (animated dashboard banner), the LSP
     servers and formatters from `nvim/lua/tools.lua`, node and python;
   - **links** `~/.config/nvim` → `nvim/` and `~/.config/tmux` → `tmux/` (live
     links, so edits apply without re-running anything; anything already
     there is moved to `*.backup-<date>`);
   - installs **Neovim plugins** at the versions in `nvim/lazy-lock.json`,
     and the treesitter parsers.

Open a new terminal afterwards. From then on, after changing or pulling the
config, just run `~/dotfiles/switch.sh`.

Useful commands:

```
nix flake update                 # update nixpkgs + Home Manager (then ./switch.sh)
home-manager generations         # list previous setups
home-manager switch --rollback   # go back to the previous one
```

> Flakes only see files that git tracks: `git add` new files before switching.

## Shell (bash + zsh)

Both shells are configured in `shell/default.nix` to look and work the same,
themed Catppuccin Mocha like tmux and Neovim. Shared parts are written once:

- **Aliases** (`home.shellAliases`) and **environment** (`home.sessionVariables`)
- **Prompt**: starship, styled like the tmux bar (`░▒▓ dir ▓▒░ ░▒▓ ◇ branch ▓▒░`, no Nerd Font needed)
- **Tools**, each with bash + zsh integration:
  - `cd` is [zoxide](https://github.com/ajeetdsouza/zoxide): `cd proj` jumps
    to the best match among directories you've used; `cdi` picks with fzf
  - fzf: `Ctrl+R` history, `Ctrl+T` files, `Alt+C` directories (with previews)
  - eza (`ls`, `ll`, `la`, `lt`), bat (`cat`), delta (git diffs), direnv +
    nix-direnv, tldr, btop
- **Functions** (`shell/functions.sh`, read live, no switch needed): `mkcd`,
  `up N`, `fe` (fuzzy-open in nvim), `rgv` (ripgrep → nvim at the line), `extract`

Each shell adds the same features its own way: zsh with autosuggestions,
syntax highlighting and history substring search; bash with
[ble.sh](https://github.com/akinomyoga/ble.sh), which brings those to bash.
Both: Up/Down search history for what you've typed, history shared between
open shells, `Ctrl+X Ctrl+E` edits the line in nvim, type a directory name to
`cd` into it.

Changing aliases or anything else in `default.nix` needs `./switch.sh` (or the
`dots-switch` alias), then `reload`. Machine-only additions, not in git:
`~/.shellrc.local` (both), `~/.bashrc.local`, `~/.zshrc.local`.

To make zsh your login shell: add `$(which zsh)` to `/etc/shells`, then
`chsh -s $(which zsh)`.

## NixOS

`setup.sh` / `switch.sh` work on NixOS too. For the user set up in
`flake.nix` (`edger`), `switch.sh` rebuilds the whole system from the flake
(`nixos-rebuild switch --flake ~/dotfiles#nixos --impure`), which applies
`home.nix` along with it; other users get standalone Home Manager.

`--impure` is needed because `nixos/configuration.nix` imports
`/etc/nixos/hardware-configuration.nix`. Note the system is built from the
flake's pinned nixpkgs (25.11), not from your nix channel.

## Backup: without Nix

On machines where you can't (or don't want to) install Nix:

```
~/dotfiles/install.sh
```

It installs the same tools with Homebrew (macOS; installed for you if missing,
needs the Xcode Command Line Tools) or your distro's package manager
(Debian/Ubuntu incl. WSL, Arch, Fedora/RHEL, openSUSE; asks for sudo), a pinned
Neovim release from GitHub, and LSP servers/formatters via mason inside Neovim.
Use `--no-packages` to skip the package step. Make sure `~/.local/bin` is on
your `PATH` (it warns if it isn't).

## Terminal notes

- In iTerm2, keep *Settings → Profiles → Text → "Treat ambiguous-width
  characters as double width"* **off** and line spacing at 100%, or the
  block-letter banner and tmux bar won't line up.
- Terminal.app has no 24-bit colour; use iTerm2, Ghostty, kitty or WezTerm.
- Optional: a [Nerd Font](https://www.nerdfonts.com/) for the icons inside
  Neovim. The tmux theme works with any font.
