#!/usr/bin/env bash
# BACKUP installer for these dotfiles (Neovim + tmux), for machines without
# Nix: installs the dependencies with Homebrew / the distro's package manager.
# The main way to install is ./setup.sh (Nix + Home Manager, see flake.nix /
# home.nix); both set up the same thing.
#
#   git clone <this repo> ~/dotfiles && ~/dotfiles/install.sh
#
# Supported: macOS (Homebrew), Debian/Ubuntu (incl. WSL), Arch (and
# derivatives), Fedora/RHEL, openSUSE. Safe to re-run any time: it skips
# what's already done, so running it again also repairs a broken setup.
# Works with macOS's stock bash 3.2.
#
# OS differences are kept small on purpose:
#   - The package manager only installs common build/CLI tools.
#   - Neovim is always the same pinned release from GitHub, put in ~/.local
#     (distros ship anything from 0.9 to nightly; this config targets 0.11).
#   - Plugins install at the exact versions in nvim/lazy-lock.json.
#   - LSP servers, formatters and treesitter parsers install inside Neovim
#     (mason / nvim-treesitter), identical on every distro.
#
# Options:
#   --no-packages   skip the system package step (no sudo/Homebrew needed)
#   -h, --help      show this help

set -euo pipefail

NVIM_VERSION="v0.11.7"
TTE_VERSION="0.15.0"
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$HOME/.local/bin"
OPT="$HOME/.local/opt"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"

SKIP_PACKAGES=0
for arg in "$@"; do
	case "$arg" in
	--no-packages) SKIP_PACKAGES=1 ;;
	-h | --help)
		sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
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
	BLUE=$'\e[38;2;137;180;250m' GREEN=$'\e[38;2;166;227;161m'
	YELLOW=$'\e[38;2;249;226;175m' RED=$'\e[38;2;243;139;168m' RESET=$'\e[0m'
else
	BLUE="" GREEN="" YELLOW="" RED="" RESET=""
fi
step() { printf '\n%s▓▒░ %s%s\n' "$BLUE" "$*" "$RESET"; }
ok() { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$*"; WARNINGS+=("$*"); }
die() {
	printf '\n%s✗ %s%s\n' "$RED" "$*" "$RESET" >&2
	exit 1
}
WARNINGS=()
has() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
case "$OS" in
Linux | Darwin) ;;
*) die "Only Linux and macOS are supported (found $OS)." ;;
esac

# Portable replacements for GNU-only tools (macOS ships BSD versions)
sha256() {
	if has sha256sum; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi
}
# Physical path of a directory (BSD readlink has no -f before macOS 12.3)
resolve_dir() { (cd -P "$1" 2>/dev/null && pwd -P); }
mkdir -p "$BIN" "$OPT" "$CONFIG"
ORIG_PATH="$PATH"
export PATH="$BIN:$PATH"

# ── 1. System packages ───────────────────────────────────────────────────────
# What each one is for:
#   git curl tar gzip unzip   plugin + tool downloads (mason needs unzip)
#   gcc/make                  telescope-fzf-native, treesitter parsers
#   ripgrep fd                telescope live grep / file search
#   python3 (+venv, pip)      mason's black/isort/clang-format, tte (dashboard)
#   nodejs npm                mason's pyright, typescript-tools
#   tmux                      tmux config
#   xclip / wl-clipboard      clipboard on desktop sessions (SSH uses OSC 52)
# On macOS: tar/gzip/unzip/curl are built in, the C compiler comes from the
# Xcode Command Line Tools, and pbcopy/pbpaste handle the clipboard.

# Put brew on PATH (a fresh shell may not have it yet even when installed)
find_brew() {
	has brew && return 0
	local b
	for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
		if [[ -x "$b" ]]; then
			eval "$("$b" shellenv)"
			return 0
		fi
	done
	return 1
}

install_packages_macos() {
	step "System packages (Homebrew)"

	if ! xcode-select -p >/dev/null 2>&1; then
		xcode-select --install >/dev/null 2>&1 || true
		die "Xcode Command Line Tools are missing (git, C compiler). Finish the installer that just opened, then re-run install.sh."
	fi

	if ! find_brew; then
		ok "Installing Homebrew (https://brew.sh)"
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" ||
			die "Homebrew install failed."
		find_brew || die "Homebrew installed but 'brew' not found."
		BREW_FRESH=1
	fi

	brew install git ripgrep fd python node tmux || die "brew install failed."
	ok "System packages installed"
}

install_packages() {
	if [[ "$OS" == "Darwin" ]]; then
		install_packages_macos
		return
	fi
	step "System packages"

	local family="" id_like=""
	if [[ -r /etc/os-release ]]; then
		# shellcheck disable=SC1091
		. /etc/os-release
		id_like="${ID:-} ${ID_LIKE:-}"
	fi
	case " $id_like " in
	*" arch "*) family=arch ;;
	*" debian "* | *" ubuntu "*) family=debian ;;
	*" fedora "* | *" rhel "* | *" centos "*) family=fedora ;;
	*" suse "* | *" opensuse "*) family=suse ;;
	esac
	# Fallback on whichever package manager exists
	if [[ -z "$family" ]]; then
		if has pacman; then family=arch
		elif has apt-get; then family=debian
		elif has dnf; then family=fedora
		elif has zypper; then family=suse
		fi
	fi

	local sudo=""
	if [[ $EUID -ne 0 ]]; then
		if has sudo; then
			sudo="sudo"
		else
			warn "Not root and no sudo: skipping system packages. Install them yourself (see the list in install.sh)."
			return
		fi
	fi

	local desktop=()
	[[ -n "${WAYLAND_DISPLAY:-}" ]] && desktop+=(wl-clipboard)
	[[ -n "${DISPLAY:-}" ]] && desktop+=(xclip)

	# ${desktop[@]+...}: an empty "${desktop[@]}" is an unbound-variable error
	# under set -u in bash < 4.4
	case "$family" in
	debian)
		ok "Detected Debian/Ubuntu family (apt)"
		# One broken third-party repo (e.g. a PPA with no release for this
		# Ubuntu version) makes `apt-get update` fail; the rest still refresh,
		# so warn and carry on instead of aborting the whole install.
		if ! $sudo apt-get update; then
			warn "apt-get update reported errors (usually a PPA/third-party repo that doesn't support this release; see the Err: lines above). Continuing with the package lists that did update."
			if grep -rqs 'neovim-ppa' /etc/apt/sources.list /etc/apt/sources.list.d/; then
				warn "The Neovim PPA is not needed (this installer uses a pinned Neovim from GitHub). Remove it with: sudo add-apt-repository --remove ppa:neovim-ppa/stable"
			fi
		fi
		$sudo apt-get install -y git curl tar gzip unzip build-essential ripgrep fd-find \
			python3 python3-venv python3-pip nodejs npm tmux ${desktop[@]+"${desktop[@]}"}
		# Debian names fd "fdfind"
		if ! has fd && has fdfind; then ln -sf "$(command -v fdfind)" "$BIN/fd"; fi
		;;
	arch)
		ok "Detected Arch family (pacman)"
		$sudo pacman -Sy --needed --noconfirm git curl tar gzip unzip base-devel ripgrep fd \
			python python-pip nodejs npm tmux ${desktop[@]+"${desktop[@]}"}
		;;
	fedora)
		ok "Detected Fedora/RHEL family (dnf)"
		$sudo dnf install -y git curl tar gzip unzip gcc make ripgrep fd-find \
			python3 python3-pip nodejs npm tmux ${desktop[@]+"${desktop[@]}"}
		;;
	suse)
		ok "Detected openSUSE (zypper)"
		$sudo zypper --non-interactive install git curl tar gzip unzip gcc make ripgrep fd \
			python3 python3-pip nodejs npm tmux ${desktop[@]+"${desktop[@]}"}
		;;
	*)
		warn "Unknown distro: skipping system packages. Install them yourself (see the list in install.sh)."
		return
		;;
	esac
	ok "System packages installed"
}

# ── 2. Neovim (pinned release from GitHub) ──────────────────────────────────
install_neovim() {
	step "Neovim $NVIM_VERSION"

	if [[ -x "$BIN/nvim" ]] && "$BIN/nvim" --version 2>/dev/null | head -1 | grep -q "NVIM $NVIM_VERSION\$"; then
		ok "Already installed ($BIN/nvim)"
		return
	fi

	local arch os asset
	arch="$(uname -m)"
	case "$OS" in
	Darwin) os=macos ;;
	*) os=linux ;;
	esac
	case "$arch" in
	x86_64 | amd64) asset="nvim-$os-x86_64.tar.gz" ;;
	aarch64 | arm64) asset="nvim-$os-arm64.tar.gz" ;;
	*) die "No prebuilt Neovim for CPU architecture '$arch'." ;;
	esac

	local tmp
	tmp="$(mktemp -d)"
	# (reset the trap once it fires, so later functions don't run it again)
	trap "rm -rf '$tmp'; trap - RETURN" RETURN
	curl -fsSL -o "$tmp/$asset" "https://github.com/neovim/neovim/releases/download/$NVIM_VERSION/$asset" ||
		die "Download failed: $asset"

	# Verify against the SHA-256 GitHub publishes for the release asset
	local expected actual
	expected="$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/tags/$NVIM_VERSION" 2>/dev/null |
		python3 -c "import json,sys; print(next((a.get('digest') or '' for a in json.load(sys.stdin)['assets'] if a['name']=='$asset'), '').removeprefix('sha256:'))" 2>/dev/null || true)"
	actual="$(sha256 "$tmp/$asset")"
	if [[ -z "$expected" ]]; then
		warn "Couldn't fetch the published checksum (GitHub API limit?); Neovim download not verified."
	elif [[ "$expected" != "$actual" ]]; then
		die "Checksum mismatch for $asset (expected $expected, got $actual)."
	else
		ok "Checksum verified"
	fi

	local dest="$OPT/nvim-$NVIM_VERSION"
	rm -rf "$dest"
	mkdir -p "$dest"
	tar -xzf "$tmp/$asset" -C "$dest" --strip-components=1
	# macOS: clear any quarantine flag so Gatekeeper doesn't block the binary
	if [[ "$OS" == "Darwin" ]]; then xattr -cr "$dest" 2>/dev/null || true; fi
	ln -sfn "$dest/bin/nvim" "$BIN/nvim"
	ok "Installed to $dest, linked as $BIN/nvim"
}

# ── 3. tte (animated dashboard header) ──────────────────────────────────────
install_tte() {
	step "TerminalTextEffects (dashboard animation)"
	local venv="$OPT/tte-venv"
	if [[ ! -x "$venv/bin/python" ]]; then
		python3 -m venv "$venv" || {
			warn "Couldn't create a Python venv (python3-venv missing?); the dashboard banner won't animate."
			return
		}
	fi
	# Pinned: the banner script uses options that older/newer releases may not
	# have (keep in sync with home.nix)
	"$venv/bin/pip" install --quiet "terminaltexteffects==$TTE_VERSION" ||
		{ warn "pip install terminaltexteffects failed; the dashboard banner won't animate."; return; }
	ln -sfn "$venv/bin/tte" "$BIN/tte"
	ok "tte $("$BIN/tte" --version 2>/dev/null | awk '{print $NF}')"
}

# ── 4. Link configs ─────────────────────────────────────────────────────────
# Existing files/dirs are moved aside to <name>.bak-<date>, never deleted.
link() {
	local src="$1" dest="$2"
	if [[ -L "$dest" && "$(resolve_dir "$dest")" == "$(resolve_dir "$src")" ]]; then
		ok "$dest → $src (already linked)"
		return
	fi
	if [[ -e "$dest" || -L "$dest" ]]; then
		local backup
		backup="$dest.bak-$(date +%Y%m%d-%H%M%S)"
		mv "$dest" "$backup"
		warn "Moved existing $dest to $backup"
	fi
	mkdir -p "$(dirname "$dest")"
	ln -s "$src" "$dest"
	ok "$dest → $src"
}

link_configs() {
	step "Linking configs"
	link "$DOTFILES/nvim" "$CONFIG/nvim"
	link "$DOTFILES/tmux" "$CONFIG/tmux"
	chmod +x "$DOTFILES/tmux/status.sh" "$DOTFILES/nvim/scripts/dashboard-art.sh"
}

# ── 5. Neovim plugins, LSP servers, formatters, parsers ─────────────────────
setup_neovim() {
	step "Neovim plugins (versions from lazy-lock.json)"
	"$BIN/nvim" --headless "+Lazy! restore" +qa ||
		die "Plugin install failed. Run 'nvim' and check :Lazy for errors."
	ok "Plugins installed"

	step "LSP servers, formatters, treesitter parsers"
	"$BIN/nvim" --headless -c "luafile $DOTFILES/nvim/scripts/bootstrap.lua" ||
		warn "Some tools failed to install (see above). Retry with :Mason inside Neovim."
}

# ── 6. tmux ─────────────────────────────────────────────────────────────────
reload_tmux() {
	if [[ -n "${TMUX:-}" ]] && has tmux; then
		tmux source-file "$CONFIG/tmux/tmux.conf" && ok "Reloaded tmux config in the running server"
	fi
}

# ── Run ─────────────────────────────────────────────────────────────────────
printf '%s▓▒░ dotfiles installer (backup, no Nix)%s  (%s)\n' "$BLUE" "$RESET" "$DOTFILES"
if has nix || [[ -d /nix/store ]]; then
	warn "Nix is installed here: ./setup.sh (Home Manager) is the preferred setup. Continuing with install.sh."
fi
# (Home Manager links ~/.config/nvim to the store, which links to this repo)
if [[ -L "$CONFIG/nvim" && "$(readlink "$CONFIG/nvim")" == /nix/store/* ]]; then
	die "~/.config/nvim is managed by Home Manager on this machine. Use ./switch.sh, or remove it from home.nix first."
fi

if [[ $SKIP_PACKAGES -eq 1 ]]; then
	step "System packages"
	ok "Skipped (--no-packages)"
else
	install_packages
fi
if [[ "$OS" == "Darwin" ]]; then find_brew || true; fi
for tool in git curl tar unzip python3; do
	has "$tool" || die "'$tool' is required but not installed."
done
has cc || has gcc || has clang || warn "No C compiler: telescope-fzf-native and treesitter parsers can't build."
has npm || warn "npm not found: pyright (Python LSP) and typescript-tools won't work."
has rg || warn "ripgrep (rg) not found: Telescope live grep won't work."
has tmux || warn "tmux not found: the tmux config is linked but unused."

install_neovim
install_tte
link_configs
setup_neovim
reload_tmux

step "Done"
if [[ "${BREW_FRESH:-0}" -eq 1 ]]; then
	warn "Homebrew was just installed. Add it to your shell: echo 'eval \"\$($(command -v brew) shellenv)\"' >> ~/.zprofile"
fi
case ":$ORIG_PATH:" in
*":$BIN:"*) ;;
*)
	rc="~/.bashrc"
	[[ "$OS" == "Darwin" || "${SHELL:-}" == */zsh ]] && rc="~/.zshrc"
	warn "$BIN is not on your PATH. Add this to $rc: export PATH=\"\$HOME/.local/bin:\$PATH\""
	;;
esac
if [[ -n "${WARNINGS[0]+set}" ]]; then
	printf '\n  %sFinished with warnings:%s\n' "$YELLOW" "$RESET"
	for w in ${WARNINGS[@]+"${WARNINGS[@]}"}; do printf '    - %s\n' "$w"; done
else
	ok "Everything installed. Start Neovim with: nvim"
fi
