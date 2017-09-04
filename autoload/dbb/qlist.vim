let s:queries = {}

function! dbb#qlist#start(queries) abort
  let s:queries = a:queries

  augroup vimdbb
    autocmd CursorMoved vimdbb_queries call <SID>open_query()
  augroup END
endfunction


function! dbb#qlist#open(queries, work_dir) abort
  execute '40vsplit'
  execute 'edit' a:work_dir . '/vimdbb_queries'

  " Delete all lines
  execute '1,$d'

  setlocal noreadonly
  call setline(1, ['QUERIES', ''])
  let names = map(keys(a:queries), {i, q -> (i + 1) . ' ' . a:queries[q].qid})
  call setline(3, names)
  update
  setlocal readonly
endfunction

function! <SID>open_query() abort
  let q = split(getline(line('.')), ' ')
  if len(q) != 2
    return
  endif

  let qid = q[1]
  if !has_key(s:queries, qid)
    return
  endif

  let q_bufinfos = map(keys(s:queries), {_, k -> getbufinfo(s:queries[k].bufnr)})
  let q_winnr = s:find_q_win_in_current_tab(q_bufinfos)
  echom 'Q_WIN' . q_winnr
  if q_winnr == 0
    return
  endif

  let my_bufnr = bufnr('%')

  execute q_winnr . 'wincmd w'
  execute 'edit ' . s:queries[qid].q_path
  setfiletype sql
  let s:queries[qid].bufnr = bufnr('%')

  " Return to queries buffer
  let bufinfo = getbufinfo(my_bufnr)
  let winnr = win_id2win(bufinfo[0].windows[0])
  execute winnr . 'wincmd w'
endfunction

function! s:find_q_win_in_current_tab(q_bufinfos)
  let q_winids = []
  for q_bufinfo in a:q_bufinfos
    if len(q_bufinfo) > 0
      call extend(q_winids, q_bufinfo[0].windows)
    endif
  endfor

  for win in range(1, winnr('$'))
    let wid = win_getid(win)
    if index(q_winids, wid) >= 0
      return win
    endif
  endfor

  return 0
endfunction
