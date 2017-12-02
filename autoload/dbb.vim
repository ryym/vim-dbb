let g:dbb = {
  \ 'work_dir': expand('%:p:h') . '/_work',
  \ 'default_connection': 'root:root@/mink_development'
  \ }

let s:state = {
  \ 'queries': {},
  \ 'ch': 0,
  \ 'sysch': 0,
  \ }

function! dbb#start() abort
  augroup vimdbb
    autocmd!
    autocmd VimLeavePre * call dbb#stop()
  augroup END

  if !isdirectory(g:dbb.work_dir)
    call mkdir(g:dbb.work_dir, 'p')
  endif

  if !dbb#server#start(g:vimdbb_server_src)
    echoerr 'Can not connect to Dbb server'
    return
  endif

  call dbb#query#start(s:state.queries, g:dbb.work_dir)
  call dbb#qlist#start(s:state.queries)
endfunction

function! dbb#stop() abort
  call dbb#server#stop()
endfunction

function! dbb#set_connection(url) abort
  let qb = s:try_get_query_buf()
  if qb == {}
    return
  endif

  let qb.connection_url = a:url
endfunction

function! dbb#run() abort
  let qb = s:try_get_query_buf()
  if qb == {}
    return
  endif

  if qb.connection_url == ''
    echoerr 'Specify conection URL'
    return
  endif

  let query = join(getbufline(qb.bufnr, 1, '$'), " ")
  let payload = {
    \   'ConnectionURL': qb.connection_url,
    \   'QueryID': qb.qid,
    \   'Query': query,
    \ }
  call dbb#server#send('Query', payload, funcref('<SID>handle_res'))
endfunction

function! <SID>try_get_query_buf() abort
  if !dbb#server#is_running()
    echoerr 'Dbb is not running'
    return {}
  endif

  let qb = dbb#query#get_from_bufnr(bufnr('%'))
  if qb == {}
    echoerr 'This is not a query buffer'
  endif

  return qb
endfunction

function! <SID>handle_res(res, err) abort
  if a:err
    echoerr 'ERR: ' . a:res.Result
    return
  endif
  if a:res.Command ==# 'Query'
    call s:show_results(a:res.Result)
  endif
endfunction

function! <SID>show_results(ret) abort
  let qid = a:ret.QueryID
  let qb = dbb#query#get(qid)
  if qb == {}
    echoerr 'Query buffer is not found'
    return
  endif

  let retwinnr = s:find_ret_win_in_current_tab()
  if retwinnr > 0
    execute retwinnr 'wincmd w'
    execute 'edit' qb.ret_path
  else
    setlocal splitbelow
    execute '20split' qb.ret_path
  endif

  let qb.ret_bufnr = bufnr('%')

  setlocal noreadonly
  normal ggdG
  call setline(1, split(a:ret.Rows, '\n'))
  update
  setlocal readonly

  let q_bufinfo = getbufinfo(qb.bufnr)
  let q_winnr = win_id2win(q_bufinfo[0].windows[0])
  execute q_winnr . 'wincmd w'
endfunction

function! s:find_ret_win_in_current_tab()
  let ret_winids = []
  for retbufinfo in dbb#query#ret_bufinfos()
    if len(retbufinfo) > 0
      call extend(ret_winids, retbufinfo[0].windows)
    endif
  endfor

  for win in range(1, winnr('$'))
    let wid = win_getid(win)
    if index(ret_winids, wid) >= 0
      return win
    endif
  endfor

  return 0
endfunction

function! dbb#open_query(...)
  let qid = get(a:, 1, 0)
  call dbb#query#open(qid, g:dbb.work_dir)
endfunction

function! dbb#open_qlist()
  call dbb#qlist#open(s:state.queries, g:dbb.work_dir)
endfunction
