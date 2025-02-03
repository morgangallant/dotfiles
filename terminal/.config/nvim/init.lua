-- MG Neovim Config
-- Inspired by:
-- - https://github.com/pushrax
-- - https://github.com/andrewrk
-- - https://github.com/jonhoo

-- Leader set first
vim.keymap.set("n", "<Space>", "<Nop>", { silent = true })
vim.g.mapleader = " "

-- Preferences
vim.opt.foldenable = false
vim.opt.foldmethod = 'manual'
vim.opt.foldlevelstart = 99
vim.opt.scrolloff = 2
vim.opt.wrap = false
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.undofile = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4
vim.opt.showtabline = 2
vim.opt.expandtab = false
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.vb = true
vim.opt.colorcolumn = '80'
vim.api.nvim_create_autocmd('Filetype', { pattern = 'rust', command = 'set colorcolumn=100' })
vim.api.nvim_create_autocmd('Filetype', { pattern = 'zig', command = 'set colorcolumn=100' })
vim.opt.listchars = 'tab:^ ,nbsp:¬,extends:»,precedes:«,trail:•'

-- Hotkeys

vim.keymap.set('', '<C-p>', '<cmd>Files<cr>')
vim.keymap.set('n', '<leader>;', '<cmd>Buffers<cr>')
vim.keymap.set('n', '<leader>w', '<cmd>w<cr>')
vim.keymap.set('n', ';', ':')
vim.keymap.set('v', '<C-h>', '<cmd>nohlsearch<cr>')
vim.keymap.set('n', '<C-h>', '<cmd>nohlsearch<cr>')
vim.keymap.set('', 'H', '^')
vim.keymap.set('', 'L', '$')

vim.keymap.set('', '<C-j>', '<cmd>bprevious<cr>')
vim.keymap.set('', '<C-k>', '<cmd>bnext<cr>')

vim.keymap.set('n', '<Left>', ':echoe "Use h"<CR>', { noremap = true })
vim.keymap.set('n', '<Right>', ':echoe "Use l"<CR>', { noremap = true })
vim.keymap.set('n', '<Up>', ':echoe "Use k"<CR>', { noremap = true })
vim.keymap.set('n', '<Down>', ':echoe "Use j"<CR>', { noremap = true })

vim.keymap.set('i', '<Left>', '<ESC>:echoe "Use h"<CR>', { noremap = true })
vim.keymap.set('i', '<Right>', '<ESC>:echoe "Use l"<CR>', { noremap = true })
vim.keymap.set('i', '<Up>', '<ESC>:echoe "Use k"<CR>', { noremap = true })
vim.keymap.set('i', '<Down>', '<ESC>:echoe "Use j"<CR>', { noremap = true })

-- Autocommands

-- Jump to last edit position on opening file
vim.api.nvim_create_autocmd(
	'BufReadPost',
	{
		pattern = '*',
		callback = function(ev)
			if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
				if not vim.fn.expand('%:p'):find('.git', 1, true) then
					vim.cmd('exe "normal! g\'\\""')
				end
			end
		end
	}
)

-- Plugins

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	spec = {
		{ "eemed/sitruuna.vim" },
		{
			'itchyny/lightline.vim',
			dependencies = { "mengelbrecht/lightline-bufferline" },
			lazy = false,
			config = function()
				vim.o.showmode = false
				vim.g.lightline = {
					colorscheme = "one",
					active = {
						left = {
							{ 'mode', 'paste' },
							{ 'readonly', 'filename', 'modified' }
						},
						right = {
							{ 'lineinfo' },
							{ 'percent' },
							{ 'fileencoding', 'filetype' }
						},
					},
					tabline = { left = { { "buffers" } }, right = { {} } },
					component_expand = { buffers = "lightline#bufferline#buffers" },
					component_type = { buffers = "tabsel" },
					component_function = {
						filename = 'LightlineFilename'
					},
				}
				function LightlineFilenameInLua(opts)
					if vim.fn.expand('%:t') == '' then
						return '[No Name]'
					else
						return vim.fn.getreg('%')
					end
				end
				vim.api.nvim_exec(
					[[
					function! g:LightlineFilename()
						return v:lua.LightlineFilenameInLua()
					endfunction
					]],
					true
				)
				vim.g["lightline#bufferline#modified"] = " ★"
				vim.g["lightline#bufferline#read_only"] = " "
			end
		},
		{
			'ggandor/leap.nvim',
			config = function()
				require('leap').create_default_mappings()
			end
		},
		{
			'notjedi/nvim-rooter.lua',
			config = function()
				require('nvim-rooter').setup()
			end
		},
		{
			'nvim-telescope/telescope.nvim',
			tag = "0.1.8",
			dependencies = { "nvim-lua/plenary.nvim" },
			config = function()
				local builtin = require('telescope.builtin')
				vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
				vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
				vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
				vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
			end
		},
		{
			'neovim/nvim-lspconfig',
			config = function()
				local lspconfig = require('lspconfig')

				-- Rust
				lspconfig.rust_analyzer.setup {
					settings = {
						["rust-analyzer"] = {
							cargo = {
								allFeatures = true,
							},
							imports = {
								group = {
									enable = false,
								},
							},
							completion = {
								postfix = {
									enable = false,
								},
							},
						},
					},
				}

				-- Zig
				lspconfig.zls.setup {
					cmd = { '/Users/mg/src/zls-0.13.0/zig-out/bin/zls' },
				}

				-- Bash
				local configs = require 'lspconfig.configs'
				if not configs.bash_lsp and vim.fn.executable('base-language-server') == 1 then
					configs.bash_lsp = {
						default_config = {
							cmd = { 'bash-language-server', 'start' },
							filetypes = { 'sh' },
							root_dir = require('lspconfig').util.find_git_ancestor,
							init_options = {
								settings = {
									args = {}
								}
							}
						}
					}
				end
				if configs.bash_lsp then
					lspconfig.bash_lsp.setup {}
				end

				-- Ruff for Python
				local configs = require 'lspconfig.configs'
				if not configs.ruff_lsp and vim.fn.executable('ruff-lsp') == 1 then
					configs.ruff_lsp = {
						default_config = {
							cmd = { 'ruff-lsp' },
							filetypes = { 'python' },
							root_dir = require('lspconfig').util.find_git_ancestor,
							init_options = {
								settings = {
									args = {}
								}
							}
						}
					}
				end
				if configs.ruff_lsp then
					lspconfig.ruff_lsp.setup {}
				end

				-- Global mappings
				vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
				vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
				vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
				vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

				-- Attaching keys after language server attach
				vim.api.nvim_create_autocmd('LspAttach', {
					group = vim.api.nvim_create_augroup('UserLspConfig', {}),
					callback = function(ev)
						vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

						local opts = { buffer = ev.buf }
						vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
						vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
						vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
						vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
						vim.keymap.set('n', '<C-s>', vim.lsp.buf.signature_help, opts)
						vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, opts)
						vim.keymap.set({ 'n', 'v' }, '<leader>a', vim.lsp.buf.code_action, opts)
						vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
						vim.keymap.set('n', '<leader>f', function()
							vim.lsp.buf.format { async = true }
						end, opts)

						local client = vim.lsp.get_client_by_id(ev.data.client_id)
						client.server_capabilities.semanticTokensProvider = nil
					end,
				})
			end
		},
		{
			'hrsh7th/nvim-cmp',
			event = "InsertEnter",
			dependencies = {
				'neovim/nvim-lspconfig',
				'hrsh7th/cmp-nvim-lsp',
				'hrsh7th/cmp-buffer',
				'hrsh7th/cmp-path',
			},
			config = function()
				local cmp = require'cmp'
				cmp.setup({
					snippet = {
						expand = function(args)
							vim.fn["vsnip#anonymous"](args.body)
						end,
					},
					mapping = cmp.mapping.preset.insert({
						['<C-b>'] = cmp.mapping.scroll_docs(-4),
						['<C-f>'] = cmp.mapping.scroll_docs(4),
						['<C-Space>'] = cmp.mapping.complete(),
						['<C-e>'] = cmp.mapping.abort(),
						['<CR>'] = cmp.mapping.confirm({select = true }),
					}),
					sources = cmp.config.sources({
						{ name = 'nvim_lsp' },
					}, {
						{ name = 'path' },
					}),
					experimental = {
						ghost_text = true,
					},
				})
				cmp.setup.cmdline(':', {
					sources = cmp.config.sources({
						{ name = 'path' }
					})
				})
			end
		},
		{
			'ray-x/lsp_signature.nvim',
			event = "VeryLazy",
			opts = {},
			config = function(_, opts)
				require "lsp_signature".setup({
					doc_lines = 0,
					handler_opts = {
						border = "none"
					},
				})
			end
		},
		{ 'cespare/vim-toml' },
		{
			'cuducos/yaml.nvim',
			ft = { 'yaml' },
			dependencies = {
				'nvim-treesitter/nvim-treesitter',
			},
		},
		{
			'rust-lang/rust.vim',
			ft = { "rust" },
			config = function()
				vim.g.rustfmt_autosave = 1
				vim.g.rustfmt_emit_files = 1
				vim.g.rustfmt_fail_silently = 0
				vim.g.rust_clip_command = 'wl-copy'
			end
		},
		{ 'ziglang/zig.vim' },
		{
			'plasticboy/vim-markdown',
			ft = { "markdown" },
			dependencies = {
				'godlygeek/tabular',
			},
			config = function()
				vim.g.vim_markdown_folding_disabled = 1
				vim.g.vim_markdown_frontmatter = 1
				vim.g.vim_markdown_new_list_item_indent = 0
				vim.g.vim_markdown_auto_insert_bullets = 0
			end
		}
	},
	checker = { enabled = false }
})

vim.cmd [[colorscheme sitruuna]]
