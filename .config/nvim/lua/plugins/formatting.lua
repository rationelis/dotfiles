return {
	"stevearc/conform.nvim",
	config = function()
		require("conform").setup({
			formatters_by_ft = {
				lua = { "stylua" },
				rust = { "rustfmt" },
				markdown = { "prettier" },
				typescript = { "prettier", "eslint_d" },
				json = { "prettier" },
				yaml = { "prettier" },
				vue = { "prettier" },
				javascript = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
				python = { "black" },
				c = { "clang-format" },
			},
		})

		vim.api.nvim_create_autocmd("BufWritePre", {
			pattern = "*",
			callback = function(args)
				require("conform").format({ bufnr = args.buf })
			end,
		})
	end,
}
