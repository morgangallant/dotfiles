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

require("lazy").setup({
  spec = {
        { "eemed/sitruuna.vim" },
        { "ziglang/zig.vim" },
        { "rust-lang/rust.vim" },
        {
          "nvim-telescope/telescope.nvim",
          tag = "0.1.8",
          dependencies = { "nvim-lua/plenary.nvim" },
        },
  },
  install = { colorscheme = { "habamax" } },
  checker = { enabled = true, notify = false },
})

vim.cmd [[colorscheme sitruuna]]

vim.opt.backspace = [[indent,eol,start]]
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.tabstop = 2

vim.opt.mouse:append('a')

vim.keymap.set('n', '<Left>', ':echoe "Use h"<CR>', { noremap = true })
vim.keymap.set('n', '<Right>', ':echoe "Use l"<CR>', { noremap = true })
vim.keymap.set('n', '<Up>', ':echoe "Use k"<CR>', { noremap = true })
vim.keymap.set('n', '<Down>', ':echoe "Use j"<CR>', { noremap = true })

vim.keymap.set('i', '<Left>', '<ESC>:echoe "Use h"<CR>', { noremap = true })
vim.keymap.set('i', '<Right>', '<ESC>:echoe "Use l"<CR>', { noremap = true })
vim.keymap.set('i', '<Up>', '<ESC>:echoe "Use k"<CR>', { noremap = true })
vim.keymap.set('i', '<Down>', '<ESC>:echoe "Use j"<CR>', { noremap = true })

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
