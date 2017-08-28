let s:queries = {}

function! dbb#query#start(queries, work_dir)
  if !isdirectory(a:work_dir . '/queries')
    call mkdir(a:work_dir . '/queries')
    call mkdir(a:work_dir . '/results')
  endif

  let s:queries = a:queries

  " Restore query files.
  let files = split(globpath(a:work_dir . '/queries', 'dbb-q-*'), '\n')
  for f in files
    let qid = matchstr(f, '\d\+$', 0)
    if qid != ''
      let s:queries[qid] = s:initial_q(qid, a:work_dir)
    endif
  endfor

  let qid = len(files) == 0 ? 0 : keys(s:queries)[len(s:queries) - 1]
  return dbb#query#open(qid, a:work_dir)
endfunction

function! dbb#query#open(qid, work_dir)
  if a:qid == 0
    let q = dbb#query#new(a:work_dir)
  elseif has_key(s:queries, a:qid)
    let q = s:queries[a:qid]
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

function! dbb#query#new(work_dir)
  let qid = s:gen_new_query_id(s:queries)
  let q = s:initial_q(qid, a:work_dir)
  let s:queries[qid] = q
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
    \   'ret_path': ret_path,
    \   'connection_url': g:dbb.default_connection,
    \ }
endfunction

function! s:gen_new_query_id(queries)
  let id = strftime('%Y%m%d%H%M%S')
  while has_key(a:queries, id)
    sleep 5m
    let id = strftime('%Y%m%d%H%M%S')
  endwhile
  return id
endfunction

function! dbb#query#get_from_bufnr(bufnr)
  let name = fnamemodify(bufname(a:bufnr), ':t')
  if name =~# '^dbb-q-\d\+$'
    let qid = matchstr(name, '\d\+$', 0)
    let q = dbb#query#get(qid)
    let q.bufnr = a:bufnr
    return q
  endif
endfunction

function! dbb#query#get(qid)
  return has_key(s:queries, a:qid) ? s:queries[a:qid] : {}
endfunction

function! dbb#query#ret_bufinfos()
  return map(keys(s:queries), 'getbufinfo(s:queries[v:val].ret_bufnr)')
endfunction
