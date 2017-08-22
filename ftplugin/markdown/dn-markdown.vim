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

" \ui : update lists of ids                                                {{{2
if !hasmapto('<Plug>DnUII')
    imap <buffer> <unique> <LocalLeader>ui <Plug>DnUII
endif
imap <buffer> <unique> <Plug>DnUII
            \ <Esc>:call dn#markdown#idsUpdate(g:dn_true)<CR>
if !hasmapto('<Plug>DnUIN')
    nmap <buffer> <unique> <LocalLeader>ui <Plug>DnUIN
endif
nmap <buffer> <unique> <Plug>DnUIN
            \ :call dn#markdown#idsUpdate()<CR>

" \ii : insert image                                                       {{{2
if !hasmapto('<Plug>DnIII')
    imap <buffer> <unique> <LocalLeader>ii <Plug>DnIII
endif
imap <buffer> <unique> <Plug>DnIII
            \ <Esc>:call dn#markdown#imageInsert(g:dn_true)<CR>
if !hasmapto('<Plug>DnIIN')
    nmap <buffer> <unique> <LocalLeader>ii <Plug>DnIIN
endif
nmap <buffer> <unique> <Plug>DnIIN
            \ :call dn#markdown#imageInsert()<CR>

" \ie : insert equation reference                                          {{{2
if !hasmapto('<Plug>DnIEI')
    imap <buffer> <unique> <LocalLeader>ie <Plug>DnIEI
endif
imap <buffer> <unique> <Plug>DnIEI
            \ <Esc>:call dn#markdown#equationRef(g:dn_true)<CR>
if !hasmapto('<Plug>DnIEN')
    nmap <buffer> <unique> <LocalLeader>ie <Plug>DnIEN
endif
nmap <buffer> <unique> <Plug>DnIEN
            \ :call dn#markdown#equationRef()<CR>

" \ir : insert image reference                                             {{{2
if !hasmapto('<Plug>DnIRI')
    imap <buffer> <unique> <LocalLeader>ir <Plug>DnIRI
endif
imap <buffer> <unique> <Plug>DnIRI
            \ <Esc>:call dn#markdown#imageRef(g:dn_true)<CR>
if !hasmapto('<Plug>DnIRN')
    nmap <buffer> <unique> <LocalLeader>ir <Plug>DnIRN
endif
nmap <buffer> <unique> <Plug>DnIRN
            \ :call dn#markdown#imageRef()<CR>

" \it : insert table reference                                             {{{2
if !hasmapto('<Plug>DnITI')
    imap <buffer> <unique> <LocalLeader>it <Plug>DnITI
endif
imap <buffer> <unique> <Plug>DnITI
            \ <Esc>:call dn#markdown#tableRef(g:dn_true)<CR>
if !hasmapto('<Plug>DnITN')
    nmap <buffer> <unique> <LocalLeader>it <Plug>DnITN
endif
nmap <buffer> <unique> <Plug>DnITN
            \ :call dn#markdown#tableRef()<CR>
                                                                         " }}}2
" Commands                                                                 {{{1

" EquationReference : insert image reference                               {{{2
command! -buffer EquationReference
            \ call dn#markdown#equationRef()

" Generate          : generate output                                      {{{2
command! -buffer -nargs=? -complete=customlist,dn#markdown#completeFormat
            \ Generate
            \ call dn#markdown#generate({'format': '<args>'})

" ImageInsert       : insert image                                         {{{2
command! -buffer ImageInsert
            \ call dn#markdown#imageInsert()

" ImageReference    : insert image reference                               {{{2
command! -buffer ImageReference
            \ call dn#markdown#imageRef()

" Regenerate        : regenerate all previous output                       {{{2
command! -buffer Regenerate
            \ call dn#markdown#regenerate()

" Settings          : edit settings                                        {{{2
command! -buffer Settings
            \ call dn#markdown#settings()

" TableReference    : insert image reference                               {{{2
command! -buffer TableReference
            \ call dn#markdown#tableRef()

" UpdateIDs         : update id lists                                      {{{2
command! -buffer UpdateIDs
            \ call dn#markdown#idsUpdate()

" View              : view output                                          {{{2
command! -buffer -nargs=? -complete=customlist,dn#markdown#completeFormat
            \ View
            \ call dn#markdown#view({'format': '<args>'})
                                                                         " }}}2
" Initialise                                                               {{{1
call dn#markdown#initialise()

" Restore cpoptions                                                        {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo                                                         " }}}1

" vim: set foldmethod=marker :
