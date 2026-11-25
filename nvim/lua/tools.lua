-- Single list of external tools this config needs. Used by:
--   lua/plugins/lsp.lua         (mason auto-install on startup)
--   lua/plugins/treesitter.lua  (parsers)
--   scripts/bootstrap.lua       (install.sh / switch.sh: installs everything up front)
local M = {
	-- Language servers, by nvim-lspconfig name
	servers = { "lua_ls", "pyright", "clangd" },

	-- Other tools: formatters for conform.nvim, rust-analyzer for rustaceanvim
	tools = { "stylua", "black", "isort", "clang-format", "rust-analyzer" },

	-- Treesitter parsers
	parsers = { "c", "python", "lua", "vim", "vimdoc", "query", "java", "rust", "markdown" },

	-- Executable of each server/tool, where it differs from the name above
	bin = {
		lua_ls = "lua-language-server",
		pyright = "pyright-langserver",
	},
}

-- Is the tool already installed outside mason (Nix / Home Manager, the
-- system package manager, ...)? Then mason doesn't need to install it. This is
-- what makes NixOS work: mason's downloaded binaries can't run there, so
-- home.nix provides all of these instead.
function M.external(name)
	local path = vim.fn.exepath(M.bin[name] or name)
	return path ~= "" and not path:find("/mason/bin/", 1, true)
end

-- The names in `list` that mason should install
function M.for_mason(list)
	return vim.tbl_filter(function(name)
		return not M.external(name)
	end, list)
end

return M
