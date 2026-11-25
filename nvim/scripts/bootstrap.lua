-- Run by install.sh / switch.sh after plugins are installed:
--   nvim --headless -c "luafile <this file>"
-- Installs the mason packages (those not already on PATH, e.g. from Nix) and
-- treesitter parsers from lua/tools.lua and waits for them, so the first real launch doesn't install things in the
-- background. Exits with status 1 if anything failed.

local tools = require("tools")
local failed = {}

local function log(msg)
	io.stdout:write(msg .. "\n")
end

-- ── Mason packages ───────────────────────────────────────────────────────────
local ok_reg, registry = pcall(require, "mason-registry")
if not ok_reg then
	log("  mason not available: " .. tostring(registry))
	vim.cmd("cquit 1")
end

local refreshed = false
registry.refresh(function()
	refreshed = true
end)
vim.wait(120000, function()
	return refreshed
end, 200)

local map = require("mason-lspconfig").get_mappings().lspconfig_to_package
local names = {}
for _, server in ipairs(tools.servers) do
	if tools.external(server) then
		log("  ✓ " .. server .. " (provided outside mason)")
	else
		table.insert(names, map[server] or server)
	end
end
for _, tool in ipairs(tools.tools) do
	if tools.external(tool) then
		log("  ✓ " .. tool .. " (provided outside mason)")
	else
		table.insert(names, tool)
	end
end

local pending = {}
for _, name in ipairs(names) do
	local ok, pkg = pcall(registry.get_package, name)
	if not ok then
		table.insert(failed, name .. " (not in mason registry)")
	elseif pkg:is_installed() then
		log("  ✓ " .. name .. " (already installed)")
	else
		pending[name] = pkg
		if not pkg:is_installing() then
			log("  … installing " .. name)
			pkg:install({}, function(success, err)
				if not success then
					table.insert(failed, name .. ": " .. tostring(err))
				end
			end)
		end
	end
end

-- Wait until every pending package is installed or has failed (10 min cap)
vim.wait(600000, function()
	for name, pkg in pairs(pending) do
		if pkg:is_installed() then
			log("  ✓ " .. name)
			pending[name] = nil
		elseif not pkg:is_installing() then
			pending[name] = nil -- finished without installing: failed
		end
	end
	return next(pending) == nil
end, 500)
for name in pairs(pending) do
	table.insert(failed, name .. " (timed out)")
end

-- ── Treesitter parsers ───────────────────────────────────────────────────────
log("  … treesitter parsers: " .. table.concat(tools.parsers, ", "))
local ok_ts, err = pcall(function()
	require("nvim-treesitter.install").ensure_installed_sync(tools.parsers)
end)
if not ok_ts then
	table.insert(failed, "treesitter parsers: " .. tostring(err))
end

-- mason-lspconfig / mason-tool-installer also start background installs when
-- the config loads; let any of those finish before quitting (2 min cap).
vim.wait(120000, function()
	for _, pkg in ipairs(registry.get_all_packages()) do
		if pkg:is_installing() then
			return false
		end
	end
	return true
end, 500)

-- ── Result ───────────────────────────────────────────────────────────────────
if #failed > 0 then
	log("\n  Failed:")
	for _, f in ipairs(failed) do
		log("    ✗ " .. f)
	end
	vim.cmd("cquit 1")
end
vim.cmd("qall!")
