let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

let &t_SI.="\e[5 q" 
let &t_SR.="\e[4 q"
let &t_EI.="\e[1 q"

call plug#begin('~/.vim/plugged')
    Plug 'eemed/sitruuna.vim'
    Plug 'ziglang/zig.vim'
    Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
    Plug 'junegunn/fzf.vim'
    Plug 'vim-airline/vim-airline'
call plug#end()

let g:zig_fmt_autosave = 1

syntax on
filetype on
set re=2
set expandtab
set bs=2
set tabstop=2
set shiftwidth=2
set autoindent
set smartindent
set smartcase
set ignorecase
set modeline
set nocompatible
set encoding=utf-8
set nohlsearch
set history=700
set t_Co=256
set termguicolors
set background=dark
set tabpagemax=1000
set ruler
set nojoinspaces
set shiftround
set relativenumber
set nonumber

nmap <C-p> :Files<CR>
nmap <C-b> :Buffers<CR>
nmap <C-l> :bnext<CR>
nmap <C-h> :bprev<CR>

noremap <Up> <Nop>
noremap <Down> <Nop>
noremap <Left> <Nop>
noremap <Right> <Nop>

set laststatus=2
set noshowmode
let g:airline_symbols = {}
let g:airline_left_sep = ''
let g:airline_right_sep = ''
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = '+++'
let g:airline#extensions#whitespace#enabled = 0
let g:airline#extensions#hunks#non_zero_only = 1
let g:airline#extensions#tabline#enabled = 1

" Autowrap markdown files to 80 characters on save
au BufRead,BufNewFile *.md setlocal textwidth=80
