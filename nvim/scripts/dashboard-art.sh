#!/usr/bin/env bash
# Art shown in the dashboard-nvim preview window (see lua/plugins/dashboard.lua).
# Runs inside a Neovim terminal buffer, so colors and animation work.
#
# Must work with GNU and BSD (macOS) tools and bash 3.2: anything this prints
# besides the art (an error, "[Process exited]") scrolls the tiny preview
# window and knocks the banner out of place.

# Character counts below need a UTF-8 locale (otherwise each █ counts as 3).
# Take the first one that exists: names differ between Linux and macOS.
probe='█'
{
	for loc in "${LC_ALL:-}" C.UTF-8 en_US.UTF-8 C.utf8; do
		[[ -n "$loc" ]] || continue
		export LC_ALL="$loc"
		((${#probe} == 1)) && break
	done
} 2>/dev/null # silence "setlocale: cannot change locale" for missing ones

# Weekday banner (art copied from dashboard-nvim's week_header) + date line
day_file="$(dirname "$0")/days/$(date +%A).txt"
art_width=0
while IFS= read -r line || [[ -n "$line" ]]; do
	((${#line} > art_width)) && art_width=${#line}
done <"$day_file"
date_line=$(date '+%Y-%m-%d %H:%M:%S')
# (leading blank line dropped: 8 lines of text leaves the 9-row preview window a
#  spare row, so tte's trailing newline never scrolls the canvas out of place)
text=$(
	sed '/./,$!d' "$day_file"
	# center the date under the art, like the original header
	printf '%*s%s\n' $(((art_width - ${#date_line}) / 2)) '' "$date_line"
)

# Two TerminalTextEffects passes chained on the same canvas (~1.5s total):
#   1. slice     - banner is cut in half and slammed together diagonally (~0.6s)
#   2. highlight - a bright glint sweeps across the finished banner (~0.9s)
# Both settle on the header color: #89b4fa (DashboardHeader in catppuccin-mocha).
#
# Layout notes (the preview window is only file_height rows, so nothing may scroll):
#   --canvas-width 0 --anchor-text n : full-width canvas, text centered in it.
#     (Avoid --anchor-canvas n: it pads the canvas to the full terminal height,
#      which scrolls the tiny window and misaligns the passes.)
#   --no-eol        : no trailing newline after a pass (would scroll by one row)
#   --reuse-canvas  : pass 2 draws over pass 1's canvas instead of below it
color=89b4fa
layout=(--canvas-width 0 --anchor-text n --no-eol)

# install.sh links tte into ~/.local/bin, which may not be on Neovim's PATH
tte=$(command -v tte || echo "$HOME/.local/bin/tte")
if [[ ! -x "$tte" ]]; then
	# No tte: draw the banner statically, centered, in the header color
	pad=$((($(tput cols 2>/dev/null || echo 80) - art_width) / 2))
	((pad < 0)) && pad=0
	printf '\e[38;2;137;180;250m'
	while IFS= read -r line; do printf '%*s%s\n' "$pad" '' "$line"; done <<<"$text"
	printf '\e[0m'
	exec sleep 2147483647
fi

"$tte" "${layout[@]}" slice \
	--slice-direction diagonal --movement-speed 0.8 \
	--final-gradient-stops "$color" <<<"$text"

"$tte" "${layout[@]}" --reuse-canvas --frame-rate 200 highlight \
	--highlight-direction diagonal_top_left_to_bottom_right \
	--highlight-width 12 --highlight-brightness 2 \
	--final-gradient-stops "$color" <<<"$text"

# Keep the terminal job alive so Neovim doesn't print "[Process exited 0]".
# The job is killed when the dashboard closes. (BSD sleep has no "infinity".)
exec sleep 2147483647
