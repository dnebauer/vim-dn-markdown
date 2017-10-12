" Title:   autoload script for vim-dn-markdown ftplugin
" Author:  David Nebauer
" URL:     https://github.com/dnebauer/vim-dn-markdown

" Load only once    {{{1
if exists('g:loaded_dn_markdown_autoload') | finish | endif
let g:loaded_dn_markdown_autoload = 1

" Save coptions    {{{1
let s:save_cpo = &cpoptions
set cpoptions&vim

" Variables    {{{1
" buffer variables are defined in the main ftplugin file    {{{2
" - brute force solution to some difficult-to-resolve initialisation
"   errors when opening new markdown files in new buffers in a vim
"   instance that already has a markdown file open
" - buffer variables are:
"   * b:dn_markdown_outputted_formats
"   * b:dn_markdown_settings
"   * b:dn_markdown_ids
"   * b:dn_markdown_refs
" operating system (s:dn_markdown_os)    {{{2
let s:dn_markdown_os = (has('win32') || has ('win64')) ? 'win'
            \      : has('unix') ? 'nix'
            \      : ''

" pandoc settings menu (s:dn_markdown_menu_{items,prompt})    {{{2
" - returns one of:
"   . citeproc_all
"   . {fontsize,linkcolor,pdfengine}_pdf
"   . stylesheet_{docx,epub,html}
"   . template_{docx,epub,html,pdf}
"   . '' (if no item selected)
let s:dn_markdown_menu_prompt = 'Select setting to modify:'
let s:dn_markdown_menu_items = {
            \ 'Citeproc (all formats)'   : 'citeproc_all',
            \ 'Converters (all formats)' : [
            \   {'pandoc'        : 'exe_pandoc'},
            \   {'ebook-convert' : 'exe_ebook_convert'},
            \   ],
            \ 'Number cross-references (all formats)' : [
            \   {'Figures'   : 'number_figures'},
            \   {'Tables'    : 'number_tables'},
            \   {'Equations' : 'number_equations'},
            \   ],
            \ 'Print only' : [
            \   {'Font size (print)'   : 'fontsize_print'},
            \   {'Link colour (print)' : 'linkcolor_print'},
            \   {'PDF engine (print)'  : 'pdfengine_print'},
            \   {'Paper size (print)'  : 'papersize_print'},
            \   ],
            \ 'Stylesheet file' : [
            \   {'Stylesheet (docx)' : 'stylesheet_docx'},
            \   {'Stylesheet (epub)' : 'stylesheet_epub'},
            \   {'Stylesheet (html)' : 'stylesheet_html'},
            \   {'Stylesheet (odt)'  : 'stylesheet_odt'},
            \   ],
            \ 'Template file' : [
            \   {'Template (azw3 via epub)'    : 'template_azw3'},
            \   {'Template (context)'          : 'template_context'},
            \   {'Template (docbook)'          : 'template_docbook'},
            \   {'Template (docx)'             : 'template_docx'},
            \   {'Template (epub)'             : 'template_epub'},
            \   {'Template (html)'             : 'template_html'},
            \   {'Template (latex)'            : 'template_latex'},
            \   {'Template (mobi via epub)'    : 'template_mobi'},
            \   {'Template (odt)'              : 'template_odt'},
            \   {'Template (pdf via context)'  : 'template_pdf_context'},
            \   {'Template (pdf via html)'     : 'template_pdf_html'},
            \   {'Template (pdf via latex)'    : 'template_pdf_latex'},
            \   ],
            \ }
" pandoc parameters to set (s:dn_markdown_pandoc_params)    {{{2
"
" ---- format: human-readable description of format;
"              ***warning*** formats must be unique
"              for function s:_select_format to work
" ---- depend: executables required for conversion
" - pandoc_to: value to provide to pandoc's '--to' option
" - after_ext: extension of pandoc's output file
" -- postproc: whether there is further conversion after pandoc
" - final_ext: extension given to final output file, i.e., after
"              post-pandoc processing when that occurs; where there
"              is no post-pandoc processing is the same as 'after_ext'
" ---- params: refers to keywords that each signify a parameter/option
"              to add to pandoc command
let s:dn_markdown_pandoc_params = {
            \ 'azw3' : {
            \   'format'    : 'Kindle Format 8 (azw3) via ePub',
            \   'depend'    : ['pandoc', 'ebook-convert'],
            \   'pandoc_to' : 'epub3',
            \   'after_ext' : '.epub',
            \   'postproc'  : g:dn_true,
            \   'final_ext' : '.azw3',
            \   'params'    : '*** copy from |epub| format ***',
            \   },
            \ 'context' : {
            \   'format'    : 'ConTeXt (tex)',
            \   'depend'    : ['pandoc', 'context'],
            \   'pandoc_to' : 'context',
            \   'after_ext' : '.tex',
            \   'postproc'  : g:dn_false,
            \   'final_ext' : '.tex',
            \   'params'    : ['figures',      'equations', 'tables',
            \                  'standalone',   'smart',     'citeproc',
            \                  'contextlinks', 'papersize', 'template',
            \                  'fontsize'],
            \   },
            \ 'docbook' : {
            \   'format'    : 'DocBook (xml)',
            \   'depend'    : ['pandoc'],
            \   'pandoc_to' : 'docbook5',
            \   'after_ext' : '.xml',
            \   'postproc'  : g:dn_false,
            \   'final_ext' : '.xml',
            \   'params'    : ['figures',    'equations', 'tables',
            \                  'standalone', 'template',  'citeproc'],
            \   },
            \ 'docx' : {
            \   'format'    : 'Microsoft Word (docx)',
            \   'depend'    : ['pandoc'],
            \   'pandoc_to' : 'docx',
            \   'after_ext' : '.docx',
            \   'postproc'  : g:dn_false,
            \   'final_ext' : '.docx',
            \   'params'    : ['figures',    'equations', 'tables',
            \                  'standalone', 'smart',     'citeproc',
            \                  'style_docx', 'template'],
            \   },
            \ 'epub' : {
            \   'format'    : 'Electronic publication (ePub)',
            \   'depend'    : ['pandoc'],
            \   'pandoc_to' : 'epub3',
            \   'after_ext' : '.epub',
            \   'postproc'  : g:dn_false,
            \   'final_ext' : '.epub',
            \   'params'    : ['figures',    'equations', 'tables',
            \                  'standalone', 'smart',     'style_epub',
            \                  'cover_epub', 'citeproc',  'template'],
            \   },
            \ 'html' : {
            \   'format'    : 'HyperText Markup Language (html)',
            \   'depend'    : ['pandoc'],
            \   'pandoc_to' : 'html5',
            \   'after_ext' : '.html',
            \   'postproc'  : g:dn_false,
            \   'final_ext' : '.html',
            \   'params'    : ['figures',    'equations',  'tables',
            \                  'standalone', 'smart',      'selfcontained',
            \                  'citeproc',   'style_html', 'template'],
            \   },
            \ 'latex' : {
            \   'format'    : 'LaTeX (tex)',
            \   'depend'    : ['pandoc', 'latex'],
            \   'pandoc_to' : 'latex',
            \   'after_ext' : '.tex',
            \   'postproc'  : g:dn_false,
            \   'final_ext' : '.tex',
            \   'params'    : ['figures',     'equations', 'tables',
            \                  'standalone',  'citeproc',  'smart',
            \                  'pdfengine', 'fontsize',  'latexlinks',
            \                  'papersize',   'template'],
            \   },
            \ 'mobi' : {
            \   'format'    : 'Mobipocket e-book (mobi) via ePub',
            \   'depend'    : ['pandoc'],
            \   'pandoc_to' : 'epub3',
            \   'after_ext' : '.epub',
            \   'postproc'  : g:dn_true,
            \   'final_ext' : '.mobi',
            \   'params'    : '*** copy from |epub| format ***',
            \   },
            \ 'odt' : {
            \   'format'    : 'OpenDocument Text (odt)',
            \   'depend'    : ['pandoc'],
            \   'pandoc_to' : 'odt',
            \   'after_ext' : '.odt',
            \   'postproc'  : g:dn_false,
            \   'final_ext' : '.odt',
            \   'params'    : ['figures',    'equations', 'tables',
            \                  'standalone', 'smart',     'citeproc',
            \                  'style_odt',  'template'],
            \   },
            \ 'pdf_context' : {
            \   'format'    : 'Portable Document Format (pdf) via ConTeXt',
            \   'depend'    : ['pandoc', 'context'],
            \   'pandoc_to' : 'context',
            \   'after_ext' : '.pdf',
            \   'postproc'  : g:dn_false,
            \   'final_ext' : '.pdf',
            \   'params'    : '***copy from |context| format ***',
            \   },
            \ 'pdf_html' : {
            \   'format'    : 'Portable Document Format (pdf) via HTML',
            \   'depend'    : ['pandoc', 'wkhtmltopdf'],
            \   'pandoc_to' : 'html5',
            \   'after_ext' : '.pdf',
            \   'postproc'  : g:dn_false,
            \   'final_ext' : '.pdf',
            \   'params'    : '*** copy from |html| format ***',
            \   },
            \ 'pdf_latex' : {
            \   'format'    : 'Portable Document Format (pdf) via LaTeX',
            \   'depend'    : ['pandoc', 'latex'],
            \   'pandoc_to' : 'latex',
            \   'after_ext' : '.pdf',
            \   'postproc'  : g:dn_false,
            \   'final_ext' : '.pdf',
            \   'params'    : '*** copy from |latex| format ***',
            \   },
            \ }
" - azw3 and mobi are produced by first creating an epub output file
let s:dn_markdown_pandoc_params.azw3.params
            \ = s:dn_markdown_pandoc_params.epub.params
let s:dn_markdown_pandoc_params.mobi.params
            \ = s:dn_markdown_pandoc_params.epub.params
" - pdf creation is based on context, html or latex
let s:dn_markdown_pandoc_params.pdf_context.params
            \ = s:dn_markdown_pandoc_params.context.params
let s:dn_markdown_pandoc_params.pdf_html.params
            \ = s:dn_markdown_pandoc_params.html.params
let s:dn_markdown_pandoc_params.pdf_latex.params
            \ = s:dn_markdown_pandoc_params.latex.params

" numbered structures (s:dn_markdown_numbered_types)    {{{2
let s:dn_markdown_numbered_types = {
            \ 'equation' : {
            \   'prefix'   : 'eq',
            \   'name'     : 'equation',
            \   'Name'     : 'Equation',
            \   'complete' : 'dn#markdown#completeIdEquation',
            \   },
            \ 'figure' : {
            \   'prefix'   : 'fig',
            \   'name'     : 'figure',
            \   'Name'     : 'Figure',
            \   'complete' : 'dn#markdown#completeIdFigure',
            \   },
            \ 'table' : {
            \   'prefix'   : 'tbl',
            \   'name'     : 'table',
            \   'Name'     : 'Table',
            \   'complete' : 'dn#markdown#completeIdTable',
            \   },
            \ }
function! dn#markdown#numbered_types() abort
    return copy(s:dn_markdown_numbered_types)
endfunction

" hanging indent    {{{2
" - default hanging indent
let s:dn_markdown_hang = 15

" Public functions    {{{1

" dn#markdown#completeFormat(A, L, P)    {{{2
" does:   return completion candidates for output formats
" params: ArgLead   - see help for |command-completion-custom|
"         CmdLine   - see help for |command-completion-custom|
"         CursorPos - see help for |command-completion-custom|
" return: List of output formats
function! dn#markdown#completeFormat(A, L, P) abort
    let l:formats = sort(keys(s:dn_markdown_pandoc_params))
    return filter(l:formats, 'v:val =~# "^' . a:A . '"')
endfunction

" dn#markdown#completeIdEquation(A, L, P)    {{{2
" does:   perform completion on equation ids
" params: ArgLead   - see help for |command-completion-custom|
"         CmdLine   - see help for |command-completion-custom|
"         CursorPos - see help for |command-completion-custom|
" return: List of ids
function! dn#markdown#completeIdEquation(A, L, P) abort
    let l:ids = sort(keys(b:dn_markdown_ids.equation))
    return filter(l:ids, 'v:val =~# "' . a:A . '"')
endfunction

" dn#markdown#completeIdFigure(A, L, P)    {{{2
" does:   perform completion on figure ids
" params: ArgLead   - see help for |command-completion-custom|
"         CmdLine   - see help for |command-completion-custom|
"         CursorPos - see help for |command-completion-custom|
" return: List of ids
function! dn#markdown#completeIdFigure(A, L, P) abort
    let l:ids = sort(keys(b:dn_markdown_ids.figure))
    return filter(l:ids, 'v:val =~# "' . a:A . '"')
endfunction

" dn#markdown#completeIdTable(A, L, P)    {{{2
" does:   perform completion on table ids
" params: ArgLead   - see help for |command-completion-custom|
"         CmdLine   - see help for |command-completion-custom|
"         CursorPos - see help for |command-completion-custom|
" return: List of ids
function! dn#markdown#completeIdTable(A, L, P) abort
    let l:ids = sort(keys(b:dn_markdown_ids.table))
    return filter(l:ids, 'v:val =~# "' . a:A . '"')
endfunction

" dn#markdown#equationInsert([insert])    {{{2
" does:   insert equation at cursor location
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#equationInsert(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " insert image
    call s:_equation_insert()
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#equationRef([insert])    {{{2
" does:   insert equation reference at cursor location
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" prints: equation reference
" return: nil
function! dn#markdown#equationRef(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " insert image
    call s:_reference_insert('equation')
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#figureInsert([insert])    {{{2
" does:   insert figure following current line
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#figureInsert(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " insert image
    call s:_figure_insert()
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#figureRef([insert])    {{{2
" does:   insert figure reference at cursor location
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" prints: figure reference
" return: nil
function! dn#markdown#figureRef(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " insert image
    call s:_reference_insert('figure')
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#generate([params])    {{{2
" does:   generate output
" params: params - parameters dictionary with the following keys:
"                  'insert' - whether entered from insert mode
"                             [optional, default=<false>, boolean]
"                  'format' - output format
"                             [optional, no default,
"                              must be a key of s:dn_markdown_pandoc_params]
" return: nil
function! dn#markdown#generate(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " process params
    let [l:insert, l:format] = s:_process_dict_params(a:000)
    if empty(l:format) | let l:format = s:_select_format() | endif
    if empty(l:format) | return | endif
    " generate output
    let l:more = &more
    set nomore
    if s:_generator(l:format) | echo 'Done' | endif
    call dn#util#prompt()
    redraw!
    let &more = l:more
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#idsUpdate([insert])    {{{2
" does:   update id lists for equations, figures and tables
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#idsUpdate(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " update ids
    call s:_update_ids('equation', 'figure', 'table')
    echo 'Updated lists of equation, figure and table ids'
    call dn#util#prompt()
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#initialise()    {{{2
" does:   initialise plugin
" params: nil
" return: nil
function! dn#markdown#initialise() abort
    if s:_utils_missing() | return | endif |  " requires dn-utils plugin
    " set default html stylesheet (because it must be set dynamically, unlike
    " other settings set statically with b:dn_markdown_settings variable)
    silent call s:_set_default_html_stylesheet()
    " set parameters from configuration variables where available,
    " otherwise set to their default values
    silent call s:_settings_configure()
    " check equation, table and figure refs (and update indices)
    if b:dn_markdown_settings.number_start_check.value
        call s:_check_refs(g:dn_true)
    endif
endfunction

" dn#markdown#refsCheck([insert])    {{{2
" does:   check all references
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#refsCheck(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " check for previous output
    let l:more = &more
    set nomore
    call s:_check_refs()
    call dn#util#prompt()
    redraw!
    let &more = l:more
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#regenerate([insert])    {{{2
" does:   regenerate all previously outputted files
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#regenerate(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " check for previous output
    let l:more = &more
    set nomore
    let l:formats = keys(b:dn_markdown_outputted_formats)
    if empty(l:formats)  " inform user
        let l:msg = 'No output files have been generated during this session'
        call dn#util#warn(l:msg)
    else  " generate output
        let l:succeeded = g:dn_true
        for l:format in l:formats
            if !s:_generator(l:format) | let l:succeeded = g:dn_false | endif
        endfor
        if l:succeeded | echo 'Done'
        else           | call dn#util#error('Problems occurred during output')
        endif
    endif
    call dn#util#prompt()
    redraw!
    let &more = l:more
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#settings()    {{{2
" does:   change settings, e.g., b:dn_markdown_settings.<var>.value
" params: nil
" return: nil, edits b:dn_markdown_settings in place
function! dn#markdown#settings() abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif |  " requires dn-utils plugin
    " get setting to edit
    let l:more = &more
    set nomore
    let l:setting = dn#util#menuSelect(s:dn_markdown_menu_items,
                \                      s:dn_markdown_menu_prompt)
    while count(keys(b:dn_markdown_settings), l:setting) == 1
        let l:label   = b:dn_markdown_settings[l:setting]['label']
        let l:value   = b:dn_markdown_settings[l:setting]['value']
        let l:source  = b:dn_markdown_settings[l:setting]['source']
        let l:allowed = b:dn_markdown_settings[l:setting]['allowed']
        let l:prompt  = b:dn_markdown_settings[l:setting]['prompt'] . ' '
        " notify user of current setting
        echo l:label
        call s:_say({'msg': ['Current value:',
                    \ s:_display_value(l:value, l:setting)]})
        call s:_say({'msg': ['Source:', l:source]})
        " display allowed values and get user input
        if     type(l:allowed) == type([])
            call s:_say({'msg': ['Allowed:', join(l:allowed, ', ')]})
            let l:options = []
            for l:option in sort(l:allowed)
                let l:item = (type(l:option) == type('')) ? l:option
                            \                             : string(l:option)
                call add(l:options, {l:item : l:option})
            endfor
            let l:input = dn#util#menuSelect(l:options, l:prompt)
        elseif l:allowed ==# 'boolean'
            call s:_say({'msg': ['Allowed:', 'Yes, No']})
            let l:options = [{'Yes': g:dn_true}, {'No': g:dn_false}]
            let l:input = dn#util#menuSelect(l:options, l:prompt)
        elseif l:allowed ==# 'executable'
            call s:_say({'msg': ['Allowed:', '[valid executable file name]']})
            let l:input = input(l:prompt, l:value, 'file_in_path')
            echo ' '  | " ensure move to a new line
        elseif l:allowed ==# 'path_url'
            call s:_say({'msg': ['Allowed:', '[valid file path or url]']})
            let l:input = input(l:prompt, l:value, 'file')
            echo ' '  | " ensure move to a new line
        elseif l:allowed ==# 'template_file'
            call s:_say({'msg': ['Allowed:',
                        \ '[valid base/file name, file path or url]']})
            let l:input = input(l:prompt, l:value, 'file')
            echo ' '  | " ensure move to a new line
        else  " script error!
            call dn#util#error("Invalid 'allowed' value: '" . l:allowed . "'")
            let &more = l:more
            return
        endif
        " validate input
        if s:_valid_setting_value(l:input, l:setting)
            let b:dn_markdown_settings[l:setting]['value']  = l:input
            let b:dn_markdown_settings[l:setting]['source'] = 'set by user'
            call s:_say({'msg': ['Now set to:',
                        \ s:_display_value(l:input, l:setting)]})
        else
            call dn#util#error('Error: Not a valid value')
        endif
        " get next setting to change
        let l:setting = dn#util#menuSelect(s:dn_markdown_menu_items,
                    \                      s:dn_markdown_menu_prompt)
    endwhile
    let &more = l:more
endfunction

" dn#markdown#tableInsert([insert])    {{{2
" does:   insert table title following current line
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#tableInsert(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " insert image
    call s:_table_insert()
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#tableRef([insert])    {{{2
" does:   insert table reference at cursor location
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" prints: table reference
" return: nil
function! dn#markdown#tableRef(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1)
    " insert image
    call s:_reference_insert('table')
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#view([params])    {{{2
" does:   view output of a specified format
" params: params - parameters dictionary with the following keys:
"                  'insert' - whether entered from insert mode
"                             [optional, default=<false>, boolean]
"                  'format' - output format
"                             [optional, no default,
"                              must be a key of s:dn_markdown_pandoc_params]
" return: nil
" note:   output is always (re)generated before viewing
function! dn#markdown#view(...) abort
    " universal tasks    {{{3
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif |  " requires dn-utils plugin
    " process params    {{{3
    let [l:insert, l:format] = s:_process_dict_params(a:000)
    let l:more = &more
    set nomore
    try
        if empty(l:format) | let l:format = s:_select_format() | endif
        if empty(l:format) | return | endif
        " (re)generate output    {{{3
        let l:more = &more
        set nomore
        if !s:_generator(l:format) | 
            throw 'Output (re)generation failed' |
        endif
        " check for output file to view    {{{3
        let l:ext    = s:dn_markdown_pandoc_params[l:format]['final_ext']
        let l:output = substitute(expand('%'), '\.md$', l:ext, '')
        if !filereadable(l:output)
            throw 'No ' . l:format . ' file to view'
        endif
        " view output    {{{3
        if s:dn_markdown_os ==# 'win'
            let l:win_view_direct = ['docx', 'epub', 'html']
            let l:win_view_cmd    = ['pdf']
            if     count(l:win_view_direct, l:format) > 0
                " execute as a direct shell (dos) command
                let l:errmsg = [
                            \   'Unable to display ' . l:format . ' output',
                            \   'Windows has no default ' . l:format
                            \   . ' viewer',
                            \   'Shell feedback:',
                            \ ]
                let l:cmd = shellescape(l:output)
                let l:succeeded = s:_execute_shell_command(l:cmd, l:errmsg)
                if l:succeeded | echo 'Done' | endif
            elseif count(l:win_view_cmd, l:format) > 0
                " execute in a cmd shell
                try
                    execute 'silent !start cmd /c "' l:output '"'
                catch /.*/
                    throw 'Unable to display ' . l:format . ' output' . "\n"
                                \ . 'Windows has no default ' . l:format
                                \ . ' viewer'
                endtry
            else  " script error - does l:win_view_{direct,cmd} = all formats?
                throw 'Invalid format: ' . l:format
            endif
        elseif s:dn_markdown_os ==# 'nix'
            echo '' | " clear command line
            let l:opener = 'xdg-open'
            if executable(l:opener) == g:dn_true
                let l:cmd = shellescape(l:opener) . ' ' . shellescape(l:output)
                let l:errmsg = [
                            \   'Unable to display ' . l:format . ' output',
                            \   l:opener . ' is not configured for ' . l:format,
                            \   'Shell feedback:',
                            \ ]
                call s:_execute_shell_command(l:cmd, l:errmsg)
            else
                throw "Could not find '" . l:opener . "'"
            endif
        else
            echo ''
            throw 'Operating system not supported'
        endif
    catch /.*/
        echohl ErrorMsg | echo v:exception | echohl None
    finally
        let &more = l:more
        " return to calling mode    {{{3
        if l:insert | call dn#util#insertMode(g:dn_true) | endif |    " }}}3
    endtry
endfunction

" Private functions    {{{1

" s:_check_refs([startup])    {{{2
" does:   check equation, figure and table references
" params: startup - whether being run at startup, because suppress
"                   non-error and non-warning output at startup
"                   [boolean, optional, default=false]
" prints: feedback on errors and warnings
" return: nil
" note:   warnings - eq/fig/tbl not referenced
"                  - duplicate references to same eq/fig/tbl
"         errors   - reference to non-existant eq/fig/tbl
"                  - eq/fig/tbl defined multiple times
function! s:_check_refs(...) abort
    " variables    {{{3
    let l:startup = (a:0 > 0 && a:1)
    let l:types   = keys(s:dn_markdown_numbered_types)
    let l:issues  = {}
    " update ref and id indices    {{{3
    if !l:startup | echo 'Updating... ' | endif
    call s:_update_ids('equation', 'figure', 'table')
    call s:_update_refs()
    " check for problems    {{{3
    if !l:startup | echon 'analysing... ' | endif
    for l:type in l:types
        for l:id in keys(b:dn_markdown_ids[l:type])
            if has_key(b:dn_markdown_refs[l:type], l:id)
                " check for multiple references to id (warning)
                let l:count = b:dn_markdown_refs[l:type][l:id]
                if l:count > 1
                    if !s:_check_refs_issue(l:issues, l:type, l:id, 'warning',
                                \ 'referenced ' . l:count . ' times')
                        return
                    endif
                endif
            else  " no references to id (warning)
                if !s:_check_refs_issue(l:issues, l:type, l:id, 'warning',
                            \ 'not referenced')
                    return
                endif
            endif
        endfor
        for l:ref in keys(b:dn_markdown_refs[l:type])
            if has_key(b:dn_markdown_ids[l:type], l:ref)
                " check for multiple definitions (error)
                let l:count = b:dn_markdown_ids[l:type][l:ref]
                if l:count > 1
                    let l:msg = 'defined ' . l:count . ' times'
                    if !s:_check_refs_issue(l:issues, l:type, l:ref, 'error',
                                \ l:msg)
                        return
                    endif
                endif
            else  " reference is to non-existant structure (error)
                let l:msg = 'is referenced but not defined anywhere'
                if !s:_check_refs_issue(l:issues, l:type, l:ref, 'error',
                            \ l:msg)
                    return
                endif
            endif
        endfor
    endfor
    " report results    {{{3
    if empty(l:issues)
        if !l:startup | echon 'references ok' | endif
        return
    endif
    " - get max length of structure + name
    let l:hang = 0
    for l:type in sort(l:types)
        if !has_key(l:issues, l:type) | continue | endif
        for l:id in keys(l:issues[l:type])
            let l:title_length = len(l:type . ' ' . l:id . ': ')
            if l:title_length > l:hang | let l:hang = l:title_length | endif
        endfor
    endfor
    " - output issues
    for l:type in sort(l:types)
        if !has_key(l:issues, l:type) | continue | endif
        let l:Name = s:dn_markdown_numbered_types[l:type]['Name']
        for l:id in sort(keys(l:issues[l:type]))
            let l:report = []
            for l:class in ['warning', 'error']
                if !has_key(l:issues[l:type][l:id], l:class) | continue | endif
                for l:item in l:issues[l:type][l:id][l:class]
                    let l:msg = l:class . ': '
                    let l:msg = dn#util#padLeft(l:msg, 9)  " 9 = 'warning: '
                    let l:msg .= l:item
                    call add(l:report, l:msg)
                endfor
            endfor
            let l:title  = l:Name . ' ' . l:id . ': '
            let l:indent = repeat(' ', l:hang)
            for l:msg in l:report[0:0]
                call s:_say({'msg': [l:title, l:msg], 'hang': l:hang})
            endfor
            for l:msg in l:report[1:]
                call s:_say({'msg': [l:indent, l:msg], 'hang': l:hang})
            endfor
        endfor
    endfor
    " during startup last line of output can be
    " overwritten by vim status line
    if l:startup | echo ' ' | endif    " }}}3
endfunction

" s:_check_refs_issue(issues, type, id, class, msg)    {{{2
" does:   add to issues with structured type
" params: issues - variable holding issues [Dict, required]
"         type   - id type [String, required, 'equation'|'figure'|table']
"         id     - id string [String, required]
"         class  - issue class [String, required, 'warning'|'error']
"         msg    - message [String, required]
" prints: nil
" return: boolean, whether operation successful
function! s:_check_refs_issue(issues, type, id, class, msg) abort
    " check params
    if empty(a:msg) | call dn#util#error('No message') | return | endif
    if empty(a:class) | call dn#util#error('No issue class') | return | endif
    if !has_key({'warning': 1, 'error': 1}, a:class)
        call dn#util#error("Invalid issue class: '" . a:class . "'")
        return
    endif
    if empty(a:id) | call dn#util#error('No id') | return | endif
    if empty(a:type) | call dn#util#error('No id type') | return | endif
    if !has_key(s:dn_markdown_numbered_types, a:type)
        call dn#util#error("Invalid id type: '" . a:type . "'")
        return
    endif
    if type(a:issues) != type({})
        let l:msg = 'Expected issues to be dict, got '
                    \ . dn#util#varType(a:issues)
        call dn#util#error(l:msg)
        return
    endif
    " add issue
    " - issues -> type
    if !has_key(a:issues, a:type)
        let a:issues[a:type] = {}
    endif
    " - issues -> type -> id
    if !has_key(a:issues[a:type], a:id)
        let a:issues[a:type][a:id] = {}
    endif
    " - issues -> type -> id -> class
    if !has_key(a:issues[a:type][a:id], a:class)
        let a:issues[a:type][a:id][a:class] = []
    endif
    " - issues -> type -> id -> class -> msg
    call add(a:issues[a:type][a:id][a:class], a:msg)
    " guess we succeeded!
    return g:dn_true
endfunction

" s:_display_value(value, setting)    {{{2
" does:   get the display value for a setting value
" params: value   - setting value to display [any, required]
"         setting - name of setting [any, required]
" return: display value [String]
function! s:_display_value(value, setting) abort
    let l:allowed = b:dn_markdown_settings[a:setting]['allowed']
    if type(l:allowed) == type('') && l:allowed ==# 'boolean'
        let l:display_value = a:value ? 'Yes' : 'No'
    else
        let l:display_value = empty(a:value) ? '[Null/empty]'
                    \                        : dn#util#stringify(a:value)
    endif
    return l:display_value
endfunction

" s:_ebook_post_processing(format)    {{{2
" does:   determine whether this format requires ebook post-processing
"         e.g., is it azw3 or mobi format?
" params: format - output format [string, required]
" return: boolean
function! s:_ebook_post_processing (format) abort
    return count(['mobi', 'azw3'], a:format) == 1
endfunction

" s:_enter_id(type, [base])    {{{2
" does:   get id for figure, table or equation 
" params: type - id type
"                [string, required, can be 'equation'|'table'|'figure']
"         base - base for default value for id
"                [string, optional, no default]
" return: String, empty if aborted
" note:   follows basic style of
"         pandoc-fignos (https://github.com/tomduck/pandoc-fignos),
"         pandoc-eqnos (https://github.com/tomduck/pandoc-eqnos) and
"         pandoc-tablenos (https://github.com/tomduck/pandoc-tablenos)
"         except allows only the characters: a-z, 0-9, _ and -
function! s:_enter_id(type, ...) abort
    " check params
    if !has_key(s:dn_markdown_numbered_types, a:type)
        call dn#util#error("Invalid reference type '" . a:type . "'")
        return ''
    endif
    let l:base = (a:0 > 0 && !empty(a:1)) ? tolower(a:1) : ''
    " set variables
    let l:prefix  = s:dn_markdown_numbered_types[a:type]['prefix']
    let l:name    = s:dn_markdown_numbered_types[a:type]['name']
    let l:Name    = s:dn_markdown_numbered_types[a:type]['Name']
    let l:default = substitute(l:base, '[^a-z0-9_-]', '-', 'g')
    let l:default = substitute(l:default, '^-\+', '', '')
    let l:default = substitute(l:default, '-\+$', '', '')
    let l:prompt  = 'Enter ' . l:name . ' id (empty to abort): '
    while 1
        let l:id = input(l:prompt, l:default)
        echo ' '  | " ensure move to a new line
        " empty value means aborting
        if empty(l:id) | return '' | endif
        " cannot use existing id
        if has_key(b:dn_markdown_ids[a:type], l:id)
            call dn#util#warn(l:Name . " id '" . l:id . "' already exists")
            continue
        endif
        " must be legal id
        if l:id !~# '\%^[a-z0-9_-]\+\%$'
            call dn#util#warn(l:Name . ' ids contain only a-z, 0-9, _ and -')
            continue
        endif
        " ok, if here must be legal
        break
    endwhile
    return l:id
endfunction

" s:_equation_insert()    {{{2
" does:   insert equation at cursor location
" params: nil
" prints: user prompts and feedback
" return: whether operation succeeded
function! s:_equation_insert() abort
    " get equation id (empty means abort)
    let l:id = s:_enter_id('equation')
    if empty(l:id) | return | endif
    let l:label = '{#eq:' . l:id . '}'
    " insert equation label
    call dn#util#insertString(l:label)
    " update ids list
    " - has to be unique or would not have been allowed
    call s:_increment_id_count('equation', l:id)
    return g:dn_true
endfunction

" s:_execute_shell_command(cmd,[err])    {{{2
" does:   execute shell command
" params: cmd - shell command [required, string]
"         err - error message [optional, List, default='Error occured:']
" prints: if error display user error message and shell feedback
" return: return status of command as vim boolean
function! s:_execute_shell_command(cmd, ...) abort
    echo '' | " clear command line
    " variables
    let l:errmsg = (a:0 > 0) ? a:1 : ['Error occurred:']
    if type(l:errmsg) != type([])
        let l:msg = 'Expected list messages, got ' . dn#util#varType(l:errmsg)
        call dn#util#error(l:msg)
        return
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
        call s:_say({'msg': [l:shell_feedback]})
        echo '--------------------------------------'
        return g:dn_false
    else
        return g:dn_true
    endif
endfunction

" s:_figure_insert()    {{{2
" does:   insert figure following current line
" params: nil
" prints: user prompts and feedback
" return: whether operation succeeded
function! s:_figure_insert() abort
    " get figure caption
    let l:caption = input('Enter figure caption (empty to abort): ')
    echo ' '  | " ensure move to a new line
    if empty(l:caption) | return | endif
    " get figure id (empty means abort)
    let l:id = s:_enter_id('figure', l:caption)
    if empty(l:id) | return | endif
    let l:label = '{#fig:' . l:id . '}'
    " get image filepath
    let l:prompt = 'Enter image filepath (empty to abort): '
    let l:path = input(l:prompt, '', 'file')
    if empty(l:path) | return | endif
    if !filereadable(l:path)
        echo ' '  | " ensure move to a new line
        let l:prompt  = 'Image filepath appears to be invalid:'
        let l:options = []
        call add(l:options, {'Proceed anyway': g:dn_true})
        call add(l:options, {'Abort': g:dn_false})
        let l:proceed = dn#util#menuSelect(l:options, l:prompt)
        if !l:proceed | return | endif
    endif
    " insert figure
    let l:cursor    = getpos('.')
    let l:indent    = repeat(' ', indent(line('.')))
    let l:cursor[1] = l:cursor[1] + 4  " line number
    let l:cursor[2] = len(l:indent)    " column number
    let l:line      = ['![', l:caption, '](', l:path, ' "',
                \      l:caption, '")', l:label]
    let l:lines = [join(l:line, ''), l:indent, l:indent]
    call append(line('.'), l:lines)
    call setpos('.', l:cursor)
    " update ids list
    " - has to be unique or would not have been allowed
    call s:_increment_id_count('figure', l:id)
    return g:dn_true
endfunction

" s:_generator(format)    {{{2
" does:   generate output
" params: format - output format
"                  [required, must be s:dn_markdown_pandoc_params key]
" return: whether output completed without error
function! s:_generator (format) abort
    " requirements    {{{3
    " - apps
    "   . get list of apps on which conversion depends
    let l:depends = s:dn_markdown_pandoc_params[a:format]['depend']
    "   . replace 'latex' with specific latex engine
    let l:index = index(l:depends, 'latex')
    if l:index >= 0
        let l:engine = b:dn_markdown_settings.pdfengine_print.value
        let l:depends[l:index] = l:engine
    endif
    "   . replace 'pandoc' and 'ebook-convert' with executable names
    let l:index = index(l:depends, 'pandoc')
    if l:index >= 0
        let l:depends[l:index] = b:dn_markdown_settings.exe_pandoc.value
    endif
    let l:index = index(l:depends, 'ebook-convert')
    if l:index >= 0
        let l:depends[l:index] = b:dn_markdown_settings.exe_ebook_convert.value
    endif
    "   . now test for each app in turn
    for l:depend in l:depends
        if !executable(l:depend)
            call dn#util#error("Cannot find '" . l:depend . "'")
            return
        endif
    endfor
    " - that buffer is a file, not a nameless buffer
    if bufname('%') ==# ''
        call dn#util#error('Current buffer has no name')
        call dn#util#showMsg("Can fix with 'write' or 'file' command")
        return
    endif
    " - that operating system is supported
    if s:dn_markdown_os !~# '^win$\|^nix$'  " currently only windows and unix
        call dn#util#error('Operating system not supported')
        return
    endif
    " process params    {{{3
    if !s:_valid_format(a:format)
        call dn#util#error("Invalid format '" . a:format . "'")
        return
    endif
    " save file to incorporate any changes    {{{3
    silent update
    call s:_say({'msg': ['Target format:', a:format]})
    let l:pandoc_exe = b:dn_markdown_settings.exe_pandoc.value
    call s:_say({'msg': ['Converter:', l:pandoc_exe]})
    " generate output
    " - note: some output options are displayed explicitly,
    "         one per line, while other are added to l:opts
    "         and displayed in a single line
    let l:params = s:dn_markdown_pandoc_params[a:format]['params']
    let l:opts   = []
    " variables    {{{3
    let l:cmd = [l:pandoc_exe]
    let l:pandoc_extensions = {'reader': [], 'writer': []}
    " number figures    {{{3
    " - pandoc-fignos filter must be called before
    "   pandoc-citeproc filter or --bibliography=FILE
    if count(l:params, 'figures') > 0                      " number figures
        let l:use_fignos = b:dn_markdown_settings.number_figures.value
        " requires pandoc-fignos filter be installed
        if l:use_fignos && !executable('pandoc-fignos')
            let l:use_fignos = g:dn_false
            call s:_say({'msg': ['Figure xref:',
                        \ 'pandoc-fignos filter not installed']})
        endif
        if l:use_fignos
            call add(l:cmd, '--filter pandoc-fignos')
            call add(l:opts, 'pandoc-fignos')
        endif
    endif
    " number equations    {{{3
    " - pandoc-eqnos filter must be called before
    "   pandoc-citeproc filter or --bibliography=FILE
    if count(l:params, 'equations') > 0                    " number equations
        let l:use_eqnos = b:dn_markdown_settings.number_equations.value
        " requires pandoc-eqnos filter be installed
        if l:use_eqnos && !executable('pandoc-eqnos')
            let l:use_eqnos = g:dn_false
            call s:_say({'msg': ['Equation xref:',
                        \ 'pandoc-eqnos filter not installed']})
        endif
        if l:use_eqnos
            call add(l:cmd, '--filter pandoc-eqnos')
            call add(l:opts, 'pandoc-eqnos')
        endif
    endif
    " number tables    {{{3
    " - pandoc-tablenos filter must be called before
    "   pandoc-citeproc filter or --bibliography=FILE
    if count(l:params, 'tables') > 0                       " number tables
        let l:use_tablenos = b:dn_markdown_settings.number_tables.value
        " requires pandoc-tablenos filter be installed
        if l:use_tablenos && !executable('pandoc-tablenos')
            let l:use_tablenos = g:dn_false
            call s:_say({'msg': ['Table xref:',
                        \ 'pandoc-tablenos filter not installed']})
        endif
        if l:use_tablenos
            call add(l:cmd, '--filter pandoc-tablenos')
            call add(l:opts, 'pandoc-tablenos')
        endif
    endif
    " latex engine    {{{3
    if count(l:params, 'pdfengine') > 0                  " pdf engine
        " latex engine
        " - can be pdflatex, lualatex or xelatex (default)
        " - xelatex is better at handling exotic unicode
        let l:engine = b:dn_markdown_settings.pdfengine_print.value
        if !executable(l:engine)
            call dn#util#error('Install ' . l:engine)
            return
        endif
        call add(l:cmd, '--pdf-engine=' . l:engine)
        call s:_say({'msg': ['PDF engine:', l:engine]})
    endif
    " make links visible    {{{3
    if count(l:params, 'latexlinks') > 0                   " latex links
        " available colours are:
        "   black,    blue,    brown, cyan,
        "   darkgray, gray,    green, lightgray,
        "   lime,     magenta, olive, orange,
        "   pink,     purple,  red,   teal,
        "   violet,   white,   yellow
        "   [https://en.wikibooks.org/wiki/LaTeX/Colors#Predefined_colors]
        " if colour is changed here, update documentation
        let l:link_color = b:dn_markdown_settings.linkcolor_print.value
        call add(l:cmd, '--variable linkcolor=' . l:link_color)
        call add(l:cmd, '--variable citecolor=' . l:link_color)
        call add(l:cmd, '--variable toccolor='  . l:link_color)
        call add(l:cmd, '--variable urlcolor='  . l:link_color)
        call s:_say({'msg': ['Link colour:', l:link_color]})
    endif
    if count(l:params, 'contextlinks') > 0                 " context links
        " available colours are:
        "   black   white
        "   gray    {light,middle,dark}gray
        "   red     {light,middle,dark}red
        "   green   {light,middle,dark}green
        "   blue    {light,middle,dark}blue
        "   cyan    {middle,dark}cyan
        "   magenta {middle,dark}magenta
        "   yellow  {middle,dark}yellow
        "   [http://wiki.contextgarden.net/Color#Pre-defined_colors]
        " if colour is changed here, update documentation
        let l:link_color = b:dn_markdown_settings.linkcolor_print.value
        call add(l:cmd, '--variable linkcolor=' . l:link_color)
        call s:_say({'msg': ['Link colour:', l:link_color]})
    endif
    " custom font size    {{{3
    if count(l:params, 'fontsize') > 0                     " font size
        let l:font_size = b:dn_markdown_settings.fontsize_print.value
        if empty(l:font_size)
            call s:_say({'msg': ['Font size:', 'default']})
        else
            let l:font_size .= 'pt'
            call s:_say({'msg': ['Font size:', l:font_size]})
            call add(l:cmd, '--variable fontsize=' . l:font_size)
        endif
    endif
    " custom paper size    {{{3
    if count(l:params, 'papersize') > 0                    " paper size
        let l:paper_size = b:dn_markdown_settings.papersize_print.value
        if empty(l:paper_size)
            call s:_say({'msg': ['Paper size:', 'default']})
        else
            call s:_say({'msg': ['Paper size:', l:paper_size]})
            call add(l:cmd, '--variable papersize=' . l:paper_size)
        endif
    endif
    " add header and footer    {{{3
    if count(l:params, 'standalone') > 0                   " standalone
        call add(l:cmd, '--standalone')
        call add(l:opts, 'standalone')
    endif
    " convert quotes, em|endash, ellipsis    {{{3
    if count(l:params, 'smart') > 0                        " smart
        call add(l:pandoc_extensions.reader, 'smart')
        call add(l:opts, 'smart')
    endif
    " incorporate external dependencies    {{{3
    if count(l:params, 'selfcontained') > 0                " self-contained
        call add(l:cmd, '--self-contained')
        call add(l:opts, 'self-contained')
    endif
    " use citeproc if selected by user    {{{3
    if count(l:params, 'citeproc') > 0                     " citeproc
        let l:use_citeproc = b:dn_markdown_settings.citeproc_all.value
        if l:use_citeproc
            call add(l:cmd, '--filter pandoc-citeproc')
            call add(l:opts, 'pandoc-citeproc')
        endif
    endif
    " use css stylesheet for html    {{{3
    if count(l:params, 'style_html') > 0                   " style/html
        let l:style_html = b:dn_markdown_settings.stylesheet_html.value
        if !empty(l:style_html)
            call add(l:cmd, '--css=' . shellescape(l:style_html))
            call s:_say({'msg': ['Stylesheet:', l:style_html]})
        endif
    endif
    " use css stylesheet for epub    {{{3
    if count(l:params, 'style_epub') > 0                   " style/epub
        let l:style_epub = b:dn_markdown_settings.stylesheet_epub.value
        if !empty(l:style_epub)
            call add(l:cmd, '--epub-stylesheet='
                        \ . shellescape(l:style_epub))
            call s:_say({'msg': ['Stylesheet:', l:style_epub]})
        endif
    endif
    " use cover image for epub    {{{3
    if count(l:params, 'cover_epub') > 0                   " cover/epub
        let l:cover_epub = ''
        for l:ext in ['gif', 'jpg', 'png']
            let l:candidate = 'cover.' . l:ext
            if filereadable(l:candidate)
                let l:cover_epub = l:candidate
            endif
        endfor
        if !empty(l:cover_epub)
            call add(l:cmd, '--epub-cover-image='
                        \ . shellescape(l:cover_epub))
            call s:_say({'msg': ['Cover image:', l:cover_epub]})
        endif
    endif
    " use docx stylesheet    {{{3
    if count(l:params, 'style_docx') > 0                   " style/docx
        let l:style_docx =
                    \ b:dn_markdown_settings.stylesheet_docx.value
        if !empty(l:style_docx)
            call add(l:cmd, '--reference-docx='
                        \ . shellescape(l:style_docx))
            call s:_say({'msg': ['Style doc:', l:style_docx]})
        endif
    endif
    " use custom template    {{{3
    if count(l:params, 'template') > 0                     " template
        let l:setting  = 'template_' . a:format
        let l:template = b:dn_markdown_settings[l:setting]['value']
        if !empty(l:template)
            call add(l:cmd, '--template='
                        \ . shellescape(l:template))
            call s:_say({'msg': ['Template:', l:template]})
        else
            call s:_say({'msg': ['Template:', '[default]']})
        endif
    endif
    " input option    {{{3
    let l:from = ['markdown']                              " input format
    call extend(l:from, l:pandoc_extensions.reader)        " + extensions
    call extend(l:cmd, ['-f', join(l:from, '+')])
    " output format    {{{3
                                                           " output format
                                                           " + extensions
    let l:to = [s:dn_markdown_pandoc_params[a:format]['pandoc_to']]
    call extend(l:opts, l:to)
    call extend(l:to, l:pandoc_extensions.writer)
    call extend(l:cmd, ['-t', join(l:to, '+')])
    " output file    {{{3
    " - display final output file
    let l:ext    = s:dn_markdown_pandoc_params[a:format]['final_ext']
    let l:output = substitute(expand('%'), '\.md$', l:ext, '')
    call s:_say({'msg': ['Output file:', l:output]})
    " - pandoc output file (may not be final output file)
    let l:ext    = s:dn_markdown_pandoc_params[a:format]['after_ext']
    let l:output = substitute(expand('%'), '\.md$', l:ext, '')
    " - if postprocessing this output, i.e., it is an intermediate file,
    "   may want to munge output file name to prevent overwriting of a
    "   final output file of the same format -- in cases where
    "   different templates are used for each case
    let l:post_processing = s:dn_markdown_pandoc_params[a:format]['postproc']
    if l:post_processing
        if s:_ebook_post_processing(a:format)  " azw3, mobi
            let l:epub_output = l:output
            let l:prefix = 1
            let l:output = l:prefix . '_' . l:epub_output
            while filereadable(l:output)
                let l:prefix += 1
                let l:output = l:prefix . '_' . l:epub_output
            endwhile
        endif
    endif
    call add(l:cmd, '--output=' . shellescape(l:output))
    " input file    {{{3
    let l:source = expand('%')                             " input file
    call add(l:cmd, shellescape(l:source))
    " generate pandoc output    {{{3
    call s:_say({'msg': ['Options:', join(l:opts, ', ')]})
    let l:errmsg = ["Error occurred during '"
                \ . a:format . "' generation"]
    call s:_say({'msg': ['Generating output... ']})
    let l:retval = s:_execute_shell_command(join(l:cmd), l:errmsg)
    " do post-pandoc conversion where required    {{{3
    if l:post_processing && l:retval
        if s:_ebook_post_processing(a:format)  " azw3, mobi
            let l:input  = l:output
            let l:ext    = s:dn_markdown_pandoc_params[a:format]['final_ext']
            let l:output = substitute(expand('%'), '\.md$', l:ext, '')
            let l:exe    = b:dn_markdown_settings.exe_ebook_convert.value
            let l:cmd    = [l:exe, shellescape(l:input),
                        \ shellescape(l:output), '--pretty-print',
                        \ '--smarten-punctuation', '--insert-blank-line',
                        \ '--keep-ligatures']
            let l:retval = s:_execute_shell_command(join(l:cmd), l:errmsg)
            if delete(l:input) == -1  " delete intermediary file
                let l:msg = "Unable to delete intermediary file '"
                            \ . l:input . "'"
                call dn#util#error(l:msg)
            endif
        endif
    endif
    " update outputted formats    {{{3
    if l:retval
        let b:dn_markdown_outputted_formats[a:format] = g:dn_true
    endif
    " return outcome    {{{3
    return l:retval    " }}}3
endfunction

" s:_increment_id_count(type, id)    {{{2
" does:   increase id count by one
" params: type - id type
"                [string, required, can be 'equation'|'table'|'figure']
"         id   - id to increment count for [string, required]
" return: nil
function! s:_increment_id_count(type, id) abort
    " check params
    if empty(a:id) || empty (a:type)  " script error
        call dn#util#error("Did not get both id ('"
                    \ . a:id . "') and type ('" . a:type . "')")
        return
    endif
    if !has_key(s:dn_markdown_numbered_types, a:type)  " script error
        call dn#util#error('Invalid type: ' . a:type)
        return
    endif
    " update id count
    if has_key(b:dn_markdown_ids[a:type], a:id)
        let b:dn_markdown_ids[a:type][a:id] += 1
    else
        let b:dn_markdown_ids[a:type][a:id] = 1
    endif
endfunction

" s:_increment_ref_count(type, ref)    {{{2
" does:   increase ref count by one
" params: type - ref type
"                [string, required, can be 'equation'|'table'|'figure']
"         ref  - ref to increment count for [string, required]
" return: nil
function! s:_increment_ref_count(type, ref) abort
    " check params
    if empty(a:ref) || empty (a:type)  " script error
        call dn#util#error("Did not get both ref ('"
                    \ . a:ref . "') and type ('" . a:type . "')")
        return
    endif
    if !has_key(s:dn_markdown_numbered_types, a:type)  " script error
        call dn#util#error('Invalid type: ' . a:type)
        return
    endif
    " update ref count
    if has_key(b:dn_markdown_refs[a:type], a:ref)
        let b:dn_markdown_refs[a:type][a:ref] += 1
    else
        let b:dn_markdown_refs[a:type][a:ref] = 1
    endif
endfunction

" s:_process_dict_params(params)    {{{2
" does:   process dict param used by dn#markdown#{view,output}
" params: params - List that may contain a parameters dictionary
"                  with the following keys:
"                  'insert' - whether entered from insert mode
"                             [optional, default=<false>, boolean]
"                  'format' - output format
"                             [optional, no default,
"                              must be a key of s:dn_markdown_pandoc_params]
" return: List [insert, format]
function! s:_process_dict_params(...) abort
    " universal tasks
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " default params
    let l:insert = g:dn_false | let l:format = '' |  " defaults
    " expecting a list containing a single dict
    if a:0 == 0
        call dn#util#error('No params provided')
        return [l:insert, l:format]
    endif
    if a:0 > 1  " script error
        call dn#util#error('Too many params provided')
        return [l:insert, l:format]
    endif
    if type(a:1) != type([])  " script error
        let l:msg = 'Param var is wrong type: ' . dn#util#varType(a:1)
        call dn#util#error(l:msg)
        return [l:insert, l:format]
    endif
    if len(a:1) == 0  " original function called with no params, so okay
        return [l:insert, l:format]
    endif
    if len(a:1) > 1  " script error
        let l:msg = 'Expected 1-element list, got ' . len(a:1)
        call dn#util#error(l:msg)
        return [l:insert, l:format]
    endif
    if type(a:1[0]) != type({})  " script error
        let l:msg = 'Expected dict in list, got ' . dn#util#varType(a:1[0])
        call dn#util#error(l:msg)
        return [l:insert, l:format]
    endif
    " have received param(s) in good order
    let l:params = deepcopy(a:1[0])
    for l:param in keys(l:params)
        if     l:param ==# 'insert'  " param 'insert'
            if l:param.insert | let l:insert = g:dn_true | endif
        elseif l:param ==# 'format'  " param 'format'
            if s:_valid_format(l:params.format)
                let l:format = l:params.format
            else
                call dn#util#error("Invalid format '"
                            \ . l:params.format . "'")
            endif
        else  " param invalid
            call dn#util#error("Invalid param key '" . l:param . "'")
            if l:insert | call dn#util#insertMode(g:dn_true) | endif
            return
        endif
    endfor
    " select output format if not set by param
    if empty(l:format)
        let l:format = s:_select_format()
    endif
    if empty(l:format)
        echo 'No output format selected'
    endif
    return [l:insert, l:format]
endfunction

" s:_reference_insert(type)    {{{2
" does:   insert equation, figure or table reference
" params: type - reference type
"                [string, required, can be 'equation'|'table'|'figure']
" return: String, reference
function! s:_reference_insert(type) abort
    " check params
    if empty (a:type) || !has_key(s:dn_markdown_numbered_types, a:type)
        " script error
        call dn#util#error("Invalid type '" . a:type . "' provided")
        return
    endif
    " get id
    let l:name     = s:dn_markdown_numbered_types[a:type]['name']
    let l:prompt   = 'Enter ' . l:name . ' id (empty to abort): '
    let l:complete = 'customlist,'
                \  . s:dn_markdown_numbered_types[a:type]['complete']
    let l:id       = input(l:prompt, '', l:complete)
    " check id value
    if empty(l:id) | return | endif
    if !has_key(b:dn_markdown_ids[a:type], l:id)
        " rebuild index to be sure it is complete and accurate
        echo ' '  | " ensure move to a new line
        echo 'Rebuilding ' . l:name . ' id index...'
        call s:_update_ids(a:type)
        if !has_key(b:dn_markdown_ids[a:type], l:id)
            " see if user wants to insert an id that does not yet exist
            let l:prompt  = 'Cannot find ' . l:name . ' with that id:'
            let l:options = []
            call add(l:options, {'Insert reference to it anyway': g:dn_true})
            call add(l:options, {'Abort': g:dn_false})
            let l:proceed = dn#util#menuSelect(l:options, l:prompt)
            if !l:proceed == g:dn_true | return | endif
        endif
    endif
    " insert reference, i.e., label
    let l:prefix = s:dn_markdown_numbered_types[a:type]['prefix']
    let l:ref    = '{@' . l:prefix . ':' . l:id . '}'
    call dn#util#insertString(l:ref)
endfunction

" s:_say(args)    {{{2
" does:   echo line of output with wrapping and hanging indent
" params: args [Dict, required]
"         keys: msg  - width of hanging indent
"                      [List, required, string]
"               hang - one, optionally two, messages to display
"                      [integer, options, default=s:dn_markdown_hang]
" return: nil
" note:   if only one msg is present, then treat output as
"         a single string
" note:   if two msgs are present, right-pad first msg with spaces
"         to the width of the hanging indent before concatenating
"         first and second msgs
function! s:_say(args) abort
    " parameters
    if type(a:args) != type({})  " script error
        let l:err = 'Expected Dict args, got ' . dn#util#varType(a:args)
        call dn#util#error(l:err)
        return
    endif
    if !has_key(a:args, 'msg')  " script error
        call dn#util#error('No msg parameter')
        return
    endif
    let l:msgs = a:args.msg
    if type(l:msgs) != type([])  " script error
        let l:err = 'Expected List msgs, got ' . dn#util#varType(l:msgs)
        call dn#util#error(l:err)
        return
    endif
    let l:count = len(l:msgs)
    if l:count < 1 || l:count > 2  " script error
        let l:err = 'Expected 1 or 2 msgs, got ' . l:count
        call dn#util#error(l:err)
        return
    endif
    let l:hang = has_key(a:args, 'hang') ? a:args.hang : s:dn_markdown_hang
    " if msg2 present, right-pad msg1
    let l:msg = l:msgs[0]
    if l:count == 2
        while len(l:msg) < l:hang | let l:msg .= ' ' | endwhile
        let l:msg .= l:msgs[1]
    endif
    " print wrapped output
    call dn#util#wrap(l:msg, l:hang)
endfunction

" s:_select_format(prompt)    {{{2
" does:   select output format
" params: prompt - prompt [string, optional, default='Select output format:']
" return: output format (a key to s:dn_markdown_pandoc_params)
"         '' if error or no format selected
" *warn*: relies on s:dn_markdown_pandoc_params.*.format values being unique
function! s:_select_format (...) abort
    let l:prompt = (a:0 > 0 && a:1) ? a:1 : 'Select output format:'
    " create dict with format names as keys, format codes as values
    let l:formats = {}
    for [l:key, l:val] in items(s:dn_markdown_pandoc_params)
        let l:format = l:val['format']
        if has_key(l:formats, l:format)
            let l:msg = "Script error: duplicate format '" . l:format . "'"
            call dn#util#error(l:msg)
            return
        endif
        let l:formats[l:format] = l:key
    endfor
    " put into list sorted bv format names
    let l:options = []
    for l:name in sort(keys(l:formats))
        call add(l:options, {l:name : l:formats[l:name]})
    endfor
    " select format name
    let l:format = dn#util#menuSelect(l:options, l:prompt)
    if empty(l:formats)
        call dn#util#error('No valid output format selected')
    endif
    return l:format
endfunction

" s:_set_default_html_stylesheet()    {{{2
" does:   set s:dn_md_settings.stylesheet_html.default
"         to the stylesheet provided by this plugin
" params: nil
" return: nil, sets variable in place
function! s:_set_default_html_stylesheet() abort
    " requires s:dn_md_settings.stylesheet_html.default
    if !exists('b:dn_markdown_settings')
        echoerr 'dn-markdown ftplugin cannot set html stylesheet default'
        echoerr 'dn-markdown ftplugin cannot find b:dn_markdown_settings'
        return
    endif
    if !(s:_valid_setting_name('stylesheet_html')
                \ && has_key(b:dn_markdown_settings.stylesheet_html,
                \            'default'))
        echoerr 'dn-markdown ftplugin cannot set html stylesheet default'
        echoerr '-- cannot find b:dn_markdown_settings.stylesheet_html.default'
    endif
    " default stylesheet is located in 'vim-dn-markdown-css'
    " subdirectory of this plugin
    let l:style_dirs = globpath(&runtimepath, 'vim-dn-markdown-css', 1, 1)
    let l:style_filepaths = []
    " - find all files in this subdirectory
    " - should be only one subdir containing one file, but who knows?
    for l:style_dir in l:style_dirs
        call extend(l:style_filepaths,
                    \ glob(l:style_dir . '/*', g:dn_false, g:dn_true))
    endfor
    " examine found file(s)
    let l:stylesheet = ''
    if     len(l:style_filepaths) == 0
        " whoah, who deleted the ftplugin stylesheet?
        echoerr 'dn-markdown ftplugin cannot find default stylesheet'
        return
    elseif len(l:style_filepaths) == 1
        " found expected single match
        let l:stylesheet = l:style_filepaths[0]
    else
        " okay, there are multiple css files (and possibly from multiple
        " matching subdirectories) (how?) -- anyway, let's pick one of them
        let l:menu_options = {}
        for l:style_filepath in l:style_filepaths
            let l:menu_option = fnamemodify(l:style_filepath, ':t:r')
            let l:menu_options[l:menu_option] = l:style_filepath
        endfor
        let l:msg = 'dn-markdown ftplugin found '
                    \. 'multiple default html stylesheets'
        call dn#util#warn(l:msg)
        call dn#util#warn('-- that should not happen with this plugin')
        let l:prompt = 'Select default html stylesheet:'
        let l:selection = dn#util#menuSelect(l:menu_options, l:prompt)
        if !empty(l:selection)
            let l:stylesheet = l:selection
        endif
    endif
    " set value
    if empty(l:stylesheet) | return | endif
    let b:dn_markdown_settings.stylesheet_html.default = l:stylesheet
endfunction

" s:_settings_configure()    {{{2
" does:   configure settings variables
" params: nil
" return: nil
function! s:_settings_configure() abort
    " set parameters from configuration variables where available,
    " otherwise set to their default values
    for l:setting in sort(keys(b:dn_markdown_settings))
        let l:default = b:dn_markdown_settings[l:setting]['default']
        let l:config  = b:dn_markdown_settings[l:setting]['config']
        let l:allowed = b:dn_markdown_settings[l:setting]['allowed']
        let l:source  = b:dn_markdown_settings[l:setting]['source']
        let l:set_from_config = g:dn_false
        if exists(l:config)  " try to set from config variable
            let l:value = {l:config}
            if s:_valid_setting_value(l:value, l:setting, g:dn_true)
                let l:source = 'set from configuration variable ' . l:config
                let b:dn_markdown_settings[l:setting]['value']  = l:value
                let b:dn_markdown_settings[l:setting]['source'] = l:source
                let l:set_from_config = g:dn_true
            else
                let l:msgs = ["Attempted to set '" . l:setting . "'",
                            \ "from variable '" . l:config . "', but it",
                            \ "had the invalid value '" . l:value . "'",
                            \ ]
                for l:msg in l:msgs | call dn#util#error(l:msg) | endfor
            endif
        endif
        if !l:set_from_config  " try to set from default
            let l:value = b:dn_markdown_settings[l:setting]['default']
            if s:_valid_setting_value(l:value, l:setting, g:dn_true)
                let l:source = 'default'
                let b:dn_markdown_settings[l:setting]['value']  = l:value
                let b:dn_markdown_settings[l:setting]['source'] = l:source
            else
                let l:msgs = ["Attempted to set '" . l:setting . "' from",
                            \ "invalid default value '" . l:value . "'",
                            \ ]
                for l:msg in l:msgs | call dn#util#error(l:msg) | endfor
            endif
        endif
    endfor
    " reset outputted formats
    let l:dn_md_outputted_formats = {}
endfunction

" s:_table_insert()    {{{2
" does:   insert table title following current line
" params: nil
" prints: user prompts and feedback
" return: whether operation succeeded
function! s:_table_insert() abort
    " get table caption
    let l:caption = input('Enter table caption (empty to abort): ')
    echo ' '  | " ensure move to a new line
    if empty(l:caption) | return | endif
    " get table id (empty means abort)
    let l:id = s:_enter_id('table', l:caption)
    if empty(l:id) | return | endif
    let l:label = '{#tbl:' . l:id . '}'
    " insert table title
    let l:cursor    = getpos('.')
    let l:indent    = repeat(' ', indent(line('.')))
    let l:cursor[1] = l:cursor[1] + 4  " line number
    let l:cursor[2] = len(l:indent)    " column number
    let l:line      = ['Table:', l:caption, l:label]
    let l:lines     = [join(l:line, ' '), l:indent, l:indent]
    call append(line('.'), l:lines)
    call setpos('.', l:cursor)
    " update ids list
    " - has to be unique or would not have been allowed
    call s:_increment_id_count('table', l:id)
    return g:dn_true
endfunction

" s:_update_ids(type, [type, [type]])    {{{2
" does:   update ids for figures, tables or equations in current file 
" params: type - id types
"                [string, required, can be 'equation'|'table'|'figure']
" return: n/a
" note:   follows basic style of
"         pandoc-fignos (https://github.com/tomduck/pandoc-fignos),
"         pandoc-eqnos (https://github.com/tomduck/pandoc-eqnos) and
"         pandoc-tablenos (https://github.com/tomduck/pandoc-tablenos)
function! s:_update_ids(...) abort
    " check params
    let l:types = uniq(sort(copy(a:000)))
    if empty(l:types)  " script error
        call dn#util#error('No id types provided')
        return
    endif
    let l:invalid = []
    for l:type in l:types
        if !has_key(s:dn_markdown_numbered_types, l:type)
            call add(l:invalid, l:type)
        endif
    endfor
    if !empty(l:invalid)
        let l:msg = 'Invalid id type(s): ' . join(l:invalid, ', ')
        call dn#util#error(l:msg)
        return
    endif
    " get file contents (and exit if file is empty)
    let l:lines = getline(1, '$')
    if len(l:lines) == 1 && empty(l:lines[0]) | return | endif
    " extract labels from file contents
    " - looking for pattern >> {#PREFIX:ID} << where PREFIX is determined
    "   by id type and ID is a unique value entered by the user
    " - assume no more than one match per line
    for l:type in l:types
        let l:prefix  = s:dn_markdown_numbered_types[l:type]['prefix']
        let l:re      = '{#' . l:prefix . ':[^}]\+}'  " [^}]\+ is ID
        let l:matches = filter(map(copy(l:lines), 'matchstr(v:val, l:re)'),
                    \ '!empty(v:val)')
        " extract id strings
        let l:start = len(l:prefix) + 3  " the 3 is for '{', '#' and ':'
        let l:ids   = map(l:matches,
                    \ 'strpart(v:val, l:start, len(v:val) - l:start - 1)')
        " update ids
        let b:dn_markdown_ids[l:type] = {}
        for l:id in l:ids
            call s:_increment_id_count(l:type, l:id)
        endfor
    endfor
endfunction

" s:_update_refs()    {{{2
" does:   update references for figures, tables or equations in current file 
" params: nil
" return: n/a
" note:   follows basic style of
"         pandoc-fignos (https://github.com/tomduck/pandoc-fignos),
"         pandoc-eqnos (https://github.com/tomduck/pandoc-eqnos) and
"         pandoc-tablenos (https://github.com/tomduck/pandoc-tablenos)
function! s:_update_refs() abort
    " get file contents (and exit if file is empty)
    let l:lines = getline(1, '$')
    if len(l:lines) == 1 && empty(l:lines[0]) | return | endif
    " extract references from file contents
    " - looking for pattern >> {@PREFIX:ID} << where PREFIX is determined
    "   by reference type and ID is a unique value entered by the user
    " - assume no more than one match per line
    for l:type in keys(s:dn_markdown_numbered_types)
        let l:labels = []
        let l:prefix = s:dn_markdown_numbered_types[l:type]['prefix']
        let l:re = '{@' . l:prefix . ':[^}]\+}'  " [^}]\+ is ID
        for l:line in l:lines
            let l:count = 1
            while 1
                let l:match = matchstr(l:line, l:re, 0, l:count)
                if empty(l:match) | break | endif
                call add(l:labels, l:match)
                let l:count += 1
            endwhile
        endfor
        " extract ref strings
        let l:start = len(l:prefix) + 3  " the 3 is for '{', '@' and ':'
        let l:refs = map(l:labels,
                    \ 'strpart(v:val, l:start, len(v:val) - l:start - 1)')
        " update refs
        let b:dn_markdown_refs[l:type] = {}
        for l:ref in l:refs
            call s:_increment_ref_count(l:type, l:ref)
        endfor
    endfor
endfunction

" s:_utils_missing()    {{{2
" does:   determine whether dn-utils plugin is loaded
" params: nil
" prints: nil
" return: whether dn-utils plugin is loaded
function! s:_utils_missing() abort
    if exists('g:loaded_dn_utils')
        return g:dn_false
    else
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return g:dn_true
    endif
endfunction

" s:_valid_format(format)    {{{2
" does:   determine whether a format value is valid
" params: format - format code to test [any, required]
" return: whether format code is valid - boolean
function! s:_valid_format(format) abort
    return has_key(s:dn_markdown_pandoc_params, a:format)
endfunction

" s:_valid_setting_name(setting)    {{{2
" does:   determine whether a setting name is valid
" params: setting - setting value to test [any, required]
" return: whether setting name is valid - boolean
function! s:_valid_setting_name(setting) abort
    return has_key(b:dn_markdown_settings, a:setting)
endfunction

" s:_valid_setting_value(value, setting, [init])    {{{2
" does:   determine whether a setting value is valid
" params: value   - value to test [any, required]
"         setting - setting being set [string, required]
"         init    - value is being initialised
"                   [boolean, optional, default=false]
" return: whether setting value is valid - boolean
" note:   during initialisation:
"         - give verbose warning messages
"         - accept value if setting is unitialised, e.g., source == '',
"           and value == default, even if it does match an allowed value
function! s:_valid_setting_value(value, setting, ...) abort
    " check args
    let l:init = (a:0 > 0) ? a:1 : g:dn_false
    if !has_key(b:dn_markdown_settings, a:setting)
        call dn#util#error('Invalid setting ' . a:setting)  " script error
        return
    endif
    " get needed param attributes
    let l:allowed = b:dn_markdown_settings[a:setting]['allowed']
    let l:source  = b:dn_markdown_settings[a:setting]['source']
    let l:default = b:dn_markdown_settings[a:setting]['default']
    " handle special initialisation case (see function notes)
    if l:init && l:source ==# '' && a:value ==# l:default
        return g:dn_true
    endif
    " now handle general case
    if     type(l:allowed) ==# type([])        " List
        return count(l:allowed, a:value)
    elseif l:allowed ==# 'boolean'             " 'boolean'
        return (a:value == 1 || a:value == 0)
    elseif l:allowed ==# 'executable'          " 'executable'
        return executable(a:value)
    elseif l:allowed ==# 'path_url'            " 'path_url'
        let l:url_regex = '^https\?:\/\/\(\w\+\(:\w\+\)\?@\)\?\([A-Za-z]'
                    \   . '[-_0-9A-Za-z]*\.\)\{1,}\(\w\{2,}\.\?\)\{1,}'
                    \   . '\(:[0-9]\{1,5}\)\?\S*$'
        return (filereadable(resolve(expand(a:value)))
                    \ || a:value =~? l:url_regex)
    elseif l:allowed ==# 'template_file'       " 'template_file'
        " template files can be a filepath or url,
        " or they can be the base name or file name
        " of a file in one of pandoc's template
        " directories;
        " also, the name of each template setting
        " has the form 'template_FORMAT', where
        " 'FORMAT' is the output format, i.e.,
        " a key of s:dn_markdown_pandoc_params
        if !filereadable(resolve(expand(a:value)))
            let l:format = strpart(a:setting, len('template_'))
            let l:msgs = [
                        \ 'This is not a valid file path',
                        \ 'That is okay if this is either:',
                        \ '- a valid and reachable url, or',
                        \ '- the base or name of a file in a',
                        \ '  pandoc templates directory,',
                        \ 'otherwise ' . l:format
                        \ . ' output generation will fail',
                        \ ]
            if l:init  " give verbose warning
                let l:msg = 'Setting ' . a:setting . " to '" . a:value . "'"
                call insert(l:msgs, l:msg)
            endif
            for l:msg in l:msgs | call dn#util#warn(l:msg) | endfor
        endif
        return g:dn_true
    else
        return
    endif
endfunction    " }}}2

" Restore cpoptions    {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo    " }}}1

" vim: set foldmethod=marker :
