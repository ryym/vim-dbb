if !exists("g:vimdbb_server_src")
  let g:vimdbb_server_src = expand('$GOPATH') . '/src/github.com/ryym/vimdbb'
endif

nnoremap <Plug>(vimdbb-start) :<C-u>call dbb#start()<CR>
nnoremap <Plug>(vimdbb-run) :<C-u>call dbb#run()<CR>

augroup vimdbb
  autocmd!
  autocmd VimLeavePre * call dbb#stop()
augroup END
