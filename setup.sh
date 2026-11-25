#!/usr/bin/env bash
# New machine? Run this one command. It does everything, asking before each
# big step:
#
#   git clone <this repo> ~/dotfiles && ~/dotfiles/setup.sh
#
#   1. Nix         installs the latest Nix (official installer, nixos.org) if
#                  it isn't installed. NixOS already has it.
#   2. Flakes      explains and turns on the "experimental features" that
#                  flakes need, permanently, so plain `nix` commands work.
#   3. Shell       adds one line to your shell rc so Home Manager's
#                  environment loads in new terminals.
#   4. switch.sh   Home Manager (packages + config links), Neovim plugins,
#                  treesitter parsers. On NixOS: rebuilds the system.
#
# Safe to re-run: finished steps are skipped. After this, re-run ./switch.sh
# to apply changes. No Nix wanted (or possible)? Use ./install.sh instead.
#
# Options:
#   -y, --yes   don't ask, accept every step
#   -h, --help  show this help

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# The PATH of the shell you ran this from, before we load Nix into this one;
# switch.sh uses it to tell whether your shell can already find nvim.
export DOTFILES_CALLER_PATH="${DOTFILES_CALLER_PATH:-$PATH}"
ASSUME_YES=0
for arg in "$@"; do
	case "$arg" in
	-y | --yes) ASSUME_YES=1 ;;
	-h | --help)
		sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'
		exit 0
		;;
	*)
		echo "Unknown option: $arg (see --help)" >&2
		exit 1
		;;
	esac
done

# ── Output helpers ────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
	BLUE=$'\e[38;2;137;180;250m' GREEN=$'\e[38;2;166;227;161m' DIM=$'\e[38;2;166;173;200m'
	YELLOW=$'\e[38;2;249;226;175m' RED=$'\e[38;2;243;139;168m' RESET=$'\e[0m'
else
	BLUE="" GREEN="" DIM="" YELLOW="" RED="" RESET=""
fi
step() { printf '\n%s▓▒░ %s%s\n' "$BLUE" "$*" "$RESET"; }
ok() { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
note() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
explain() { printf '%s%s%s\n' "$DIM" "$(sed 's/^/  /')" "$RESET"; }
die() {
	printf '\n%s✗ %s%s\n' "$RED" "$*" "$RESET" >&2
	exit 1
}
has() { command -v "$1" >/dev/null 2>&1; }
# Path with $HOME shown as ~
pretty() {
	local p="$1"
	[[ "$p" == "$HOME"/* ]] && p="~${p#"$HOME"}"
	printf '%s' "$p"
}

# ask "Question?" -> 0 for yes (the default), 1 for no
ask() {
	if [[ $ASSUME_YES -eq 1 ]]; then
		printf '  %s? %s%s yes (--yes)\n' "$BLUE" "$1" "$RESET"
		return 0
	fi
	[[ -r /dev/tty ]] || die "Can't ask \"$1\" (no terminal). Re-run with --yes to accept every step."
	local reply
	printf '  %s? %s%s [Y/n] ' "$BLUE" "$1" "$RESET"
	read -r reply </dev/tty || reply=n
	case "$reply" in
	"" | [Yy]*) return 0 ;;
	*) return 1 ;;
	esac
}

OS="$(uname -s)"
case "$OS" in
Linux | Darwin) ;;
*) die "Only Linux and macOS are supported (found $OS)." ;;
esac
NIXOS=0
[[ -e /etc/NIXOS ]] && NIXOS=1

# Put an installed Nix on this shell's PATH (the installer only sets up
# shells started after it)
load_nix() {
	has nix && return 0
	local profile
	for profile in /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
		"$HOME/.nix-profile/etc/profile.d/nix.sh"; do
		if [[ -r "$profile" ]]; then
			# The profile scripts aren't written for `set -u`
			set +u
			# shellcheck disable=SC1090
			. "$profile"
			set -u
			has nix && return 0
		fi
	done
	return 1
}

flakes_enabled() {
	[[ "$(nix-instantiate --eval --expr 'builtins ? getFlake' 2>/dev/null)" == "true" ]]
}

printf '%s▓▒░ dotfiles setup%s  (%s)\n' "$BLUE" "$RESET" "$DOTFILES"

# ── 1. Nix ────────────────────────────────────────────────────────────────────
step "1/4  Nix"
if [[ $NIXOS -eq 1 ]]; then
	ok "NixOS: Nix is part of the system"
elif load_nix; then
	ok "Already installed: $(nix --version)"
else
	explain <<'EOF'
Nix is a package manager that installs everything into /nix/store, separate
from your system's own packages, at exact pinned versions. This installs the
latest release with the official installer from nixos.org. It needs sudo to:
  - create /nix (on macOS: a separate APFS volume named "Nix Store")
  - add a nix-daemon service and a few "nixbld" build users
  - add a few lines to the system shell rc files, so new terminals find Nix
Uninstalling is documented at https://nix.dev/manual/nix/latest/installation/uninstall
EOF
	ask "Install Nix now?" || die "Setup needs Nix. (To set up without Nix, use ./install.sh.)"

	has curl || die "curl is needed to download Nix. Install it with your package manager, then re-run."
	if [[ "$OS" == "Linux" ]] && has getenforce && [[ "$(getenforce 2>/dev/null)" == "Enforcing" ]]; then
		note "SELinux is enforcing: the official Nix installer may fail. If it does, see https://nix.dev/manual/nix/latest/installation/"
	fi

	installer_args=()
	if [[ "$OS" == "Darwin" ]]; then
		: # macOS installs are always multi-user (with the daemon)
	elif [[ -d /run/systemd/system ]]; then
		installer_args+=(--daemon) # multi-user: recommended
	else
		# No systemd (e.g. WSL without systemd, containers): no daemon possible
		note "No systemd here: installing single-user Nix (owned by you, no daemon)."
		installer_args+=(--no-daemon)
	fi
	[[ $ASSUME_YES -eq 1 ]] && installer_args+=(--yes)

	tmp="$(mktemp -d)"
	curl -fsSL -o "$tmp/install-nix" https://nixos.org/nix/install || die "Couldn't download the Nix installer."
	ok "Running the official Nix installer (it explains each step and asks for sudo)"
	sh "$tmp/install-nix" ${installer_args[@]+"${installer_args[@]}"} ||
		die "The Nix installer failed (see above)."
	rm -rf "$tmp"

	load_nix || die "Nix was installed but isn't found from this shell. Open a new terminal and run ./setup.sh again."
	ok "Installed: $(nix --version)"
fi

# ── 2. Flakes ─────────────────────────────────────────────────────────────────
step "2/4  Flakes (Nix \"experimental features\")"
explain <<'EOF'
This repo's setup is a "flake" (flake.nix + flake.lock): a Nix project that
pins every input to an exact version, so each machine gets an identical setup.
Flakes, and the `nix` command used with them, have been in wide use for years
but are still labeled "experimental" by Nix, so they're off by default. You
turn them on with one setting:

    experimental-features = nix-command flakes

Without it, every command needs a flag, e.g. `nix --extra-experimental-features
'nix-command flakes' flake update`.
EOF
if flakes_enabled; then
	ok "Already enabled"
elif [[ $NIXOS -eq 1 ]]; then
	explain <<'EOF'
On NixOS this is a system setting: nixos/configuration.nix sets
`nix.settings.experimental-features`, so it's on for good after the rebuild in
step 4. Until then it's enabled just for this setup run.
EOF
	ok "Will be enabled by the NixOS rebuild"
else
	conf="${XDG_CONFIG_HOME:-$HOME/.config}/nix/nix.conf"
	explain <<EOF
This saves the setting for your user in $(pretty "$conf")
(no sudo needed; other users on the machine are unaffected).
EOF
	if ask "Turn on flakes for your user?"; then
		mkdir -p "$(dirname "$conf")"
		if [[ -f "$conf" ]] && grep -qE '^[[:space:]]*experimental-features' "$conf"; then
			# Add to the existing line instead of overriding it
			cp "$conf" "$conf.bak"
			sed -E 's/^([[:space:]]*experimental-features[[:space:]]*=.*)$/\1 nix-command flakes/' "$conf.bak" >"$conf"
			note "Added to the existing experimental-features line (old file: $(pretty "$conf.bak"))"
		else
			printf '\n# Added by dotfiles/setup.sh: enable flakes and the `nix` command\nexperimental-features = nix-command flakes\n' >>"$conf"
		fi
		flakes_enabled || die "Wrote $conf, but Nix still reports flakes as off. Check that file (and /etc/nix/nix.conf)."
		ok "Enabled in $(pretty "$conf")"
	else
		note "Skipped: flakes are enabled for this run only. You'll need the flag above for nix commands."
	fi
fi

# ── 3. Shell ──────────────────────────────────────────────────────────────────
step "3/4  Shell startup"
# Marker line of the block below (older setup.sh versions added only the
# hm-session-vars line; this block replaces that)
rc_marker='# Nix + Home Manager environment (added by dotfiles/setup.sh)'
rc_block="$rc_marker
# Load Nix if the system shell config didn't (single-user installs only edit
# ~/.profile, which terminal windows don't read)
if ! command -v nix >/dev/null 2>&1; then
	for f in /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \"\$HOME/.nix-profile/etc/profile.d/nix.sh\"; do
		if [ -r \"\$f\" ]; then . \"\$f\"; break; fi
	done
fi
# Home Manager's environment variables (locales for Nix programs, ...)
[ -r \"\$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh\" ] && . \"\$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh\"
# (end of dotfiles block)"
if [[ $NIXOS -eq 1 ]]; then
	ok "NixOS sets up Nix and Home Manager's environment itself"
else
	explain <<'EOF'
New terminals need to find Nix and the programs Home Manager installs. The
Nix installer handles that system-wide in most cases; this adds a small block
to your shell rc file(s) that covers the rest (e.g. single-user installs) and
loads Home Manager's environment variables (hm-session-vars.sh):
EOF
	printf '%s\n' "$rc_block" | sed 's/^/      /'
	rcs=()
	case "${SHELL:-}" in
	*/zsh) rcs+=("$HOME/.zshrc") ;;
	*/bash) rcs+=("$HOME/.bashrc") ;;
	esac
	[[ "$OS" == "Darwin" && ${#rcs[@]} -eq 0 ]] && rcs+=("$HOME/.zshrc") # macOS default shell
	for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
		[[ -f "$rc" ]] && rcs+=("$rc")
	done

	todo=()
	for rc in ${rcs[@]+"${rcs[@]}"}; do
		grep -qsF "$rc_marker" "$rc" && continue
		case " ${todo[*]-} " in *" $rc "*) continue ;; esac
		todo+=("$rc")
	done
	if [[ ${#rcs[@]} -eq 0 ]]; then
		note "Couldn't tell which shell rc to use (shell: ${SHELL:-unknown}). Add the block above to yours."
	elif [[ ${#todo[@]} -eq 0 ]]; then
		ok "Already set up"
	else
		names=""
		for rc in "${todo[@]}"; do names+="${names:+ and }$(pretty "$rc")"; done
		if ask "Add it to $names?"; then
			for rc in "${todo[@]}"; do
				# Drop the one-line version older setup.sh runs added
				if grep -qsF '# Home Manager environment (added by dotfiles/setup.sh)' "$rc"; then
					cp "$rc" "$rc.dotfiles-bak"
					awk '/^# Home Manager environment \(added by dotfiles\/setup.sh\)$/ {skip = 1; next}
						skip && /hm-session-vars/ {skip = 0; next} {skip = 0; print}' "$rc.dotfiles-bak" >"$rc"
				fi
				printf '\n%s\n' "$rc_block" >>"$rc"
				ok "Added to $(pretty "$rc")"
			done
		else
			note "Skipped: add the block above to your shell rc yourself."
		fi
	fi
fi

# ── 4. Home Manager ───────────────────────────────────────────────────────────
step "4/4  Home Manager"
explain <<'EOF'
Hands over to ./switch.sh, which you re-run after changing or pulling the
config. Home Manager doesn't need installing first: switch.sh runs the
version pinned in flake.lock, and that puts the `home-manager` command on your
PATH from then on.
EOF
exec "$DOTFILES/switch.sh"
