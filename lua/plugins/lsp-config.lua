local servers = {
	"bashls",
	"basedpyright",
	"jsonls",
	"dockerls",
	"gopls",
	"lua_ls",
	"ts_ls",
	"buf_ls",
	"sqlls",
	"terraformls",
	"clangd",
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
			for _, lsp in ipairs(servers) do
				if lsp ~= "clangd" then
                    vim.lsp.config(lsp, {
                        capabilities = capabilities,
                    })
				end
			end

			vim.lsp.config("clangd", {
				capabilities = capabilities,
				filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "h", "hpp" },
			})

			vim.lsp.config("basedpyright", {
				capabilities = capabilities,
				settings = {
					basedpyright = {
						typeCheckingMode = "standard",
						analysis = {
							autoSearchPaths = true,
							useLibraryCodeForTypes = true,
							diagnosticMode = "workspace",
						},
					},
				},
			})

			vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {})
			vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {})
			vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
		end,
	},
}
