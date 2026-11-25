#!/usr/bin/env bash
# Apply these dotfiles with Nix + Home Manager. Run it after changing or
# pulling the config. (First time on a machine: ./setup.sh, which installs
# Nix and then runs this. No Nix: ./install.sh is the backup.)
#
# What it does:
#   1. Home Manager: installs the packages in home.nix and links
#      ~/.config/nvim and ~/.config/tmux to this repo. Anything already there
#      is moved aside to <name>.backup-<date>.
#      On NixOS, as the user configured in flake.nix: rebuilds the system
#      instead (nixos-rebuild), which applies home.nix along with it.
#   2. Neovim plugins at the versions in nvim/lazy-lock.json, plus treesitter
#      parsers (LSP servers and formatters come from Nix).
#
# Arguments are passed on to `home-manager switch` / `nixos-rebuild switch`
# (e.g. --show-trace).
# Undo with: home-manager switch --rollback (NixOS: nixos-rebuild switch --rollback)

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES # read by flake.nix (paths of the config links)
# PATH of your interactive shell (setup.sh passes the one it was started with),
# taken before Nix is loaded into this script
CALLER_PATH="${DOTFILES_CALLER_PATH:-$PATH}"

if [[ -t 1 ]]; then
	BLUE=$'\e[38;2;137;180;250m' GREEN=$'\e[38;2;166;227;161m'
	YELLOW=$'\e[38;2;249;226;175m' RED=$'\e[38;2;243;139;168m' RESET=$'\e[0m'
else
	BLUE="" GREEN="" YELLOW="" RED="" RESET=""
fi
step() { printf '\n%s▓▒░ %s%s\n' "$BLUE" "$*" "$RESET"; }
ok() { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
note() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
die() {
	printf '\n%s✗ %s%s\n' "$RED" "$*" "$RESET" >&2
	exit 1
}

printf '%s▓▒░ dotfiles: Home Manager switch%s  (%s)\n' "$BLUE" "$RESET" "$DOTFILES"

# Nix may be installed but not on PATH yet (fresh install, non-login shell)
if ! command -v nix >/dev/null 2>&1; then
	for profile in /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
		"$HOME/.nix-profile/etc/profile.d/nix.sh"; do
		if [[ -r "$profile" ]]; then
			# shellcheck disable=SC1090
			. "$profile"
			break
		fi
	done
fi
if ! command -v nix >/dev/null 2>&1; then
	die "Nix is not installed. Run ./setup.sh: it installs Nix and then runs this.
  (No Nix, or can't install it? Use ./install.sh instead.)"
fi

# Flakes are still "experimental" in Nix itself; enable them for this run
export NIX_CONFIG="extra-experimental-features = nix-command flakes${NIX_CONFIG:+
$NIX_CONFIG}"

# Flakes only see files git knows about
if [[ -n "$(git -C "$DOTFILES" ls-files --others --exclude-standard -- '*.nix')" ]]; then
	note "Untracked .nix files are invisible to the flake: git add them first."
fi

# On NixOS, is this the user that flake.nix's nixosConfigurations sets up?
nixos_user=0
if [[ -e /etc/NIXOS ]] &&
	nix eval --impure --json "$DOTFILES#nixosConfigurations.nixos.config.home-manager.users" \
		--apply builtins.attrNames 2>/dev/null | grep -q "\"$USER\""; then
	nixos_user=1
fi

if [[ $nixos_user -eq 1 ]]; then
	step "NixOS rebuild (system + Home Manager)"
	ok "NixOS user $USER: applying home.nix as part of the system"
	# Built as you, activated with sudo (root can't read a repo you own)
	nixos-rebuild switch --flake "$DOTFILES#nixos" --impure --use-remote-sudo "$@" ||
		die "nixos-rebuild failed (see above). Re-run with --show-trace for details."
	ok "System rebuilt, ~/.config/nvim and ~/.config/tmux linked"
else
	step "Home Manager"
	system="$(nix eval --impure --raw --expr builtins.currentSystem)"
	ok "Platform: $system"
	backup_ext="backup-$(date +%Y%m%d-%H%M%S)"
	nix run "$DOTFILES#home-manager" -- switch --impure -b "$backup_ext" \
		--flake "$DOTFILES#$system" "$@" ||
		die "home-manager switch failed (see above). Re-run with --show-trace for details."
	ok "Packages installed, shell + nvim + tmux config linked"
	# Report what Home Manager moved out of the way (e.g. your old ~/.bashrc)
	moved=()
	while IFS= read -r f; do moved+=("$f"); done < <(
		find "$HOME" "$HOME/.config" -maxdepth 2 -name "*.$backup_ext" 2>/dev/null | sort -u
	)
	if [[ ${#moved[@]} -gt 0 ]]; then
		note "Moved aside (Home Manager manages these now):"
		for f in "${moved[@]}"; do printf '      ~%s\n' "${f#"$HOME"}"; done
		note "Keep anything you need from them in ~/.shellrc.local, ~/.bashrc.local or ~/.zshrc.local"
	fi
fi

# The new packages, even if this shell's PATH doesn't have them yet
export PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:$PATH"

step "Neovim plugins (versions from lazy-lock.json)"
nvim --headless "+Lazy! restore" +qa ||
	die "Plugin install failed. Run 'nvim' and check :Lazy for errors."
ok "Plugins installed"

step "Treesitter parsers (and anything not provided by Nix)"
nvim --headless -c "luafile $DOTFILES/nvim/scripts/bootstrap.lua" ||
	note "Some tools failed to install (see above). Retry with :Mason / :TSUpdate inside Neovim."

if [[ -n "${TMUX:-}" ]]; then
	tmux source-file "$HOME/.config/tmux/tmux.conf" && ok "Reloaded tmux config"
fi

step "Done"
# Can the shell you ran this from find nvim? Not right after a first install:
# a running shell never picks up a new PATH by itself.
# (In a subshell: assigning PATH there also clears bash's remembered location
# of nvim from running it above; a `PATH=... command -v` prefix would not.)
if (PATH="$CALLER_PATH" && command -v nvim >/dev/null 2>&1); then
	ok "Start Neovim with: nvim"
elif [[ -t 0 && -t 1 && -n "${SHELL:-}" ]]; then
	ok "Starting a fresh $(basename "$SHELL") so this terminal finds nvim and the other new tools"
	printf '  %s(new terminals have them too; type exit to get back to the old shell)%s\n\n' "$YELLOW" "$RESET"
	exec "$SHELL" -l
else
	note "Open a new terminal (or run: exec \$SHELL -l), then start Neovim with: nvim"
fi
