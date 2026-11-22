-- Add / change / delete surrounding pairs:
--   ysiw)   wrap word in ( )          cs"'   change " " to ' '
--   ds]     delete surrounding [ ]    S"     (visual) wrap selection in " "
--   yss}    wrap whole line in { }    cst<div>  change surrounding HTML tag
return {
	"kylechui/nvim-surround",
	version = "*",
	event = "VeryLazy",
	opts = {},
}
