-- Jump anywhere on screen: press s, type a couple of characters, then the
-- label shown next to the match you want.
return {
	"folke/flash.nvim",
	event = "VeryLazy",
	opts = {},
	keys = {
		-- s: jump to any match (also works as a motion: ds<label> deletes to it)
		{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
		-- S: select a treesitter node (function, block, argument...) by label.
		-- Normal/operator mode only: visual S stays nvim-surround's "surround selection".
		{ "S", mode = { "n", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
		-- r: remote action in operator mode, e.g. yr<label>iw yanks a word elsewhere
		{ "r", mode = "o", function() require("flash").remote() end, desc = "Flash remote" },
		{ "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Flash treesitter search" },
		-- Ctrl+s while typing a / or ? search: toggle flash labels on the matches
		{ "<c-s>", mode = "c", function() require("flash").toggle() end, desc = "Toggle flash search" },
	},
}
