-- ╔════════════════════════════════════════════════════════════════╗
-- ║                    NEOVIM CONFIGURATION                         ║
-- ║          Single-file, future-proof, maintainable config        ║
-- ╚════════════════════════════════════════════════════════════════╝

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 1. LEADER KEY
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 2. VIM OPTIONS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local opt = vim.opt

-- UI
opt.guicursor = ""
opt.nu = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.colorcolumn = "80"
opt.scrolloff = 8

-- Indentation
opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- Search
opt.hlsearch = false
opt.incsearch = true

-- Files & Undo
opt.swapfile = false
opt.backup = false
opt.undodir = vim.fn.stdpath("data") .. "/undo"
opt.undofile = true

-- Performance
opt.updatetime = 50
opt.isfname:append("@-@")

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 3. CORE KEYMAPS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local map = vim.keymap.set

-- File explorer
map("n", "<leader>pv", vim.cmd.Ex, { desc = "Open file explorer" })

-- Diagnostics
map("n", "<leader>di", vim.diagnostic.open_float, { desc = "Open diagnostics float" })

-- Hard mode: disable arrow keys
for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
	map({ "n", "i", "v" }, key, "<NOP>", { noremap = true })
end

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 4. LAZY.NVIM BOOTSTRAP
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
	local out = vim.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	}):wait()

	if out.code ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim\n", "ErrorMsg" },
			{ out.stderr or "", "WarningMsg" },
		}, true, {})
		return
	end
end
opt.rtp:prepend(lazypath)

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 5. PLUGINS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
require("lazy").setup({
	-- ────────────────────────────────────────────────────────────
	-- COLORSCHEME
	-- ────────────────────────────────────────────────────────────
	{
		"rebelot/kanagawa.nvim",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("kanagawa")
		end,
	},

	-- ────────────────────────────────────────────────────────────
	-- ESSENTIAL UTILITIES
	-- ────────────────────────────────────────────────────────────
	{ "nvim-lua/plenary.nvim" },
	{ "github/copilot.vim" },

	{
		"tpope/vim-fugitive",
		config = function()
			map("n", "<leader>gs", vim.cmd.Git, { desc = "Git status" })
		end,
	},

	{
		"mbbill/undotree",
		config = function()
			map("n", "<leader><F5>", vim.cmd.UndotreeToggle, { desc = "Toggle Undotree" })
		end,
	},

	-- ────────────────────────────────────────────────────────────
	-- TREESITTER
	-- ────────────────────────────────────────────────────────────
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					"lua",
					"rust",
					"typescript",
					"python",
					"haskell",
					"c",
					"html",
					"css",
					"markdown",
					"markdown_inline",
					"bash",
					"regex",
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
	},

	-- ────────────────────────────────────────────────────────────
	-- LSP BASE
	-- ────────────────────────────────────────────────────────────
	{
		"neovim/nvim-lspconfig",
		dependencies = { "hrsh7th/cmp-nvim-lsp" },
		config = function()
			-- LSP keybinds on attach
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufnr = args.buf
					local opts = { buffer = bufnr }

					map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
					map(
						"n",
						"gi",
						vim.lsp.buf.implementation,
						vim.tbl_extend("force", opts, { desc = "Go to implementation" })
					)
					map("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Go to references" }))
					map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))
				end,
			})

			-- Diagnostic config
			vim.diagnostic.config({ virtual_text = true })

			-- Get capabilities from cmp
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Python: Pyright with Ruff
			vim.lsp.config("pyright", {
				capabilities = capabilities,
				settings = {
					pyright = {
						disableOrganizeImports = true,
					},
					python = {
						analysis = {
							ignore = { "*" },
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

	-- ────────────────────────────────────────────────────────────
	-- MASON: LSP/TOOL INSTALLER
	-- ────────────────────────────────────────────────────────────
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		config = function()
			require("mason").setup()
		end,
	},

	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"lua_ls",
				"pyright",
				"ruff",
				"clangd",
			},
			automatic_installation = true,
		},
	},

	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "williamboman/mason.nvim" },
		opts = {
			ensure_installed = {
				"prettier",
				"stylua",
				"black",
				"eslint_d",
			},
			auto_update = true,
			run_on_start = true,
		},
	},

	-- ────────────────────────────────────────────────────────────
	-- LANGUAGE-SPECIFIC
	-- ────────────────────────────────────────────────────────────
	{
		"mrcjkb/rustaceanvim",
		version = "^6",
		lazy = false,
		ft = "rust",
	},

	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		opts = {
			settings = {
				tsserver_file_preferences = {
					includeInlayParameterNameHints = "literals",
					includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					includeInlayFunctionParameterTypeHints = false,
					includeInlayVariableTypeHints = false,
					includeInlayPropertyDeclarationTypeHints = false,
					includeInlayFunctionLikeReturnTypeHints = false,
					includeInlayEnumMemberValueHints = false,
					includeCompletionsForModuleExports = true,
					quotePreference = "auto",
				},
				tsserver_format_options = {
					allowIncompleteCompletions = false,
					allowRenameOfImportPath = false,
				},
			},
		},
	},

	{
		"Saecki/crates.nvim",
		event = "BufRead Cargo.toml",
		opts = {},
		dependencies = { "nvimtools/none-ls.nvim" },
	},

	{
		"hat0uma/csvview.nvim",
		cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
		opts = {
			parser = { comments = { "#", "//" } },
			keymaps = {
				textobject_field_inner = { "if", mode = { "o", "x" } },
				textobject_field_outer = { "af", mode = { "o", "x" } },
				jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
				jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
				jump_next_row = { "<Enter>", mode = { "n", "v" } },
				jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
			},
		},
	},

	-- ────────────────────────────────────────────────────────────
	-- COMPLETION
	-- ────────────────────────────────────────────────────────────
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
		},
		config = function()
			local cmp = require("cmp")

			local cmp_kinds = {
				Text = "  ",
				Method = "  ",
				Function = "  ",
				Constructor = "  ",
				Field = "  ",
				Variable = "  ",
				Class = "  ",
				Interface = "  ",
				Module = "  ",
				Property = "  ",
				Unit = "  ",
				Value = "  ",
				Enum = "  ",
				Keyword = "  ",
				Snippet = "  ",
				Color = "  ",
				File = "  ",
				Reference = "  ",
				Folder = "  ",
				EnumMember = "  ",
				Constant = "  ",
				Struct = "  ",
				Event = "  ",
				Operator = "  ",
				TypeParameter = "  ",
			}

			cmp.setup({
				sources = {
					{ name = "nvim_lsp" },
					{ name = "nvim_lsp_signature_help" },
					{ name = "buffer" },
					{ name = "path" },
				},
				preselect = cmp.PreselectMode.None,
				mapping = cmp.mapping.preset.insert({
					["<C-u>"] = cmp.mapping.scroll_docs(-4),
					["<C-d>"] = cmp.mapping.scroll_docs(4),
					["<C-n>"] = cmp.mapping.select_next_item(),
					["<C-p>"] = cmp.mapping.select_prev_item(),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = false }),
				}),
				formatting = {
					format = function(_, vim_item)
						vim_item.kind = (cmp_kinds[vim_item.kind] or "") .. vim_item.kind
						vim_item.abbr = string.sub(vim_item.abbr, 1, 15)
						return vim_item
					end,
				},
			})
		end,
	},

	-- ────────────────────────────────────────────────────────────
	-- FORMATTING
	-- ────────────────────────────────────────────────────────────
	{
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

			-- Format on save
			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = "*",
				callback = function(args)
					require("conform").format({ bufnr = args.buf })
				end,
			})
		end,
	},

	-- ────────────────────────────────────────────────────────────
	-- NAVIGATION & SEARCH
	-- ────────────────────────────────────────────────────────────
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local telescope = require("telescope")
			telescope.setup({})
			telescope.load_extension("projects")

			local builtin = require("telescope.builtin")

			map("n", "<leader>pf", function()
				builtin.find_files({ cwd = vim.fn.getcwd() })
			end, { desc = "Find files in CWD" })

			map("n", "<leader>pp", function()
				telescope.extensions.projects.projects({})
			end, { desc = "Find projects" })

			map("n", "<leader>ps", function()
				builtin.live_grep()
			end, { desc = "Live grep" })

			map("n", "<leader>pd", function()
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
			end, { desc = "Buffer diagnostics" })
		end,
	},

	{
		"ahmedkhalf/project.nvim",
		config = function()
			require("project_nvim").setup({
				patterns = { ".git", "Cargo.toml", "package.json", "README.md" },
				detection_methods = { "pattern" },
			})
		end,
	},

	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local harpoon = require("harpoon")
			harpoon:setup()

			map("n", "<leader>a", function()
				harpoon:list():add()
			end, { desc = "Harpoon: Add file" })

			map("n", "<C-e>", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end, { desc = "Harpoon: Toggle menu" })

			map("n", "<C-h>", function()
				harpoon:list():prev()
			end, { desc = "Harpoon: Prev buffer" })

			map("n", "<C-l>", function()
				harpoon:list():next()
			end, { desc = "Harpoon: Next buffer" })
		end,
	},

	{
		"hedyhli/outline.nvim",
		config = function()
			require("outline").setup({
				symbol_folding = { autofold_depth = 2 },
			})
			map("n", "<leader>o", "<cmd>Outline<CR>", { desc = "Toggle Outline" })
		end,
	},

	{
		"nvim-pack/nvim-spectre",
		config = function()
			map("n", "<leader>S", function()
				require("spectre").toggle()
			end, { desc = "Toggle Spectre" })

			map("n", "<leader>sw", function()
				require("spectre").open_visual({ select_word = true })
			end, { desc = "Search current word" })

			map("v", "<leader>sw", function()
				vim.cmd("esc")
				require("spectre").open_visual()
			end, { desc = "Search selection" })

			map("n", "<leader>sp", function()
				require("spectre").open_file_search({ select_word = true })
			end, { desc = "Search in current file" })
		end,
	},

	-- ────────────────────────────────────────────────────────────
	-- UI & APPEARANCE
	-- ────────────────────────────────────────────────────────────
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			signcolumn = true,
			numhl = false,
			linehl = false,
			word_diff = false,
			watch_gitdir = {
				interval = 1000,
				follow_files = true,
			},
			attach_to_untracked = true,
			current_line_blame = false,
			sign_priority = 6,
			update_debounce = 100,
			max_file_length = 40000,
			preview_config = {
				border = "single",
				style = "minimal",
				relative = "cursor",
				row = 0,
				col = 1,
			},
		},
	},

	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				icons_enabled = true,
				theme = "auto",
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
				globalstatus = false,
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch", "diff", "diagnostics" },
				lualine_c = { "filename" },
				lualine_x = { "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
		},
	},

	-- ────────────────────────────────────────────────────────────
	-- DATABASE
	-- ────────────────────────────────────────────────────────────
	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = {
			{ "tpope/vim-dadbod", lazy = true },
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
		},
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
		end,
	},
}, {
	-- Lazy.nvim options
	checker = { enabled = true },
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"matchit",
				"matchparen",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"tutor",
				"zipPlugin",
			},
		},
	},
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 6. FILETYPE-SPECIFIC CONFIGURATION
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Rust configuration
vim.api.nvim_create_autocmd("FileType", {
	pattern = "rust",
	callback = function()
		vim.g.rustaceanvim = {
			server = {
				default_settings = {
					["rust-analyzer"] = {
						rustc = { source = "discover" },
						cargo = { allFeatures = true },
					},
				},
			},
		}
	end,
})

-- JavaScript configuration (P5.js compatibility)
vim.api.nvim_create_autocmd("FileType", {
	pattern = "javascript",
	callback = function()
		-- Disable inlay hints for JavaScript to prevent column range errors
		pcall(vim.lsp.inlay_hint.enable, false, { bufnr = 0 })

		-- Set indentation
		vim.bo.shiftwidth = 2
		vim.bo.tabstop = 2
		vim.bo.softtabstop = 2
		vim.bo.expandtab = true
		vim.bo.commentstring = "// %s"
	end,
})

-- Vue configuration
vim.api.nvim_create_autocmd("FileType", {
	pattern = "vue",
	callback = function()
		vim.lsp.config("vtsls", {
			settings = {
				vtsls = {
					tsserver = {
						globalPlugins = {
							{
								name = "@vue/typescript-plugin",
								location = vim.fn.expand(
									"~/.local/share/pnpm/global/5/node_modules/@vue/language-server"
								),
								languages = { "vue" },
								configNamespace = "typescript",
							},
						},
					},
				},
			},
			filetypes = { "typescript", "javascript", "vue" },
		})

		vim.lsp.enable({ "vue_ls", "vtsls" })
	end,
})

-- Enable inlay hints for specific filetypes
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "lua", "rust", "python", "typescript", "vue" },
	callback = function()
		pcall(vim.lsp.inlay_hint.enable)
	end,
})

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- 7. FINAL TOUCHES
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

-- Create undo directory if it doesn't exist
local undo_dir = vim.fn.stdpath("data") .. "/undo"
if vim.fn.isdirectory(undo_dir) == 0 then
	vim.fn.mkdir(undo_dir, "p")
end
