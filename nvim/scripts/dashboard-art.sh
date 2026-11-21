#!/usr/bin/env bash
# Art shown in the dashboard-nvim preview window (see lua/plugins/dashboard.lua).
# Runs inside a Neovim terminal buffer, so colors and animation work.

# Weekday banner (art copied from dashboard-nvim's week_header) + date line,
# animated via TerminalTextEffects. Swap "decrypt" for any effect:
# beams, burn, fireworks, matrix, rain, slide, waves, ... (`tte --help` lists all)
day_file="$(dirname "$0")/days/$(date +%A).txt"
art_width=$(wc -L <"$day_file")
date_line=$(date '+%Y-%m-%d %H:%M:%S')

# Final colors. With --existing-color-handling dynamic, decrypt still shows its
# green ciphertext but settles on these input colors.
header_color='\e[38;2;137;180;250m' # #89b4fa, DashboardHeader in catppuccin-mocha
banner_color=$header_color
date_color=$header_color
reset='\e[0m'
{
	printf "$banner_color"
	cat "$day_file"
	# center the date under the art, like the original header
	printf "%*s${date_color}%s${reset}\n" $(((art_width - ${#date_line}) / 2)) '' "$date_line"
} | tte --anchor-canvas n --anchor-text n --existing-color-handling dynamic decrypt

# Keep the terminal job alive so Neovim doesn't print "[Process exited 0]".
# The job is killed when the dashboard closes.
exec sleep infinity
