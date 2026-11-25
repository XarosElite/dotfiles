#!/usr/bin/env bash
# Right side of the tmux status bar, styled after xero/dotfiles' tmux-status,
# in Catppuccin Mocha. Called by tmux every status-interval:
#   status-right "#(~/.config/tmux/status.sh #{client_width})"
#
#   ░▒▓ cpu 12% ━━── mem 41% ━━── dsk 57% ━━━─ ▓▒░ 14:05 2026-11-22 ▓▒░
#
# Only block elements and box-drawing characters, so any monospace font works.

width=${1:-200}

# Catppuccin Mocha
crust='#11111b'
surface0='#313244'
surface1='#45475a'
blue='#89b4fa'
sapphire='#74c7ec'
peach='#fab387'
red='#f38ba8'

# ── Measurements ──────────────────────────────────────────────────────────────

# CPU: usage since the previous call (stored per user), not since boot
state_dir="${TMUX_TMPDIR:-/tmp}/tmux-$(id -u)"
mkdir -p "$state_dir" 2>/dev/null
cpu=0
if [[ -r /proc/stat ]]; then
	# Linux
	read -r _ user nice system idle iowait irq softirq steal _ </proc/stat
	total=$((user + nice + system + idle + iowait + irq + softirq + steal))
	busy=$((total - idle - iowait))
	if read -r prev_total prev_busy 2>/dev/null <"$state_dir/cpu.prev"; then
		dt=$((total - prev_total))
		((dt > 0)) && cpu=$(((busy - prev_busy) * 100 / dt))
	fi
	echo "$total $busy" >"$state_dir/cpu.prev" 2>/dev/null

	mem=$(awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf "%d", (t - a) * 100 / t}' /proc/meminfo)
	dsk=$(df -P / | awk 'NR==2 {gsub("%", "", $5); print $5}')
else
	# macOS: no /proc. CPU = sum of per-process %CPU over all cores (cheap,
	# unlike `top -l`); memory = app + wired + compressed pages, like Activity
	# Monitor's "Memory Used"; disk = the Data volume (/ is the sealed system).
	ncpu=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
	cpu=$(ps -A -o %cpu= | awk -v n="$ncpu" '{s += $1} END {v = s / n; if (v > 100) v = 100; printf "%d", v}')
	mem=$(vm_stat | awk -v total="$(sysctl -n hw.memsize)" '
		/page size of/ {ps = $8}
		/^Anonymous pages/ {anon = $3}
		/^Pages purgeable/ {purg = $3}
		/^Pages wired down/ {wired = $4}
		/^Pages occupied by compressor/ {comp = $5}
		END {printf "%d", (anon - purg + wired + comp) * ps * 100 / total}')
	vol=/System/Volumes/Data
	[[ -d $vol ]] || vol=/
	dsk=$(df -P "$vol" | awk 'NR==2 {gsub("%", "", $5); print $5}')
fi
: "${cpu:=0}" "${mem:=0}" "${dsk:=0}"

# ── Drawing helpers ───────────────────────────────────────────────────────────

# Text colour for a value: dark normally, peach when busy, red when critical
pressure() {
	if (($1 > 90)); then
		echo "$red"
	elif (($1 > 74)); then
		echo "$peach"
	else
		echo "$crust"
	fi
}

# 4-cell meter: ━ filled, ─ empty
meter() {
	local filled=$((($1 * 4 + 50) / 100)) out="" i
	for ((i = 0; i < 4; i++)); do
		if ((i < filled)); then out+="#[fg=$2]━"; else out+="#[fg=$surface1]─"; fi
	done
	printf '%s' "$out"
}

stat() { # label value
	local c
	c=$(pressure "$2")
	printf '#[fg=%s]%s %3s%% %s ' "$c" "$1" "$2" "$(meter "$2" "$c")"
}

# ── Render ────────────────────────────────────────────────────────────────────

if ((width > 80)); then
	# fade in to blue, stats, then blue → sapphire fade
	out="#[bg=default,fg=$blue]░▒▓#[bg=$blue] "
	if ((width > 110)); then
		out+="$(stat cpu "$cpu")$(stat mem "$mem")$(stat dsk "$dsk")"
	else
		out+="#[fg=$(pressure "$cpu")]cpu $cpu% #[fg=$(pressure "$mem")]mem $mem% "
	fi
	out+="#[bg=$sapphire,fg=$blue]▓▒░"
else
	# narrow: skip the stats, fade straight in to the time segment
	out="#[bg=default,fg=$sapphire]░▒▓#[bg=$sapphire]"
fi
out+="#[fg=$crust,bold] $(date +%H:%M) #[nobold]"
if ((width > 80)); then
	out+="#[fg=$surface0]$(date +%Y-%m-)#[fg=$crust,bold]$(date +%d) #[nobold]"
fi
# fade out into the background
out+="#[bg=default,fg=$sapphire]▓▒░"

printf '%s' "$out"
