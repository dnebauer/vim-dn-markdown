" Function:    Vim ftplugin for markdown
" Last Change: 2017-07-08
" Maintainer:  David Nebauer <david@nebauer.org>

" Load only once    {{{1
if exists('b:did_dnm_markdown_pandoc') | finish | endif
let b:did_dnm_markdown_pandoc = 1

" Save cpoptions    {{{1
" - avoids unpleasantness from customised 'compatible' settings
let s:save_cpo = &cpoptions
set cpoptions&vim

" Add system help    {{{1
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
    if !has_key(g:dn_help_topics, 'markdown ftplugin')
        let g:dn_help_topics['markdown ftplugin'] = {}
    endif
    let g:dn_help_topics['markdown ftplugin']['tasks']
                \ = 'markdown_ftplugin_tasks'
    let g:dn_help_data['markdown_ftplugin_tasks'] = [
        \ 'This markdown ftplugin automates the following tasks:',
        \ '',
        \ '',
        \ '',
        \ 'Task                       Mapping  Command',
        \ '',
        \ '-------------------------  -------  -------------------',
        \ '',
        \ 'generate output            \og      MDGenerate',
        \ '',
        \ 'regenerate output          \or      MDRegenerate',
        \ '',
        \ 'view output                \ov      MDView',
        \ '',
        \ '',
        \ '',
        \ 'insert equation            \ei      MDEquationInsert',
        \ '',
        \ 'insert figure              \fi      MDFigureInsert',
        \ '',
        \ 'insert table               \ti      MDTableInsert',
        \ '',
        \ '',
        \ '',
        \ 'insert equation reference  \er      MDEquationReference',
        \ '',
        \ 'insert figure reference    \fr      MDFigureReference',
        \ '',
        \ 'insert table reference     \tr      MDTableReference',
        \ ]
    let g:dn_help_topics['markdown ftplugin']['utilities']
                \ = 'markdown_ftplugin_util'
    let g:dn_help_data['markdown_ftplugin_util'] = [
        \ 'This markdown ftplugin has the following utility features:',
        \ '',
        \ '',
        \ '',
        \ 'Feature                  Mapping  Command',
        \ '',
        \ '-----------------------  -------  -----------------',
        \ '',
        \ 'change plugin settings   \se      MDSettings',
        \ '',
        \ 'manually update id list  \iu      MDUpdateIDs',
        \ '',
        \ 'check references         \rc      MDCheckReferences',
        \ ]
endif

" Variables    {{{1
" outputted formats (b:dn_markdown_outputted_formats)    {{{2
let b:dn_markdown_outputted_formats = {}

" settings values (b:dn_markdown_settings)    {{{2
" - keep b:dn_md_settings.stylesheet_html.default = '' as it is set by
"   function dn#markdown#initialise to the stylesheet provided by this
"   plugin (unless it is set by the corresponding config variable)
let b:dn_markdown_settings = {
            \ 'citeproc_all' : {
            \   'label'   : 'Use pandoc-citeproc filter [all formats]',
            \   'value'   : '',
            \   'default' : 0,
            \   'source'  : '',
            \   'allowed' : 'boolean',
            \   'config'  : 'g:DN_markdown_citeproc_all',
            \   'prompt'  : 'Use the pandoc-citeproc filter?',
            \   },
            \ 'exe_pandoc' : {
            \   'label'   : 'Name of pandoc executable',
            \   'value'   : '',
            \   'default' : 'pandoc',
            \   'source'  : '',
            \   'allowed' : 'executable',
            \   'config'  : 'g:DN_markdown_exe_pandoc',
            \   'prompt'  : 'Enter name of pandoc executable:',
            \   },
            \ 'exe_ebook_convert' : {
            \   'label'   : 'Name of ebook-convert executable',
            \   'value'   : '',
            \   'default' : 'ebook-convert',
            \   'source'  : '',
            \   'allowed' : 'executable',
            \   'config'  : 'g:DN_markdown_exe_ebook_convert',
            \   'prompt'  : 'Enter name of ebook-convert executable:',
            \   },
            \ 'fontsize_print' : {
            \   'label'   : 'Output font size (pts) [print only]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : [11, 12, 13, 14],
            \   'config'  : 'g:DN_markdown_fontsize_print',
            \   'prompt'  : 'Select font size (points):',
            \   },
            \ 'pdfengine_print' : {
            \   'label'   : 'PDF engine [print only]',
            \   'value'   : '',
            \   'default' : 'xelatex',
            \   'source'  : '',
            \   'allowed' : ['xelatex', 'lualatex', 'pdflatex'],
            \   'config'  : 'g:DN_markdown_pdfengine_print',
            \   'prompt'  : 'Select pdf engine:',
            \   },
            \ 'linkcolor_print' : {
            \   'label'   : 'Select color for hyperlinks [print only]',
            \   'value'   : '',
            \   'default' : 'gray',
            \   'source'  : '',
            \   'allowed' : ['black',     'blue',    'cyan',
            \                'darkgray',  'gray',    'green',
            \                'lightgray', 'magenta', 'red',
            \                'yellow'],
            \   'config'  : 'g:DN_markdown_linkcolor_print',
            \   'prompt'  : 'Select pdf hyperlink colour:',
            \   },
            \ 'number_equations' : {
            \   'label'   : 'Number equations and equation references',
            \   'value'   : '',
            \   'default' : 1,
            \   'source'  : '',
            \   'allowed' : 'boolean',
            \   'config'  : 'g:DN_markdown_number_equations',
            \   'prompt'  : 'Number equations and equation references?',
            \   },
            \ 'number_figures' : {
            \   'label'   : 'Number figures and figure references',
            \   'value'   : '',
            \   'default' : 1,
            \   'source'  : '',
            \   'allowed' : 'boolean',
            \   'config'  : 'g:DN_markdown_number_figures',
            \   'prompt'  : 'Number figures and figure references?',
            \   },
            \ 'number_start_check' : {
            \   'label'   : 'Check eq/fig/tbl references at startup',
            \   'value'   : '',
            \   'default' : 1,
            \   'source'  : '',
            \   'allowed' : 'boolean',
            \   'config'  : 'g:DN_markdown_number_start_check',
            \   'prompt'  : 'Check eq/fig/tbl references at startup?',
            \   },
            \ 'number_tables' : {
            \   'label'   : 'Number tables and table references',
            \   'value'   : '',
            \   'default' : 1,
            \   'source'  : '',
            \   'allowed' : 'boolean',
            \   'config'  : 'g:DN_markdown_number_tables',
            \   'prompt'  : 'Number tables and table references?',
            \   },
            \ 'papersize_print' : {
            \   'label'   : 'Paper size [print only]',
            \   'value'   : '',
            \   'default' : 'A4',
            \   'source'  : '',
            \   'allowed' : ['A4', 'letter'],
            \   'config'  : 'g:DN_markdown_papersize_print',
            \   'prompt'  : 'Select paper size:',
            \   },
            \ 'stylesheet_docx' : {
            \   'label'   : 'Pandoc stylesheet file [docx]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'path_url',
            \   'config'  : 'g:DN_markdown_stylesheet_docx',
            \   'prompt'  : 'Enter the path/url to the docx stylesheet:',
            \   },
            \ 'stylesheet_epub' : {
            \   'label'   : 'Pandoc stylesheet file [epub]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'path_url',
            \   'config'  : 'g:DN_markdown_stylesheet_epub',
            \   'prompt'  : 'Enter the path/url to the epub stylesheet:',
            \   },
            \ 'stylesheet_html' : {
            \   'label'   : 'Pandoc stylesheet file [html]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'path_url',
            \   'config'  : 'g:DN_markdown_stylesheet_html',
            \   'prompt'  : 'Enter the path/url to the html stylesheet:',
            \   },
            \ 'stylesheet_odt' : {
            \   'label'   : 'Pandoc stylesheet file [odt]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'path_url',
            \   'config'  : 'g:DN_markdown_stylesheet_odt',
            \   'prompt'  : 'Enter the path/url to the odt stylesheet:',
            \   },
            \ 'template_azw3' : {
            \   'label'   : 'Pandoc template file [azw3]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'template_file',
            \   'config'  : 'g:DN_markdown_template_azw3',
            \   'prompt'  : 'Specify the azw3 (epub) template:',
            \   },
            \ 'template_context' : {
            \   'label'   : 'Pandoc template file [context]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'template_file',
            \   'config'  : 'g:DN_markdown_template_context',
            \   'prompt'  : 'Specify the context template:',
            \   },
            \ 'template_docbook' : {
            \   'label'   : 'Pandoc template file [docbook]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'template_file',
            \   'config'  : 'g:DN_markdown_template_docbook',
            \   'prompt'  : 'Specify the docbook template:',
            \   },
            \ 'template_docx' : {
            \   'label'   : 'Pandoc template file [docx]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'template_file',
            \   'config'  : 'g:DN_markdown_template_docx',
            \   'prompt'  : 'Specify the docx template:',
            \   },
            \ 'template_epub' : {
            \   'label'   : 'Pandoc template file [epub]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'template_file',
            \   'config'  : 'g:DN_markdown_template_epub',
            \   'prompt'  : 'Specify the epub template:',
            \   },
            \ 'template_html' : {
            \   'label'   : 'Pandoc template file [html]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'template_file',
            \   'config'  : 'g:DN_markdown_template_html',
            \   'prompt'  : 'Specify the html template:',
            \   },
            \ 'template_latex' : {
            \   'label'   : 'Pandoc template file [latex]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'template_file',
            \   'config'  : 'g:DN_markdown_template_latex',
            \   'prompt'  : 'Specify the latex template:',
            \   },
            \ 'template_mobi' : {
            \   'label'   : 'Pandoc template file [mobi]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'template_file',
            \   'config'  : 'g:DN_markdown_template_mobi',
            \   'prompt'  : 'Specify the mobi (epub) template:',
            \   },
            \ 'template_odt' : {
            \   'label'   : 'Pandoc template file [odt]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'template_file',
            \   'config'  : 'g:DN_markdown_template_odt',
            \   'prompt'  : 'Specify the odt template:',
            \   },
            \ 'template_pdf_context' : {
            \   'label'   : 'Pandoc template file [pdf via context]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'template_file',
            \   'config'  : 'g:DN_markdown_template_pdf_context',
            \   'prompt'  : 'Specify the context template for pdf generation:',
            \   },
            \ 'template_pdf_html' : {
            \   'label'   : 'Pandoc template file [pdf via html]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'template_file',
            \   'config'  : 'g:DN_markdown_template_pdf_html',
            \   'prompt'  : 'Specify the html template for pdf generation:',
            \   },
            \ 'template_pdf_latex' : {
            \   'label'   : 'Pandoc template file [pdf via latex]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'template_file',
            \   'config'  : 'g:DN_markdown_template_pdf_latex',
            \   'prompt'  : 'Specify the latex template for pdf generation:',
            \   },
            \ }
" - note: initialisation process will call s:_set_default_html_stylesheet()
"         to set b:dn_markdown_settings.stylesheet_html as a special case
"         (because ftplugin includes a default html stylesheet)

" referenced types ids and refs (b:dn_markdown_{ids,refs})    {{{2
" - can't use one-liner because lambda confuses the vint syntax checker
"let b:dn_markdown_ids = map(dn#markdown#referenced_types(), {key -> {}})
let b:dn_markdown_ids = {}
for s:type in keys(dn#markdown#referenced_types())
    let b:dn_markdown_ids[s:type] = {}
endfor
unlet s:type
let b:dn_markdown_refs = deepcopy(b:dn_markdown_ids)

" Mappings    {{{1

" \ei : insert equation label    {{{2
if !hasmapto('<Plug>DnEII')
    imap <buffer> <unique> <LocalLeader>ei <Plug>DnEII
endif
imap <buffer> <unique> <Plug>DnEII
            \ <Esc>:call dn#markdown#structureInsert('equation', g:dn_true)<CR>
if !hasmapto('<Plug>DnEIN')
    nmap <buffer> <unique> <LocalLeader>ei <Plug>DnEIN
endif
nmap <buffer> <unique> <Plug>DnEIN
            \ :call dn#markdown#structureInsert('equation')<CR>

" \er : insert equation reference    {{{2
if !hasmapto('<Plug>DnERI')
    imap <buffer> <unique> <LocalLeader>er <Plug>DnERI
endif
imap <buffer> <unique> <Plug>DnERI
            \ <Esc>:call dn#markdown#refInsert('equation', g:dn_true)<CR>
if !hasmapto('<Plug>DnERN')
    nmap <buffer> <unique> <LocalLeader>er <Plug>DnERN
endif
nmap <buffer> <unique> <Plug>DnERN
            \ :call dn#markdown#refInsert('equation')<CR>

" \fi : insert figure    {{{2
if !hasmapto('<Plug>DnFII')
    imap <buffer> <unique> <LocalLeader>fi <Plug>DnFII
endif
imap <buffer> <unique> <Plug>DnFII
            \ <Esc>:call dn#markdown#structureInsert('figure', g:dn_true)<CR>
if !hasmapto('<Plug>DnFIN')
    nmap <buffer> <unique> <LocalLeader>fi <Plug>DnFIN
endif
nmap <buffer> <unique> <Plug>DnFIN
            \ :call dn#markdown#structureInsert('figure')<CR>

" \fr : insert figure reference    {{{2
if !hasmapto('<Plug>DnFRI')
    imap <buffer> <unique> <LocalLeader>fr <Plug>DnFRI
endif
imap <buffer> <unique> <Plug>DnFRI
            \ <Esc>:call dn#markdown#refInsert('figure', g:dn_true)<CR>
if !hasmapto('<Plug>DnFRN')
    nmap <buffer> <unique> <LocalLeader>fr <Plug>DnFRN
endif
nmap <buffer> <unique> <Plug>DnFRN
            \ :call dn#markdown#refInsert('figure')<CR>

" \iu : update lists of ids    {{{2
if !hasmapto('<Plug>DnIUI')
    imap <buffer> <unique> <LocalLeader>iu <Plug>DnIUI
endif
imap <buffer> <unique> <Plug>DnIUI
            \ <Esc>:call dn#markdown#idsUpdate(g:dn_true)<CR>
if !hasmapto('<Plug>DnIUN')
    nmap <buffer> <unique> <LocalLeader>iu <Plug>DnIUN
endif
nmap <buffer> <unique> <Plug>DnIUN
            \ :call dn#markdown#idsUpdate()<CR>

" \og : output generation    {{{2
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

" \or : output regeneration    {{{2
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

" \ov : output viewing    {{{2
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

" \rc : check references    {{{2
if !hasmapto('<Plug>DnRCI')
    imap <buffer> <unique> <LocalLeader>rc <Plug>DnRCI
endif
imap <buffer> <unique> <Plug>DnRCI
            \ <Esc>:call dn#markdown#refsCheck(g:dn_true)<CR>
if !hasmapto('<Plug>DnRCN')
    nmap <buffer> <unique> <LocalLeader>rc <Plug>DnRCN
endif
nmap <buffer> <unique> <Plug>DnRCN
            \ :call dn#markdown#refsCheck()<CR>

" \se : settings edit    {{{2
if !hasmapto('<Plug>DnSEI')
    imap <buffer> <unique> <LocalLeader>se <Plug>DnSEI
endif
imap <buffer> <unique> <Plug>DnSEI
            \ <Esc>:call dn#markdown#settings({'insert': g:dn_true})<CR>
if !hasmapto('<Plug>DnSEN')
    nmap <buffer> <unique> <LocalLeader>se <Plug>DnSEN
endif
nmap <buffer> <unique> <Plug>DnSEN
            \ :call dn#markdown#settings()<CR>

" \ti : insert table title    {{{2
if !hasmapto('<Plug>DnTII')
    imap <buffer> <unique> <LocalLeader>ti <Plug>DnTII
endif
imap <buffer> <unique> <Plug>DnTII
            \ <Esc>:call dn#markdown#structureInsert('table', g:dn_true)<CR>
if !hasmapto('<Plug>DnTIN')
    nmap <buffer> <unique> <LocalLeader>ti <Plug>DnTIN
endif
nmap <buffer> <unique> <Plug>DnTIN
            \ :call dn#markdown#structureInsert('table')<CR>

" \tr : insert table reference    {{{2
if !hasmapto('<Plug>DnTRI')
    imap <buffer> <unique> <LocalLeader>tr <Plug>DnTRI
endif
imap <buffer> <unique> <Plug>DnTRI
            \ <Esc>:call dn#markdown#refInsert('table', g:dn_true)<CR>
if !hasmapto('<Plug>DnTRN')
    nmap <buffer> <unique> <LocalLeader>tr <Plug>DnTRN
endif
nmap <buffer> <unique> <Plug>DnTRN
            \ :call dn#markdown#refInsert('table')<CR>
" }}}2
" Commands    {{{1

" MDCheckReferences   : check references    {{{2
command! -buffer MDCheckReferences
            \ call dn#markdown#refsCheck()

" MDEquationInsert    : insert image    {{{2
command! -buffer MDEquationInsert
            \ call dn#markdown#structureInsert('equation')

" MDEquationReference : insert image reference    {{{2
command! -buffer MDEquationReference
            \ call dn#markdown#refInsert('equation')

" MDGenerate          : generate output    {{{2
command! -buffer -nargs=* -complete=customlist,dn#markdown#completeFormat
            \ MDGenerate
            \ call dn#markdown#generate({'formats': '<args>'})

" MDFigureInsert      : insert image    {{{2
command! -buffer MDFigureInsert
            \ call dn#markdown#structureInsert('figure')

" MDFigureReference   : insert image reference    {{{2
command! -buffer MDFigureReference
            \ call dn#markdown#refInsert('figure')

" MDRegenerate        : regenerate all previous output    {{{2
command! -buffer MDRegenerate
            \ call dn#markdown#regenerate()

" MDSettings          : edit settings    {{{2
command! -buffer MDSettings
            \ call dn#markdown#settings()

" MDTableInsert       : insert image    {{{2
command! -buffer MDTableInsert
            \ call dn#markdown#structureInsert('table')

" MDTableReference    : insert image reference    {{{2
command! -buffer MDTableReference
            \ call dn#markdown#refInsert('table')

" MDUpdateIDs         : update id lists    {{{2
command! -buffer MDUpdateIDs
            \ call dn#markdown#idsUpdate()

" MDView              : view output    {{{2
command! -buffer -nargs=* -complete=customlist,dn#markdown#completeFormat
            \ MDView
            \ call dn#markdown#view({'formats': '<args>'})
" }}}2
" Initialise    {{{1
call dn#markdown#initialise()

" Restore cpoptions    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo                                                         " }}}1

" vim: set foldmethod=marker :
