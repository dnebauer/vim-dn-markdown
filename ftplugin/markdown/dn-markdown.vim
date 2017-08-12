" Function:    Vim ftplugin for markdown
" Last Change: 2017-07-08
" Maintainer:  David Nebauer <david@nebauer.org>

" Load only once                                                           {{{1
if exists('b:did_dnm_markdown_pandoc') | finish | endif
let b:did_dnm_markdown_pandoc = 1

" Save cpoptions                                                           {{{1
" - avoids unpleasantness from customised 'compatible' settings
let s:save_cpo = &cpoptions
set cpoptions&vim

" Help variables                                                           {{{1
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

" Mappings                                                                 {{{1

" \og : output generation                                                  {{{2
if !hasmapto('<Plug>DnOGI')
    imap <buffer> <unique> <LocalLeader>og <Plug>DnOGI
endif
imap <buffer> <unique> <Plug>DnOGI
            \ <Esc>:call dn#markdown#generate({'insert': g:dn_true})<CR>
if !hasmapto('<Plug>DnOGN')
    nmap <buffer> <unique> <LocalLeader>og <Plug>DnOGN
endif
nmap <buffer> <unique> <Plug>DnOGN
            \ :call dn#markdown#generate()<CR>

" \or : output regeneration                                                {{{2
if !hasmapto('<Plug>DnORI')
    imap <buffer> <unique> <LocalLeader>or <Plug>DnORI
endif
imap <buffer> <unique> <Plug>DnORI
            \ <Esc>:call dn#markdown#regenerate(g:dn_true)<CR>
if !hasmapto('<Plug>DnORN')
    nmap <buffer> <unique> <LocalLeader>or <Plug>DnORN
endif
nmap <buffer> <unique> <Plug>DnORN
            \ :call dn#markdown#regenerate()<CR>

" \ov : output viewing                                                     {{{2
if !hasmapto('<Plug>DnOVI')
    imap <buffer> <unique> <LocalLeader>ov <Plug>DnOVI
endif
imap <buffer> <unique> <Plug>DnOVI
            \ <Esc>:call dn#markdown#view({'insert': g:dn_true})<CR>
if !hasmapto('<Plug>DnOVN')
    nmap <buffer> <unique> <LocalLeader>ov <Plug>DnOVN
endif
nmap <buffer> <unique> <Plug>DnOVN
            \ :call dn#markdown#view()<CR>

" \es : edit settings                                                      {{{2
if !hasmapto('<Plug>DnESI')
    imap <buffer> <unique> <LocalLeader>es <Plug>DnESI
endif
imap <buffer> <unique> <Plug>DnESI
            \ <Esc>:call dn#markdown#settings({'insert': g:dn_true})<CR>
if !hasmapto('<Plug>DnESN')
    nmap <buffer> <unique> <LocalLeader>es <Plug>DnESN
endif
nmap <buffer> <unique> <Plug>DnESN
            \ :call dn#markdown#settings()<CR>
" \ii : insert image                                                       {{{2
if !hasmapto('<Plug>DnIII')
    imap <buffer> <unique> <LocalLeader>ii <Plug>DnIII
endif
imap <buffer> <unique> <Plug>DnIII
            \ <Esc>:call dn#markdown#image(g:dn_true)<CR>
if !hasmapto('<Plug>DnIIN')
    nmap <buffer> <unique> <LocalLeader>ii <Plug>DnIIN
endif
nmap <buffer> <unique> <Plug>DnIIN
            \ :call dn#markdown#image()<CR>

                                                                         " }}}2

" Commands                                                                 {{{1

" Generate   : generate output                                             {{{2
command! -buffer -nargs=? -complete=customlist,dn#markdown#complete
            \ Generate
            \ call dn#markdown#generate({'format': '<args>'})

" Regenerate : regenerate all previous output                              {{{2
command! -buffer Regenerate
            \ call dn#markdown#regenerate()

" View       : view output                                                 {{{2
command! -buffer -nargs=? -complete=customlist,dn#markdown#complete
            \ View
            \ call dn#markdown#view({'format': '<args>'})

" Settings   : edit settings                                               {{{2
command! -buffer Settings
            \ call dn#markdown#settings()
" Image      : insert image                                                {{{2
command! -buffer Image
            \ call dn#markdown#image()
                                                                         " }}}2

" Restore cpoptions                                                        {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo                                                         " }}}1

" vim: set foldmethod=marker :
