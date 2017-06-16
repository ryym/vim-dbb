let g:dbb_work_dir = expand('%:p:h') . '/_work'

function! dbb#install_server() abort
  " TODO: Download server binary program.
endfunction

let s:ch = 0
let s:q_bufnr = -1
let s:res_bufnr = -1

function! dbb#start() abort
  let s:ch = ch_open('localhost:8080')

  if s:q_bufnr == -1
    execute 'edit' g:dbb_work_dir . '/query'
    setfiletype sql
    let s:q_bufnr = bufnr('%')
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

  let mes = { 'Query': query }
  call ch_sendexpr(s:ch, mes, { 'callback': funcref('<SID>show_results') })
endfunction

function! <SID>show_results(ch, res) abort
  let resbufinfo = getbufinfo(s:res_bufnr)
  let s:res_bufnr = resbufinfo[0].bufnr
  let retw = resbufinfo[0].windows[0]
  let [rettabnr, retwinnr] = win_id2tabwin(retw)
  execute 'tabnext' . rettabnr
  execute retwinnr . 'wincmd w'

  normal ggdG
  call setline(1, split(a:res.Rows, '\n'))

  setlocal noreadonly
  update
  setlocal readonly
endfunction
