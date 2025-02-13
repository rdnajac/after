" Location: plugin/apathy.vim
" Author: Tim Pope <http://tpo.pe/>

if exists('g:loaded_apathy')
  finish
endif
let g:loaded_apathy = 1

if &g:path =~# '\v^\.,/%(usr|emx)/include,,$'
  setglobal path=.,,
endif
setglobal include=
setglobal includeexpr=
setglobal define=

setglobal isfname+=@-@

augroup apathy_sh
  autocmd!
  autocmd FileType sh,zsh call apathy#Prepend('path', apathy#EnvSplit($PATH))
  autocmd FileType sh,zsh setlocal include=^\\s*\\%(\\.\\\|source\\)\\s
  autocmd FileType sh,zsh setlocal define=\\<\\%(\\i\\+\\s*()\\)\\@=
  autocmd FileType sh,zsh call apathy#Undo()
augroup END

augroup apathy_python
  autocmd!
  autocmd FileType python if !exists('g:python_path')
    \ let g:python_path = split(system(get(g:, 'python_executable', 'python') . ' -c "import sys; print(''\n''.join(sys.path))"')[0:-2], "\n", 1)
    \ if v:shell_error
    \   let g:python_path = []
    \ endif
  \ endif
  autocmd FileType python call apathy#Prepend('path', g:python_path)
  autocmd FileType python call apathy#Prepend('suffixesadd', '.py,/__init__.py')
  autocmd FileType python call apathy#Undo()
augroup END

function! s:CPreProcIncludes(exe, opts) abort
  let paths = []
  let active = 0
  for line in executable(a:exe) ? split(system(a:exe . ' ' . a:opts), "\n") : []
    if line =~# '^#include '
      let active = 1
    elseif line =~# '^\S'
      let active = 0
    elseif active
      call add(paths, matchstr(line, '\S\+'))
    endif
  endfor
  return paths
endfunction

augroup apathy_c
  autocmd!
  autocmd FileType c,cpp if &filetype ==# 'cpp'
    \ if !exists('g:cpp_path')
    \   let g:c_path_compiler = get(g:, 'c_path_compiler', executable('clang') ? 'clang' : 'gcc')
    \   let g:cpp_path = ['.'] + s:CPreProcIncludes(g:c_path_compiler, '-E -v -x c++ /dev/null')
    \ endif
    \ call apathy#Prepend('path', g:cpp_path)
  \ else
    \ if !exists('g:c_path')
    \   let g:c_path_compiler = get(g:, 'c_path_compiler', executable('clang') ? 'clang' : 'gcc')
    \   let g:c_path = ['.'] + s:CPreProcIncludes(g:c_path_compiler, '-E -v -x c /dev/null')
    \ endif
    \ call apathy#Prepend('path', g:c_path)
  \ endif
  autocmd FileType c,cpp setlocal include=^\\s*#\\s*include\\s*[\"<]\\@=
  autocmd FileType c,cpp setlocal includeexpr&
  autocmd FileType c,cpp setlocal define&
  autocmd FileType c,cpp call apathy#Undo()
augroup END

function! s:matchfilter(list, pat) abort
  return filter(map(copy(a:list), 'matchstr(v:val, '.string(a:pat).')'), 'len(v:val)')
endfunction

function! LuaIncludeExpr(fname) abort
  if a:fname =~# '/' || a:fname =~# '\.lua$'
    return a:fname
  endif
  let fname = tr(a:fname, '.', '/')
  let file = fname
  while file !=# '.'
    for suffix in split(&l:suffixesadd, ',')
      let path = findfile(file . suffix)
      if !empty(path)
        return file . suffix
      endif
    endfor
    let file = fnamemodify(file, ':h')
  endwhile
  return fname
endfunction

augroup apathy_lua
  autocmd!
  autocmd FileType lua if !exists('g:lua_path')
    \ let g:lua_path = split(system('lua -e "print(package.path)"')[0:-2], ';')
    \ if v:shell_error || empty(g:lua_path)
    \   let g:lua_path = ['./?.lua', './?/init.lua']
    \ endif
  \ endif
  autocmd FileType lua call apathy#Prepend('path', s:matchfilter(g:lua_path, '^[^?]*[^?\/]'))
  autocmd FileType lua call apathy#Prepend('suffixesadd', s:matchfilter(g:lua_path, '?\zs[^?]*$'))
  autocmd FileType lua setlocal include=\\<require\\s*(\\=\\s*[\"']
  autocmd FileType lua setlocal includeexpr=LuaIncludeExpr(v:fname)
  autocmd FileType lua call apathy#Undo()
augroup END
