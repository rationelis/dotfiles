return {
	{ "github/copilot.vim" },
	{ "nvim-lua/plenary.nvim" },

	{
		"tpope/vim-fugitive",
		config = function()
			vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "Fugitive: Git status" })
		end,
	},

	{
		"mbbill/undotree",
		config = function()
			vim.keymap.set("n", "<leader><F5>", vim.cmd.UndotreeToggle, { desc = "Toggle Undotree" })
		end,
	},

	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" },
		opts = {},
	},

	{
		"Saecki/crates.nvim",
		ft = "toml",
		opts = {},
		dependencies = { "nvimtools/none-ls.nvim" },
	},
}
