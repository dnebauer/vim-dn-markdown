" Function:    Vim ftplugin for markdown
" Last Change: 2015-04-29
" Maintainer:  David Nebauer <david@nebauer.org>

" 1.  CONTROL STATEMENTS                                              {{{1

" Only do this when not done yet for this buffer
if exists('b:did_dnm_markdown_pandoc') | finish | endif
let b:did_dnm_markdown_pandoc = 1

" Use default cpoptions to avoid unpleasantness from customised
" 'compatible' settings
let s:save_cpo = &cpoptions
set cpoptions&vim

" ========================================================================

" 2.  VARIABLES                                                       {{{1

" help                                                                {{{2
if !exists('g:dn_help_plugins')
    let g:dn_help_plugins = []
endif
if !exists('g:dn_help_topics')
    let g:dn_help_topics = {}
endif
if !exists('g:dn_help_data')
    let g:dn_help_data = {}
endif
if count(g:dn_help_plugins, 'dn-markdown') == 0
    call add(g:dn_help_plugins, 'dn-markdown')
    if !has_key(g:dn_help_topics, 'vim')
        let g:dn_help_topics['vim'] = {}
    endif
    let g:dn_help_topics['vim']['markdown ftplugin']
                \ = 'vim_markdown_ftplugin'
    let g:dn_help_data['vim_markdown_ftplugin'] = [
        \ 'This markdown ftplugin automates the following tasks:',
        \ '',
        \ '',
        \ '',
        \ 'Task                   Mapping  Command',
        \ '',
        \ '--------------------   -------  ------------',
        \ '',
        \ 'generate html output   \gh      GenerateHTML',
        \ '',
        \ 'generate pdf output    \gp      GeneratePDF',
        \ '',
        \ 'display html output    \vh      ViewHTML',
        \ '',
        \ 'display pdf output     \vp      ViewPDF',
        \ ]
endif

" operating system                                                    {{{2
if has('win32') || has ('win64')
    let s:os = 'win'
elseif has('unix')
    let s:os = 'nix'
endif

" pandoc parameters                                                   {{{2
let s:pandoc_html = {'style': '', 'template': ''}
let s:pandoc_tex = {'template': '', 'fontsize': 0}
let s:pandoc_citeproc = 0    " default

" ========================================================================

" 3.  FUNCTIONS                                                       {{{1

" Function: DNM_HtmlOutput                                            {{{2
" Purpose:  generate html output
" Params:   1 - insert mode [default=<false>, optional, boolean]
" Return:   nil
function! DNM_HtmlOutput(...)
    echo '' |    " clear command line
    " requires dn-utils plugin
    if s:dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    let l:insert = (a:0 > 0 && a:1) ? g:dn_true : g:dn_false
    let l:succeeded = s:html_output_engine()
    if l:succeeded | echo 'Done' | endif
    call dn#util#prompt()
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction
" ------------------------------------------------------------------------
" Function: DNM_ViewHtml                                              {{{2
" Purpose:  view html output
" Params:   1 - insert mode [default=<false>, optional, boolean]
" Return:   nil
function! DNM_ViewHtml(...)
    echo '' |    " clear command line
    " requires dn-utils plugin
    if s:dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    " variables
    let l:insert = (a:0 > 0 && a:1) ? g:dn_true : g:dn_false
    let l:output = substitute(expand('%'), '\.md$', '.html', '')
    " check for file to view
    if !filereadable(l:output)
        call s:html_output_engine()
        if !filereadable(l:output)
            call dn#util#error('No html file to view')
            return
        endif
    endif
    " view html output
    if s:os ==# 'win'
        let l:errmsg = [
                    \   'Unable to display html output',
                    \   'Windows has no default html viewer',
                    \   'Shell feedback:',
                    \ ]
        let l:cmd = shellescape(l:output)
        let l:succeeded = s:execute_shell_command(l:cmd, l:errmsg)
        if l:succeeded
            echo 'Done'
        endif
    elseif s:os ==# 'nix'
        echo '' | " clear command line
        let l:opener = 'xdg-open'
        if executable(l:opener) == 1
            let l:cmd = shellescape(l:opener) . ' ' . shellescape(l:output)
            let l:errmsg = [
                        \   'Unable to display html output',
                        \   l:opener . ' is not configured for html',
                        \   'Shell feedback:',
                        \ ]
            call s:execute_shell_command(l:cmd, l:errmsg)
        else
            call dn#util#error("Could not find '" . l:opener . "'")
        endif
    else
        echo ''
        call dn#util#error('Operating system not supported')
    endif
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction
" ------------------------------------------------------------------------
" Function: DNM_PdfOutput                                            {{{2
" Purpose:  generate pdf output
" Params:   1 - insert mode [default=<false>, optional, boolean]
" Return:   nil
function! DNM_PdfOutput (...)
    echo '' | " clear command line
    " requires dn-utils plugin
    if s:dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    let l:insert = (a:0 > 0 && a:1) ? g:dn_true : g:dn_false
    let l:succeeded = s:pdf_output_engine()
    if l:succeeded | echo 'Done' | endif
    call dn#util#prompt()
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction
" ------------------------------------------------------------------------
" Function: DNM_ViewPdf                                               {{{2
" Purpose:  view pdf output
" Params:   1 - insert mode [default=<false>, optional, boolean]
" Return:   nil
function! DNM_ViewPdf(...)
    echo '' | " clear command line
    " requires dn-utils plugin
    if s:dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    " variables
    let l:insert = (a:0 > 0 && a:1) ? g:dn_true : g:dn_false
    let l:output = substitute(expand('%'), '\.md$', '.pdf', '')
    " check for file to view
    if !filereadable(l:output)
        call s:pdf_output_engine()
        if !filereadable(l:output)
            call dn#util#error('No pdf file to view')
            return
        endif
    endif
    " view pdf output
    if s:os ==# 'win'
        " can't use shell command because starts in foreground
        try
            execute 'silent !start cmd /c "%:r.pdf"'
        catch
            call dn#util#error('Unable to display pdf output')
            call dn#util#error('Windows has no default pdf viewer')
            return
        endtry
    elseif s:os ==# 'nix'
        echo '' | " clear command line
        let l:opener = 'xdg-open'
        if executable(l:opener) == 1
            let l:cmd = shellescape(l:opener) . ' ' . shellescape(l:output)
            let l:errmsg = [
                        \   l:opener . ' is not configured for pdf',
                        \   'Unable to display pdf output',
                        \   'Shell feedback:',
                        \ ]
            call s:execute_shell_command(l:cmd, l:errmsg)
        else
            call dn#util#error("Could not find '" . l:opener . "'")
        endif
    else
        call dn#util#error('Operating system not supported')
    endif
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction
" ------------------------------------------------------------------------
" Function: DNM_AllOutput                                            {{{2
" Purpose:  generate html and pdf output
" Params:   1 - insert mode [default=<false>, optional, boolean]
" Return:   nil
function! DNM_AllOutput (...)
    echo '' | " clear command line
    " requires dn-utils plugin
    if s:dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    let l:insert = (a:0 > 0 && a:1) ? g:dn_true : g:dn_false
    " html output
    let l:succeeded = s:html_output_engine()
    if l:succeeded | echo 'Done'
    else           | call dn#util#prompt()
    endif
    " pdf output
    let l:succeeded = s:pdf_output_engine()
    if l:succeeded | echo 'Done' | endif
    call dn#util#prompt()
    " return to calling mode
    redraw!
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction
" ------------------------------------------------------------------------
" Function: DNM_SetHtmlTemplate                                       {{{2
" Purpose:  set s:pandoc_html['template'] to template parameter
" Params:   1 - template filepath
" Return:   nil
" Note:     this value is passed to pandoc's --template parameter
function! DNM_SetHtmlTemplate(template)
    " requires dn-utils plugin
    if s:dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    let s:pandoc_html['template'] = a:template
endfunction
" ------------------------------------------------------------------------
" Function: DNM_SetLatexTemplate                                      {{{2
" Purpose:  set s:pandoc_tex['template'] to template parameter
" Params:   1 - template filepath
" Return:   nil
" Note:     this value is passed to pandoc's --template parameter
function! DNM_SetLatexTemplate(template)
    " requires dn-utils plugin
    if s:dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    let s:pandoc_tex['template'] = a:template
endfunction
" ------------------------------------------------------------------------
" Function: DNM_SetHtmlStyle                                          {{{2
" Purpose:  set s:pandoc_html['style'] to style file
" Params:   1 - style file path
" Return:   nil
function! DNM_SetHtmlStyle(style)
    " requires dn-utils plugin
    if s:dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    let s:pandoc_html['style'] = a:style
endfunction
" ------------------------------------------------------------------------
" Function: DNM_SetLatexFontsize                                      {{{2
" Purpose:  set s:pandoc_tex['fontsize'] to font size (in points)
" Params:   1 - font size in points (must be 10, 11, 12, 13, or 14)
" Return:   nil
function! DNM_SetLatexFontsize(size)
    " requires dn-utils plugin
    if s:dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    " check value
    let l:valid_fontsizes = [10, 11, 12, 13, 14]
    if !count(l:valid_fontsizes, a:size)
        echoerr 'Font size must be 10, 11, 12, 13 or 14'
        return
    endif
    let s:pandoc_tex['fontsize'] = a:size
endfunction
" ------------------------------------------------------------------------
" Function: DNM_PandocCiteproc                                        {{{2
" Purpose:  set flag to include citeproc filter
" Params:   nil
" Return:   nil
" Note:     adds '--filter citeproc' to pandoc command
" Note:     does not check for installation of filter
function! DNM_PandocCiteproc()
    echo ''    | " clear command line
    " requires dn-utils plugin
    if s:dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    if exists('s:pandoc_citeproc') && s:pandoc_citeproc
        echo 'Already set to use pandoc-citeproc filter'
        return
    endif
    let s:pandoc_citeproc = g:dn_true
    echo 'Now set to use pandoc-citeproc filter'
endfunction
" ------------------------------------------------------------------------
" Function: DNM_NoPandocCiteproc                                      {{{2
" Purpose:  set flag to not include citeproc filter
" Params:   nil
" Return:   nil
function! DNM_NoPandocCiteproc()
    echo ''    | " clear command line
    " requires dn-utils plugin
    if s:dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    if exists('s:pandoc_citeproc') && !s:pandoc_citeproc
        echo 'Already NOT using pandoc-citeproc filter'
        return
    endif
    let s:pandoc_citeproc = g:dn_false
    echo 'Now set to NOT use pandoc-citeproc filter'
endfunction
" ------------------------------------------------------------------------
" Function: s:ensure_html_style                                       {{{2
" Purpose:  set s:pandoc_html['style'] to default if no user value
" Params:   nil
" Return:   nil
function! s:ensure_html_style()
    " requires dn-utils plugin
    if s:dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    " set by user
    if strlen(s:pandoc_html['style']) > 0
        echo 'Stylesheet:    set by user'
        return
    endif
    " no user value so set to default
    let l:style_dirs = globpath(&runtimepath, 'vim-dn-markdown-css', 1, 1)
    let l:style_filepaths = []
    for l:style_dir in l:style_dirs
        call extend(l:style_filepaths,
                    \ glob(l:style_dir . '/*', g:dn_false, g:dn_true))
    endfor
    if len(l:style_filepaths) == 0    " - whoah, something bad has happened
        call dn#util#error('Cannot find default styleheet')
        return
    endif
    " - found expected single match
    if len(l:style_filepaths) == 1
        let s:pandoc_html['style'] = l:style_filepaths[0]
        echo 'Stylesheet:    using default'
        return
    endif
    " - okay, there are multiple css files (how?); let's pick one
    let l:menu_options = {}
    for l:style_filepath in l:style_filepaths
        let l:menu_option = fnamemodify(l:style_filepath, ':t:r')
        let l:menu_options[l:menu_option] = l:style_filepath
    endfor
    let l:style = dn#util#menuSelect(l:menu_options, 'Select style:')
    if strlen(l:style) > 0
        let s:pandoc_html['style'] = l:style
        echo 'Stylesheet:    selected by user'
        return
    endif
    " if here then failed to pick from multiple style files
    " ignore it as user should konw what happened
endfunction
" ------------------------------------------------------------------------
" Function: s:execute_shell_command                                   {{{2
" Purpose:  execute shell command
" Params:   1 - shell command [required, string]
"           2 - error message [optional, List, default='Error occured:']
" Prints:   if error display user error message and shell feedback
" Return:   return status of command as vim boolean
function! s:execute_shell_command(cmd, ...)
    echo '' | " clear command line
    " variables
    if a:0 > 0
        let l:errmsg = a:1
    else
        let l:errmsg = ['Error occurred:']
    endif
    " run command
    let l:shell_feedback = system(a:cmd)
    " if failed display error message and shell feedback
    if v:shell_error
        echo ' ' |    " previous output was echon
        for l:line in l:errmsg
            call dn#util#error(l:line)
        endfor
        echo '--------------------------------------'
        echo l:shell_feedback
        echo '--------------------------------------'
        return g:dn_false
    else
        return g:dn_true
    endif
endfunction
" ------------------------------------------------------------------------
" Function: s:dn_utils_missing                                        {{{2
" Purpose:  determine whether dn-utils plugin is loaded
" Params:   nil
" Prints:   nil
" Return:   whether dn-utils plugin is loaded
function! s:dn_utils_missing()
    return !exists('g:loaded_dn_utils')
endfunction
" ------------------------------------------------------------------------
" Function: s:html_output_engine                                      {{{2
" Purpose:  generate html output
" Params:   nil
" Return:   whether executed without error
function! s:html_output_engine()
    let l:succeeded = g:dn_false
    " can't do this without pandoc
    if !executable('pandoc')
        call dn#util#error('Pandoc is not installed')
        if l:insert | call dn#util#insertMode(g:dn_true) | endif
        return g:dn_false
    endif
    " need to be editing a file rather than nameless buffer
    if bufname('%') ==# ''
        call dn#util#error('Current buffer has no name')
        call dn#util#showMsg("Can fix with 'write' or 'file' command")
        if l:insert | call dn#util#insertMode(g:dn_true) | endif
        return g:dn_false
    endif
    " save file to incorporate any changes
    silent update
    echo 'Target format: html'
    echo 'Converter:     pandoc'
    call s:ensure_html_style()    " set style file
    let l:output = substitute(expand('%'), '\.md$', '.html', '')
    let l:source = expand('%')
    " generate output
    if s:os =~# '^win$\|^nix$'
        let l:opts = ''
        let l:cmd = 'pandoc'
        " set to html5                         -t html5
        let l:cmd .=  ' ' . '-t html5'
        let l:opts .= ', html5'
        " add header and footer                --standalone
        let l:cmd .= ' ' . '--standalone'
        let l:opts .= ', standalone'
        " convert quotes, em|endash, ellipsis  --smart
        let l:cmd .= ' ' . '--smart'
        let l:opts .= ', smart'
        " incorporate external dependencies    --self-contained
        let l:cmd .= ' ' . '--self-contained'
        let l:opts .= ', self-contained'
        " use citeproc if selected by user     --filter pandoc-citeproc
        if s:pandoc_citeproc
            let l:cmd .= ' ' . '--filter pandoc-citeproc'
            let l:opts .= ', pandoc-citeproc'
        endif
        " display options
        let l:opts = strpart(l:opts, 2)
        echo 'Options:       ' . l:opts
        " link to css stylesheet               --css=<stylesheet>
        if filereadable(s:pandoc_html['style'])
            let l:cmd .= ' ' . '--css=' . shellescape(s:pandoc_html['style'])
            echo 'Stylesheet:    ' . s:pandoc_html['style']
        endif
        " use custom template                  --template=<template>
        if strlen(s:pandoc_html['template']) > 0
            let l:cmd .= ' ' . '--template=' . s:pandoc_html['template']
            echo 'Template:      ' . s:pandoc_html['template']
        else
            echo 'Template:      [default]'
        endif
        " output file                          --output=<target_file>
        let l:cmd .= ' ' . '--output=' . shellescape(l:output)
        echo 'Output file:   ' . l:output
        " input file
        let l:errmsg = ['Error occurred during html generation']
        echo 'Generating output... '
        let l:cmd .= ' ' . shellescape(l:source)
        let l:succeeded =  s:execute_shell_command(l:cmd, l:errmsg)
    else
        echo ''
        call dn#util#error('Operating system not supported')
    endif
    return l:succeeded
endfunction
" ------------------------------------------------------------------------
" Function: s:pdf_output_engine                                      {{{2
" Purpose:  generate pdf output
" Params:   1 - insert mode [default=<false>, optional, boolean]
" Return:   whether output completed without error
function! s:pdf_output_engine ()
    let l:succeeded = g:dn_false
    " latex engine
    " - can be pdflatex (default), lualatex or xelatex
    " - xelatex is better at handling exotic unicode
    let l:engine = 'xelatex'
    " need pandoc and latex engine
    if !executable('pandoc')
        call dn#util#error('Install pandoc')
        return g:dn_false
    endif
    if !executable(l:engine)
        call dn#util#error('Install ' . l:engine)
        return g:dn_false
    endif
    " need to be editing a file rather than nameless buffer
    if bufname('%') ==# ''
        call dn#util#error('Current buffer has no name')
        call dn#util#showMsg("Can fix with 'write' or 'file' command")
        if l:insert | call dn#util#insertMode(g:dn_true) | endif
        return g:dn_false
    endif
    " save file to incorporate any changes
    silent update
    echo 'Target format: pdf'
    echo 'Converter:     pandoc'
    let l:output = substitute(expand('%'), '\.md$', '.pdf', '')
    let l:source = expand('%')
    " generate output
    if s:os =~# '^win$\|^nix$'
        let l:opts = ''
        let l:cmd = 'pandoc'
        " use xelatex                          --latex-engine=<engine>
        let l:cmd .= ' ' . '--latex-engine=' . l:engine
        echo 'Latex engine:  ' . l:engine
        " make links visible                   --variable urlcolor=<colour>
        "                                      --variable linkcolor=<colour>
        "                                      --variable citecolor=<colour>
        "                                      --variable toccolor=<colour>
        " - available colours are:
        "   black,     blue, brown,   cyan,  darkgray, gray, green,
        "   lightgray, lime, magenta, olive, orange,   pink, purple,
        "   red,       teal, violet,  white, yellow
        "   [https://en.wikibooks.org/wiki/LaTeX/Colors#Predefined_colors]
        " - if colour is changed here, update documentation
        let l:link_colour = 'gray'
        let l:cmd .= ' ' . '--variable urlcolor=' . l:link_colour
        let l:cmd .= ' ' . '--variable linkcolor=' . l:link_colour
        let l:cmd .= ' ' . '--variable citecolor=' . l:link_colour
        let l:cmd .= ' ' . '--variable toccolor=' . l:link_colour
        echo 'Link colour:   ' . l:link_colour
        " convert quotes, em|endash, ellipsis  --smart
        let l:cmd .= ' ' . '--smart'
        let l:opts .= ', smart'
        " use citeproc if selected by user     --filter pandoc-citeproc
        if s:pandoc_citeproc
            let l:cmd .= ' ' . '--filter pandoc-citeproc'
            let l:opts .= ', pandoc-citeproc'
        endif
        " set custom font size if provided
        if s:pandoc_tex['fontsize']
            let l:font_size = s:pandoc_tex['fontsize'] . 'pt'
            echo 'Font size:     ' . l:font_size
            let l:cmd .= ' ' . '--variable fontsize=' . l:font_size
        else
            echo 'Font size:     default'
        endif
        " display options
        let l:opts = strpart(l:opts, 2)
        echo 'Options:       ' . l:opts
        " use custom template                  --template=<template>
        if strlen(s:pandoc_html['template']) > 0
            let l:cmd .= ' ' . '--template=' . s:pandoc_html['template']
            echo 'Template:      ' . s:pandoc_html['template']
        else
            echo 'Template:      [default]'
        endif
        " output file                          --output=<target_file>
        let l:cmd .= ' ' . '--output=' . shellescape(l:output)
        echo 'Output file:   ' . l:output
        " input file
        let l:errmsg = ['Error occurred during pdf generation']
        echo 'Generating output... '
        let l:cmd .= ' ' . shellescape(l:source)
        let l:succeeded =  s:execute_shell_command(l:cmd, l:errmsg)
    else
        echo ''
        call dn#util#error('Operating system not supported')
    endif
    return l:succeeded
endfunction
" ------------------------------------------------------------------------
" 4.  CONTROL STATEMENTS                                              {{{1

" restore user's cpoptions
let &cpoptions = s:save_cpo

" ========================================================================

" 5.  MAPPINGS AND COMMANDS                                           {{{1

" Mappings:                                                           {{{2

" \gh : generate html output                                          {{{3
if !hasmapto('<Plug>DnGHI')
    imap <buffer> <unique> <LocalLeader>gh <Plug>DnGHI
endif
imap <buffer> <unique> <Plug>DnGHI <Esc>:call DNM_HtmlOutput(g:dn_true)<CR>
if !hasmapto('<Plug>DnGHN')
    nmap <buffer> <unique> <LocalLeader>gh <Plug>DnGHN
endif
nmap <buffer> <unique> <Plug>DnGHN :call DNM_HtmlOutput()<CR>

" \vh : view html output                                              {{{3
if !hasmapto('<Plug>DnVHI')
    imap <buffer> <unique> <LocalLeader>vh <Plug>DnVHI
endif
imap <buffer> <unique> <Plug>DnVHI <Esc>:call DNM_ViewHtml(g:dn_true)<CR>
if !hasmapto('<Plug>DnVHN')
    nmap <buffer> <unique> <LocalLeader>vh <Plug>DnVHN
endif
nmap <buffer> <unique> <Plug>DnVHN :call DNM_ViewHtml()<CR>

" \gp : generate pdf output                                           {{{3
if !hasmapto('<Plug>DnGPI')
    imap <buffer> <unique> <LocalLeader>gp <Plug>DnGPI
endif
imap <buffer> <unique> <Plug>DnGPI <Esc>:call DNM_PdfOutput(g:dn_true)<CR>
if !hasmapto('<Plug>DnGPN')
    nmap <buffer> <unique> <LocalLeader>gp <Plug>DnGPN
endif
nmap <buffer> <unique> <Plug>DnGPN :call DNM_PdfOutput()<CR>

" \vp : view pdf output                                               {{{3
if !hasmapto('<Plug>DnVPI')
    imap <buffer> <unique> <LocalLeader>vp <Plug>DnVPI
endif
imap <buffer> <unique> <Plug>DnVPI <Esc>:call DNM_ViewPdf(g:dn_true)<CR>
if !hasmapto('<Plug>DnVPN')
    nmap <buffer> <unique> <LocalLeader>vp <Plug>DnVPN
endif
nmap <buffer> <unique> <Plug>DnVPN :call DNM_ViewPdf()<CR>

" \ga : generate html and pdf output                                  {{{3
if !hasmapto('<Plug>DnGAI')
    imap <buffer> <unique> <LocalLeader>ga <Plug>DnGAI
endif
imap <buffer> <unique> <Plug>DnGAI <Esc>:call DNM_AllOutput(g:dn_true)<CR>
if !hasmapto('<Plug>DnGAN')
    nmap <buffer> <unique> <LocalLeader>ga <Plug>DnGAN
endif
nmap <buffer> <unique> <Plug>DnGAN :call DNM_AllOutput()<CR>

" Commands:                                                           {{{2

" GenerateHTML : generate HTML output                                 {{{3
command! -buffer GenerateHTML call DNM_HtmlOutput()

" ViewHTML     : view HTML output                                     {{{3
command! -buffer ViewHTML call DNM_ViewHtml()

" FontsizePDF  : set font size for PDF output                         {{{3
command! -buffer -nargs=1 FontsizePDF call DNM_SetLatexFontsize(<args>)

" GeneratePDF  : generate PDF output                                  {{{3
command! -buffer GeneratePDF call DNM_PdfOutput()

" ViewPDF      : view PDF output                                      {{{3
command! -buffer ViewPDF call DNM_ViewPdf()

" GenerateAll  : generate HTML and PDF output                         {{{3
command! -buffer GenerateAll call DNM_AllOutput()

                                                                    " }}}1

" vim: set foldmethod=marker :
