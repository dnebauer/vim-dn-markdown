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

" outputted formats                                                        {{{2
let b:dn_md_outputted_formats = {}

" pandoc settings menu (s:menu_items, s:menu_prompt)                       {{{2
" - returns one of:
"   . citeproc_all
"   . {fontsize,linkcolor,latexengine}_pdf
"   . stylesheet_{docx,epub,html}
"   . template_{docx,epub,html,pdf}
"   . '' (if no item selected)
let s:menu_prompt = 'Select setting to modify:'
let s:menu_items = {
            \ 'Citeproc (all formats)' : 'citeproc_all',
            \ 'Print only' : [
            \   {'Font size (print)'    : 'fontsize_print'},
            \   {'Link colour (print)'  : 'linkcolor_print'},
            \   {'Latex engine (print)' : 'latexengine_print'},
            \   {'Paper size (print)'   : 'papersize_print'},
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
" pandoc settings values (b:dn_md_settings)                                {{{2
" - keep b:dn_md_settings.stylesheet_html.default = '' as it is set by
"   function s:_initialise to the stylesheet provided by this plugin
"   (unless it is set by the corresponding config variable)
let b:dn_md_settings = {
            \ 'citeproc_all' : {
            \   'label'   : 'Use pandoc-citeproc filter [all formats]',
            \   'value'   : '',
            \   'default' : 0,
            \   'source'  : '',
            \   'allowed' : 'boolean',
            \   'config'  : 'g:DN_markdown_citeproc_all',
            \   'prompt'  : 'Use the pandoc-citeproc filter?',
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
            \ 'latexengine_print' : {
            \   'label'   : 'Latex engine for pdf generation [print only]',
            \   'value'   : '',
            \   'default' : 'xelatex',
            \   'source'  : '',
            \   'allowed' : ['xelatex', 'lualatex', 'pdflatex'],
            \   'config'  : 'g:DN_markdown_latexengine_print',
            \   'prompt'  : 'Select latex engine:',
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
            \ 'papersize_print' : {
            \   'label'   : 'Paper size [print only]',
            \   'value'   : '',
            \   'default' : 'a4',
            \   'source'  : '',
            \   'allowed' : ['a4', 'letter'],
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
            \   'allowed' : 'base_file_path_url',
            \   'config'  : 'g:DN_markdown_template_azw3',
            \   'prompt'  : 'Specify the azw3 (epub) template:',
            \   },
            \ 'template_context' : {
            \   'label'   : 'Pandoc template file [context]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'base_file_path_url',
            \   'config'  : 'g:DN_markdown_template_context',
            \   'prompt'  : 'Specify the context template:',
            \   },
            \ 'template_docx' : {
            \   'label'   : 'Pandoc template file [docx]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'base_file_path_url',
            \   'config'  : 'g:DN_markdown_template_docx',
            \   'prompt'  : 'Specify the docx template:',
            \   },
            \ 'template_epub' : {
            \   'label'   : 'Pandoc template file [epub]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'base_file_path_url',
            \   'config'  : 'g:DN_markdown_template_epub',
            \   'prompt'  : 'Specify the epub template:',
            \   },
            \ 'template_html' : {
            \   'label'   : 'Pandoc template file [html]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'base_file_path_url',
            \   'config'  : 'g:DN_markdown_template_html',
            \   'prompt'  : 'Specify the html template:',
            \   },
            \ 'template_latex' : {
            \   'label'   : 'Pandoc template file [latex]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'base_file_path_url',
            \   'config'  : 'g:DN_markdown_template_latex',
            \   'prompt'  : 'Specify the latex template:',
            \   },
            \ 'template_mobi' : {
            \   'label'   : 'Pandoc template file [mobi]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'base_file_path_url',
            \   'config'  : 'g:DN_markdown_template_mobi',
            \   'prompt'  : 'Specify the mobi (epub) template:',
            \   },
            \ 'template_odt' : {
            \   'label'   : 'Pandoc template file [odt]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'base_file_path_url',
            \   'config'  : 'g:DN_markdown_template_odt',
            \   'prompt'  : 'Specify the odt template:',
            \   },
            \ 'template_pdf_context' : {
            \   'label'   : 'Pandoc template file [pdf via context]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'base_file_path_url',
            \   'config'  : 'g:DN_markdown_template_pdf_context',
            \   'prompt'  : 'Specify the context template for pdf generation:',
            \   },
            \ 'template_pdf_html' : {
            \   'label'   : 'Pandoc template file [pdf via html]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'base_file_path_url',
            \   'config'  : 'g:DN_markdown_template_pdf_html',
            \   'prompt'  : 'Specify the html template for pdf generation:',
            \   },
            \ 'template_pdf_latex' : {
            \   'label'   : 'Pandoc template file [pdf via latex]',
            \   'value'   : '',
            \   'default' : '',
            \   'source'  : '',
            \   'allowed' : 'base_file_path_url',
            \   'config'  : 'g:DN_markdown_template_pdf_latex',
            \   'prompt'  : 'Specify the latex template for pdf generation:',
            \   },
            \ }
" - note: initialisation process will call s:_set_default_html_stylesheet()
"         to set b:dn_md_settings.stylesheet_html as a special case
"         (because ftplugin includes a default html stylesheet)
" pandoc parameters to set (s:pandoc_params)                               {{{2
let s:pandoc_params = {
            \ 'azw3' : '*** copy from |epub| with modified format ***',
            \ 'context' : {
            \   'format'    : 'ConTeXt (tex)',
            \   'depend'    : ['pandoc', 'context'],
            \   'extension' : '.tex',
            \   'pandoc_to' : 'context',
            \   'params'    : ['standalone',   'smart',     'citeproc',
            \                  'contextlinks', 'papersize', 'template',
            \                  'fontsize'],
            \   },
            \ 'docx' : {
            \   'format'    : 'Microsoft Word (docx)',
            \   'depend'    : ['pandoc'],
            \   'extension' : '.docx',
            \   'pandoc_to' : 'docx',
            \   'params'    : ['standalone', 'smart',   'citeproc',
            \                  'style_docx', 'template'],
            \   },
            \ 'epub' : {
            \   'format'    : 'Electronic publication (ePub)',
            \   'depend'    : ['pandoc'],
            \   'extension' : '.epub',
            \   'pandoc_to' : 'epub3',
            \   'params'    : ['standalone', 'smart',    'style_epub',
            \                  'cover_epub', 'citeproc', 'template'],
            \   },
            \ 'html' : {
            \   'format'    : 'HyperText Markup Language (html)',
            \   'depend'    : ['pandoc'],
            \   'extension' : '.html',
            \   'pandoc_to' : 'html5',
            \   'params'    : ['standalone', 'smart',      'selfcontained',
            \                  'citeproc',   'style_html', 'template'],
            \   },
            \ 'latex' : {
            \   'format'    : 'LaTeX (tex)',
            \   'depend'    : ['pandoc', 'latex'],
            \   'extension' : '.tex',
            \   'pandoc_to' : 'latex',
            \   'params'    : ['standalone',  'citeproc', 'smart',
            \                  'latexengine', 'fontsize', 'latexlinks',
            \                  'papersize',   'template'],
            \   },
            \ 'mobi' : '*** copy from |epub| with modified format ***',
            \ 'odt' : {
            \   'format'    : 'OpenDocument Text (odt)',
            \   'depend'    : ['pandoc'],
            \   'extension' : '.odt',
            \   'pandoc_to' : 'odt',
            \   'params'    : ['standalone', 'smart',   'citeproc',
            \                  'style_odt', 'template'],
            \   },
            \ 'pdf_context' : '*** copy from |context| with modifications ***',
            \ 'pdf_html'    : '*** copy from |html| with modifications ***',
            \ 'pdf_latex'   : '*** copy from |latex| with modifications ***',
            \ }
" - azw3 is produced by first creating an epub output file
let s:pandoc_params.azw3 = deepcopy(s:pandoc_params.epub)
let s:pandoc_params.azw3.format = 'Kindle Format 8 (azw3) via ePub'
call add(s:pandoc_params.azw3.depend, 'ebook-convert')
" - mobi is produced by first creating an epub output file
let s:pandoc_params.mobi = deepcopy(s:pandoc_params.epub)
let s:pandoc_params.mobi.format = 'Mobipocket e-book (mobi) via ePub'
call add(s:pandoc_params.mobi.depend, 'ebook-convert')
" - pdf-via-context produces pdf output via context
let s:pandoc_params.pdf_context = deepcopy(s:pandoc_params.context)
let s:pandoc_params.pdf_context.format
            \ = 'Portable Document Format (pdf) via ConTeXt'
let s:pandoc_params.pdf_context.extension = '.pdf'
" - pdf-via-html produces pdf output via html
let s:pandoc_params.pdf_html = deepcopy(s:pandoc_params.html)
let s:pandoc_params.pdf_html.format
            \ = 'Portable Document Format (pdf) via HTML'
call add(s:pandoc_params.pdf_html.depend, 'wkhtmltopdf')
let s:pandoc_params.pdf_html.extension = '.pdf'
" - pdf-via-latex produces pdf output via latex
let s:pandoc_params.pdf_latex = deepcopy(s:pandoc_params.latex)
let s:pandoc_params.pdf_latex.format
            \ = 'Portable Document Format (pdf) via LaTeX'
let s:pandoc_params.pdf_latex.extension = '.pdf'

" Public functions                                                         {{{1

" dn#markdown#view([params])                                               {{{2
" does:   view output of a specified format
" params: params - parameters dictionary with the following keys:
"                  'insert' - whether entered from insert mode
"                             [optional, default=<false>, boolean]
"                  'format' - output format
"                             [optional, no default,
"                              must be a key of s:pandoc_params]
" return: nil
" note:   output is always (re)generated before viewing
function! dn#markdown#view(...) abort
    " universal tasks                                                      {{{3
    echo '' |  " clear command line
    if s:_dn_utils_missing() | return | endif |  " requires dn-utils plugin
    if !exists('s:initialised') | call s:_initialise() | endif  " initialise
    " process params                                                       {{{3
    let [l:insert, l:format] = s:_process_dict_params(a:000)
    if empty(l:format) | let l:format = s:_select_format() | endif
    if empty(l:format) | return | endif
    " (re)generate output                                                  {{{3
    if !s:_generator(l:format)
        call dn#util#error('Output (re)generation failed')
        if l:insert | call dn#util#insertMode(g:dn_true) | endif
        return
    endif
    " check for output file to view                                        {{{3
    let l:ext    = s:pandoc_params[l:format]['extension']
    let l:output = substitute(expand('%'), '\.md$', l:ext, '')
    if !filereadable(l:output)
        call dn#util#error('No ' . l:format . ' file to view')
        if l:insert | call dn#util#insertMode(g:dn_true) | endif
        return
    endif
    " view output                                                          {{{3
    if s:os ==# 'win'
        let l:win_view_direct = ['docx', 'epub', 'html']
        let l:win_view_cmd    = ['pdf']
        if     count(l:win_view_direct, l:format) > 0
            " execute as a direct shell (dos) command
            let l:errmsg = [
                        \   'Unable to display ' . l:format . ' output',
                        \   'Windows has no default ' . l:format . ' viewer',
                        \   'Shell feedback:',
                        \ ]
            let l:cmd = shellescape(l:output)
            let l:succeeded = s:_execute_shell_command(l:cmd, l:errmsg)
            if l:succeeded
                echo 'Done'
            endif
        elseif count(l:win_view_cmd, l:format) > 0
            " execute in a cmd shell
            try
                execute 'silent !start cmd /c "' l:output '"'
            catch
                let l:msg = 'Unable to display ' . l:format . ' output'
                call dn#util#error(l:msg)
                let l:msg = 'Windows has no default ' . l:format . ' viewer'
                call dn#util#showMsg(l:msg)
                return
            endtry
        else  " script error - do l:win_view_{direct,cmd} cover all formats?
            call dn#util#error('Invalid format: ' . l:format)
        endif
    elseif s:os ==# 'nix'
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
            call dn#util#error("Could not find '" . l:opener . "'")
        endif
    else
        echo ''
        call dn#util#error('Operating system not supported')
    endif
    " return to calling mode                                               {{{3
    if l:insert | call dn#util#insertMode(g:dn_true) | endif |           " }}}3
endfunction

" dn#markdown#generate([params])                                           {{{2
" does:   generate output
" params: params - parameters dictionary with the following keys:
"                  'insert' - whether entered from insert mode
"                             [optional, default=<false>, boolean]
"                  'format' - output format
"                             [optional, no default,
"                              must be a key of s:pandoc_params]
" return: nil
function! dn#markdown#generate(...) abort
    " universal tasks
    echo '' |  " clear command line
    if !exists('s:initialised') | call s:_initialise() | endif  " initialise
    if s:_dn_utils_missing() | return | endif  " requires dn-utils plugin
    " process params
    let [l:insert, l:format] = s:_process_dict_params(a:000)
    if empty(l:format) | let l:format = s:_select_format() | endif
    if empty(l:format) | return | endif
    " generate output
    if s:_generator(l:format) | echo 'Done' | endif
    call dn#util#prompt()
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#regenerate([insert])                                         {{{2
" does:   regenerate all previously outputted files
" params: insert - whether entered from insert mode
"                  [default=<false>, optional, boolean]
" return: nil
function! dn#markdown#regenerate(...) abort
    " universal tasks
    echo '' |  " clear command line
    if !exists('s:initialised') | call s:_initialise() | endif  " initialise
    if s:_dn_utils_missing() | return | endif  " requires dn-utils plugin
    " params
    let l:insert = (a:0 > 0 && a:1) ? g:dn_true : g:dn_false
    " check for previous output
    let l:formats = keys(b:dn_md_outputted_formats)
    if empty(l:formats)  " inform user
        let l:msg = 'No output files have been generated during this session'
        call dn#util#warn(l:msg)
    else  " generate output
        let l:succeeded = g:dn_true
        for l:format in l:formats
            if !s:_generator(l:format)
                let l:succeeded = g:dn_false
            endif
        endfor
        if l:succeeded | echo 'Done'
        else           | call dn#util#error('Problems occurred during output')
        endif
    endif
    call dn#util#prompt()
    redraw!
    " return to calling mode
    if l:insert | call dn#util#insertMode(g:dn_true) | endif
endfunction

" dn#markdown#settings()                                                   {{{2
" does:   change settings, e.g., b:dn_md_settings.<var>.value
" params: nil
" return: nil, edits b:dn_md_settings in place
function! dn#markdown#settings() abort
    " universal tasks
    echo '' |  " clear command line
    if s:_dn_utils_missing() | return | endif |  " requires dn-utils plugin
    if !exists('s:initialised') | call s:_initialise() | endif
    " get setting to edit
    let l:setting = dn#util#menuSelect(s:menu_items, s:menu_prompt)
    while count(keys(b:dn_md_settings), l:setting) == 1
        let l:label   = b:dn_md_settings[l:setting]['label']
        let l:value   = b:dn_md_settings[l:setting]['value']
        let l:source  = b:dn_md_settings[l:setting]['source']
        let l:allowed = b:dn_md_settings[l:setting]['allowed']
        let l:prompt  = b:dn_md_settings[l:setting]['prompt'] . ' '
        " notify user of current setting
        echo l:label
        call s:_say('Current value:', s:_display_value(l:value, l:setting))
        call s:_say('Source:', l:source)
        " display allowed values and get user input
        if     type(l:allowed) == type([])
            call s:_say('Allowed:', join(l:allowed, ', '))
            let l:options = []
            for l:option in sort(l:allowed)
                let l:item = (type(l:option) == type('')) ? l:option
                            \                             : string(l:option)
                call add(l:options, {l:item : l:option})
            endfor
            let l:input = dn#util#menuSelect(l:options, l:prompt)
        elseif l:allowed ==# 'boolean'
            call s:_say('Allowed:', 'Yes, No')
            let l:options = [{'Yes': g:dn_true}, {'No': g:dn_false}]
            let l:input = dn#util#menuSelect(l:options, l:prompt)
        elseif l:allowed ==# 'path_url'
            call s:_say('Allowed:', '[valid file path or url]')
            let l:input = input(l:prompt, l:value, 'file')
            echo ' '  | " ensure move to a new line
        elseif l:allowed ==# 'base_file_path_url'
            call s:_say('Allowed:', '[valid base/file name, file path or url]')
            let l:input = input(l:prompt, l:value, 'file')
            echo ' '  | " ensure move to a new line
        else  " script error!
            call dn#util#error("Invalid 'allowed' value: '" . l:allowed . "'")
            return
        endif
        " validate input
        if s:_valid_param(l:input, l:allowed)
            let b:dn_md_settings[l:setting]['value']  = l:input
            let b:dn_md_settings[l:setting]['source'] = 'set by user'
            call s:_say('Now set to:', s:_display_value(l:input, l:setting))
        else
            call dn#util#error('Error: Not a valid value')
        endif
        " get next setting to change
        let l:setting = dn#util#menuSelect(s:menu_items, s:menu_prompt)
    endwhile
endfunction


" dn#markdown#complete(ArgLead, CmdLine, CursorPos)                        {{{2
" does:   return completion candidates for output formats
" params: ArgLead   - see help for |command-completion-custom|
"         CmdLine   - see help for |command-completion-custom|
"         CursorPos - see help for |command-completion-custom|
" return: List of output formats
function! dn#markdown#complete(A, L, P) abort
    return keys(s:pandoc_params)
endfunction


" Private functions                                                        {{{1

" s:_say(msg1, [msg2])                                                     {{{2
" does:   echo line of output with wrapping and hanging indent
" params: msg1 - message to display [string, required]
"         msg2 - message to display [string, optional]
" return: nil
" note:   if only msg1 is present, then treat output as a single string
" note:   if msg2 is present, right-pad msg1 with spaces to the width
"         of the hanging indent before concatenating msg1 and msg2
function! s:_say(msg1, ...) abort
    " hanging indent
    let l:hang = 15
    " if msg2 present, right-pad msg1
    let l:msg = a:msg1
    if a:0 > 0
        let l:msg2 = a:1
        while len(l:msg) < l:hang | let l:msg .= ' ' | endwhile
        let l:msg .= l:msg2
    endif
    " print wrapped output
    call dn#util#wrap(l:msg, l:hang)
endfunction

" s:_dn_utils_missing()                                                    {{{2
" does:   determine whether dn-utils plugin is loaded
" params: nil
" prints: nil
" return: whether dn-utils plugin is loaded
function! s:_dn_utils_missing() abort
    if exists('g:loaded_dn_utils')
        return g:dn_false
    else
        echoerr 'dn-markdown ftplugin cannot find the dn-utils plugin'
        echoerr 'dn-markdown ftplugin requires the dn-utils plugin'
        return g:dn_true
    endif
endfunction

" s:_initialise()                                                          {{{2
" does:   initialise plugin
" params: nil
" return: nil
function! s:_initialise() abort
    let s:initialised = 1  " do only once
    " set default html stylesheet (because it must be set dynamically,
    " unlike other settings set statically with b:dn_md_settings variable)
    call s:_set_default_html_stylesheet()
    " set parameters from configuration variables where available,
    " otherwise set to their default values
    for l:param in keys(b:dn_md_settings)
        let l:default = b:dn_md_settings[l:param]['default']
        let l:config  = b:dn_md_settings[l:param]['config']
        let l:allowed = b:dn_md_settings[l:param]['allowed']
        let l:source  = b:dn_md_settings[l:param]['source']
        let l:set_from_config = g:dn_false
        if exists(l:config)  " try to set from config variable
            let l:value = {l:config}
            if s:_valid_param(l:value, l:allowed)
                let l:source = 'set from configuration variable ' . l:config
                let b:dn_md_settings[l:param]['value']  = l:value
                let b:dn_md_settings[l:param]['source'] = l:source
                let l:set_from_config = g:dn_true
            else
                call dn#util#error("Invalid variable '" . l:config . "': '"
                            \ . l:value . "'")
            endif
        endif
        if !l:set_from_config  " try to set from default
            let l:value = b:dn_md_settings[l:param]['default']
            if s:_valid_param(l:value, l:allowed, l:default, l:source)
                let l:source = 'default'
                let b:dn_md_settings[l:param]['value']  = l:value
                let b:dn_md_settings[l:param]['source'] = l:source
            else
                call dn#util#error("Invalid default: '" . l:value . "'")
            endif
        endif
    endfor
    " reset outputted formats
    let l:dn_md_outputted_formats = {}
endfunction

" s:_process_dict_params(params)                                           {{{2
" does:   process dict param used by dn#markdown#{view,output}
" params: params - List that may contain a parameters dictionary
"                  with the following keys:
"                  'insert' - whether entered from insert mode
"                             [optional, default=<false>, boolean]
"                  'format' - output format
"                             [optional, no default,
"                              must be a key of s:pandoc_params]
" return: List [insert, format]
function! s:_process_dict_params(...) abort
    " universal tasks
    echo '' |  " clear command line
    if !exists('s:initialised') | call s:_initialise() | endif  " initialise
    if s:_dn_utils_missing() | return | endif  " requires dn-utils plugin
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

" s:_valid_param(value, allowed, [default, source])                        {{{2
" does:   determine whether a parameter value is valid
" params: value   - parameter value to test [any, required]
"         allowed - type of value allowed
"                   [List or string, required, one of:
"                    List|'boolean'|'path_url'|'base_file_path_url']
"         default - default value [string, optional, no default]
"         source  - source of value [string, optional, no default]
" return: whether param value is valid - boolean
" note:   when both default and source values are provided, there is
"         an extra valid condition: if source == '' (i.e., param not
"         yet initialised) then a value is valid if it matches the
"         default, even if it does not match an allowed value
function! s:_valid_param(value, allowed, ...) abort
    " first handle special case (see note above)
    if a:0 == 2
        let l:default = a:1 | let l:source = a:2
        if l:source ==# ''  " param is uninitialised
            if a:value ==# l:default | return g:dn_true | endif
        endif
    endif
    " now handle general case
    if     type(a:allowed) ==# type([])        " List
        return count(a:allowed, a:value)
    elseif a:allowed ==# 'boolean'             " 'boolean'
        return (a:value == 1 || a:value == 0)
    elseif a:allowed ==# 'path_url'            " 'path_url'
        let l:url_regex = '^https\?:\/\/\(\w\+\(:\w\+\)\?@\)\?\([A-Za-z]'
                    \   . '[-_0-9A-Za-z]*\.\)\{1,}\(\w\{2,}\.\?\)\{1,}'
                    \   . '\(:[0-9]\{1,5}\)\?\S*$'
        return (filereadable(resolve(expand(a:value)))
                    \ || a:value =~? l:url_regex)
    elseif a:allowed ==# 'base_file_path_url'  " 'base_file_path_url'
        if !filereadable(resolve(expand(a:value)))
            let l:msgs = [
                        \ 'This is not a valid file path',
                        \ 'That is okay if this is either:',
                        \ '- a valid and reachable url, or',
                        \ '- the basename or filename of a file in the',
                        \ '  ''templates'' subdirectory of the pandoc',
                        \ '  user data directory',
                        \ 'If it is neither, output generation will fail',
                        \ ]
            for l:msg in l:msgs | call dn#util#warn(l:msg) | endfor
        endif
        return g:dn_true
    else
        return
    endif
endfunction

" s:_valid_format(format)                                                  {{{2
" does:   determine whether a format value is valid
" params: format - format code to test [any, required]
" return: whether format code is valid - boolean
function! s:_valid_format(format) abort
    return has_key(s:pandoc_params, a:format)
endfunction

" s:_valid_setting(setting)                                                {{{2
" does:   determine whether a setting is valid
" params: setting - setting value to test [any, required]
" return: whether setting is valid - boolean
function! s:_valid_setting(setting) abort
    return has_key(b:dn_md_settings, a:setting)
endfunction

" s:_display_value(value, setting)                                         {{{2
" does:   get the display value for a setting value
" params: value   - setting value to display [any, required]
"         setting - name of setting [any, required]
" return: display value [String]
function! s:_display_value(value, setting) abort
    let l:allowed = b:dn_md_settings[a:setting]['allowed']
    if type(l:allowed) == type('') && l:allowed ==# 'boolean'
        let l:display_value = a:value ? 'Yes' : 'No'
    else
        let l:display_value = empty(a:value) ? '[Null/empty]'
                    \                        : dn#util#stringify(a:value)
    endif
    return l:display_value
endfunction

" s:_set_default_html_stylesheet()                                         {{{2
" does:   set s:dn_md_settings.stylesheet_html.default
"         to the stylesheet provided by this plugin
" params: nil
" return: nil, sets variable in place
function! s:_set_default_html_stylesheet() abort
    " universal tasks
    echo '' |  " clear command line
    if s:_dn_utils_missing() | return | endif |  " requires dn-utils plugin
    " requires s:dn_md_settings.stylesheet_html.default
    if !exists('b:dn_md_settings')
        echoerr 'dn-markdown ftplugin cannot set html stylesheet default'
        echoerr 'dn-markdown ftplugin cannot find b:dn_md_settings'
        return
    endif
    if !(s:_valid_setting('stylesheet_html')
                \ && has_key(b:dn_md_settings.stylesheet_html, 'default'))
        echoerr 'dn-markdown ftplugin cannot set html stylesheet default'
        echoerr '-- cannot find b:dn_md_settings.stylesheet_html.default'
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
    let b:dn_md_settings.stylesheet_html.default = l:stylesheet
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

" s:_generator(format)                                                     {{{2
" does:   generate output
" params: format - output format [required, must be s:pandoc_params key]
" return: whether output completed without error
function! s:_generator (format) abort
    " requirements                                                         {{{3
    " - apps
    "   . get list of apps on which conversion depends
    let l:depends = s:pandoc_params[a:format]['depend']
    "   . replace 'latex' with specific latex engine
    let l:index = index(l:depends, 'latex')
    if l:index >= 0
        let l:engine = b:dn_md_settings.latexengine_print.value
        if empty(l:engine)  " script error
            call dn#util#error('No latex engine defined')
            return
        endif
        let l:depends[l:index] = l:engine
    endif
    "   . now test for each app in turn
    for l:depend in l:depends
        if !executable(l:depend)
            call dn#util#error(l:depend . ' is not installed')
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
    if s:os !~# '^win$\|^nix$'  " currently only windows and unix
        call dn#util#error('Operating system not supported')
        return
    endif
    " process params                                                       {{{3
    if !s:_valid_format(a:format)
        call dn#util#error("Invalid format '" . a:format . "'")
        return
    endif
    " save file to incorporate any changes                                 {{{3
    silent update
    call s:_say('Target format:', a:format)
    call s:_say('Converter:', 'pandoc')
    " generate output
    " - note: some output options are displayed explicitly,
    "         one per line, while other are added to l:opts
    "         and displayed in a single line
    let l:params = s:pandoc_params[a:format]['params']
    let l:opts   = []
    " output format                                                        {{{3
    let l:to  = s:pandoc_params[a:format]['pandoc_to']     " output format
    let l:cmd = ['pandoc -t', l:to]
    call add(l:opts, l:to)
    " latex engine                                                         {{{3
    if count(l:params, 'latexengine') > 0                  " latex engine
        " latex engine
        " - can be pdflatex, lualatex or xelatex (default)
        " - xelatex is better at handling exotic unicode
        let l:engine = b:dn_md_settings.latexengine_print.value
        if !executable(l:engine)
            call dn#util#error('Install ' . l:engine)
            return
        endif
        call add(l:cmd, '--latex-engine=' . l:engine)
        call s:_say('Latex engine:', l:engine)
    endif
    " make links visible                                                   {{{3
    if count(l:params, 'latexlinks') > 0                   " latex links
        " available colours are:
        "   black,    blue,    brown, cyan,
        "   darkgray, gray,    green, lightgray,
        "   lime,     magenta, olive, orange,
        "   pink,     purple,  red,   teal,
        "   violet,   white,   yellow
        "   [https://en.wikibooks.org/wiki/LaTeX/Colors#Predefined_colors]
        " if colour is changed here, update documentation
        let l:link_color = b:dn_md_settings.linkcolor_print.value
        call add(l:cmd, '--variable linkcolor=' . l:link_color)
        call add(l:cmd, '--variable citecolor=' . l:link_color)
        call add(l:cmd, '--variable toccolor='  . l:link_color)
        call add(l:cmd, '--variable urlcolor='  . l:link_color)
        call s:_say('Link colour:', l:link_color)
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
        let l:link_color = b:dn_md_settings.linkcolor_print.value
        call add(l:cmd, '--variable linkcolor=' . l:link_color)
        call s:_say('Link colour:', l:link_color)
    endif
    " custom font size                                                     {{{3
    if count(l:params, 'fontsize') > 0                     " font size
        let l:font_size = b:dn_md_settings.fontsize_print.value
        if empty(l:font_size)
            call s:_say('Font size:', 'default')
        else
            let l:font_size .= 'pt'
            call s:_say('Font size:', l:font_size)
            call add(l:cmd, '--variable fontsize=' . l:font_size)
        endif
    endif
    " custom paper size                                                    {{{3
    if count(l:params, 'papersize') > 0                    " paper size
        let l:paper_size = b:dn_md_settings.papersize_print.value
        if empty(l:paper_size)
            call s:_say('Paper size:', 'default')
        else
            call s:_say('Paper size:', l:paper_size)
            call add(l:cmd, '--variable papersize=' . l:paper_size)
        endif
    endif
    " add header and footer                                                {{{3
    if count(l:params, 'standalone') > 0                   " standalone
        call add(l:cmd, '--standalone')
        call add(l:opts, 'standalone')
    endif
    " convert quotes, em|endash, ellipsis                                  {{{3
    if count(l:params, 'smart') > 0                        " smart
        call add(l:cmd, '--smart')
        call add(l:opts, 'smart')
    endif
    " incorporate external dependencies                                    {{{3
    if count(l:params, 'selfcontained') > 0                " self-contained
        call add(l:cmd, '--self-contained')
        call add(l:opts, 'self-contained')
    endif
    " use citeproc if selected by user                                     {{{3
    if count(l:params, 'citeproc') > 0                     " citeproc
        let l:use_citeproc = b:dn_md_settings.citeproc_all.value
        if l:use_citeproc
            call add(l:cmd, '--filter pandoc-citeproc')
            call add(l:opts, 'pandoc-citeproc')
        endif
    endif
    " use css stylesheet for html                                          {{{3
    if count(l:params, 'style_html') > 0                   " style/html
        let l:style_html = b:dn_md_settings.stylesheet_html.value
        if !empty(l:style_html)
            call add(l:cmd, '--css=' . shellescape(l:style_html))
            call s:_say('Stylesheet:', l:style_html)
        endif
    endif
    " use css stylesheet for epub                                          {{{3
    if count(l:params, 'style_epub') > 0                   " style/epub
        let l:style_epub = b:dn_md_settings.stylesheet_epub.value
        if !empty(l:style_epub)
            call add(l:cmd, '--epub-stylesheet='
                        \ . shellescape(l:style_epub))
            call s:_say('Stylesheet:', l:style_epub)
        endif
    endif
    " use cover image for epub                                             {{{3
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
            call s:_say('Cover image:', l:cover_epub)
        endif
    endif
    " use docx stylesheet                                                  {{{3
    if count(l:params, 'style_docx') > 0                   " style_docx
        let l:style_docx =
                    \ b:dn_md_settings.stylesheet_docx.value
        if !empty(l:style_docx)
            call add(l:cmd, '--reference-docx='
                        \ . shellescape(l:style_docx))
            call s:_say('Style doc:', l:style_docx)
        endif
    endif
    " use custom template                                                  {{{3
    if count(l:params, 'template') > 0                     " template
        let l:setting  = 'template_' . a:format
        let l:template = b:dn_md_settings[l:setting]['value']
        if !empty(l:template)
            call add(l:cmd, '--template='
                        \ . shellescape(l:template))
            call s:_say('Template:', l:template)
        else
            call s:_say('Template:', '[default]')
        endif
    endif
    " output file                                                          {{{3
    let l:ext    = s:pandoc_params[a:format]['extension']  " output file
    let l:output = substitute(expand('%'), '\.md$', l:ext, '')
    call s:_say('Output file:', l:output)
    " - special case for mobi and azw3 output
    "   . need to output a temporary epub file that
    "     won't overwrite any existing epub output
    if count(['mobi', 'azw3'], a:format) == 1
        let l:epub_output = l:output
        let l:prefix = 1
        let l:output = l:prefix . '_' . l:epub_output
        while filereadable(l:output)
            let l:prefix += 1
            let l:output = l:prefix . '_' . l:epub_output
        endwhile
    endif
    call add(l:cmd, '--output=' . shellescape(l:output))
    " input file                                                           {{{3
    let l:source = expand('%')                             " input file
    call add(l:cmd, shellescape(l:source))
    " generate output                                                      {{{3
    call s:_say('Options:', join(l:opts, ', '))
    let l:errmsg = ["Error occurred during '"
                \ . a:format . "' generation"]
    call s:_say('Generating output... ')
    let l:retval = s:_execute_shell_command(join(l:cmd), l:errmsg)
    " perform additional conversion for mobi and azw3 output               {{{3
    if l:retval && count(['mobi', 'azw3'], a:format) == 1
        let l:input  = l:output
        let l:exts   = {'mobi': '.mobi', 'azw3': '.azw3'}
        let l:ext    = l:exts[a:format]
        let l:output = substitute(expand('%'), '\.md$', l:ext, '')
        let l:cmd    = ['ebook-convert', shellescape(l:input),
                    \ shellescape(l:output), '--pretty-print',
                    \ '--smarten-punctuation', '--insert-blank-line',
                    \ '--keep-ligatures']
        let l:retval = s:_execute_shell_command(join(l:cmd), l:errmsg)
        if delete(l:input) == -1
            let l:msg = "Unable to delete intermediary file '" . l:input . "'"
            call dn#util#error(l:msg)
        endif
    endif
    " update outputted formats                                             {{{3
    if l:retval
        let b:dn_md_outputted_formats[a:format] = g:dn_true
    endif
    " return outcome                                                       {{{3
    return l:retval                                                      " }}}3
endfunction

" s:_select_format(prompt)                                                 {{{2
" does:   select output format
" params: prompt - prompt [string, optional, default='Select output format:']
" return: output format (a key to s:pandoc_params)
function! s:_select_format (...) abort
    let l:prompt = (a:0 > 0 && a:1) ? a:1 : 'Select output format:'
    " create dict with format names as keys, format codes as values
    let l:formats = {}
    for [l:key, l:val] in items(s:pandoc_params)
        let l:formats[l:val['format']] = l:key
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
endfunction                                                              " }}}2

" Restore cpoptions                                                        {{{1
let &cpoptions = s:save_cpo
unlet s:save_cpo                                                         " }}}1

" vim: set foldmethod=marker :
