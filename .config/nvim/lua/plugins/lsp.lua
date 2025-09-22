return {
	{
		"neovim/nvim-lspconfig",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local on_attach = function(_, bufnr)
				local map = function(mode, lhs, rhs, desc)
					vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
				end
				map("n", "gd", vim.lsp.buf.definition, "Go to definition")
				map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
				map("n", "gr", vim.lsp.buf.references, "Go to references")
				map("n", "K", vim.lsp.buf.hover, "Hover documentation")
			end

			vim.lsp.inlay_hint.enable()
			vim.diagnostic.config({ virtual_text = true })

			-- Migrate from require("lspconfig").pyright.setup
			vim.lsp.config("pyright", {
				on_attach = on_attach,
				capabilities = capabilities,
				settings = {
					pyright = {
						disableOrganizeImports = true, -- use Ruff for organizing imports
					},
					python = {
						analysis = {
							ignore = { "*" }, -- disable analysis, Ruff handles linting
						},
					},
				},
			})
		end,
	},

	{
		"nvimdev/lspsaga.nvim",
		branch = "main",
		opts = {
			preview = {
				lines_above = 2,
				lines_below = 10,
			},
			symbol_in_winbar = {
				enable = false,
			},
			ui = {
				border = "single",
				code_action = "🦝",
			},
			lightbulb = {
				sign = false,
			},
		},
	},

	{
		"nvim-treesitter/nvim-treesitter",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					-- Core
					"lua",
					"rust",
					"typescript",
					"python",
					"haskell",
					"c",

					-- Web
					"html",
					"css",

					-- Docs
					"markdown",
					"markdown_inline",

					-- Shell
					"bash",
					"regex",

					-- Config
					"json",
					"yaml",
					"toml",
				},
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
			})
		end,
		build = ":TSUpdate",
	},
}
