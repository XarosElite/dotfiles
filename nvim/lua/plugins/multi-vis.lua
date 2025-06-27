return {
	{
		"mg979/vim-visual-multi",
		branch = "master",
		init = function()
			-- Optional: Set your own keybindings here
			vim.g.VM_default_mappings = 1 -- set to 0 if you want to define your own
			vim.g.VM_maps = {
				["Find Under"] = "<leader>d", -- like VS Code
				["Find Subword Under"] = "<leader>d",
			}
		end,
	},
}
