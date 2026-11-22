-- IMPORTANT: This sets the "LEADER" (starter key) for your keymaps. It must be
-- set before any <leader> mapping is defined (remaps.lua, plugins).
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.scrolloff = 8
vim.opt.updatetime = 50
vim.opt.undofile = true

-- No plugins here are written as Node/Perl/Python/Ruby remote plugins, so skip
-- loading those providers (faster startup, fewer :checkhealth warnings).
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- Clipboard: see lua/clipboard.lua
