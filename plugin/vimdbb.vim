if !exists("g:vimdbb_server_src")
  let g:vimdbb_server_src = expand('$GOPATH') . '/src/github.com/ryym/vimdbb'
endif

augroup vimdbb
  autocmd!
  autocmd VimLeavePre * call dbb#stop()
augroup END
