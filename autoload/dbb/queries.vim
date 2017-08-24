let s:qdata = {}

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

  let qid = len(files) == 0 ? 0 : keys(s:qdata)[len(s:qdata) - 1]
  return dbb#queries#open(qid, a:work_dir)
endfunction

function! dbb#queries#open(qid, work_dir)
  if a:qid == 0
    let q = dbb#queries#new(a:work_dir)
  elseif has_key(s:qdata, a:qid)
    let q = s:qdata[a:qid]
  else
    echoerr 'Query ' . a:qid ' does not exist'
    return
  endif

  " Open query buffer
  execute 'edit' q.q_path
  setfiletype sql
  let q.bufnr = bufnr('%')

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
  let name = fnamemodify(bufname(a:bufnr), ':t')
  if name =~# '^dbb-q-\d\+$'
    let qid = matchstr(name, '\d\+$', 0)
    let q = dbb#queries#get(qid)
    let q.bufnr = a:bufnr
    return q
  endif
endfunction

function! dbb#queries#get(qid)
  return has_key(s:qdata, a:qid) ? s:qdata[a:qid] : {}
endfunction

function! dbb#queries#ret_bufinfos()
  return map(keys(s:qdata), 'getbufinfo(s:qdata[v:val].ret_bufnr)')
endfunction
