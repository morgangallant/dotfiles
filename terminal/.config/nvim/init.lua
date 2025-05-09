-- mg neovim config

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.bs = '2'
vim.opt.tabstop = 2
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.smartcase = true
vim.opt.ignorecase = true
vim.opt.compatible = false
vim.opt.encoding = 'utf-8'
vim.opt.hlsearch = false
vim.opt.relativenumber = true

-- configure lazy.nvim to install itself on first startup
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

-- nvim-lspconfig configuration
local nvim_lsp_config_func = function()
  local lspconfig = require("lspconfig")

  -- Go
  lspconfig.gopls.setup {}

  -- Rust
  lspconfig.rust_analyzer.setup {
    on_attach = on_attach,
    settings = {
      ["rust-analyzer"] = {
        checkOnSave = {
          command = "clippy",
        },
        imports = {
          granularity = {
            group = "module",
          },
          prefix = "self",
        },
        procMacro = {
          enable = true,
        },
      },
    },
  }


  vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next)

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
      vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

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

-- nvim-cmp configuration
local nvim_cmp_config_func = function()
  local cmp = require("cmp")
  cmp.setup({
    snippet = {
      expand = function(args)
        vim.fn["vsnip#anonymous"](args.body)
      end,
     },
     mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['C-Space>'] = cmp.mapping.complete(),
        ['C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
      }),
      sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'vsnip' },
        { name = 'buffer' },
        { name = 'path' }
      }),
      experimental = {
        ghost_text = false,
      },
    })
end

-- telescope.nvim configuration
local telescope_config_func = function()
  local builtin = require("telescope.builtin")
  vim.keymap.set('n', '<leader>ff', builtin.find_files)
  vim.keymap.set('n', '<leader>fg', builtin.live_grep)
  vim.keymap.set('n', '<leader>fb', builtin.buffers)
  vim.keymap.set('n', '<leader>fh', builtin.help_tags)
end

-- copilot.lua configuration
local copilot_config_func = function()
  require("copilot").setup({
    suggestion = {
      auto_trigger = true,
      keymap = {
        accept = "<Tab>",
      },
    },
  })
end

-- load plugins
require("lazy").setup({
	spec = {
    { "nvim-lua/plenary.nvim" },
    {
      "neovim/nvim-lspconfig",
      config = nvim_lsp_config_func,
    },
    {
      "hrsh7th/nvim-cmp",
      event = "InsertEnter",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
      },
      config = nvim_cmp_config_func,
    },
    {
      "nvim-telescope/telescope.nvim",
      tag = "0.1.8",
      config = telescope_config_func,
    },
    {
      "zbirenbaum/copilot.lua",
      cmd = "Copilot",
      event = "InsertEnter",
      config = copilot_config_func,
    },
	},
	defaults = {
		version = false,
	},
	install = { colorscheme = { "tokyonight", "habamax" } },
	checker = {
		enabled = true,
		notify = false,
	},
})

-- autoformat certain files on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.go", "*.rs" },
  callback = function(ev)
    vim.lsp.buf.format()
    vim.lsp.buf.code_action { context = { only = { 'source.organizeImports' } }, apply = true }
    vim.lsp.buf.code_action { context = { only = { 'source.fixAll' } }, apply = true }
  end
})
