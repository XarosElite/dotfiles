return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"jay-babu/mason-nvim-dap.nvim",
		"saghen/blink.cmp",
	},
	config = function()
		local capabilities = require("blink.cmp").get_lsp_capabilities()
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = { "lua_ls", "pyright" },

			-- Auto enable lsp with (vim.lsp.enable()) if the lsp was installed with mason. Version 0.11 neovim
			automatic_enable = {
				"lua_ls",
				"pyright",
			},
		})

		require("mason-tool-installer").setup({

			ensure_installed = {
				-- Installs packages on boot. Some may fail because your are missing unzip or other cli programs
				"lua-language-server",
				"stylua",
				"luacheck",
			},

			auto_update = false,
			run_on_start = true,

			start_delay = 3000,
			debounce_hours = 5,
		})
		-- Neovim 0.11 native LSP config. nvim-lspconfig still supplies the default
		-- server configs (cmd, filetypes, root markers); we only add overrides here.

		-- Applies to every server: advertise blink.cmp completion capabilities
		vim.lsp.config("*", {
			capabilities = capabilities,
		})

		-- clangd uses the system binary (not installed via mason)
		vim.lsp.config("clangd", {
			--     cmd = { "clangd", "--background-index", "--clang-tidy", "--log=verbose" },
			--     init_options = {
			--         fallbackFlags = { "-std=c++17" },
			--     },
		})
		vim.lsp.enable("clangd")
	end,
}
