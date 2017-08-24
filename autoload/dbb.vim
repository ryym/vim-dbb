let g:dbb_work_dir = expand('%:p:h') . '/_work'
let g:dbb_default_connection = 'root:root@/mink_development'

function! dbb#install_server() abort
  " TODO: Download server binary program.
endfunction

let s:dbb_running = 0
let s:sysch = 0
let s:ch = 0

function! dbb#start() abort
  if !isdirectory(g:dbb_work_dir)
    call mkdir(g:dbb_work_dir, 'p')
  endif

  if !s:dbb_running
    echom 'Running dbb server...'
    call system('go run ' . g:vimdbb_server_src . '/cmd/vimdbb/main.go&')

    let mtry = 200
    let ntry = 0
    let s:sysch = ch_open('localhost:8080')
    while ch_status(s:sysch) != 'open'
      sleep 10m
      let s:sysch = ch_open('localhost:8080')
      let ntry += 1
      if ntry >= mtry
        echoerr 'Can not connect to Dbb server'
        return
      endif
    endwhile
    echom 'Dbb start'

    let s:dbb_running = 1
  else
    echo 'Dbb is already running'
  endif

  let s:ch = ch_open('localhost:8080')

  call dbb#queries#start(g:dbb_work_dir)
endfunction

function! dbb#stop() abort
  if s:dbb_running
    call ch_sendexpr(s:sysch, ['KILL', {}])
    let s:dbb_running = 0
  endif
endfunction

function! dbb#run() abort
  if !s:dbb_running
    echoerr 'Dbb is not running'
    return
  endif

  let qb = dbb#queries#get_from_bufnr(bufnr('%'))
  if qb == {}
    echoerr 'This is not a query buffer'
    return
  endif

  if qb.connection_url == ''
    echoerr 'Specify conection URL'
    return
  endif

  let query = join(getbufline(qb.bufnr, 1, '$'), " ")
  let mes = ['Query', {
    \   'ConnectionURL': qb.connection_url,
    \   'QueryID': qb.qid,
    \   'Query': query,
    \ }]
  call ch_sendexpr(s:ch, mes, { 'callback': funcref('<SID>handle_res') })
endfunction

function! <SID>handle_res(ch, res) abort
  if a:res.Command ==# 'ERR'
    echoerr 'ERR: ' . a:res.Result
    return
  endif
  if a:res.Command ==# 'Query'
    call s:show_results(a:ch, a:res.Result)
  endif
endfunction

function! <SID>show_results(ch, ret) abort
  let qid = a:ret.QueryID
  let qb = dbb#queries#get(qid)
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
  let q_winnr = win_id2tabwin(q_bufinfo[0].windows[0])[0]
  execute q_winnr . 'wincmd w'
endfunction

function! s:find_ret_win_in_current_tab()
  let ret_winids = []
  for retbufinfo in dbb#queries#ret_bufinfos()
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
  call dbb#queries#open(qid, g:dbb_work_dir)
endfunction
