-- Copy to the system clipboard (clipboard=unnamedplus already does this for
-- every yank; these are kept as an explicit shortcut). Works as an operator in
-- normal mode, e.g. <leader>yiw, <leader>yy
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>Y", '"+y$', { desc = "Yank to end of line to system clipboard" })

-- Enter Terminal Mode
vim.keymap.set("n", "<leader>t", "<cmd>terminal<CR>", { desc = "Open terminal" })

-- Exit Terminal Mode and into Normal mode
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Black Hole Delete (does not overwrite your yank register / clipboard)
-- Note: in visual mode vim-visual-multi also uses <leader>d and takes priority.
vim.keymap.set("v", "<leader>d", '"_d', { desc = "Delete without yanking" })

-- Move to window using the <ctrl> hjkl keys
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- File explorer: <leader>e opens Oil (see lua/plugins/oil.lua)
