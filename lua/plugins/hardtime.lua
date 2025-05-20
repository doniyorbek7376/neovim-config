return {
	"m4xshen/hardtime.nvim",
	lazy = false,
	dependencies = { "MunifTanjim/nui.nvim" },
	opts = {

		showmode = false,
		cmdheight = 2,
	},
	config = function()
		require("hardtime").setup()
	end,
}
