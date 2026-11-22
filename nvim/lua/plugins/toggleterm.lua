-- Floating terminal over the current buffer: Ctrl+\ toggles it (from normal,
-- insert or terminal mode). It's the same shell session every time, so your
-- git aliases, history and running commands are kept while it's hidden.
return {
	"akinsho/toggleterm.nvim",
	version = "*",
	keys = { { [[<C-\>]], desc = "Toggle floating terminal" } },
	cmd = { "ToggleTerm", "TermExec" },
	opts = {
		open_mapping = [[<C-\>]],
		direction = "float",
		float_opts = {
			border = "curved", -- ╭─╮ rounded box-drawing border
			width = function()
				return math.floor(vim.o.columns * 0.85)
			end,
			height = function()
				return math.floor(vim.o.lines * 0.8)
			end,
			winblend = 0,
		},
		persist_mode = true, -- reopen in insert/terminal mode if you left it there
		start_in_insert = true,
		shade_terminals = false,
		highlights = {
			FloatBorder = { guifg = "#89b4fa" }, -- catppuccin blue, like tmux
		},
	},
}
