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

" \gh : generate html output                                               {{{2
if !hasmapto('<Plug>DnGHI')
    imap <buffer> <unique> <LocalLeader>gh <Plug>DnGHI
endif
imap <buffer> <unique> <Plug>DnGHI
            \ <Esc>:call dn#markdown#htmlOutput(g:dn_true)<CR>
if !hasmapto('<Plug>DnGHN')
    nmap <buffer> <unique> <LocalLeader>gh <Plug>DnGHN
endif
nmap <buffer> <unique> <Plug>DnGHN
            \ :call dn#markdown#htmlOutput()<CR>

" \vh : view html output                                                   {{{2
if !hasmapto('<Plug>DnVHI')
    imap <buffer> <unique> <LocalLeader>vh <Plug>DnVHI
endif
imap <buffer> <unique> <Plug>DnVHI
            \ <Esc>:call dn#markdown#viewHtml(g:dn_true)<CR>
if !hasmapto('<Plug>DnVHN')
    nmap <buffer> <unique> <LocalLeader>vh <Plug>DnVHN
endif
nmap <buffer> <unique> <Plug>DnVHN
            \ :call dn#markdown#viewHtml()<CR>

" \gp : generate pdf output                                                {{{2
if !hasmapto('<Plug>DnGPI')
    imap <buffer> <unique> <LocalLeader>gp <Plug>DnGPI
endif
imap <buffer> <unique> <Plug>DnGPI
            \ <Esc>:call dn#markdown#pdfOutput(g:dn_true)<CR>
if !hasmapto('<Plug>DnGPN')
    nmap <buffer> <unique> <LocalLeader>gp <Plug>DnGPN
endif
nmap <buffer> <unique> <Plug>DnGPN
            \ :call dn#markdown#pdfOutput()<CR>

" \vp : view pdf output                                                    {{{2
if !hasmapto('<Plug>DnVPI')
    imap <buffer> <unique> <LocalLeader>vp <Plug>DnVPI
endif
imap <buffer> <unique> <Plug>DnVPI
            \ <Esc>:call dn#markdown#viewPdf(g:dn_true)<CR>
if !hasmapto('<Plug>DnVPN')
    nmap <buffer> <unique> <LocalLeader>vp <Plug>DnVPN
endif
nmap <buffer> <unique> <Plug>DnVPN
            \ :call dn#markdown#viewPdf()<CR>

" \ga : generate html and pdf output                                       {{{2
if !hasmapto('<Plug>DnGAI')
    imap <buffer> <unique> <LocalLeader>ga <Plug>DnGAI
endif
imap <buffer> <unique> <Plug>DnGAI
            \ <Esc>:call dn#markdown#allOutput(g:dn_true)<CR>
if !hasmapto('<Plug>DnGAN')
    nmap <buffer> <unique> <LocalLeader>ga <Plug>DnGAN
endif
nmap <buffer> <unique> <Plug>DnGAN
            \ :call dn#markdown#allOutput()<CR>
                                                                         " }}}2

" Commands                                                                 {{{1

" GenerateHTML : generate HTML output                                      {{{2
command! -buffer GenerateHTML
            \ call dn#markdown#htmlOutput()

" ViewHTML     : view HTML output                                          {{{2
command! -buffer ViewHTML
            \ call dn#markdown#viewHtml()

" FontsizePDF  : set font size for PDF output                              {{{2
command! -buffer -nargs=1 FontsizePDF
            \ call dn#markdown#setLatexFontsize(<args>)

" GeneratePDF  : generate PDF output                                       {{{2
command! -buffer GeneratePDF
            \ call dn#markdown#pdfOutput()

" ViewPDF      : view PDF output                                           {{{2
command! -buffer ViewPDF
            \ call dn#markdown#viewPdf()

" GenerateAll  : generate HTML and PDF output                              {{{2
command! -buffer GenerateAll
            \ call dn#markdown#allOutput()
                                                                         " }}}2

" Restore cpoptions                                                        {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo                                                         " }}}1

" vim: set foldmethod=marker :
