-- Live terminal running our art script; replaces the static header
local preview = {
	command = "bash",
	file_path = vim.fn.stdpath("config") .. "/scripts/dashboard-art.sh",
	file_width = 80, -- widest weekday banner (Wednesday) is 77 cols
	file_height = 9, -- blank line + 6-line banner + date
}

-- dashboard-nvim reserves (file_height + 4) blank lines for the preview, then
-- vertically centers the page by adding filler lines above it. The preview
-- float, however, is opened at a fixed row near the top of the screen. This
-- re-anchors the float onto its reserved block so it moves with the page.
local function center_preview()
	local pv = require("dashboard.preview")
	local buf, float = require("dashboard").bufnr, pv.preview_winid
	local win = buf and vim.fn.bufwinid(buf) or -1
	if win == -1 or not (float and vim.api.nvim_win_is_valid(float)) then
		return
	end

	-- First non-blank line is the first thing rendered below the reserved block
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
	local first_content
	for i, line in ipairs(lines) do
		if line:match("%S") then
			first_content = i - 1
			break
		end
	end
	if not first_content then
		return
	end
	local block_start = first_content - (preview.file_height + 4)

	-- After a resize re-render the window can be left scrolled down; the page is
	-- centered for topline 1, so show it from the top.
	vim.api.nvim_win_call(win, function()
		vim.fn.winrestview({ topline = 1 })
	end)

	vim.api.nvim_win_set_config(float, {
		relative = "win",
		win = win,
		bufpos = { math.max(block_start, 0) + 2, 0 }, -- 2 lines of the block's padding above
		row = 0,
		col = math.floor((vim.api.nvim_win_get_width(win) - preview.file_width) / 2),
	})
end

return {
	"nvimdev/dashboard-nvim",
	event = "VimEnter",
	config = function()
		-- On VimResized the plugin re-renders the whole dashboard and opens a NEW
		-- preview without closing the old one (duplicate art), and each open adds
		-- another BufWipeout cleanup handler (errors when you leave the dashboard).
		-- This runs first (defined before setup), so tear the old preview down.
		vim.api.nvim_create_autocmd("VimResized", {
			group = vim.api.nvim_create_augroup("DashboardPreviewReset", { clear = true }),
			callback = function()
				local db = require("dashboard")
				if not db.bufnr or vim.api.nvim_get_current_buf() ~= db.bufnr then
					return
				end
				for _, au in ipairs(vim.api.nvim_get_autocmds({ event = "BufWipeout", buffer = db.bufnr })) do
					if au.desc == "make preview have same lifetime with dashboard buffer" then
						vim.api.nvim_del_autocmd(au.id)
					end
				end
				require("dashboard.preview"):close_preview_window()
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "DashboardLoaded",
			callback = function()
				-- The plugin's own resize handler errors on Neovim 0.10+ (it indexes
				-- win config `col` as a table), so replace it with ours.
				local pv = require("dashboard.preview")
				if pv.preview_bufnr then
					pcall(vim.api.nvim_del_augroup_by_name, "DashboardClosePreview" .. pv.preview_bufnr)
				end
				vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
					group = vim.api.nvim_create_augroup("DashboardCenterPreview", { clear = true }),
					callback = center_preview,
				})
				center_preview()
			end,
		})

		require("dashboard").setup({
			theme = "hyper",
			preview = preview,
			config = {
				week_header = {
					enable = true,
				},
				shortcut = {},
				project = { enable = false }, -- hide "Recent Projects"
				mru = { enable = false }, -- hide "Most Recent Files"
				footer = { "" },
			},
		})
	end,
	dependencies = { { "nvim-tree/nvim-web-devicons" } },
}
