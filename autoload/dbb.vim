let g:dbb_work_dir = expand('%:p:h') . '/_work'

function! dbb#install_server() abort
  " TODO: Download server binary program.
endfunction

let s:dbb_running = 0
let s:sysch = 0
let s:ch = 0
let s:q_bufnr = -1
let s:res_bufnr = -1

function! dbb#start() abort
  call system('go run ' . g:vimdbb_server_src . '/cmd/vimdbb/main.go&')

  if !s:dbb_running
    let mtry = 200
    let ntry = 0
    let s:sysch = ch_open('localhost:8080')
    while ch_status(s:sysch) != 'open'
      sleep 10m
      let s:sysch = ch_open('localhost:8080')
      let ntry += 1
      if ntry >= mtry
        throw 'Can not connect to Dbb server'
      endif
    endwhile
    echom 'Dbb start'

    let s:dbb_running = 1
  endif

  let s:ch = ch_open('localhost:8080')

  if s:q_bufnr == -1
    execute 'edit' g:dbb_work_dir . '/query'
    setfiletype sql
    let s:q_bufnr = bufnr('%')
  endif
endfunction

function! dbb#stop() abort
  if s:dbb_running
    call ch_sendexpr(s:sysch, ['KILL', {}])
    let s:dbb_running = 0
  endif
endfunction

function! dbb#run() abort
  let query = getbufline(s:q_bufnr, 1, '$')

  if getbufinfo(s:res_bufnr) == []
    setlocal splitbelow
    execute '20split' g:dbb_work_dir . '/result'
    let s:res_bufnr = bufnr('%')
  endif

  let query = join(getbufline(s:q_bufnr, 1, '$'), " ")

  let mes = ['Query', { 'Query': query }]
  call ch_sendexpr(s:ch, mes, { 'callback': funcref('<SID>show_results') })
endfunction

function! <SID>show_results(ch, res) abort
  let resbufinfo = getbufinfo(s:res_bufnr)
  let s:res_bufnr = resbufinfo[0].bufnr
  let retw = resbufinfo[0].windows[0]
  let [rettabnr, retwinnr] = win_id2tabwin(retw)
  execute 'tabnext' . rettabnr
  execute retwinnr . 'wincmd w'

  setlocal noreadonly
  normal ggdG
  call setline(1, split(a:res.Rows, '\n'))
  update
  setlocal readonly
endfunction
