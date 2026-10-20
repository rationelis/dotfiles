-- Neovim >= 0.12 only.
--
-- Ownership map (one owner per responsibility):
--   Rust LSP + Cargo/Clippy ........ rustaceanvim (the ONLY thing that starts rust-analyzer)
--   Every other language server .... vim.lsp.config / vim.lsp.enable (definitions come from nvim-lspconfig)
--   Installing external tools ...... mason.nvim (rust toolchain tools come from rustup, not Mason)
--   Completion / signature help .... Neovim's built-in LSP completion
--   Syntax highlighting ............ Neovim's built-in tree-sitter (nvim-treesitter only supplies parsers + queries)
--   Formatting ..................... conform.nvim (formatters), never LSP formatting
--   Linting ........................ language servers (rust-analyzer/clippy, ruff, eslint, pyright)

if vim.fn.has("nvim-0.12") == 0 then
	vim.notify("This config requires Neovim >= 0.12", vim.log.levels.ERROR)
	return
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set
local augroup = vim.api.nvim_create_augroup("user", { clear = true })

-- ── Data: what gets installed ──────────────────────────────────────

-- Tree-sitter parsers installed by nvim-treesitter. Parsers that Neovim ships
-- itself (c, lua, vim, vimdoc, query, markdown) are deliberately not listed.
local parsers = {
	"rust",
	"toml",
	"javascript",
	"typescript",
	"tsx",
	"python",
	"json",
	"yaml",
	"bash",
	"html",
	"css",
}

-- Mason package names (not lspconfig names). rust-analyzer, rustfmt and clippy
-- come from rustup: Mason's rust-analyzer would not match your toolchain.
local mason_tools = {
	"lua-language-server",
	"stylua",
	"typescript-language-server",
	"eslint-lsp",
	"prettier",
	"pyright",
	"ruff",
}

-- lspconfig server names enabled through vim.lsp.enable().
-- Never add "rust_analyzer" here: rustaceanvim owns rust-analyzer.
local lsp_servers = { "lua_ls", "ts_ls", "eslint", "pyright", "ruff" }

-- ── Options ────────────────────────────────────────────────────────

local opt = vim.opt

opt.guicursor = ""
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.colorcolumn = "80"
opt.scrolloff = 8
opt.winborder = "single"

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.expandtab = true

opt.hlsearch = false

opt.swapfile = false
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undo" -- Nvim creates it on first write

opt.updatetime = 250
opt.isfname:append("@-@")

-- Completion: the popup opens as you type and is refreshed on <BS>.
-- "o" = omnifunc, which Neovim sets to the LSP client on attach; "." = current
-- buffer words (limited to 5). Select with <C-n>/<C-p> (or Up/Down while the
-- popup is open), accept with <C-y>.
opt.autocomplete = true
opt.complete = "o,.^5"
opt.completeopt = { "menu", "menuone", "noselect", "popup" }

-- ── Keymaps (LSP keymaps gra/grn/grr/gri/grt/gO/K/<C-s> are built in) ──

map("n", "<leader>pv", "<cmd>Ex<CR>", { desc = "File explorer" })
map("n", "<leader>di", vim.diagnostic.open_float, { desc = "Diagnostics float" })
map("n", "<leader>u", function()
	vim.cmd.packadd("nvim.undotree") -- bundled with Neovim 0.12, replaces the undotree plugin
	vim.cmd.Undotree()
end, { desc = "Undo tree" })

-- Hard mode: arrow keys are disabled, except Up/Down move through the completion popup.
for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
	map({ "n", "v" }, key, "<Nop>")
	map("i", key, "<Nop>")
end
-- <CR>: accept the selected completion item, otherwise close the popup and insert a newline.
map("i", "<CR>", function()
	if vim.fn.pumvisible() == 0 then
		return "<CR>"
	end
	return vim.fn.complete_info({ "selected" }).selected >= 0 and "<C-y>" or "<C-e><CR>"
end, { expr = true })
map("i", "<Down>", function()
	return vim.fn.pumvisible() == 1 and "<C-n>" or ""
end, { expr = true })
map("i", "<Up>", function()
	return vim.fn.pumvisible() == 1 and "<C-p>" or ""
end, { expr = true })

-- Indent: 2 spaces for the web stack.
vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact", "json", "yaml", "html", "css" },
	callback = function()
		vim.bo.shiftwidth = 2
		vim.bo.tabstop = 2
		vim.bo.softtabstop = 2
	end,
})

-- ── lazy.nvim bootstrap ────────────────────────────────────────────

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
		vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n" .. (out.stderr or ""), "ErrorMsg" } }, true, {})
		return
	end
end
opt.rtp:prepend(lazypath)

-- ── Plugins ────────────────────────────────────────────────────────

require("lazy").setup({
	{
		"EdenEast/nightfox.nvim",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("nightfox")
		end,
	},

	-- Tree-sitter: provides parsers and queries only. Highlighting is started
	-- by the FileType autocmd below (the plugin does not do it for you).
	-- The plugin does not support lazy-loading.
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")
			local installed = ts.get_installed("parsers")
			local missing = vim.tbl_filter(function(lang)
				return not vim.list_contains(installed, lang)
			end, parsers)
			if #missing > 0 then
				ts.install(missing) -- async; only runs when something is actually missing
			end
		end,
	},

	-- Provides the lsp/<server>.lua definitions used by vim.lsp.enable().
	-- It is not set up and never starts anything on its own.
	{ "neovim/nvim-lspconfig" },

	-- Installs tools only; no mason-lspconfig / mason-tool-installer needed.
	{
		"mason-org/mason.nvim",
		lazy = false, -- must run at startup so Mason's bin dir is on $PATH before the first LSP starts
		opts = {},
		config = function(_, opts)
			require("mason").setup(opts)
			vim.api.nvim_create_autocmd("VimEnter", {
				group = augroup,
				once = true,
				callback = function()
					-- is_installed() is a plain directory check: no network, no registry load.
					local registry = require("mason-registry")
					local missing = vim.tbl_filter(function(name)
						return not registry.is_installed(name)
					end, mason_tools)
					if #missing > 0 then
						vim.cmd("MasonInstall " .. table.concat(missing, " "))
					end
				end,
			})
		end,
	},

	-- Rust: starts and owns rust-analyzer. Needs no setup() or lspconfig.
	-- Clippy-on-save is enabled automatically when `cargo clippy` exists.
	{
		"mrcjkb/rustaceanvim",
		version = "^9",
		lazy = false, -- already lazy by design (filetype plugin)
	},

	-- Cargo.toml: dependency versions/features/upgrade actions through an in-process LSP.
	{
		"Saecki/crates.nvim",
		event = "BufRead Cargo.toml",
		opts = {
			lsp = { enabled = true, actions = true, completion = true, hover = true },
		},
	},

	-- Formatting: conform is the only thing that formats. Each filetype lists
	-- its formatters explicitly and LSP formatting is never used, so tools
	-- cannot compete with each other.
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				rust = { "rustfmt" },
				lua = { "stylua" },
				python = { "ruff_organize_imports", "ruff_format" },
				javascript = { "prettier" },
				javascriptreact = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
				json = { "prettier" },
				jsonc = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				scss = { "prettier" },
			},
			format_on_save = function(bufnr)
				if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then
					return
				end
				return { timeout_ms = 2000, lsp_format = "never" }
			end,
		},
		config = function(_, opts)
			require("conform").setup(opts)
			map({ "n", "v" }, "<leader>cf", function()
				require("conform").format({ async = true, lsp_format = "never" })
			end, { desc = "Format buffer" })
			vim.api.nvim_create_user_command("AutoformatToggle", function()
				vim.g.autoformat = vim.g.autoformat == false
				vim.notify("Autoformat on save: " .. tostring(vim.g.autoformat ~= false))
			end, { desc = "Toggle format on save" })
		end,
	},

	-- Navigation / search
	{
		"nvim-telescope/telescope.nvim",
		version = "*",
		dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
		cmd = "Telescope",
		keys = {
			{
				"<leader>pf",
				function()
					require("telescope.builtin").find_files()
				end,
				desc = "Find files",
			},
			{
				"<leader>ps",
				function()
					require("telescope.builtin").live_grep()
				end,
				desc = "Live grep",
			},
			{
				"<leader>pb",
				function()
					require("telescope.builtin").buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>po",
				function()
					require("telescope.builtin").lsp_document_symbols()
				end,
				desc = "Document symbols",
			},
			{
				"<leader>pd",
				function()
					require("telescope.builtin").diagnostics({
						bufnr = 0,
						layout_strategy = "vertical",
						layout_config = { height = 0.8, width = 0.8, preview_cutoff = 0, prompt_position = "top" },
						sorting_strategy = "ascending",
					})
				end,
				desc = "Buffer diagnostics",
			},
		},
		opts = {},
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
			end, { desc = "Harpoon: add file" })
			map("n", "<C-e>", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end, { desc = "Harpoon: menu" })
			map("n", "<C-h>", function()
				harpoon:list():prev()
			end, { desc = "Harpoon: previous" })
			map("n", "<C-l>", function()
				harpoon:list():next()
			end, { desc = "Harpoon: next" })
		end,
	},

	-- Git
	{ "tpope/vim-fugitive", cmd = { "Git", "G" }, keys = { { "<leader>gs", "<cmd>Git<CR>", desc = "Git status" } } },

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
			on_attach = function(bufnr)
				local gs = require("gitsigns")
				local function bmap(lhs, rhs, desc)
					map("n", lhs, rhs, { buffer = bufnr, desc = desc })
				end
				bmap("]h", function()
					gs.nav_hunk("next")
				end, "Next hunk")
				bmap("[h", function()
					gs.nav_hunk("prev")
				end, "Previous hunk")
				bmap("<leader>hp", gs.preview_hunk, "Preview hunk")
				bmap("<leader>hs", gs.stage_hunk, "Stage hunk")
				bmap("<leader>hr", gs.reset_hunk, "Reset hunk")
				bmap("<leader>hb", gs.blame_line, "Blame line")
			end,
		},
	},

	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = { component_separators = "", section_separators = "" },
			sections = { lualine_x = { "filetype" } },
		},
	},

	-- Optional extras, loaded only on demand.
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

	{
		"kristijanhusak/vim-dadbod-ui",
		dependencies = { { "tpope/vim-dadbod", lazy = true } },
		cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
		init = function()
			vim.g.db_ui_use_nerd_fonts = 1
		end,
	},
}, {
	checker = { enabled = false }, -- no background git fetches; use :Lazy update when you want to
	change_detection = { notify = false },
	rocks = { enabled = false },
	install = { colorscheme = { "nightfox" } },
	performance = {
		rtp = { disabled_plugins = { "gzip", "matchit", "matchparen", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
	},
})

-- ── Tree-sitter highlighting ───────────────────────────────────────

vim.api.nvim_create_autocmd("FileType", {
	group = augroup,
	callback = function(args)
		local lang = vim.treesitter.language.get_lang(args.match)
		-- language.add() returns nil (no error) when the parser is not installed.
		if lang and vim.list_contains(parsers, lang) and vim.treesitter.language.add(lang) then
			vim.treesitter.start(args.buf, lang)
		end
	end,
})

-- ── LSP ────────────────────────────────────────────────────────────

-- Capabilities: Neovim's defaults already advertise snippets, resolveSupport,
-- etc. for its built-in completion, and rustaceanvim extends the same defaults,
-- so no per-server capability plumbing is needed.

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
		},
	},
})

-- Pyright does type checking; Ruff does linting, import sorting and formatting.
vim.lsp.config("pyright", {
	settings = { pyright = { disableOrganizeImports = true } }, -- Ruff owns import sorting
})
vim.lsp.config("ruff", {
	on_attach = function(client)
		client.server_capabilities.hoverProvider = false -- Pyright owns hover (documented by Ruff)
	end,
})

vim.lsp.enable(lsp_servers)
vim.lsp.inlay_hint.enable(true)

vim.diagnostic.config({
	virtual_text = true,
	severity_sort = true,
	float = { source = true },
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = augroup,
	callback = function(args)
		local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
		local buf = args.buf

		if client:supports_method("textDocument/completion") then
			vim.lsp.completion.enable(true, client.id, buf, { autotrigger = true })
		end

		map("n", "gd", vim.lsp.buf.definition, { buffer = buf, desc = "Go to definition" })
		map("i", "<C-Space>", vim.lsp.completion.get, { buffer = buf, desc = "Trigger completion" })

		if client.name == "rust-analyzer" then
			local function rmap(lhs, cmd, desc)
				map("n", lhs, function()
					vim.cmd.RustLsp(cmd)
				end, { buffer = buf, desc = desc })
			end
			rmap("gra", "codeAction", "Code action (grouped)")
			rmap("K", { "hover", "actions" }, "Hover actions")
			rmap("<leader>rr", "runnables", "Rust: runnables")
			rmap("<leader>rt", "testables", "Rust: testables")
			rmap("<leader>re", "explainError", "Rust: explain error")
			rmap("<leader>rd", "renderDiagnostic", "Rust: rendered diagnostic")
			rmap("<leader>rm", "expandMacro", "Rust: expand macro")
			rmap("<leader>rc", "openCargo", "Rust: open Cargo.toml")
			rmap("<leader>rp", "parentModule", "Rust: parent module")
		end
	end,
})
