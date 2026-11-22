-- https://github.com/nvim-treesitter/nvim-treesitter
-- Pinned to the `master` branch: it supports Neovim 0.11 and this config API
-- (`nvim-treesitter.configs`). The newer `main` branch is a rewrite with a
-- different setup and needs Neovim 0.12.
return {
	"nvim-treesitter/nvim-treesitter",
	branch = "master",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = { "c", "python", "lua", "vim", "vimdoc", "query", "java", "rust", "markdown" },

			-- Install parsers synchronously (only applied to `ensure_installed`)
			sync_install = false,

			-- Automatically install missing parsers when entering buffer
			auto_install = true,

			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
			indent = { enable = true },

			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			},
		})
	end,
}
