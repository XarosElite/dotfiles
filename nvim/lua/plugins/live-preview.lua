-- Live browser preview for Markdown/HTML/AsciiDoc/SVG (:LivePreview start)
return {
	"brianhuster/live-preview.nvim",
	cmd = "LivePreview",
	dependencies = {
		-- picker used by :LivePreview pick (telescope is already installed)
		"nvim-telescope/telescope.nvim",
	},
}
