return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"mason-org/mason.nvim",
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		"saghen/blink.cmp",
	},
	config = function()
		-- Neovim 0.11 native LSP config. nvim-lspconfig supplies the default
		-- server configs (cmd, filetypes, root markers); we only add overrides.

		-- Applies to every server: advertise blink.cmp completion capabilities
		vim.lsp.config("*", {
			capabilities = require("blink.cmp").get_lsp_capabilities(),
		})

		-- clangd overrides go here, e.g.:
		-- vim.lsp.config("clangd", {
		-- 	cmd = { "clangd", "--background-index", "--clang-tidy" },
		-- 	init_options = { fallbackFlags = { "-std=c++17" } },
		-- })

		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = { "lua_ls", "pyright", "clangd" },

			-- Calls vim.lsp.enable() for these once installed. Listed explicitly
			-- (not `true`) so mason's rust_analyzer is NOT enabled here:
			-- rustaceanvim manages rust-analyzer itself.
			automatic_enable = { "lua_ls", "pyright", "clangd" },
		})

		require("mason-tool-installer").setup({
			-- Formatters used by conform.nvim (lua/plugins/conform.lua).
			-- Language servers are installed by mason-lspconfig above.
			ensure_installed = {
				"stylua",
				"black",
				"isort",
				"clang-format",
			},

			auto_update = false,
			run_on_start = true,

			start_delay = 3000,
			debounce_hours = 5,
		})
	end,
}
