return {
	"nvim-telescope/telescope.nvim",
	version = "*", -- latest release (0.2.x)
	dependencies = {
		"nvim-lua/plenary.nvim",
		-- Compiled fzf sorter: faster, better fuzzy matching (needs make + gcc)
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	},

	-- See documentation for different GO TOs that telescope can do. https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#getting-started
	config = function()
		require("telescope").setup({})
		require("telescope").load_extension("fzf")

		local builtin = require("telescope.builtin")
		vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
		vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Grep under cursor" })
		vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
		vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
		vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
		vim.keymap.set("n", "gr", function()
			require("telescope.builtin").lsp_references()
		end, { desc = "Go to References" })

		vim.keymap.set("n", "gd", function()
			require("telescope.builtin").lsp_definitions()
		end, { desc = "Go to definitions" })

		vim.keymap.set("n", "gT", function()
			require("telescope.builtin").lsp_type_definitions()
		end, { desc = "Type definitions" })

		vim.keymap.set("n", "gI", function()
			require("telescope.builtin").lsp_implementations()
		end, { desc = "Implementations" })

		vim.keymap.set("n", "<leader>o", function()
			require("telescope.builtin").lsp_document_symbols()
		end, { desc = "Document Symbols" })
	end,
}
