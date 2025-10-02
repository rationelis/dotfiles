return {
	{
		"ahmedkhalf/project.nvim",
		config = function()
			require("project_nvim").setup({
				patterns = {
					".git",
					"Cargo.toml",
					"package.json",
					"README.md",
				},
				detection_methods = { "pattern" },
			})
		end,
	},

	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		requires = { { "nvim-lua/plenary.nvim" } },
		config = function()
			local harpoon = require("harpoon")

			-- REQUIRED
			harpoon:setup()
			-- REQUIRED

			vim.keymap.set("n", "<leader>a", function()
				harpoon:list():add()
			end, { desc = "Harpoon: Add file" })
			vim.keymap.set("n", "<C-e>", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end, { desc = "Harpoon: Toggle menu" })

			-- Toggle previous & next buffers stored within Harpoon list
			vim.keymap.set("n", "<C-h>", function()
				harpoon:list():prev()
			end, { desc = "Harpoon: Prev buffer" })
			vim.keymap.set("n", "<C-l>", function()
				harpoon:list():next()
			end, { desc = "Harpoon: Next buffer" })
		end,
	},

	{
		"hedyhli/outline.nvim",
		config = function()
			local opts = {
				symbol_folding = {
					autofold_depth = 2,
				},
			}
			require("outline").setup(opts)

			vim.keymap.set("n", "<leader>o", ":Outline<CR>", { noremap = true, silent = true, desc = "Toggle Outline" })
		end,
	},

	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local telescope = require("telescope")
			telescope.setup({})

			require("telescope").load_extension("projects")

			local builtin = require("telescope.builtin")
			local utils = require("telescope.utils")

			vim.keymap.set("n", "<leader>pf", function()
				require("telescope").extensions.projects.projects({})
			end, { desc = "Find Files in Project Root" })

			vim.keymap.set("n", "<leader>ps", function()
				require("telescope.builtin").live_grep({
					additional_args = function()
						--return { "--max-count=1" }
					end,
				})
			end, { noremap = true, silent = true, desc = "Live Grep (1 per file)" })

			vim.keymap.set("n", "<leader>pd", function()
				builtin.diagnostics({
					bufnr = 0,
					layout_strategy = "vertical",
					layout_config = {
						height = 0.8,
						width = 0.8,
						preview_cutoff = 0,
						prompt_position = "top",
					},
					sorting_strategy = "ascending",
				})
			end, { noremap = true, silent = true, desc = "Telescope Diagnostics" })
		end,
	},

	{
		"nvim-pack/nvim-spectre",
		config = function()
			vim.keymap.set("n", "<leader>S", function()
				require("spectre").toggle()
			end, { desc = "Toggle Spectre" })

			vim.keymap.set("n", "<leader>sw", function()
				require("spectre").open_visual({ select_word = true })
			end, { desc = "Search current word" })

			vim.keymap.set("v", "<leader>sw", function()
				vim.cmd("esc") -- ensure normal mode before opening visual
				require("spectre").open_visual()
			end, { desc = "Search current word" })

			vim.keymap.set("n", "<leader>sp", function()
				require("spectre").open_file_search({ select_word = true })
			end, { desc = "Search on current file" })
		end,
	},
}
