-- MG Neovim Configuration
-- Last updated: March 1st, 2026

-- set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- tab / backspace configuration
-- TL;DR two characters, auto-indent properly, make backspaces work nicely
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.bs = '2'

-- better search defaults
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.hlsearch = false

-- when yanking something, use the system clipboard
-- on macos, this will use pbcopy/pbpaste
vim.opt.clipboard = 'unnamedplus'

-- lazy.nvim initialization needs to happen after the basic vim configuration
-- is done, e.g. specificially after `mapleader` and `maplocalleader`.
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

-- configuration for telescope (fuzzy file finder)
local telescopeConfig = function()
  local builtin = require("telescope.builtin")
  vim.keymap.set('n', '<leader>ff', builtin.find_files)
  vim.keymap.set('n', '<leader>fg', builtin.live_grep)
  vim.keymap.set('n', '<leader>fb', builtin.buffers)
end

-- completion engine config
-- this is needed for showing LSP autocomplete
local cmpConfig = function()
  local cmp = require('cmp')
  cmp.setup({
    sources = {
      { name = 'nvim_lsp' }
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }),
      ['<C-n>'] = cmp.mapping.select_next_item(),
      ['<C-p>'] = cmp.mapping.select_prev_item(),
    })
  })
end

-- lsp config
local lspConfig = function()
  local lspconfig = require('lspconfig')
  local capabilities = require('cmp_nvim_lsp').default_capabilities()

  -- setup keybinds
  vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
      local buf = args.buf
      local opts = { buffer = buf }

      -- navigation
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
      vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
      vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
      vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, opts)

      -- info
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
      vim.keymap.set('n', '<leader>k', vim.lsp.buf.signature_help, opts)

      -- actions
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
      vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
      vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format({ async = true }) end, opts)

      -- diagnostics
      vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
      vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
      vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)
    end
  })

  -- rust
  lspconfig.rust_analyzer.setup {
    capabilities = capabilities,
    settings = {
      ["rust-analyzer"] = {
        check = {
          command = "clippy"
        },
        cargo = {
          targetDir = true,
          buildScripts = {
            enable = true
          }
        },
        diagnostics = {
          disabled = { "unresolved-proc-macro" }
        },
        numThreads = 4
      }
    }
  }
end

-- load plugins with lazy.nvim
require("lazy").setup({
  spec = {
    {
      'eemed/sitruuna.vim',
      config = function()
        vim.cmd("colorscheme sitruuna")
      end,
    },
    { 'nvim-lua/plenary.nvim' },
    {
      'nvim-telescope/telescope.nvim',
      config = telescopeConfig
    },
    { 'hrsh7th/cmp-nvim-lsp' },
    {
      'hrsh7th/nvim-cmp',
      config = cmpConfig
    },
    {
      'neovim/nvim-lspconfig',
      config = lspConfig
    },
    { 'github/copilot.vim' }
  },
  defaults = {
    version = false
  },
  checker = {
    enabled = true,
    notify = false
  }
})

-- autoformat files on save using lsp
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.rs' },
  callback = function()
    vim.lsp.buf.format()
    vim.lsp.buf.code_action { context = { only = { 'source.organizeImports' } }, apply = true }
    vim.lsp.buf.code_action { context = { only = { 'source.fixAll' } }, apply = true }
  end
})
