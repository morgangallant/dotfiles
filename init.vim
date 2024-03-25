set nocompatible

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
    Plug 'ziglang/zig.vim'
    Plug 'rust-lang/rust.vim'
    Plug 'fatih/vim-go', { 'do': ':GoInstallBinaries' }
    Plug 'junegunn/fzf'
    Plug 'junegunn/fzf.vim'
    Plug 'neoclide/coc.nvim', { 'do': 'npm ci' }
call plug#end()

let g:zig_fmt_autosave = 1
let g:go_fmt_command = "golines"
let g:rustfmt_autosave = 1

filetype plugin indent on
syntax on

set autoindent
set softtabstop=4
set shiftwidth=4
set shiftround

set relativenumber
set ruler
set number
set ignorecase
set smartcase
set nohlsearch
set wrap

inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"
