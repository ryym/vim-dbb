let s:qdata = {}
let s:b2q = {}
let s:qid = 1

function! dbb#queries#new(bufnr, work_dir)
  if has_key(s:b2q, a:bufnr)
    return s:qdata[s:b2q[a:bufnr]]
  endif

  " XXX: Allow to open multiple queries.
  execute 'edit' a:work_dir . '/query'
  setfiletype sql
  let q_bufnr = bufnr('%')

  let q = {
    \   'qid': s:qid,
    \   'bufnr': a:bufnr,
    \   'ret_bufnr': -1,
    \   'ret_path': a:work_dir . '/result'
    \ }
  let s:qdata[s:qid] = q
  let s:b2q[a:bufnr] = s:qid

  let s:qid += 1 " XXX: safe?

  return q
endfunction

function! dbb#queries#get_from_bufnr(bufnr)
  return has_key(s:b2q, a:bufnr) ? s:qdata[s:b2q[a:bufnr]] : {}
endfunction

function! dbb#queries#get(qid)
  return has_key(s:qdata, a:qid) ? s:qdata[a:qid] : {}
endfunction
