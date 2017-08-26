function! dbb#server#install() abort
  " TODO: Download server binary program.
endfunction

let s:dbb_running = 0
let s:sysch = 0
let s:ch = 0

function! dbb#server#start(server_src) abort
  if s:dbb_running
    echo 'Dbb is already running'
    return
  endif

  echom 'Running dbb server...'
  call system('go run ' . a:server_src . '/cmd/vimdbb/main.go&')

  let mtry = 200
  let ntry = 0
  let s:sysch = ch_open('localhost:8080')
  while ch_status(s:sysch) != 'open'
    sleep 10m
    let s:sysch = ch_open('localhost:8080')
    let ntry += 1
    if ntry >= mtry
      return 0
    endif
  endwhile

  let s:dbb_running = 1
  let s:ch = ch_open('localhost:8080')

  return 1
endfunction

function! dbb#server#stop() abort
  if s:dbb_running
    call ch_sendexpr(s:sysch, ['KILL', {}])
    let s:dbb_running = 0
  endif
endfunction

function dbb#server#is_running() abort
  return s:dbb_running
endfunction

function! dbb#server#send(command, payload, callback) abort
  if s:dbb_running
    call ch_sendexpr(s:ch, [a:command, a:payload], {
      \   'callback': funcref('<SID>handle_res', [a:callback])
      \ })
  endif
endfunction

function! <SID>handle_res(Callback, ch, res) abort
  call a:Callback(a:res, a:res.Command ==# 'ERR')
endfunction
