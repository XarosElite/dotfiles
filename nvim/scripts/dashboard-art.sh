#!/usr/bin/env bash
# Art shown in the dashboard-nvim preview window (see lua/plugins/dashboard.lua).
# Runs inside a Neovim terminal buffer, so colors and animation work.

# Weekday banner (art copied from dashboard-nvim's week_header) + date line
day_file="$(dirname "$0")/days/$(date +%A).txt"
art_width=$(wc -L <"$day_file")
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

tte "${layout[@]}" slice \
	--slice-direction diagonal --movement-speed 0.8 \
	--final-gradient-stops "$color" <<<"$text"

tte "${layout[@]}" --reuse-canvas --frame-rate 200 highlight \
	--highlight-direction diagonal_top_left_to_bottom_right \
	--highlight-width 12 --highlight-brightness 2 \
	--final-gradient-stops "$color" <<<"$text"

# Keep the terminal job alive so Neovim doesn't print "[Process exited 0]".
# The job is killed when the dashboard closes.
exec sleep infinity
