" MG Vim Config
set nocompatible

" Core settings
set expandtab
set bs=2
set tabstop=2
set shiftwidth=2
set smartcase
set ignorecase
set modeline
set encoding=utf-8
set nohlsearch
set history=700
set ruler
set nojoinspaces
set shiftround

" Store .swp files in a different directory
set directory=~/.vim/swap//,~/tmp,/var/tmp,/tmp

" Auto-install vim-plug if it doesn't exist
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()

" Yellow-ish color scheme
Plug 'eemed/sitruuna.vim'

" Language support
Plug 'ziglang/zig.vim'
Plug 'rust-lang/rust.vim'
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" Fuzzy finder (for buffers and files)
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

call plug#end()

" Use the custom color scheme
colorscheme sitruuna

" Auto-format files on save
let g:zig_fmt_autosave = 1
let g:rustfmt_autosave = 1

" Use golines if we have it
if executable('golines')
  let g:go_fmt_command = "golines"
endif
