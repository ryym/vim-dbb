let g:dbb_work_dir = expand('%:p:h') . '/_work'

function! dbb#install_server() abort
  " TODO: Download server binary program.
endfunction

let s:dbb_running = 0
let s:sysch = 0
let s:ch = 0

function! dbb#start() abort
  if !isdirectory(g:dbb_work_dir)
    call mkdir(g:dbb_work_dir, "p")
  endif

  if !s:dbb_running
    call system('go run ' . g:vimdbb_server_src . '/cmd/vimdbb/main.go&')
    echom 'Running dbb server...'

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
  call dbb#queries#new(bufnr('%'), g:dbb_work_dir)
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

  if getbufinfo(qb.ret_bufnr) == []
    setlocal splitbelow

    execute '20split' qb.ret_path
    let qb.ret_bufnr = bufnr('%')
  endif

  let query = join(getbufline(qb.bufnr, 1, '$'), " ")
  let mes = ['Query', { 'QueryID': qb.qid, 'Query': query }]
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

  let retbufinfo = getbufinfo(qb.ret_bufnr)
  let retw = retbufinfo[0].windows[0]
  let [rettabnr, retwinnr] = win_id2tabwin(retw)
  execute 'tabnext' . rettabnr
  execute retwinnr . 'wincmd w'

  setlocal noreadonly
  normal ggdG
  call setline(1, split(a:ret.Rows, '\n'))
  update
  setlocal readonly

  let q_bufinfo = getbufinfo(qb.bufnr)
  let q_winnr = win_id2tabwin(q_bufinfo[0].windows[0])[0]
  execute q_winnr . 'wincmd w'
endfunction
