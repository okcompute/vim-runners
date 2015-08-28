" vim:fdm=marker
"
" Location: autoload/nose.vim
" Author: Pascal Lalancette (okcompute@icloud.com)


if !has('python')
    echo "Error: Required vim compiled with +python"
    finish
endif

" Configure python environment {{{
let s:script_folder_path = escape( expand( '<sfile>:p:h' ), '\' )

function! s:setup_python() abort
python << EOF
import os
import sys
import vim
script_path = vim.eval("s:script_folder_path")
script_path = os.path.normpath(os.path.join(script_path, "../python2"))
sys.path.insert( 0, script_path)
EOF
endfunction

call s:setup_python()

" }}}

" VirtualEnv {{{

function! nose#prepare_virtualenv()
    let l:old_path = $PATH
    try
        let l:venv=nose#get_virtual_env_path()
    catch /^No virtualenv/
        if !exists('$VIRTUALENV')
            echo "vim-nose: No virtualenv found!"
            return l:old_path
        endif
    endtry
    if has('win32')
        let $PATH=l:venv.";".$PATH
    else
        let $PATH=l:venv.":".$PATH
    endif
    return l:old_path
endfunction

function! nose#reset_virtualenv(old_path)
    let $PATH = a:old_path
endfunction

function! nose#get_virtual_env_path()
    try
        return nose#read_virtualenv_config_from_file()
    catch /^Configuration not found/
    endtry
    try
        return nose#read_virtualenv_config_from_git()
    catch /^Configuration not found/
    endtry
    throw "No virtualenv configuration found"
endfunction

" }}}

" '.venv' config file {{{
"
function! nose#read_virtualenv_config_from_file()
    let venv_config = findfile(".venv", "./;")
    if !filereadable(venv_config)
        throw "Configuration not found.`.venv` file not found."
    endif
python << EOF
import vim
import os
venv_config = vim.eval("venv_config")
path = ""
with open(venv_config) as vc:
    lines = [line for line in vc.readlines() if line]
    path = lines[0].strip()
    # `path` comes from a configured value. Make sure possible `~` gets
    # expanded
    path = os.path.expanduser(path)
    # reminder: os.path.join works with relative and absolute path. If second
    # parameter is an existing absolute path, it will be the returned value.
    path = os.path.normpath(os.path.join(os.path.dirname(venv_config), path))
    if os.name == 'nt':
        path = os.path.join(path, "scripts")
    else:
        path = os.path.join(path, "bin")
    # python is portable and rightfully manage correct path separators on
    # every platform. Vim does it differently. Its all POSIX internally.
    path = path.replace("\\", "/")
    vim.command("let l:path=\"%s\"" % path)
EOF
    return l:path
    endfunction

" }}}

" git {{{

function! nose#read_virtualenv_config_from_git()
    let l:venv =  system('git config vim-nose.venv')
    if v:shell_error
        throw "Configuration not found. Git not available or virtualenv configuration not set."
    endif
    let l:root = nose#get_git_repository_root()
python << EOF
import vim
import os
venv = vim.eval("l:venv").strip()
# `venv` comes from a configured value. Make sure possible `~` gets expanded
venv = os.path.expanduser(venv)
root = vim.eval("l:root").strip()
path = os.path.normpath(os.path.join(root, venv))
if os.name == 'nt':
    path = os.path.join(path, "scripts")
else:
    path = os.path.join(path, "bin")
# python is portable and rightfully manage correct path separators on
# every platform. Vim does it differently. Its all POSIX internally.
path = path.replace("\\", "/")
vim.command("let l:path=\"%s\"" % path)
EOF
    return l:path
endfunction

function! nose#get_git_repository_root()
    let root =  substitute(system('git rev-parse --show-toplevel'), "\n", "", "")
    if v:shell_error
        throw "Git not available for project root discovery!"
    endif
    return l:root
endfunction

" }}}

" Test finder functions {{{

function! nose#get_current_test()
python << EOF
import code_analyzer
import vim
position = vim.current.window.cursor
filename  = vim.current.buffer.name
runner = vim.eval("g:vim_python_runner")
separator = "::" if runner == 'pytest' else "."
try:
    test_function = code_analyzer.get_test_function_at(
        filename,
        position,
        separator,
    )
except:
    # No function found because there is an error in the parsed file. Let nose
    # found the error too and show it in the quickfix window.
    test_function = ""
    print "This did not work!"
    import sys
    print sys.exc_info()
print test_function
# test is either a test function, a test case or a test module
test = filename
if test_function:
    separator = "::" if runner == 'pytest' else ":"
    test = separator.join([test, test_function])
# Always use Posix path (even on Windows)
test = test.replace("\\", "/")
vim.command("let l:test=\"%s\"" % test)
EOF
    echo l:test
    let g:nose#last_test=l:test
    return l:test
endfunction

function! nose#get_last_test()
    return g:nose#last_test
endfunction

" }}}

" Test case finder functions {{{

function! nose#get_current_case()
python << EOF
import code_analyzer
import vim
position = vim.current.window.cursor
filename  = vim.current.buffer.name
runner = vim.eval("g:vim_python_runner")
separator = "::" if runner == 'pytest' else "."
try:
    test_case = code_analyzer.get_test_case_at(
        filename,
        position,
        separator,
    )
except:
    # No test case found because there is an error in the parsed file. Let
    nose # found the error too and show it in the quickfix window.
    test_case = ""
if test_case:
    separator = "::" if runner == 'pytest' else ":"
    test_case = separator.join([filename, test_case])
else:
    test_case = filename
# Always use Posix path (even on Windows)
test_case = test_case.replace("\\", "/")
vim.command("let l:test_case=\"%s\"" % test_case)
EOF
    let g:nose#last_case=l:test_case
    return l:test_case
endfunction

function! nose#get_last_case()
    return g:nose#last_case
endfunction

" }}}

" Test module finder functions {{{

function! nose#get_current_module()
    let g:nose#last_module=expand("%:p")
    return g:nose#last_module
endfunction

function! nose#get_last_module()
    return g:nose#last_module
endfunction

" }}}

" Commands selection {{{

function! nose#make_interactive_command()
    let l:cmd = ":!"
    if exists(":Start")
        let l:cmd = ":Start "
    elseif has('win32')
        let l:cmd = ":!start "
    endif
    if g:vim_python_runner == 'nose'
        return l:cmd."nosetests -s "
    elseif g:vim_python_runner == 'pytest'
        if has('win32') || has('win64')
            return l:cmd."py.test.exe -s "
        else
            return l:cmd."py.test -s "
        endif
    else
        echoerr "Unknown test runner!: ".g:vim_python_runner
    endif
endfunction

function! nose#make_foreground_command()
    if exists(":Make")
        return ":Make "
    else
        return ":make "
    endif
endfunction

" }}}

" Generic run method {{{

function! nose#run(interactive, get_test_method) abort
    let old_path = nose#prepare_virtualenv()
    try
        let l:args = nose#get_{a:get_test_method}()
        if a:interactive
            let l:cmd = nose#make_interactive_command()
            " In case of test error, introduce a pause in the interactive
            " shell so the user can see what the error was!
            if has('win32')
                let l:args = l:args." || pause"
            else
                let l:msg = "\"Press any key to continue...\""
                let l:args = l:args." || read -p ".l:msg
            endif
        else
            let l:cmd = nose#make_foreground_command()
        endif
        exec l:cmd.l:args
    catch /^Vim\%((\a\+)\)\=:E121/	" catch error E121
        echo "vim-nose: No previous run test history."
    catch /^Git not available/
        echo "vim-nose: Cannot run test command (".v:exception.")"
    finally
        call nose#reset_virtualenv(old_path)
    endtry
endfunction

"}}}

" Run commands implementations {{{

function! nose#run_test(bang) abort
    call nose#run(a:bang, "current_test")
endfunction

function! nose#run_last_test(bang) abort
    call nose#run(a:bang, "last_test")
endfunction

function! nose#run_case(bang) abort
    call nose#run(a:bang, "current_case")
endfunction

function! nose#run_last_case(bang) abort
    call nose#run(a:bang, "last_case")
endfunction

function! nose#run_module(bang) abort
    call nose#run(a:bang, "current_module")
endfunction

function! nose#run_last_module(bang) abort
    call nose#run(a:bang, "last_module")
endfunction

function! nose#run_all(bang) abort
    call nose#run(a:bang, "git_repository_root")
endfunction

" }}}
