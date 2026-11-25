# Shell functions for both bash and zsh (sourced by the rc files that
# shell/default.nix generates). Read live from the repo: edits apply to new
# shells without running switch.sh. Keep it to syntax both shells understand.

# Make a directory and cd into it
mkcd() {
	mkdir -p -- "$1" && cd -- "$1"
}

# cd up N levels: `up 3` = cd ../../..
up() {
	local n="${1:-1}" target=""
	while [ "$n" -gt 0 ]; do
		target="../$target"
		n=$((n - 1))
	done
	cd -- "${target:-..}"
}

# Fuzzy-find a file (with preview) and open it in Neovim
fe() {
	local file
	file="$(fzf --preview 'bat --color=always --style=numbers --line-range=:300 {}' --query="${1:-}")" &&
		nvim -- "$file"
}

# Search file contents with ripgrep, pick a match with fzf, open Neovim at
# that line: `rgv TODO`
rgv() {
	local match file line
	match="$(rg --line-number --no-heading --color=always --smart-case -- "${1:-.}" |
		fzf --ansi --delimiter : --nth 3.. \
			--preview 'bat --color=always --style=numbers --highlight-line {2} {1}' \
			--preview-window '+{2}-/2')" || return
	file="${match%%:*}"
	line="${match#*:}"
	line="${line%%:*}"
	nvim "+$line" -- "$file"
}

# Extract any common archive: `extract foo.tar.gz`
extract() {
	if [ ! -f "$1" ]; then
		echo "extract: '$1' is not a file" >&2
		return 1
	fi
	case "$1" in
	*.tar.bz2 | *.tbz2) tar -xjf "$1" ;;
	*.tar.gz | *.tgz) tar -xzf "$1" ;;
	*.tar.xz | *.txz) tar -xJf "$1" ;;
	*.tar.zst) tar --zstd -xf "$1" ;;
	*.tar) tar -xf "$1" ;;
	*.bz2) bunzip2 "$1" ;;
	*.gz) gunzip "$1" ;;
	*.xz) unxz "$1" ;;
	*.zip) unzip "$1" ;;
	*.7z) 7z x "$1" ;;
	*) echo "extract: don't know how to extract '$1'" >&2 && return 1 ;;
	esac
}
