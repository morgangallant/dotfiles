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

" LSP support
Plug 'neoclide/coc.nvim', {'branch': 'release'}

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

" CoC settings
set hidden
set updatetime=300
set shortmess+=c

" Use tab for trigger completion
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <cr> to confirm completion
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

" GoTo code navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> ]d <Plug>(coc-diagnostic-next)
nmap <silent> [d <Plug>(coc-diagnostic-prev)

" Auto-install CoC extensions
let g:coc_global_extensions = [
  \ 'coc-go',
  \ 'coc-rust-analyzer',
  \ 'coc-zls'
  \ ]
