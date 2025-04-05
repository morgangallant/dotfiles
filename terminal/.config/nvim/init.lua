-- MG Neovim Config
-- Inspirations:
-- - https://github.com/pushrax
-- - https://github.com/andrewrk
-- - https://github.com/jonhoo

-- Leader mapping
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Basic vim options
vim.cmd('syntax on')
vim.cmd('filetype on')
vim.opt.expandtab = true
vim.opt.bs = '2'
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.modeline = true
vim.opt.compatible = false
vim.opt.encoding = 'utf-8'
vim.opt.hlsearch = false
vim.opt.history = 700
vim.opt.termguicolors = true
vim.opt.background = 'dark'
vim.opt.tabpagemax = 1000
vim.opt.ruler = true
vim.opt.shiftround = true
vim.opt.relativenumber = true
vim.opt.number = false
vim.opt.showtabline = 2

-- Show rulers for particular languages
vim.api.nvim_create_autocmd('Filetype', { pattern = 'rust', command = 'set colorcolumn=100' })
vim.api.nvim_create_autocmd('Filetype', { pattern = 'zig', command = 'set colorcolumn=100' })

-- Navigating buffers
vim.keymap.set('', '<C-h>', '<cmd>bprevious<cr>')
vim.keymap.set('', '<C-l>', '<cmd>bnext<cr>')

-- Enforcing good habits
vim.keymap.set('n', '<Left>', ':echoe "Use h"<CR>', { noremap = true })
vim.keymap.set('n', '<Right>', ':echoe "Use l"<CR>', { noremap = true })
vim.keymap.set('n', '<Up>', ':echoe "Use k"<CR>', { noremap = true })
vim.keymap.set('n', '<Down>', ':echoe "Use j"<CR>', { noremap = true })
vim.keymap.set('i', '<Left>', '<ESC>:echoe "Use h"<CR>', { noremap = true })
vim.keymap.set('i', '<Right>', '<ESC>:echoe "Use l"<CR>', { noremap = true })
vim.keymap.set('i', '<Up>', '<ESC>:echoe "Use k"<CR>', { noremap = true })
vim.keymap.set('i', '<Down>', '<ESC>:echoe "Use j"<CR>', { noremap = true })

-- Bootstrap lazy.nvim, will auto-install if missing
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

-- Install and configure plugins
require("lazy").setup({
  spec = {
    -- Color scheme
    { "eemed/sitruuna.vim" },

    -- Zig
    {
      "ziglang/zig.vim",
      ft = { "zig" },
      config = function()
        vim.g.zig_fmt_autosave = 0
        vim.g.zig_fmt_parse_errors = 0
      end
    },

    -- Rust
    {
      "rust-lang/rust.vim",
      ft = { "rust" },
      config = function()
        vim.g.rustfmt_autosave = 1
        vim.g.rustfmt_emit_files = 1
        vim.g.rustfmt_fail_silently = 0
        vim.g.rust_clip_command = "wl-copy"
      end
    },

    -- Lightline for status bar
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

    -- LSP
    {
      "neovim/nvim-lspconfig",
      config = function()
        local lspconfig = require('lspconfig')

        -- Zig
        lspconfig.zls.setup {
          settings = {
            zls = {
              semantic_tokens = "partial"
            }
          }
        }

        -- Rust
        lspconfig.rust_analyzer.setup {
          settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true
              },
              imports = {
                group = {
                  enable = true,
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

        -- Global mappings
        vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
			  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
			  vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
			  vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

        -- Configure keymaps after the language server attaches to the buffer
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('UserLspConfig', {}),
          callback = function(ev)
            vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

            -- Buffer local mappings
            local opts = { buffer = ev.buf }
            vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
					  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
					  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
					  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
            vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
            vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, opts)
            vim.keymap.set({ 'n', 'v' }, '<leader>a', vim.lsp.buf.code_action, opts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            vim.keymap.set('n', '<leader>f', function()
						  vim.lsp.buf.format { async = true }
					  end, opts)

            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            client.server_capabilities.semanticTokensProvider = nil
          end
        })
      end
    },

    -- LSP based code completion
    {
      "hrsh7th/nvim-cmp",
      event = "InsertEnter",
      dependencies = {
			  "neovim/nvim-lspconfig",
			  "hrsh7th/cmp-nvim-lsp",
			  "hrsh7th/cmp-buffer",
			  "hrsh7th/cmp-path",
		  },
      config = function()
        local cmp = require 'cmp'
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
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp" },
          }, {
            { name = "path" },
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

    -- Telescope for fuzzy matching
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
  },
  checker = { enabled = true },
})

-- Colorscheme
vim.cmd [[colorscheme sitruuna]]

-- Format Zig with ZLS
vim.api.nvim_create_autocmd('BufWritePre',{
  pattern = {"*.zig", "*.zon"},
  callback = function(ev)
    vim.lsp.buf.format()
  end
})

-- Jump to the last edit position on opening a file.
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
