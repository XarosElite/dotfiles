-- Single list of external tools this config needs. Used by:
--   lua/plugins/lsp.lua         (mason auto-install on startup)
--   lua/plugins/treesitter.lua  (parsers)
--   scripts/bootstrap.lua       (install.sh: installs everything up front)
return {
	-- Language servers, by nvim-lspconfig name (installed + enabled via mason-lspconfig)
	servers = { "lua_ls", "pyright", "clangd" },

	-- Other mason packages: formatters for conform.nvim, rust-analyzer for rustaceanvim
	tools = { "stylua", "black", "isort", "clang-format", "rust-analyzer" },

	-- Treesitter parsers
	parsers = { "c", "python", "lua", "vim", "vimdoc", "query", "java", "rust", "markdown" },
}
