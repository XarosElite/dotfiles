-- System clipboard that works in as many environments as possible.
--
-- All yanks/deletes/puts use the system clipboard ("unnamedplus"). The provider
-- is picked like this:
--
--   1. Inside tmux        -> tmux buffers. `load-buffer -w` also forwards the
--                            copy to the outer terminal's clipboard (OSC 52), so
--                            it reaches your local machine even through SSH.
--                            Needs tmux >= 3.2 and `set-clipboard` not "off".
--   2. Over SSH (no tmux) -> OSC 52 escape sequence to your local terminal.
--                            Paste falls back to Neovim's own register, since
--                            most terminals block OSC 52 reads; use your
--                            terminal's paste (Ctrl+Shift+V / Cmd+V) for
--                            text copied outside Neovim.
--   3. Local desktop      -> Neovim's auto-detection (wl-copy, xclip, xsel,
--                            pbcopy, win32yank, ...).
--   4. WSL without win32yank -> clip.exe / powershell Get-Clipboard.
--   5. Nothing found      -> OSC 52, same as SSH.
--
-- OSC 52 needs terminal support: kitty, WezTerm, Alacritty, foot, Ghostty,
-- Windows Terminal, xterm and iTerm2 (enable "Applications in terminal may
-- access clipboard") work; GNOME Terminal / other VTE terminals do not.
-- Check what's in use with :checkhealth vim.provider

vim.opt.clipboard = "unnamedplus"

local env = vim.env
local function has(bin)
	return vim.fn.executable(bin) == 1
end

local function tmux_provider()
	local copy = { "tmux", "load-buffer", "-w", "-" }
	local paste = { "tmux", "save-buffer", "-" }
	return {
		name = "tmux (+ OSC 52 to outer terminal)",
		copy = { ["+"] = copy, ["*"] = copy },
		paste = { ["+"] = paste, ["*"] = paste },
		cache_enabled = 0,
	}
end

local function osc52_provider()
	local osc52 = require("vim.ui.clipboard.osc52")
	-- Paste from Neovim's unnamed register instead of asking the terminal
	-- (OSC 52 reads are usually unsupported and would hang until timeout).
	local function paste()
		return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
	end
	return {
		name = "OSC 52",
		copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
		paste = { ["+"] = paste, ["*"] = paste },
	}
end

local function wsl_provider()
	local paste = {
		"powershell.exe",
		"-NoLogo",
		"-NoProfile",
		"-Command",
		"[Console]::Out.Write($(Get-Clipboard -Raw).ToString().Replace(\"`r\", \"\"))",
	}
	return {
		name = "WSL clip.exe",
		copy = { ["+"] = { "clip.exe" }, ["*"] = { "clip.exe" } },
		paste = { ["+"] = paste, ["*"] = paste },
		cache_enabled = 0,
	}
end

-- Would Neovim's built-in detection find a real desktop clipboard?
local function has_native_clipboard()
	return (env.WAYLAND_DISPLAY and has("wl-copy"))
		or (env.DISPLAY and (has("xclip") or has("xsel")))
		or has("pbcopy")
		or has("win32yank.exe")
		or has("termux-clipboard-set")
end

local in_ssh = env.SSH_TTY or env.SSH_CONNECTION or env.SSH_CLIENT
local tmux_ok = env.TMUX and has("tmux")

if tmux_ok and (in_ssh or not has_native_clipboard()) then
	vim.g.clipboard = tmux_provider()
elseif in_ssh then
	vim.g.clipboard = osc52_provider()
elseif has_native_clipboard() then
	-- leave vim.g.clipboard unset: Neovim picks the right tool itself
elseif vim.fn.has("wsl") == 1 and has("clip.exe") then
	vim.g.clipboard = wsl_provider()
else
	vim.g.clipboard = osc52_provider()
end
