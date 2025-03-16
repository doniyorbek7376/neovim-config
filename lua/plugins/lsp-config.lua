local servers = {
	"bashls",
	"clangd",
	"basedpyright",
	"jsonls",
	"dockerls",
	"gopls",
	"lua_ls",
	"ts_ls",
	"buf_ls",
	"sqlls",
}

return {
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = function()
			require("mason").setup()
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = servers,
			})
		end,
	},
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local lspconfig = require("lspconfig")
			local utils = require("lsp.utils")
			local common_on_attach = utils.common_on_attach
			for _, lsp in ipairs(servers) do
				lspconfig[lsp].setup({
					on_attach = common_on_attach,
					capabilities = capabilities,
				})
			end
			lspconfig.lua_ls.setup({
				capabilities = capabilities,
			})
			lspconfig.basedpyright.setup({
				capabilities = capabilities,
				settings = {
					basedpyright = {
						typeCheckingMode = "standard",
					},
				},
			})
			lspconfig.gopls.setup({
				capabilities = capabilities,
			})
			lspconfig.ts_ls.setup({
				capabilities = capabilities,
			})
			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
}
