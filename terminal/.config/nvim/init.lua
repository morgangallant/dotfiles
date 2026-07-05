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

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0

vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250

require("lazy").setup({
  spec = {
    {
      "menduz/sitruuna.vim",
      config = function()
        vim.cmd.colorscheme("sitruuna")
      end,
    },

    {
      "mason-org/mason.nvim",
      opts = {},
    },
    {
      "mason-org/mason-lspconfig.nvim",
      dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
      opts = {

        ensure_installed = { "lua_ls", "rust_analyzer" },
        automatic_enable = true,
      },
    },

    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      dependencies = { "mason-org/mason.nvim" },
      opts = {
        ensure_installed = { "stylua" },
      },
    },

    {
      "folke/lazydev.nvim",
      ft = "lua",
      opts = {
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      },
    },

    {
      "saghen/blink.cmp",
      version = "1.*",
      build = "cargo build --release",
      opts = {
        keymap = {
          preset = "default",
          ["<CR>"] = { "accept", "fallback" },
          ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
          ["<S-Tab>"] = { "snippet_backward", "fallback" },
        },
        fuzzy = {
          prebuilt_binaries = { download = false },
        },
        completion = {
          documentation = { auto_show = true },
        },
        sources = {
          default = { "lsp", "path", "snippets", "buffer", "lazydev" },
          providers = {
            lazydev = {
              name = "LazyDev",
              module = "lazydev.integrations.blink",
              score_offset = 100,
            },
          },
        },
      },
    },

    {
      "neovim/nvim-lspconfig",
      dependencies = { "saghen/blink.cmp" },
      config = function()
        vim.lsp.config("*", {
          capabilities = require("blink.cmp").get_lsp_capabilities(),
        })

        vim.lsp.config("lua_ls", {
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim" } },
              format = { enable = false },
            },
          },
        })

        vim.lsp.config("rust_analyzer", {
          settings = {
            ["rust-analyzer"] = {
              cargo = {
                targetDir = true,
                buildScripts = { enable = true },
              },
              check = { command = "check" },
              procMacro = { enable = true },
              files = {
                excludeDirs = { ".git", "target", ".direnv" },
              },
            },
          },
        })
      end,
    },

    {
      "stevearc/conform.nvim",
      event = { "BufWritePre" },
      cmd = { "ConformInfo" },
      opts = {
        formatters_by_ft = {
          lua = { "stylua" },
        },
        format_on_save = {
          timeout_ms = 2000,
          lsp_format = "fallback",
        },
      },
    },

    {
      "nvim-telescope/telescope.nvim",
      dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      },
      cmd = "Telescope",
      keys = {
        { "<leader>f", "<cmd>Telescope find_files<cr>", desc = "Find files" },
        { "<leader>g", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
        { "<leader>b", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
        { "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", desc = "Search current buffer" },
        { "<leader>?", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
        { "<leader>d", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
        { "<leader>s", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace symbols" },
        { "<leader>S", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
      },
      opts = {},
      config = function(_, opts)
        local telescope = require("telescope")
        telescope.setup(opts)
        pcall(telescope.load_extension, "fzf")
      end,
    },

    {
      "nvim-treesitter/nvim-treesitter",
      branch = "main",
      lazy = false,
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter").install({
          "lua",
          "rust",
          "toml",
          "vim",
          "vimdoc",
          "markdown",
          "markdown_inline",
          "bash",
          "json",
          "yaml",
        })

        vim.api.nvim_create_autocmd("FileType", {
          group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
          callback = function(args)
            if vim.b[args.buf].bigfile then
              return
            end
            pcall(vim.treesitter.start, args.buf)
          end,
        })
      end,
    },

    {
      "folke/which-key.nvim",
      event = "VeryLazy",
      opts = {
        spec = {
          { "<leader>h", group = "git hunks" },
        },
      },
    },

    {
      "lewis6991/gitsigns.nvim",
      event = { "BufReadPre", "BufNewFile" },
      opts = {
        on_attach = function(bufnr)
          local gs = require("gitsigns")
          local function map(keys, fn, desc)
            vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = desc })
          end

          map("]c", function() gs.nav_hunk("next") end, "Next hunk")
          map("[c", function() gs.nav_hunk("prev") end, "Previous hunk")
          map("<leader>hs", gs.stage_hunk, "Stage hunk")
          map("<leader>hr", gs.reset_hunk, "Reset hunk")
          map("<leader>hp", gs.preview_hunk, "Preview hunk")
          map("<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
        end,
      },
    },
  },
  checker = { enabled = true },
})

vim.api.nvim_create_autocmd("BufReadPre", {
  group = vim.api.nvim_create_augroup("bigfile", { clear = true }),
  callback = function(args)
    local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(args.buf))
    if ok and stats and stats.size > 1024 * 1024 then
      vim.b[args.buf].bigfile = true
      vim.bo[args.buf].syntax = "off"
      vim.bo[args.buf].swapfile = false
      vim.opt_local.foldmethod = "manual"
      vim.opt_local.undolevels = -1
    end
  end,
})

vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local bufnr = args.buf
    if vim.b[bufnr].bigfile then
      vim.schedule(function()
        vim.lsp.buf_detach_client(bufnr, args.data.client_id)
      end)
      return
    end
    local function map(keys, fn, desc)
      vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = "LSP: " .. desc })
    end

    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("gr", vim.lsp.buf.references, "References")
    map("gi", vim.lsp.buf.implementation, "Go to implementation")
    map("K", vim.lsp.buf.hover, "Hover docs")
    map("<leader>rn", vim.lsp.buf.rename, "Rename")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("<leader>e", vim.diagnostic.open_float, "Show diagnostic")
    map("[d", function()
      vim.diagnostic.jump({ count = -1 })
    end, "Previous diagnostic")
    map("]d", function()
      vim.diagnostic.jump({ count = 1 })
    end, "Next diagnostic")
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("rust_prewarm", { clear = true }),
  callback = function()
    local root = vim.fs.root(vim.fn.getcwd(), { "Cargo.toml", "rust-project.json" })
    if not root then
      return
    end
    local config = vim.lsp.config["rust_analyzer"]
    if not config then
      return
    end
    vim.lsp.start(vim.tbl_extend("force", config, { root_dir = root }), { attach = false })
  end,
})
