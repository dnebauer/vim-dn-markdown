" Function:    Vim ftplugin for markdown
" Last Change: 2015-04-29
" Maintainer:  David Nebauer <david@nebauer.org>
" License:     Public domain

" 1.  CONTROL STATEMENTS                                              {{{1

" Only do this when not done yet for this buffer
if exists('b:did_markdown_pandoc') | finish | endif
let b:did_markdown_pandoc = 1

" Use default cpoptions to avoid unpleasantness from customised
" 'compatible' settings
let s:save_cpo = &cpo
set cpo&vim

" Warn if dn-utils plugin is not detected
if !exists('b:do_not_load_dn_utils')
    echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
    echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
endif

" ========================================================================

" 2.  VARIABLES                                                       {{{1

" help                                                                {{{2
if !exists( 'b:dn_help_plugins' )
    let b:dn_help_plugins = []
endif
if !exists( 'b:dn_help_topics' )
    let b:dn_help_topics = {}
endif
if !exists( 'b:dn_help_data' )
    let b:dn_help_data = {}
endif
if count( b:dn_help_plugins, 'dn-markdown' ) == 0
    call add( b:dn_help_plugins, 'dn-markdown' )
    let b:dn_help_topics['vim']['markdown ftplugin'] 
                \ = 'vim_markdown_ftplugin'
    let b:dn_help_data['vim_markdown_ftplugin'] = [ 
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

" vim home variable                                                   {{{2
if s:os == 'win'
    let $VIMHOME = $HOME . '\\vimfiles'
elseif s:os == 'nix'
    let $VIMHOME = $HOME . '/.vim'
endif                                                               " }}}2

" ========================================================================

" 3.  FUNCTIONS                                                       {{{1

" Function: s:get_css_dir                                             {{{2
" Purpose:  get path to plugin css directory
" Params:   nil
" Return:   string
function! s:get_css_dir()
    let l:rtp_dirs = split(&runtimepath, ',')
    let l:css_dirs = []
    for l:dir in l:rtp_dirs
        let l:css_dir = l:dir . '/vim-dn-markdown-css'
        echo l:css_dir
        if isdirectory(l:css_dir)
            call add(l:css_dirs, l:css_dir)
        endif
    endfor
    for l:dir in l:css_dirs
        echo l:dir
    endfor
endfunction
" ------------------------------------------------------------------------
" Function: DNM_HtmlOutput                                            {{{2
" Purpose:  generate html output
" Params:   1 - insert mode [default=<false>, optional, boolean]
" Return:   nil
function! DNM_HtmlOutput(...)
	echo '' | " clear command line

    call s:get_css_dir()
    return

    " variables
    let l:insert = ( a:0 > 0 && a:1 ) ? b:dn_true : b:dn_false
    let l:style = $VIMHOME . '\\after\\ftplugin\\markdown\\buttondown.css'
    let l:output = substitute( expand('%'), '\.md$', '.html', '' )
    let l:source = expand('%')
    " generate output
    echon 'Generating html... '
    if s:os == 'win'
        if !executable('pandoc')
            call DNU_Error('Pandoc is not installed')
            return
        endif
        let l:cmd = 'pandoc' . ' '
                    \ . '-t html5' . ' '
                    \ . '--standalone' . ' '
                    \ . '--smart' . ' '
                    \ . '--self-contained' . ' '
        if filereadable(l:style)
            let l:cmd .= '--css=' . shellescape(l:style)  . ' '
        endif
        let l:cmd .= '-o' . ' ' . shellescape(l:output) . ' '
        let l:cmd .= shellescape(l:source)
        call system(l:cmd)
        if v:shell_error
            call DNU_Error('Error occurred during html generation')
            return
        endif
    elseif s:os == 'nix'
        echo ''
        call DNU_Error('Not yet implemented for linux/unix')
    else
        echo ''
        call DNU_Error('Operating system not supported')
    endif
    echon 'Done.' | sleep 1 | redraw!
    " return to calling mode
    if l:insert | call DNU_InsertMode(b:dn_true) | endif
endfunction
" ------------------------------------------------------------------------
" Function: DNM_ViewHtml                                              {{{2
" Purpose:  view html output
" Params:   1 - insert mode [default=<false>, optional, boolean]
" Return:   nil
function! DNM_ViewHtml(...)
	echo '' | " clear command line
    " variables
    let l:insert = ( a:0 > 0 && a:1 ) ? b:dn_true : b:dn_false
    let l:output = substitute( expand('%'), '\.md$', '.html', '' )
    " check for file to view
    if !filereadable(l:output)
        call DNU_Error('No html file to view')
        return
    endif
    " view html output
    if s:os == 'win'
        call system(shellescape(l:output))
        if v:shell_error
            call DNU_Error('Unable to display html output')
            call DNU_Error('Windows has no default html viewer')
            return
        endif
    elseif s:os == 'nix'
        echo ''
        echoerr 'Not yet implemented for linux/unix'
    else
        echo ''
        echoerr 'Operating system not supported'
    endif
    " return to calling mode
    if l:insert | call DNU_InsertMode(b:dn_true) | endif
endfunction
" ------------------------------------------------------------------------
" Function: DNM_PdfOutput                                            {{{2
" Purpose:  generate pdf output
" Params:   1 - insert mode [default=<false>, optional, boolean]
" Return:   nil
function! DNM_PdfOutput (...)
	echo '' | " clear command line
    " variables
    let l:insert = ( a:0 > 0 && a:1 ) ? b:dn_true : b:dn_false
    let l:output = substitute( expand('%'), '\.md$', '.pdf', '' )
    let l:source = expand('%')
    " generate output
    echon 'Generating pdf... '
    if s:os == 'win'
        if !executable('pandoc')
            call DNU_Error('Pandoc is not installed')
            return
        endif
        if !executable('lualatex')
            call DNU_Error('Lualatex is not installed')
            return
        endif
        let l:cmd = 'pandoc' . ' '
                    \ . '--smart' . ' '
                    \ . '-o' . ' ' . shellescape(l:output) . ' '
                    \ . '--latex-engine=lualatex' . ' '
                    \ . shellescape(l:source)
        call system(l:cmd)
        if v:shell_error
            call DNU_Error('Error occurred during pdf generation')
            return
        endif
    elseif s:os == 'nix'
        echo ''
        echoerr 'Not yet implemented for linux/unix'
    else
        echo ''
        echoerr 'Operating system not supported'
    endif
    echon 'Done.' | sleep 1 | redraw!
    " return to calling mode
    if l:insert | call DNU_InsertMode(b:dn_true) | endif
endfunction
" ------------------------------------------------------------------------
" Function: DNM_ViewPdf                                               {{{2
" Purpose:  view pdf output
" Params:   1 - insert mode [default=<false>, optional, boolean]
" Return:   nil
function! DNM_ViewPdf(...)
	echo '' | " clear command line
    " variables
    let l:insert = ( a:0 > 0 && a:1 ) ? b:dn_true : b:dn_false
    let l:output = substitute( expand('%'), '\.md$', '.pdf', '' )
    " check for file to view
    if !filereadable(l:output)
        call DNU_Error('No pdf file to view')
        return
    endif
    " view pdf output
    if s:os == 'win'
        try
            execute 'silent !start cmd /c "%:r.pdf"'
        catch
            call DNU_Error('Unable to display pdf output')
            call DNU_Error('Windows has no default pdf viewer')
            return
        endtry
    elseif s:os == 'nix'
        echo ''
        echoerr 'Not yet implemented for linux/unix'
    else
        echoerr 'Operating system not supported'
    endif
    " return to calling mode
    if l:insert | call DNU_InsertMode(b:dn_true) | endif
endfunction

" ========================================================================

" 4.  CONTROL STATEMENTS                                              {{{1

" restore user's cpoptions
let &cpo = s:save_cpo

" ========================================================================

" 5.  MAPPINGS AND COMMANDS                                           {{{1

" Mappings:                                                           {{{2

" \gh : generate html output                                          {{{3
if !hasmapto( '<Plug>DnGHI' )
	imap <buffer> <unique> <LocalLeader>gh <Plug>DnGHI
endif
imap <buffer> <unique> <Plug>DnGHI <Esc>:call DNM_HtmlOutput( b:dn_true )<CR>
if !hasmapto( '<Plug>DnGHN' )
	nmap <buffer> <unique> <LocalLeader>gh <Plug>DnGHN
endif
nmap <buffer> <unique> <Plug>DnGHN :call DNM_HtmlOutput()<CR>

" \vh : view html output                                              {{{3
if !hasmapto( '<Plug>DnVHI' )
	imap <buffer> <unique> <LocalLeader>vh <Plug>DnVHI
endif
imap <buffer> <unique> <Plug>DnVHI <Esc>:call DNM_ViewHtml( b:dn_true )<CR>
if !hasmapto( '<Plug>DnVHN' )
	nmap <buffer> <unique> <LocalLeader>vh <Plug>DnVHN
endif
nmap <buffer> <unique> <Plug>DnVHN :call DNM_ViewHtml()<CR>

" \gp : generate pdf output                                           {{{3
if !hasmapto( '<Plug>DnGPI' )
	imap <buffer> <unique> <LocalLeader>gp <Plug>DnGPI
endif
imap <buffer> <unique> <Plug>DnGPI <Esc>:call DNM_PdfOutput( b:dn_true )<CR>
if !hasmapto( '<Plug>DnGPN' )
	nmap <buffer> <unique> <LocalLeader>gp <Plug>DnGPN
endif
nmap <buffer> <unique> <Plug>DnGPN :call DNM_PdfOutput()<CR>

" \vp : view pdf output                                               {{{3
if !hasmapto( '<Plug>DnVPI' )
	imap <buffer> <unique> <LocalLeader>vp <Plug>DnVPI
endif
imap <buffer> <unique> <Plug>DnVPI <Esc>:call DNM_ViewPdf( b:dn_true )<CR>
if !hasmapto( '<Plug>DnVPN' )
	nmap <buffer> <unique> <LocalLeader>vp <Plug>DnVPN
endif
nmap <buffer> <unique> <Plug>DnVPN :call DNM_ViewPdf()<CR>

" Commands:                                                           {{{2

" GenerateHTML : generate HTML output                                 {{{3
command GenerateHTML call DNM_HtmlOutput()

" ViewHTML : view HTML output                                         {{{3
command ViewHTML call DNM_ViewHtml()

" GeneratePDF : generate PDF output                                   {{{3
command GeneratePDF call DNM_PdfOutput()

" ViewPDF : view PDF output                                           {{{3
command ViewPDF call DNM_ViewPdf()

                                                                    " }}}1

" vim: set foldmethod=marker :
