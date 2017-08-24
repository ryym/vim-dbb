let s:qdata = {}
let s:b2q = {}

function! dbb#queries#start(work_dir)
  if !isdirectory(a:work_dir . '/queries')
    call mkdir(a:work_dir . '/queries')
    call mkdir(a:work_dir . '/results')
  endif

  " Restore query files.
  let files = split(globpath(a:work_dir . '/queries', 'dbb-q-*'), '\n')
  for f in files
    let qid = matchstr(f, '\d\+$', 0)
    if qid != ''
      let s:qdata[qid] = s:initial_q(qid, a:work_dir)
    endif
  endfor

  if len(files) == 0
    let q = dbb#queries#new(a:work_dir)
  else
    let q = s:qdata[keys(s:qdata)[len(s:qdata) - 1]]
  endif

  " Open buffer
  execute 'edit' q.q_path
  setfiletype sql
  let q.bufnr = bufnr('%')
  let s:b2q[q.bufnr] = q.qid

  return q
endfunction

function! dbb#queries#new(work_dir)
  let qid = s:gen_new_query_id(s:qdata)
  let q = s:initial_q(qid, a:work_dir)
  let s:qdata[qid] = q
  return q
endfunction

function! s:initial_q(qid, work_dir)
  let q_path = a:work_dir . '/queries/dbb-q-' . a:qid
  let ret_path = a:work_dir . '/results/dbb-ret-' . a:qid
  return {
    \   'qid': a:qid,
    \   'q_path': q_path,
    \   'bufnr': -1,
    \   'ret_bufnr': -1,
    \   'ret_path': ret_path
    \ }
endfunction

function! s:gen_new_query_id(qdata)
  let id = strftime('%Y%m%d%H%M%S')
  while has_key(a:qdata, id)
    sleep 5m
    let id = strftime('%Y%m%d%H%M%S')
  endwhile
  return id
endfunction

function! dbb#queries#get_from_bufnr(bufnr)
  return has_key(s:b2q, a:bufnr) ? s:qdata[s:b2q[a:bufnr]] : {}
endfunction

function! dbb#queries#get(qid)
  return has_key(s:qdata, a:qid) ? s:qdata[a:qid] : {}
endfunction
