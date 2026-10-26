" mg vimrc

set nocompatible
filetype plugin indent on
syntax on
let mapleader = " "

" performance
set lazyredraw
set ttyfast
set synmaxcol=300
set updatetime=300
set ttimeout ttimeoutlen=10
set noswapfile
set nobackup nowritebackup
set regexpengine=0

" editing
set encoding=utf-8
set backspace=indent,eol,start
set hidden
set autoread
set expandtab shiftwidth=4 softtabstop=4 tabstop=4
set autoindent smarttab
set nowrap
set scrolloff=5 sidescrolloff=5
set mouse=a
set clipboard=unnamed

" search
set incsearch hlsearch
set ignorecase smartcase
nnoremap <silent> <Esc> :nohlsearch<CR><Esc>
nnoremap <silent> <C-l> :nohlsearch<CR><C-l>

" ui
set number
set laststatus=2
set ruler showcmd
set wildmenu wildmode=longest:full,full
set shortmess+=c
set belloff=all
set splitright splitbelow
hi clear Todo | hi! link Todo Comment
augroup no_todo
  autocmd!
  autocmd ColorScheme * hi clear Todo | hi! link Todo Comment
augroup END

" undo
if has('persistent_undo')
  silent! call mkdir(expand('~/.vim/undo'), 'p')
  set undodir=~/.vim/undo undofile
endif

" cursor
let &t_SI = "\e[5 q"
let &t_SR = "\e[3 q"
let &t_EI = "\e[2 q"
augroup cursor_shape
  autocmd!
  autocmd VimEnter * silent !echo -ne "\e[2 q"
augroup END

" zig
let g:zig_fmt_autosave = 1
let g:zig_fmt_parse_errors = 1

" git signs (vim-signify): thin bars, below lsp diagnostics; ]c/[c jump hunks
let g:signify_vcs_list = ['git']
let g:signify_priority = 5
let g:signify_sign_show_count = 0
let g:signify_sign_add = '▎'
let g:signify_sign_change = '▎'
let g:signify_sign_change_delete = '▎'
let g:signify_sign_delete = '▁'
let g:signify_sign_delete_first_line = '▔'

" rust
let g:rustfmt_autosave = 1
let g:rustfmt_fail_silently = 0
augroup rust_cargo
  autocmd!
  autocmd FileType rust compiler cargo
augroup END

" markdown: hard wrap at 100, highlighted code fences
let g:markdown_fenced_languages = ['go', 'rust', 'rs=rust', 'zig', 'bash=sh', 'sh', 'js=javascript', 'ts=typescript', 'json', 'html', 'css']
augroup markdown_setup
  autocmd!
  autocmd BufRead,BufNewFile *.mdx setfiletype markdown
  autocmd FileType markdown setlocal textwidth=100 formatoptions+=tn
augroup END

" lsp (yegappan/lsp: async, native channels)
augroup lsp_setup
  autocmd!
  autocmd User LspSetup call LspOptionsSet(#{
        \ autoComplete: v:false,
        \ omniComplete: v:true,
        \ autoHighlight: v:false,
        \ autoHighlightDiags: v:true,
        \ showDiagWithVirtualText: v:false,
        \ showInlayHints: v:false,
        \ ignoreMissingServer: v:true,
        \ showDiagOnStatusLine: v:true,
        \ diagSignErrorText: '●',
        \ diagSignWarningText: '●',
        \ diagSignInfoText: '●',
        \ diagSignHintText: '●',
        \ })
  autocmd User LspSetup call LspAddServer([
        \ #{name: 'gopls', filetype: ['go', 'gomod'], path: exepath('gopls') ?? expand('~/go/bin/gopls'), args: ['serve']},
        \ #{name: 'zls', filetype: ['zig'], path: exepath('zls')},
        \ #{name: 'rust-analyzer', filetype: ['rust'], path: exepath('rust-analyzer'), args: []},
        \ ])
  autocmd User LspAttached call s:lsp_maps()
  autocmd BufWritePre *.go silent! LspFormat
augroup END

" diagnostics: colored dot in a clear sign column, underline the range
function! s:lsp_colors() abort
  hi SignColumn ctermbg=NONE guibg=NONE
  hi LspDiagSignErrorText   ctermfg=1 ctermbg=NONE guifg=#e06c75 guibg=NONE
  hi LspDiagSignWarningText ctermfg=3 ctermbg=NONE guifg=#e5c07b guibg=NONE
  hi LspDiagSignInfoText    ctermfg=4 ctermbg=NONE guifg=#61afef guibg=NONE
  hi LspDiagSignHintText    ctermfg=8 ctermbg=NONE guifg=#7f848e guibg=NONE
  hi LspDiagInlineError   cterm=underline ctermbg=NONE ctermul=1 gui=undercurl guibg=NONE guisp=#e06c75
  hi LspDiagInlineWarning cterm=underline ctermbg=NONE ctermul=3 gui=undercurl guibg=NONE guisp=#e5c07b
  hi LspDiagInlineInfo    cterm=underline ctermbg=NONE ctermul=4 gui=undercurl guibg=NONE guisp=#61afef
  hi LspDiagInlineHint    cterm=NONE ctermbg=NONE gui=NONE guibg=NONE
  hi SignifySignAdd    ctermfg=2 ctermbg=NONE guifg=#98c379 guibg=NONE
  hi SignifySignChange ctermfg=3 ctermbg=NONE guifg=#e5c07b guibg=NONE
  hi SignifySignDelete ctermfg=1 ctermbg=NONE guifg=#e06c75 guibg=NONE
endfunction
call s:lsp_colors()
augroup lsp_colors
  autocmd!
  autocmd ColorScheme * call s:lsp_colors()
augroup END

function! s:lsp_maps() abort
  nnoremap <buffer> <silent> gd :LspGotoDefinition<CR>
  nnoremap <buffer> <silent> gr :LspShowReferences<CR>
  nnoremap <buffer> <silent> gi :LspGotoImpl<CR>
  nnoremap <buffer> <silent> K  :LspHover<CR>
  nnoremap <buffer> <silent> [d :LspDiag prev<CR>
  nnoremap <buffer> <silent> ]d :LspDiag next<CR>
  nnoremap <buffer> <silent> <leader>d  :LspDiag current<CR>
  nnoremap <buffer> <silent> <leader>n :LspRename<CR>
  nnoremap <buffer> <silent> <leader>ca :LspCodeAction<CR>
endfunction

" quickfix: ]q/[q to step, dd in the list to drop an entry
function! s:qf_step(next) abort
  let l:qf = getqflist(#{idx: 0, items: 0})
  if empty(l:qf.items)
    echo 'quickfix list is empty' | return
  endif
  let l:cur = l:qf.items[l:qf.idx - 1]
  if l:cur.bufnr != bufnr() || l:cur.lnum != line('.')
    execute 'cc' l:qf.idx
  elseif a:next
    try | cnext | catch /E553/ | cfirst | endtry
  else
    try | cprev | catch /E553/ | clast | endtry
  endif
endfunction
nnoremap <silent> ]q :call <SID>qf_step(1)<CR>
nnoremap <silent> [q :call <SID>qf_step(0)<CR>
function! s:qf_del() abort
  let l:loc = getwininfo(win_getid())[0].loclist
  let l:items = l:loc ? getloclist(0) : getqflist()
  if empty(l:items) | return | endif
  let l:line = line('.')
  call remove(l:items, l:line - 1)
  if l:loc
    call setloclist(0, [], 'r', #{items: l:items})
  else
    call setqflist([], 'r', #{items: l:items})
  endif
  execute min([l:line, max([len(l:items), 1])])
endfunction
augroup qf_maps
  autocmd!
  autocmd FileType qf nnoremap <buffer> <silent> dd :call <SID>qf_del()<CR>
  " quitting the last real window also closes quickfix/location lists
  autocmd QuitPre * if &buftype !=# 'quickfix' && len(filter(getwininfo(),
        \ {_, w -> w.tabnr == tabpagenr() && !w.quickfix})) == 1
        \ | silent! cclose | silent! lclose | endif
augroup END
