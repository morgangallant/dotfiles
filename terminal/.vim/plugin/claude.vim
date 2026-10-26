" claude.vim: ask, review (read-only) and edit with claude, async
"
"   :[range]Ask [question]   ask about the selection / whole buffer
"                            (from the claude-ask buffer: follow up)
"   :[range]Review           review the selection / whole buffer into quickfix
"   :ReviewDiff [rev]        review `git diff [rev]` (default HEAD) into quickfix
"   :[range]ClaudeEdit [ask] have claude edit the selection (and nearby, if
"                            needed) on disk, then reload; `u` undoes it
"   :ClaudeStop              cancel whatever is running
"   :AskClose                close the claude-ask window (keeps the conversation)

if exists('g:loaded_claude') || !executable('claude')
  finish
endif
let g:loaded_claude = 1

let s:tools = 'Read,Grep,Glob'
let s:base = ['claude', '-p', '--tools', s:tools, '--allowedTools', s:tools,
      \ '--strict-mcp-config']
let s:job = v:null
let s:session = ''
let s:buf = -1

function! s:root() abort
  let l:root = systemlist('git -C ' . shellescape(expand('%:p:h')) . ' rev-parse --show-toplevel')
  return v:shell_error ? getcwd() : l:root[0]
endfunction

function! s:start(cmd, cwd, input, opts) abort
  call s:stop()
  let s:job = job_start(a:cmd, extend(#{cwd: a:cwd, in_io: 'pipe', err_io: 'out'}, a:opts))
  let l:ch = job_getchannel(s:job)
  call ch_sendraw(l:ch, a:input)
  call ch_close_in(l:ch)
endfunction

function! s:stop() abort
  if s:job isnot v:null && job_status(s:job) ==# 'run'
    call job_stop(s:job)
  endif
endfunction

" ---- ask ----------------------------------------------------------------

function! s:askbuf() abort
  if bufwinnr(s:buf) != -1
    return
  endif
  if bufexists(s:buf)
    execute 'botright vertical sbuffer' s:buf
  else
    botright vnew
    setlocal buftype=nofile bufhidden=hide noswapfile wrap linebreak filetype=markdown
    file claude-ask
    nnoremap <buffer> <silent> <C-c> :ClaudeStop<CR>
    let s:buf = bufnr()
  endif
  wincmd p
endfunction

function! s:askclose() abort
  for l:win in win_findbuf(s:buf)
    silent! execute win_id2win(l:win) . 'close'
  endfor
endfunction

function! s:put(text) abort
  let l:nr = s:buf
  let l:lines = split(a:text, "\n", 1)
  let l:last = getbufline(l:nr, '$')[0]
  call setbufline(l:nr, '$', l:last . l:lines[0])
  if len(l:lines) > 1
    call appendbufline(l:nr, '$', l:lines[1:])
  endif
  for l:win in win_findbuf(l:nr)
    call win_execute(l:win, 'normal! G')
  endfor
endfunction

function! s:on_ask(ch, line) abort
  try
    let l:msg = json_decode(a:line)
  catch
    return s:put("\n" . a:line)
  endtry
  let l:type = get(l:msg, 'type', '')
  if l:type ==# 'system' && get(l:msg, 'subtype', '') ==# 'init'
    let s:session = l:msg.session_id
  elseif l:type ==# 'stream_event'
    let l:ev = l:msg.event
    if l:ev.type ==# 'content_block_delta' && l:ev.delta.type ==# 'text_delta'
      call s:put(l:ev.delta.text)
    elseif l:ev.type ==# 'content_block_start' && l:ev.content_block.type ==# 'text'
          \ && getbufline(s:buf, '$')[0] !=# ''
      call s:put("\n\n")
    endif
  elseif l:type ==# 'assistant'
    for l:c in l:msg.message.content
      if l:c.type ==# 'tool_use'
        let l:arg = get(l:c.input, 'file_path', get(l:c.input, 'pattern', ''))
        call s:put("\n> " . l:c.name . ' ' . fnamemodify(l:arg, ':.') . "\n")
      endif
    endfor
  elseif l:type ==# 'result' && get(l:msg, 'is_error', v:false)
    call s:put("\n\n**error:** " . get(l:msg, 'result', 'unknown'))
  endif
endfunction

function! s:ask(line1, line2, question) abort
  let l:question = a:question !=# '' ? a:question : input('Ask: ')
  if l:question ==# ''
    return
  endif
  let l:followup = bufnr() == s:buf && s:session !=# ''
  if l:followup
    let l:prompt = l:question
    let l:cwd = s:cwd
  else
    let s:cwd = s:root()
    let l:file = fnamemodify(expand('%:p'), ':s?' . escape(s:cwd, '?') . '/??')
    let l:lines = getline(a:line1, a:line2)
    let l:code = join(map(l:lines, {i, l -> printf('%d: %s', a:line1 + i, l)}), "\n")
    let l:where = a:line1 == 1 && a:line2 == line('$')
          \ ? printf('the whole of %s, cursor on line %d', l:file, line('.'))
          \ : printf('%s lines %d-%d', l:file, a:line1, a:line2)
    let l:prompt = printf("Context: %s (%s), shown with line numbers.\n\n```%s\n%s\n```\n\n%s",
          \ l:where, &filetype, &filetype, l:code, l:question)
    let l:cwd = s:cwd
  endif
  call s:askbuf()
  let l:nr = s:buf
  if !l:followup
    let s:session = ''
    call deletebufline(l:nr, 1, '$')
  endif
  call s:put((getbufline(l:nr, 1, '$') == [''] ? '' : "\n\n---\n\n")
        \ . '## ' . l:question . "\n\n")
  let l:cmd = s:base + ['--output-format', 'stream-json', '--verbose',
        \ '--include-partial-messages', '--append-system-prompt',
        \ 'The user writes their own code. Answer the question directly in a few '
        \ . 'sentences; no preamble, no summary, no unsolicited rewrites. Short code '
        \ . 'snippets only if they help. Cite file:line.']
  if l:followup
    let l:cmd += ['--resume', s:session]
  endif
  call s:start(l:cmd, l:cwd, l:prompt, #{out_mode: 'nl', out_cb: function('s:on_ask'),
        \ exit_cb: {j, s -> s ? s:put("\n\n_(exited " . s . ")_") : 0}})
endfunction

" ---- review -------------------------------------------------------------

let s:schema = json_encode(#{type: 'object', required: ['findings'], properties: #{
      \ findings: #{type: 'array', items: #{type: 'object',
      \   required: ['file', 'line', 'severity', 'text'], properties: #{
      \     file: #{type: 'string', description: 'path relative to repo root'},
      \     line: #{type: 'integer'},
      \     severity: #{type: 'string', enum: ['error', 'warning', 'info']},
      \     text: #{type: 'string', description: 'one short sentence, under 100 chars'}}}}}})

function! s:on_review(root, out, ch) abort
  let l:raw = join(a:out, '')
  try
    let l:findings = json_decode(l:raw).structured_output.findings
  catch
    redraw | echohl ErrorMsg | echom 'claude review failed: ' . l:raw[:200] | echohl None
    return
  endtry
  let l:types = #{error: 'E', warning: 'W', info: 'I'}
  call setqflist([], ' ', #{title: 'claude review', items: map(l:findings, {_, f -> #{
        \ filename: a:root . '/' . f.file, lnum: f.line,
        \ type: get(l:types, f.severity, 'I'), text: f.text}})})
  " redraw first, or the message gets wiped when vim redraws after the callback
  redraw
  if empty(l:findings)
    echom 'claude review: no findings'
  else
    echom printf('claude review: %d finding(s)', len(l:findings))
    botright copen
  endif
endfunction

let s:rules = "Report only real bugs and risky code; no style nits, no praise. "
      \ . "Each finding is one terse sentence. Read other code only if needed "
      \ . "to judge correctness. Empty findings is fine.\n\n"

function! s:run_review(root, prompt, what) abort
  let l:out = []
  call s:start(s:base + ['--no-session-persistence', '--output-format', 'json',
        \ '--json-schema', s:schema], a:root, a:prompt,
        \ #{out_mode: 'raw', out_cb: {ch, msg -> add(l:out, msg)},
        \   close_cb: function('s:on_review', [a:root, l:out])})
  echom 'claude review: reviewing ' . a:what . '...'
endfunction

" review lines of the current buffer (unsaved edits included)
function! s:review(line1, line2) abort
  let l:root = s:root()
  let l:file = fnamemodify(expand('%:p'), ':s?' . escape(l:root, '?') . '/??')
  if l:file ==# ''
    echom 'claude review: buffer has no file name'
    return
  endif
  let l:lines = getline(a:line1, a:line2)
  let l:code = join(map(l:lines, {i, l -> printf('%d: %s', a:line1 + i, l)}), "\n")
  let l:whole = a:line1 == 1 && a:line2 == line('$')
  let l:what = l:whole ? l:file : printf('%s:%d-%d', l:file, a:line1, a:line2)
  let l:prompt = printf("Review %s (%s), shown with line numbers.%s\n\n%s```%s\n%s\n```",
        \ l:what, &filetype,
        \ l:whole ? '' : ' Only report problems within these lines.',
        \ s:rules, &filetype, l:code)
  call s:run_review(l:root, l:prompt, l:what)
endfunction

function! s:review_diff(rev) abort
  let l:root = s:root()
  let l:rev = a:rev !=# '' ? a:rev : 'HEAD'
  let l:diff = system('git -C ' . shellescape(l:root) . ' diff ' . l:rev)
  if v:shell_error || l:diff ==# ''
    echom 'claude review: no diff against ' . l:rev
    return
  endif
  let l:prompt = "Review this diff. Use line numbers from the new version of each "
        \ . "file; don't restate correct changes. " . s:rules . l:diff
  call s:run_review(l:root, l:prompt, 'diff against ' . l:rev)
endfunction

" ---- edit ---------------------------------------------------------------

function! s:on_edit(buf, out, ch) abort
  call setbufvar(a:buf, '&modifiable', 1)
  checktime
  let l:raw = join(a:out, '')
  try
    let l:res = json_decode(l:raw)
    let l:msg = get(l:res, 'result', '')
    let l:err = get(l:res, 'is_error', v:false)
  catch
    let [l:msg, l:err] = [l:raw[:200], v:true]
  endtry
  if l:err
    echohl ErrorMsg | echom 'claude edit failed: ' . l:msg | echohl None
  else
    echom 'claude edit: ' . substitute(l:msg, '\n', ' ', 'g') . ' (u to undo)'
  endif
endfunction

function! s:edit(line1, line2, ask) abort
  let l:ask = a:ask !=# '' ? a:ask : input('Edit: ')
  if l:ask ==# '' || expand('%') ==# ''
    return
  endif
  if &modified
    silent write
  endif
  let l:root = s:root()
  let l:file = fnamemodify(expand('%:p'), ':s?' . escape(l:root, '?') . '/??')
  let l:code = join(getline(a:line1, a:line2), "\n")
  let l:prompt = printf("In %s, I selected lines %d-%d (%s):\n\n```%s\n%s\n```\n\n"
        \ . "Request: %s\n\nEdit the file directly with the Edit tool. Focus the "
        \ . "change on the selected code, but also make any small edits nearby or "
        \ . "elsewhere that it requires (call sites, imports, signatures). Don't "
        \ . "refactor anything else. When done, reply with one short sentence "
        \ . "describing what you changed.",
        \ l:file, a:line1, a:line2, &filetype, &filetype, l:code, l:ask)
  let l:tools = 'Read,Grep,Glob,Edit'
  let l:buf = bufnr()
  " lock the buffer so your typing can't race claude's write
  setlocal nomodifiable
  let l:out = []
  call s:start(['claude', '-p', '--tools', l:tools, '--allowedTools', l:tools,
        \ '--strict-mcp-config', '--no-session-persistence', '--output-format', 'json'],
        \ l:root, l:prompt, #{out_mode: 'raw', out_cb: {ch, msg -> add(l:out, msg)},
        \   close_cb: function('s:on_edit', [l:buf, l:out])})
  echom 'claude edit: working on ' . l:file . '... (:ClaudeStop to cancel)'
endfunction

command! -range=% -nargs=* Ask call s:ask(<line1>, <line2>, <q-args>)
command! -range=% Review call s:review(<line1>, <line2>)
command! -nargs=? ReviewDiff call s:review_diff(<q-args>)
command! -range -nargs=* ClaudeEdit call s:edit(<line1>, <line2>, <q-args>)
command! ClaudeStop call s:stop()
command! AskClose call s:askclose()

nnoremap <leader>a :Ask<CR>
xnoremap <leader>a :Ask<CR>
nnoremap <silent> <leader>A :AskClose<CR>
nnoremap <leader>r :Review<CR>
xnoremap <leader>r :Review<CR>
nnoremap <leader>e :ClaudeEdit<CR>
xnoremap <leader>e :ClaudeEdit<CR>
