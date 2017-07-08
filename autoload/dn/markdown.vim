" Title:   autoload script for vim-dn-markdown ftplugin
" Author:  David Nebauer
" URL:     https://github.com/dnebauer/vim-dn-markdown

" Load only once                                                           {{{1
if exists('g:loaded_dn_markdown_autoload') | finish | endif
let g:loaded_dn_markdown_autoload = 1

" Save coptions                                                            {{{1
let s:save_cpo = &cpoptions
set cpoptions&vim

" Variables                                                                {{{1
" operating system                                                         {{{2
if has('win32') || has ('win64')
    let s:os = 'win'
elseif has('unix')
    let s:os = 'nix'
endif

" pandoc parameters                                                        {{{2
" - settings menu returns one of:
"   . fontsize_pdf
"   . citeproc_all
"   . stylesheet_{docx,epub,html}
"   . template_{docx,epub,html,pdf}
"   . '' (if no item selected)
let s:menu_prompt = 'Select setting to modify:'
let s:menu_items = [
            \   { '__PARENT_ITEM__'        : 'Font size (points)',
            \     'Font size (pdf)'        : 'fontsize_pdf' },
            \   { '__PARENT_ITEM__'        : 'Pandoc-citeproc filter',
            \     'Citeproc (all formats)' : 'citeproc_all' },
            \   { '__PARENT_ITEM__'        : 'Stylesheet file',
            \     'Stylesheet (docx)'      : 'stylesheet_docx',
            \     'Stylesheet (epub)'      : 'stylesheet_epub',
            \     'Stylesheet (html)'      : 'stylesheet_html' },
            \   { '__PARENT_ITEM__'        : 'Template file',
            \     'Template (docx)'        : 'template_docx',
            \     'Template (epub)'        : 'template_epub',
            \     'Template (html)'        : 'template_html',
            \     'Template (latex/pdf)'   : 'template_pdf' },
            \ ]
let b:dn_md_settings = {
            \ 'fontsize_pdf' : {
            \   'value'   : '',
            \   'allowed' : [11, 12, 13, 14],
            \   'preset'  : 'g:DN_markdown_fontsize_pdf',
            \   'prompt'  : 'Select font size (points):',
            \ },
            \ 'citeproc_all' : {
            \   'value'   : 0,
            \   'allowed' : 'boolean',
            \   'preset'  : 'g:DN_markdown_citeproc_all',
            \   'prompt'  : 'Use the pandoc-citeproc filter?',
            \ },
            \ 'stylesheet_docx' : {
            \   'value'   : '',
            \   'allowed' : 'file_url',
            \   'preset'  : 'g:DN_markdown_stylesheet_docx',
            \   'prompt'  : 'Enter the path/url to the docx stylesheet:',
            \ },
            \ 'stylesheet_epub' : {
            \   'value'   : '',
            \   'allowed' : 'file_url',
            \   'preset'  : 'g:DN_markdown_stylesheet_epub',
            \   'prompt'  : 'Enter the path/url to the epub stylesheet:',
            \ },
            \ 'stylesheet_html' : {
            \   'value'   : '',
            \   'allowed' : 'file_url',
            \   'preset'  : 'g:DN_markdown_stylesheet_html',
            \   'prompt'  : 'Enter the path/url to the html stylesheet:',
            \ },
            \ 'template_docx' : {
            \   'value'   : '',
            \   'allowed' : 'file_url',
            \   'preset'  : 'g:DN_markdown_template_docx',
            \   'prompt'  : 'Enter the path/url to the docx template:',
            \ },
            \ 'template_epub' : {
            \   'value'   : '',
            \   'allowed' : 'file_url',
            \   'preset'  : 'g:DN_markdown_template_epub',
            \   'prompt'  : 'Enter the path/url to the epub template:',
            \ },
            \ 'template_html' : {
            \   'value'   : '',
            \   'allowed' : 'file_url',
            \   'preset'  : 'g:DN_markdown_template_html',
            \   'prompt'  : 'Enter the path/url to the html template:',
            \ },
            \ 'template_pdf' : {
            \   'value'   : '',
            \   'allowed' : 'file_url',
            \   'preset'  : 'g:DN_markdown_template_pdf',
            \   'prompt'  : 'Enter the path/url to the latex/pdf template:',
            \ },
            \ }
" TODO retire s:pandoc_[html|tex] in favour of b:dn_md_pandoc_params
let s:pandoc_html = {'style': '', 'template': ''}
let s:pandoc_tex = {'template': '', 'fontsize': 0}
" TODO wrap buffer vars in exists() conditional to ensure set only once
" TODO convert to b:pandoc_citeproc
let s:pandoc_citeproc = 0    " default
let s:pandoc_params = {
            \ 'docx': {
            \         'format'    : 'Microsoft Word (docx)',
            \         'extension' : '.docx',
            \         'pandoc_to' : 'docx',
            \         'params'    : ['standalone', 'smart',
            \                        'style_docx', 'template'],
            \         },
            \ 'epub': {
            \         'format'    : 'Electronic publication (ePub)',
            \         'extension' : '.epub',
            \         'pandoc_to' : 'epub3',
            \         'params'    : ['standalone', 'smart',
            \                        'style_epub'],
            \         },
            \ 'html': {
            \         'format'    : 'HTML',
            \         'extension' : '.html',
            \         'pandoc_to' : 'html5',
            \         'params'    : ['standalone',    'smart',
            \                        'selfcontained', 'citeproc',
            \                        'style_html',    'template'],
            \         },
            \ 'pdf':  {
            \         'format'    : 'Portable Document Format (pdf)',
            \         'extension' : '.pdf',
            \         'pandoc_to' : 'latex',
            \         'params'    : ['standalone',  'smart',
            \                        'latexengine', 'links',
            \                        'smart',       'citeproc',
            \                        'fontsize',    'template'],
            \         },
            \ }                                                          " }}}2

" Public functions                                                         {{{1

" dn#markdown#htmlOutput([insert])                                         {{{2
" does:   generate html output
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#htmlOutput(...) abort
    echo '' |    " clear command line
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    let l:insert = (a:0 > 0 && a:1) ? g:dn_true : g:dn_false
    let l:succeeded = s:_html_output_engine()
    if l:succeeded | echo 'Done' | endif
    call dn#util#prompt()
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#viewHtml([insert])                                           {{{2
" does:   view html output
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#viewHtml(...) abort
    echo '' |    " clear command line
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    " variables
    let l:insert = (a:0 > 0 && a:1) ? g:dn_true : g:dn_false
    let l:output = substitute(expand('%'), '\.md$', '.html', '')
    " check for file to view
    if !filereadable(l:output)
        call s:_html_output_engine()
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
        let l:succeeded = s:_execute_shell_command(l:cmd, l:errmsg)
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
            call s:_execute_shell_command(l:cmd, l:errmsg)
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

" dn#markdown#output([insert])                                             {{{2
" does:   generate output
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#output(...) abort
    echo '' | " clear command line
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    " note user mode
    let l:insert = (a:0 > 0 && a:1) ? g:dn_true : g:dn_false
    " select output format
    let l:format = s:_output_format()
    if l:format
        let l:succeeded = s:_output_engine(l:format)
        if l:succeeded | echo 'Done' | endif
    else
        echo 'No output format selected'
    endif
    call dn#util#prompt()
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#pdfOutput([insert])                                          {{{2
" does:   generate pdf output
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#pdfOutput(...) abort
    echo '' | " clear command line
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    let l:insert = (a:0 > 0 && a:1) ? g:dn_true : g:dn_false
    let l:succeeded = s:_pdf_output_engine()
    if l:succeeded | echo 'Done' | endif
    call dn#util#prompt()
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#viewPdf([insert])                                            {{{2
" does:   view pdf output
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#viewPdf(...) abort
    echo '' | " clear command line
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    " variables
    let l:insert = (a:0 > 0 && a:1) ? g:dn_true : g:dn_false
    let l:output = substitute(expand('%'), '\.md$', '.pdf', '')
    " check for file to view
    if !filereadable(l:output)
        call s:_pdf_output_engine()
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
            call s:_execute_shell_command(l:cmd, l:errmsg)
        else
            call dn#util#error("Could not find '" . l:opener . "'")
        endif
    else
        call dn#util#error('Operating system not supported')
    endif
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#allOutput([insert])                                          {{{2
" does:   generate html and pdf output
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#allOutput(...) abort
    echo '' | " clear command line
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    let l:insert = (a:0 > 0 && a:1) ? g:dn_true : g:dn_false
    " html output
    let l:succeeded = s:_html_output_engine()
    if l:succeeded | echo 'Done'
    else           | call dn#util#prompt()
    endif
    " pdf output
    let l:succeeded = s:_pdf_output_engine()
    if l:succeeded | echo 'Done' | endif
    call dn#util#prompt()
    " return to calling mode
    redraw!
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#setHtmlTemplate(template)                                    {{{2
" does:   set s:pandoc_html['template'] to template parameter
" params: template - template filepath
" return: nil
" note:   this value is passed to pandoc's --template parameter
function! dn#markdown#setHtmlTemplate(template) abort
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    let s:pandoc_html['template'] = a:template
endfunction

" dn#markdown#setLatexTemplate(template)                                   {{{2
" does:   set s:pandoc_tex['template'] to template parameter
" params: template - template filepath
" return: nil
" note:   this value is passed to pandoc's --template parameter
function! dn#markdown#setLatexTemplate(template) abort
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    let s:pandoc_tex['template'] = a:template
endfunction

" dn#markdown#setHtmlStyle(style)                                          {{{2
" does:   set s:pandoc_html['style'] to style file
" params: style - style file path
" return: nil
function! dn#markdown#setHtmlStyle(style) abort
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    let s:pandoc_html['style'] = a:style
endfunction

" dn#markdown#setLatexFontsize(size)                                       {{{2
" does:   set s:pandoc_tex['fontsize'] to font size (in points)
" params: size - font size in points (must be 10, 11, 12, 13, or 14)
" return: nil
function! dn#markdown#setLatexFontsize(size) abort
    " requires dn-utils plugin
    if s:_dn_utils_missing()
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

" dn#markdown#pandocCiteproc()                                             {{{2
" does:   set flag to include citeproc filter
" params: nil
" return: nil
" note:   adds '--filter citeproc' to pandoc command
" note:   does not check for installation of filter
function! dn#markdown#pandocCiteproc() abort
    echo ''    | " clear command line
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    if exists('s:pandoc_citeproc') && s:pandoc_citeproc
        call s:_say('Already set to use pandoc-citeproc filter')
        return
    endif
    let s:pandoc_citeproc = g:dn_true
    call s:_say('Now set to use pandoc-citeproc filter')
endfunction

" dn#markdown#noPandocCiteproc()                                           {{{2
" does:   set flag to not include citeproc filter
" params: nil
" return: nil
function! dn#markdown#noPandocCiteproc() abort
    echo ''    | " clear command line
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    if exists('s:pandoc_citeproc') && !s:pandoc_citeproc
        call s:_say('Already NOT using pandoc-citeproc filter')
        return
    endif
    let s:pandoc_citeproc = g:dn_false
    call s:_say('Now set to NOT use pandoc-citeproc filter')
endfunction                                                              " }}}2

" Private functions                                                        {{{1

" s:_say(msg)                                                              {{{2
" does:   echo line of output with wrapping
" params: msg - message to display [string]
" return: nil
function! s:_say(msg) abort
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    " print wrapped output
    call dn#util#wrap(a:msg, 15)
endfunction

" s:_ensure_html_style()                                       {{{2
" does:   set s:pandoc_html['style'] to default if no user value
" params: nil
" return: nil
function! s:_ensure_html_style() abort
    " requires dn-utils plugin
    if s:_dn_utils_missing()
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return
    endif
    " set by user
    if strlen(s:pandoc_html['style']) > 0
        call s:_say('Stylesheet:    set by user')
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
        call s:_say('Stylesheet:    using default')
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
        call s:_say('Stylesheet:    selected by user')
        return
    endif
    " if here then failed to pick from multiple style files
    " ignore it as user should konw what happened
endfunction

" s:_execute_shell_command(cmd,[err])                                      {{{2
" does:   execute shell command
" params: cmd - shell command [required, string]
"         err - error message [optional, List, default='Error occured:']
" prints: if error display user error message and shell feedback
" return: return status of command as vim boolean
function! s:_execute_shell_command(cmd, ...) abort
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
        call s:_say(l:shell_feedback)
        echo '--------------------------------------'
        return g:dn_false
    else
        return g:dn_true
    endif
endfunction

" s:_dn_utils_missing()                                                    {{{2
" does:   determine whether dn-utils plugin is loaded
" params: nil
" prints: nil
" return: whether dn-utils plugin is loaded
function! s:_dn_utils_missing() abort
    return !exists('g:loaded_dn_utils')
endfunction

" s:_html_output_engine()                                                  {{{2
" does:   generate html output
" params: nil
" return: whether executed without error
function! s:_html_output_engine() abort
    let l:succeeded = g:dn_false
    " can't do this without pandoc
    if !executable('pandoc')
        call dn#util#error('Pandoc is not installed')
        return g:dn_false
    endif
    " need to be editing a file rather than nameless buffer
    if bufname('%') ==# ''
        call dn#util#error('Current buffer has no name')
        call dn#util#showMsg("Can fix with 'write' or 'file' command")
        return g:dn_false
    endif
    " save file to incorporate any changes
    silent update
    call s:_say('Target format: html')
    call s:_say('Converter:     pandoc')
    call s:_ensure_html_style()    " set style file
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
        call s:_say('Options:       ' . l:opts)
        " link to css stylesheet               --css=<stylesheet>
        if filereadable(s:pandoc_html['style'])
            let l:cmd .= ' ' . '--css=' . shellescape(s:pandoc_html['style'])
            call s:_say('Stylesheet:    ' . s:pandoc_html['style'])
        endif
        " use custom template                  --template=<template>
        if strlen(s:pandoc_html['template']) > 0
            let l:cmd .= ' ' . '--template=' . s:pandoc_html['template']
            call s:_say('Template:      ' . s:pandoc_html['template'])
        else
            call s:_say('Template:      [default]')
        endif
        " output file                          --output=<target_file>
        let l:cmd .= ' ' . '--output=' . shellescape(l:output)
        call s:_say('Output file:   ' . l:output)
        " input file
        let l:errmsg = ['Error occurred during html generation']
        call s:_say('Generating output... ')
        let l:cmd .= ' ' . shellescape(l:source)
        let l:succeeded =  s:_execute_shell_command(l:cmd, l:errmsg)
    else
        echo ''
        call dn#util#error('Operating system not supported')
    endif
    return l:succeeded
endfunction

" s:_output_engine(format)                                                 {{{2
" does:   generate output
" params: fomat - output format [required, must be 'pdf'|'html'|'docx'|'epub']
" return: whether output completed without error
function! s:_output_engine (format) abort
endfunction

" s:_output_format(prompt)                                                 {{{2
" does:   select output format
" params: prompt - prompt [string, optional, default='Select output format:']
" return: output format (a key to s:pandoc_params)
function! s:_output_format (prompt) abort
    let l:prompt = empty(a:prompt) ? 'Select output format:' : a:prompt
    " create dict with format names as keys, format codes as values
    let l:format_codes = {}
    for [l:key, l:val] in items(s:pandoc_params)
        let l:format_codes[l:val['format']] = l:key
    endfor
    " select format name
    let l:format_names = keys(s:pandoc_params)
    let l:format_name = dn#util#menuSelect(l:format_names, l:prompt)
    " look up corresponding format code
    if empty(l:format_name) | return | endif
    let l:format_code = l:format_codes[l:format_name]
    if empty(l:format_code)
        call dn#util#error('No valid output format selected')
    endif
    return l:format_code
endfunction

" s:_pdf_output_engine()                                                   {{{2
" does:   generate pdf output
" params: nil
" return: whether output completed without error
function! s:_pdf_output_engine () abort
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
        return g:dn_false
    endif
    " save file to incorporate any changes
    silent update
    call s:_say('Target format: pdf')
    call s:_say('Converter:     pandoc')
    let l:output = substitute(expand('%'), '\.md$', '.pdf', '')
    let l:source = expand('%')
    " generate output
    if s:os =~# '^win$\|^nix$'
        let l:opts = ''
        let l:cmd = 'pandoc'
        " use xelatex                          --latex-engine=<engine>
        let l:cmd .= ' ' . '--latex-engine=' . l:engine
        call s:_say('Latex engine:  ' . l:engine)
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
        call s:_say('Link colour:   ' . l:link_colour)
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
            call s:_say('Font size:     ' . l:font_size)
            let l:cmd .= ' ' . '--variable fontsize=' . l:font_size
        else
            call s:_say('Font size:     default')
        endif
        " display options
        let l:opts = strpart(l:opts, 2)
        call s:_say('Options:       ' . l:opts)
        " use custom template                  --template=<template>
        if strlen(s:pandoc_html['template']) > 0
            let l:cmd .= ' ' . '--template=' . s:pandoc_html['template']
            call s:_say('Template:      ' . s:pandoc_html['template'])
        else
            call s:_say('Template:      [default]')
        endif
        " output file                          --output=<target_file>
        let l:cmd .= ' ' . '--output=' . shellescape(l:output)
        call s:_say('Output file:   ' . l:output)
        " input file
        let l:errmsg = ['Error occurred during pdf generation']
        call s:_say('Generating output... ')
        let l:cmd .= ' ' . shellescape(l:source)
        let l:succeeded =  s:_execute_shell_command(l:cmd, l:errmsg)
    else
        echo ''
        call dn#util#error('Operating system not supported')
    endif
    return l:succeeded
endfunction                                                              " }}}2

" Restore cpoptions                                                        {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo                                                         " }}}1

" vim: set foldmethod=marker :
