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

" \ei : insert equation id                                                 {{{2
if !hasmapto('<Plug>DnEII')
    imap <buffer> <unique> <LocalLeader>ei <Plug>DnEII
endif
imap <buffer> <unique> <Plug>DnEII
            \ <Esc>:call dn#markdown#equationInsert(g:dn_true)<CR>
if !hasmapto('<Plug>DnEIN')
    nmap <buffer> <unique> <LocalLeader>ei <Plug>DnEIN
endif
nmap <buffer> <unique> <Plug>DnEIN
            \ :call dn#markdown#equationInsert()<CR>

" \fi : insert figure                                                      {{{2
if !hasmapto('<Plug>DnFII')
    imap <buffer> <unique> <LocalLeader>fi <Plug>DnFII
endif
imap <buffer> <unique> <Plug>DnFII
            \ <Esc>:call dn#markdown#figureInsert(g:dn_true)<CR>
if !hasmapto('<Plug>DnFIN')
    nmap <buffer> <unique> <LocalLeader>fi <Plug>DnFIN
endif
nmap <buffer> <unique> <Plug>DnFIN
            \ :call dn#markdown#figureInsert()<CR>

" \ti : insert table title                                                 {{{2
if !hasmapto('<Plug>DnTII')
    imap <buffer> <unique> <LocalLeader>ti <Plug>DnTII
endif
imap <buffer> <unique> <Plug>DnTII
            \ <Esc>:call dn#markdown#tableInsert(g:dn_true)<CR>
if !hasmapto('<Plug>DnTIN')
    nmap <buffer> <unique> <LocalLeader>ti <Plug>DnTIN
endif
nmap <buffer> <unique> <Plug>DnTIN
            \ :call dn#markdown#tableInsert()<CR>

" \er : insert equation reference                                          {{{2
if !hasmapto('<Plug>DnERI')
    imap <buffer> <unique> <LocalLeader>er <Plug>DnERI
endif
imap <buffer> <unique> <Plug>DnERI
            \ <Esc>:call dn#markdown#equationRef(g:dn_true)<CR>
if !hasmapto('<Plug>DnERN')
    nmap <buffer> <unique> <LocalLeader>er <Plug>DnERN
endif
nmap <buffer> <unique> <Plug>DnERN
            \ :call dn#markdown#equationRef()<CR>

" \fr : insert figure reference                                            {{{2
if !hasmapto('<Plug>DnFRI')
    imap <buffer> <unique> <LocalLeader>fr <Plug>DnFRI
endif
imap <buffer> <unique> <Plug>DnFRI
            \ <Esc>:call dn#markdown#figureRef(g:dn_true)<CR>
if !hasmapto('<Plug>DnFRN')
    nmap <buffer> <unique> <LocalLeader>fr <Plug>DnFRN
endif
nmap <buffer> <unique> <Plug>DnFRN
            \ :call dn#markdown#figureRef()<CR>

" \tr : insert table reference                                             {{{2
if !hasmapto('<Plug>DnTRI')
    imap <buffer> <unique> <LocalLeader>tr <Plug>DnTRI
endif
imap <buffer> <unique> <Plug>DnTRI
            \ <Esc>:call dn#markdown#tableRef(g:dn_true)<CR>
if !hasmapto('<Plug>DnTRN')
    nmap <buffer> <unique> <LocalLeader>tr <Plug>DnTRN
endif
nmap <buffer> <unique> <Plug>DnTRN
            \ :call dn#markdown#tableRef()<CR>
                                                                         " }}}2
" Commands                                                                 {{{1

" EquationInsert    : insert image                                         {{{2
command! -buffer EquationInsert
            \ call dn#markdown#equationInsert()

" EquationReference : insert image reference                               {{{2
command! -buffer EquationReference
            \ call dn#markdown#equationRef()

" Generate          : generate output                                      {{{2
command! -buffer -nargs=? -complete=customlist,dn#markdown#completeFormat
            \ Generate
            \ call dn#markdown#generate({'format': '<args>'})

" FigureInsert      : insert image                                         {{{2
command! -buffer FigureInsert
            \ call dn#markdown#figureInsert()

" FigureReference   : insert image reference                               {{{2
command! -buffer FigureReference
            \ call dn#markdown#figureRef()

" Regenerate        : regenerate all previous output                       {{{2
command! -buffer Regenerate
            \ call dn#markdown#regenerate()

" Settings          : edit settings                                        {{{2
command! -buffer Settings
            \ call dn#markdown#settings()

" TableInsert       : insert image                                         {{{2
command! -buffer TableInsert
            \ call dn#markdown#tableInsert()

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
