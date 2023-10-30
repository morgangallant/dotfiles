set nocompatible

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')
	Plug 'ziglang/zig.vim'
call plug#end()

let g:zig_fmt_autosave = 1

filetype plugin indent on
syntax on

set autoindent
set softtabstop=4
set shiftwidth=4
set shiftround

set backspace=indent,eol,start
set hidden
set laststatus=2
set display=lastline

set showmode
set showcmd

set incsearch
set hlsearch

set ttyfast
set lazyredraw

set splitbelow
set splitright

set wrapscan
set report=0
set synmaxcol=100

set relativenumber

set nohlsearch

set list
if has('multi_byte') && &encoding ==# 'utf-8'
  let &listchars = 'tab:▸ ,extends:❯,precedes:❮,nbsp:±'
else
  let &listchars = 'tab:> ,extends:>,precedes:<,nbsp:.'
endif

if &shell =~# 'fish$'
  set shell=/bin/bash
endif

" Configure line wrapping for markdown files
augroup Markdown
    autocmd!
    autocmd FileType markdown set wrap
augroup END
