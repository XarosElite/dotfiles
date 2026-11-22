-- Keeps the cursor line vertically centered while moving (like typing `zz`
-- after every vertical motion). Toggle with <leader>z.
return {
	"arnamak/stay-centered.nvim",
	lazy = false,
	opts = {
		-- UIs where re-centering would be odd or fight the plugin's own layout
		skip_filetypes = {
			"dashboard",
			"lazy",
			"mason",
			"TelescopePrompt",
			"TelescopeResults",
			"trouble",
			"oil",
			"help",
			"qf",
		},
	},
	keys = {
		{
			"<leader>z",
			function()
				require("stay-centered").toggle()
			end,
			mode = { "n", "v" },
			desc = "Toggle stay-centered",
		},
	},
}
