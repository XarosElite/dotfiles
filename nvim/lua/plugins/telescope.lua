return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	-- or                              , branch = '0.1.x',
	dependencies = { "nvim-lua/plenary.nvim" },

	-- See documentation for different GO TOs that telescope can do. https://github.com/nvim-telescope/telescope.nvim?tab=readme-ov-file#getting-started
	config = function()
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
