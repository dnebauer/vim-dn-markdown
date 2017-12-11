" Test vim-dn-markdown ftplugin variables for correctness

" Tests: s:dn_markdown_referenced_types
"        s:dn_markdown_pandoc_params

" Usage: open script in vim, execute command ':source %'
"        open from command line with 'vim check-vars.vim "+source %"'

" s:main()    {{{1
" does:   initial loading function
" params: nil
" return: nil
function! s:main() abort
    " requires vim-dn-utils plugin    {{{2
    echo '' |  " clear command line
    if s:_utils_missing() | return | endif  " requires dn-utils plugin
    " must start with filetype vim    {{{2
    if &filetype !=# 'vim'
        let l:msg = ["expected 'vim' filetype, found '" . &filetype . "'",
                    \ 'close and reopen script before sourcing it']
        call dn#util#error(l:msg)
        return
    endif
    " check for previous sourcing    {{{2
    if exists('s:sourced')
        let l:msg = 'script has been previously sourced in this buffer'
        call dn#util#warn(l:msg)
    else
        let s:sourced = 1
    endif
    " activate markdown plugin to load it    {{{2
    set filetype=markdown
    set filetype=vim    " }}}2
    " get values for variables    {{{2
    call s:_set_vars_manually()
    " - s:referenced_types    {{{3
    if exists('s:referenced_types') && !empty(s:referenced_types)
        echo "variable 's:referenced_types' set by this script"
    else  " retrieve from ftplugin autoload
        " - use function to retrieve value of target variable
        let l:fn = 'dn#markdown#referenced_types'
        if !exists('*'.l:fn)
            let l:msg = "can't find function " . l:fn . '()'
            call dn#util#error(l:msg)
            return
        endif
        let s:referenced_types = dn#markdown#referenced_types()
        if empty(s:referenced_types)
            let l:msg = 'unable to retrieve value for '
                        \ . 's:dn_markdown_referenced_types'
            call dn#util#error(l:msg)
            return
        endif
    endif
    " - s:pandoc_params    {{{3
    if exists('s:pandoc_params') && !empty(s:pandoc_params)
        echo "variable 's:pandoc_params' set by this script"
    else  " retrieve from ftplugin autoload
        " - use function to retrieve value of target variable
        let l:fn = 'dn#markdown#pandoc_params'
        if !exists('*'.l:fn)
            let l:msg = "can't find function " . l:fn . '()'
            call dn#util#error(l:msg)
            return
        endif
        let s:pandoc_params = dn#markdown#pandoc_params()
        if empty(s:pandoc_params)
            let l:msg = 'unable to retrieve value for '
                        \ . 's:dn_markdown_pandoc_params'
            call dn#util#error(l:msg)
            return
        endif
    endif
    " test variables for validity    {{{2
    " - s:dn_markdown_referenced_types    {{{3
    if s:_check_referenced_types()
        echo '- definition is VALID'
    else
        call dn#util#warn('- definition is *INVALID*')
    endif
    " - s:dn_markdown_pandoc_params    {{{3
    if s:_check_pandoc_params()
        echo '- definition is VALID'
    else
        call dn#util#warn('- definition is *INVALID*')
    endif    " }}}3
    " last output line can be overwritten by status line on startup    {{{2
    echo ' ' |  " }}}2
    " restore vim filetype    {{{2
    "set filetype=vim    " }}}2
    " }}}2
endfunction

" s:_check_referenced_types()    {{{1
" does:   check that s:dn_markdown_referenced_types is valid
" params: nil
" prints: error message if invalidity detected
" return: whether variable is valid
function! s:_check_referenced_types() abort
    " feedback    {{{2
    echo ' ' |  " clear command line
    echo 's:dn_markdown_referenced_types'
    " variables    {{{2
    let l:placeholders = {}
    "let l:valid_types = ['equation', 'figure', 'footnote', 'link', 'table']
    let l:valid_types = ['equation', 'figure', 'table']
    let l:valid_type_params = ['regex_str', 'write_str', 'regex_ref',
                \              'templ_ref', 'multi_ref', 'zero_ref',
                \              'name',      'Name',      'complete']
    let l:valid_ref_values = ['ignore', 'warning', 'error']
    let l:valid_write_str_params = ['layout', 'template', 'params']
    " must be Dict    {{{2
    if !s:_valid_dict(s:referenced_types, 'var') | return | endif
    " must have correct keys    {{{2
    let l:types = keys(s:referenced_types)
    if !s:_valid_keys(l:valid_types, l:types, 'var') | return | endif
    " process value for each reference type    {{{2
    for l:type in l:types
        " needs to be a Dict    {{{3
        let l:data = s:referenced_types[l:type]
        let l:var  = 'type ' . l:type
        if !s:_valid_dict(l:data, l:var) | return | endif
        " check that keys are valid    {{{3
        let l:params = keys(l:data)
        if !s:_valid_keys(l:valid_type_params, l:params, l:var)
            return
        endif
        " all params except 'write_str' must be non-empty strings    {{{3
        for l:param in l:params
            if l:param ==# 'write_str' | continue | endif
            let l:var = join([l:type, l:param])
            let l:value = l:data[l:param]
            if !s:_valid_non_empty_string(l:value, l:var)
                return
            endif
        endfor
        " multi_ref and zero_ref have restricted values    {{{3
        let l:multi_ref = l:data.multi_ref
        if !count(l:valid_ref_values, l:multi_ref)
            let l:var = join([l:type, 'multi_ref'])
            let l:msg = '- ' . l:var . ": invalid value '" . l:multi_ref . "'"
            call dn#util#wrap(l:msg, 2)
            return
        endif
        let l:zero_ref = l:data.zero_ref
        if !count(l:valid_ref_values, l:zero_ref)
            let l:var = join([l:type, 'zero_ref'])
            let l:msg = '- ' . l:var . ": invalid value '" . l:zero_ref . "'"
            call dn#util#wrap(l:msg, 2)
            return
        endif
        " complete value needs to be existing function    {{{3
        let l:complete = l:data.complete
        if !exists('*'.l:complete)
            let l:var = join([l:type, 'complete'])
            let l:msg = '- ' . l:var . ": bad funcname '" . l:complete . "'"
            call dn#util#wrap(l:msg, 2)
            return
        endif
        " write_str value needs to be a Dict   {{{3
        let l:var = join([l:type, 'write_str'])
        let l:write_str = l:data.write_str
        if !s:_valid_dict(l:write_str, l:var) | return | endif
        " write_str Dict needs right keys    {{{3
        let l:params = keys(l:write_str)
        if !s:_valid_keys(l:valid_write_str_params, l:params, l:var)
            return
        endif
        " check write_str keys layout and template    {{{3
        for l:key in ['layout', 'template']
            let l:var = join([l:type, 'write_str', l:key])
            let l:value = l:write_str[l:key]
            " must be non-empty string
            if !s:_valid_non_empty_string(l:value, l:var) | return | endif
            " layout must be inline or block
            if l:key ==# 'layout'
                let l:valid_layouts = ['inline', 'block']
                if !count(l:valid_layouts, l:value)
                    let l:msg = '- ' . l:var . ": invalid value '" . l:value
                                \ . "'"
                    call dn#util#wrap(l:msg, 2)
                    return
                endif
            endif
        endfor
        " test write_str params value, i.e, placeholders    {{{3
        if !s:_check_placeholders(l:type) | return | endif    " }}}3
    endfor    " }}}2
    " report success    {{{2
    return g:dn_true    " }}}2
endfunction

" s:_check_placeholders(type)    {{{1
" does:   check that placeholder definitions for a type in
"         s:dn_markdown_referenced_types are valid
" params: type - referenced structure type to check
" prints: error message if invalidity detected
" return: whether placeholder definitions are valid
function! s:_check_placeholders(type) abort
    " variables    {{{2
    let l:placeholders = {}
    let l:data         = s:referenced_types[a:type]['write_str']
    let l:template     = l:data['template']
    let l:params       = l:data['params']
    " params value is a List    {{{2
    let l:var = join([a:type, 'write_str', 'params'])
    if type(l:params) != type([])
        let l:msg = '- ' . l:var . ': expected List, got '
                    \ . dn#util#varType(l:params)
        call dn#util#wrap(l:msg, 2)
        return
    endif
    " process placeholders in turn    {{{2
    for l:param in l:params
        " each placeholder defined in a Dict    {{{3
        let l:var = join([a:type, 'write_str', 'placeholder', string(l:param)])
        if !s:_valid_dict(l:param, l:var) | return | endif
        " each placeholder Dict has one key    {{{3
        let l:keys = keys(l:param)
        let l:count = len(l:keys)
        if l:count != 1
            let l:msg = '- ' . l:var . ': expected 1 key, got ' . l:count
            call dn#util#wrap(l:msg, 2)
            return
        endif
        let l:term = l:keys[0]
        " cannot have duplicate placeholder terms    {{{3
        let l:var = join([a:type, 'write_str', 'placeholder'])
        if has_key(l:placeholders, l:term)
            let l:msg = '- ' . l:var . ': duplicate placeholder term '
                        \ . l:term
            call dn#util#wrap(l:msg, 2)
            return
        endif
        " store placeholder term    {{{3
        let l:placeholders[l:term] = 1
        " placeholder term must appear in template    {{{3
        let l:var = join([a:type, 'write_str', 'placeholder', l:term])
        let l:pattern = '{' . l:term . '}'
        if empty(matchstr(l:template, l:pattern))
            let l:msg = '- ' . l:var . ': does not appear in template'
            call dn#util#wrap(l:msg, 2)
            return
        endif
        " placeholder value is Dict    {{{3
        let l:details = l:param[l:term]
        if !s:_valid_dict(l:details, l:var) | return | endif
        " placeholder must have 'type' key    {{{3
        if !has_key(l:details, 'type')
            let l:msg = '- ' . l:var . ": no 'type' key"
            call dn#util#wrap(l:msg, 2)
            return
        endif
        let l:type = l:details.type
        " placeholder type value must be string    {{{3
        let l:var = join([a:type, 'write_str', 'placeholder', l:term, 'type'])
        if !s:_valid_non_empty_string(l:type, l:var) | return | endif
        " process remaining placeholder key values    {{{3
        " - placeholder type: 'id'    {{{4
        if     l:type ==# 'id'
            " allowed only one other, optional, key named 'default'
            let l:count = len(keys(l:details))
            if l:count > 2  " id-type placeholder has too many keys
                let l:msg = '- ' . a:type . ' placeholder ' . l:term
                            \ . ': too many keys (>2)'
                call dn#util#wrap(l:msg, 2)
                return
            endif
            if l:count > 1  " id-type placeholder has second key
                " second key has to be 'default'
                let l:var = join([a:type, 'write_str', 'placeholder', l:term])
                let l:other_key = s:_non_type_key(l:details, l:var)
                if l:other_key !=# 'default'
                    let l:msg = '- ' . a:type . ' placeholder ' . l:term
                                \ . ": invalid key '" . l:other_key . "'"
                    call dn#util#wrap(l:msg, 2)
                    return
                endif
                " default has to be Dict
                let l:default = l:details.default
                let l:var = join([a:type, 'write_str', 'placeholder', l:term, 
                            \ 'default'])
                if !s:_valid_dict(l:default, l:var) | return | endif
                " default has to be Dict with single key 'param'
                let l:keys = keys(l:default)
                let l:count = len(l:keys)
                if l:count != 1
                    let l:msg = '- ' . a:type . ' placeholder ' . l:term
                                \ . " 'default' key: expected 1 key, got "
                                \ . l:count
                    call dn#util#wrap(l:msg, 2)
                    return
                endif
                let l:key = l:keys[0]
                if l:key !=# 'param'
                    let l:msg = '- ' . a:type . ' placeholder ' . l:term
                                \ . " 'default': expected 'param' key, got '"
                                \ . l:key . "'"
                    call dn#util#wrap(l:msg, 2)
                    return
                endif
                " default param has to be string
                let l:var = join([a:type, 'write_str', 'placeholder', l:term, 
                            \ 'default param'])
                let l:previous_term = l:default.param
                if !s:_valid_non_empty_string(l:previous_term, l:var)
                    return
                endif
                " default param has to be previously defined placeholder term
                if !has_key(l:placeholders, l:previous_term)
                    let l:msg = '- ' . a:type . ' ' . l:term . ': uses ' 
                                \ . l:previous_term
                                \ . ' which is not previously defined'
                    call dn#util#wrap(l:msg, 2)
                    return
                endif
            endif
        " - placeholder type: 'string', 'filepath'    {{{4
        elseif count(['string', 'filepath'], l:type)
            " require one other key
            let l:count = len(keys(l:details))
            if l:count != 2  " wrong number of keys
                let l:msg = '- ' . a:type . ' placeholder ' . l:term
                            \ . ': expected 2 keys, got ' . l:count
                call dn#util#wrap(l:msg, 2)
                return
            endif
            " other key has to be 'noun'
            let l:var = join([a:type, 'write_str', 'placeholder', l:term])
            let l:other_key = s:_non_type_key(l:details, l:var)
            if l:other_key !=# 'noun'
                let l:msg = '- ' . a:type . ' placeholder ' . l:term
                            \ . ": invalid key '" . l:other_key . "'"
                call dn#util#wrap(l:msg, 2)
                return
            endif
            " noun param has to be string
            let l:var = join([a:type, 'write_str', 'placeholder', l:term, 
                        \ 'noun param'])
            let l:noun = l:details.noun
            if !s:_valid_non_empty_string(l:noun, l:var) | return | endif
        " - placeholder type: invalid    {{{4
        else
            " invalid placeholder type
            let l:msg = '- ' . a:type . ' placeholder ' . l:term
                        \ . ": invalid type '" . l:type . "'"
            call dn#util#wrap(l:msg, 2)
            return
        endif    " }}}3
    endfor    " }}}2
    " report success    {{{2
    return g:dn_true    " }}}2
endfunction

" s:_check_pandoc_params()    {{{1
" does:   check that s:dn_markdown_pandoc_params is valid
" params: nil
" prints: error message if invalidity detected
" return: whether variable is valid
function! s:_check_pandoc_params() abort
    " feedback    {{{2
    echo ' ' |  " clear command line
    echo 's:dn_markdown_pandoc_params'
    " variables    {{{2
    " - note unfortunate naming convention
    let l:formats = {}
    let l:valid_names = ['azw3', 'context',     'docbook',  'docx',
                \        'epub', 'html',        'latex',    'mobi',
                \        'odt',  'pdf_context', 'pdf_html', 'pdf_latex']
    let l:valid_format_params = ['format',    'depend',   'pandoc_to',
                \                'after_ext', 'postproc', 'final_ext',
                \                'steps']
    let l:valid_format_depends = ['context', 'ebook-convert', 'latex',
                \                 'pandoc',  'wkhtmltopdf']
    let l:valid_format_steps = ['citeproc',   'contextlinks',  'cover_epub',
                \               'equations',  'figures',       'fontsize',
                \               'footnotes',  'latexlinks',    'papersize',
                \               'pdfengine',  'selfcontained', 'smart',
                \               'standalone', 'style_docx',    'style_epub',
                \               'style_html', 'style_odt',     'tables',
                \               'template']
    let l:string_format_params    = ['pandoc_to', 'format']
    let l:extension_format_params = ['after_ext', 'final_ext']
    let l:boolean_format_params   = ['postproc']
    " must be Dict    {{{2
    if !s:_valid_dict(s:pandoc_params, 'var') | return | endif
    " must have correct keys    {{{2
    let l:names = keys(s:pandoc_params)
    if !s:_valid_keys(l:valid_names, l:names, 'var') | return | endif
    " process value for each format name    {{{2
    for l:name in l:names
        " needs to be a Dict    {{{3
        let l:data = s:pandoc_params[l:name]
        let l:var  = 'format ' . l:name
        if !s:_valid_dict(l:data, l:var) | return | endif
        " check that keys are valid    {{{3
        let l:format_params = keys(l:data)
        if !s:_valid_keys(l:valid_format_params, l:format_params, l:var)
            return
        endif
        " check all string params are non-empty strings    {{{3
        for l:param in l:string_format_params
            let l:var   = join([l:name, l:param])
            let l:value = l:data[l:param]
            if !s:_valid_non_empty_string(l:value, l:var) | return | endif
        endfor
        " check all extension params are valid    {{{3
        for l:param in l:extension_format_params
            let l:var   = join([l:name, l:param])
            let l:value = l:data[l:param]
            if !s:_valid_non_empty_string(l:value, l:var) | return | endif
            if l:value !~# '\.[a-z0-9]\+$'
                let l:msg = '- ' . l:var . ': expected extension, got '
                            \ . dn#util#stringify(l:value, g:dn_true)
                call dn#util#wrap(l:msg, 2)
                return
            endif
        endfor
        " check all boolean params are valid    {{{3
        for l:param in l:boolean_format_params
            let l:var   = join([l:name, l:param])
            let l:value = l:data[l:param]
            " can be integer 1 or 0
            if type(l:value) == type(0) && (l:value == 1 || l:value == 0)
                continue
            endif
            " can be a true boolean
            if exists('v:t_number') && type(l:value) == type(v:true)
                continue
            endif
            " otherwise is invalid
            let l:msg = '- ' . l:var . ': expected boolean, got '
                        \ . dn#util#stringify(l:value, g:dn_true)
            call dn#util#wrap(l:msg, 2)
            return
        endfor
        " check depend values    {{{3
        let l:var   = join([l:name, 'depend'])
        let l:value = l:data['depend']
        if !s:_valid_list(l:value, l:var) | return | endif
        for l:depend in l:value
            if !count(l:valid_format_depends, l:depend)
                let l:msg = '- ' . l:var . ": invalid value '"
                            \ . l:depend . "'"
                call dn#util#wrap(l:msg, 2)
                return
            endif
        endfor
        " check steps values    {{{3
        let l:var   = join([l:name, 'steps'])
        let l:value = l:data['steps']
        " - can be Dict {'source': <valid-name>}
        if     type(l:value) == type({})
            let l:keys = keys(l:value)
            if !(len(l:keys) == 1 && l:keys[0] ==# 'source')
                let l:msg = '- ' . l:var
                            \ . ": expected single key 'source', got key(s) "
                            \ . join(l:keys, ', ')
                call dn#util#wrap(l:msg, 2)
                return
            endif
            let l:source = l:keys[0]
            let l:var    = join([l:name, 'steps', 'source'])
            if !s:_valid_non_empty_string(l:source, l:var) | return | endif
            if !count(l:valid_names, l:source) || l:source ==# l:name
                let l:msg = '- ' . l:var . ': invalid value: '
                            \ . dn#util#stringify(l:value)
                call dn#util#wrap(l:msg, 2)
                return
            endif
        " - can be List
        elseif type(l:value) == type([])
            for l:step in l:value
                if !count(l:valid_format_steps, l:step)
                    let l:msg = '- ' . l:var . ": invalid value '" 
                                \ . l:step . "'"
                    call dn#util#wrap(l:msg, 2)
                    return
                endif
            endfor
        else  " invalid variable type
            let l:msg = '- ' . l:var . ': expected List or Dict, got '
                        \ . dn#util#varType(l:value)
            call dn#util#wrap(l:msg, 2)
            return
        endif
        " check format value    {{{3
        " - already checked that it is a string
        let l:value = l:data['format']
        if has_key(l:formats, l:value)
            let l:var = join([l:name, 'format'])
            let l:msg = '- ' . l:var . ": duplicate value '" . l:value . "'"
            call dn#util#wrap(l:msg, 2)
            return
        else
            let l:formats[l:value] = 1
        endif
    endfor    " }}}2
    " report success    {{{2
    return g:dn_true    " }}}2
endfunction

" s:_non_type_key(value, var)    {{{1
" does:   assumes two key Dict with one key = 'type',
"         and returns the other key
" params: value - value to analyse [required, Dict]
"         var   - name of variable provided [required, string]
" prints: error message if invalidity detected
" return: keys name, string
function! s:_non_type_key(value, var) abort
    " check variable name    {{{2
    if type(a:var) != type('') || empty(a:var)
        let l:msg = '- ' . a:var . ': expected non-empty string var, got '
                    \ . dn#util#varType(a:var) . " with value '"
                    \ . dn#util#stringify(a:var) . "'"
        call dn#util#wrap(l:msg, 2)
        return
    endif
    " value must be a Dict    {{{2
    if type(a:value) != type({})
        let l:msg = '- ' . a:var . ': expected Dict, got '
                    \ . dn#util#varType(a:value)
        call dn#util#wrap(l:msg, 2)
        return
    endif
    let l:dict = deepcopy(a:value)
    " Dict must have two keys    {{{2
    let l:count = len(l:dict)
    if l:count != 2
        let l:msg = '- ' . a:var . ': expected Dict with 2 keys, got '
                    \ . l:count . ' keys'
        call dn#util#wrap(l:msg, 2)
        return
    endif
    " one key must be 'type'    {{{2
    if !has_key(l:dict, 'type')
        let l:msg = '- ' . a:var . ": key 'type' not found"
        call dn#util#wrap(l:msg, 2)
        return
    endif
    " return other key    {{{2
    call remove(l:dict, 'type')
    return keys(l:dict)[0]    " }}}2
endfunction

" s:_set_vars_manually()    {{{1
" does:   if setting variable value manually, do it here
" params: nil
" prints: error message if invalidity detected
" return: n/a
function! s:_set_vars_manually() abort
    " s:referenced_types    {{{2
    let s:referenced_types = {}    " }}}2
    " s:pandoc_params    {{{2
    let s:pandoc_params = {
                \ 'azw3' : {
                \   'format'    : 'Kindle Format 8 (azw3) via ePub',
                \   'depend'    : ['pandoc', 'ebook-convert'],
                \   'pandoc_to' : 'epub3',
                \   'after_ext' : '.epub',
                \   'postproc'  : g:dn_true,
                \   'final_ext' : '.azw3',
                \   'steps'     : {'source': 'epub'},
                \   },
                \ 'context' : {
                \   'format'    : 'ConTeXt (tex)',
                \   'depend'    : ['pandoc', 'context'],
                \   'pandoc_to' : 'context',
                \   'after_ext' : '.tex',
                \   'postproc'  : g:dn_false,
                \   'final_ext' : '.tex',
                \   'steps'     : ['figures',   'equations',    'tables',
                \                  'footnotes', 'standalone',   'smart',
                \                  'citeproc',  'contextlinks', 'papersize',
                \                  'template',  'fontsize'],
                \   },
                \ 'docbook' : {
                \   'format'    : 'DocBook (xml)',
                \   'depend'    : ['pandoc'],
                \   'pandoc_to' : 'docbook5',
                \   'after_ext' : '.xml',
                \   'postproc'  : g:dn_false,
                \   'final_ext' : '.xml',
                \   'steps'     : ['figures',   'equations',  'tables',
                \                  'footnotes', 'standalone', 'template',
                \                  'citeproc'],
                \   },
                \ 'docx' : {
                \   'format'    : 'Microsoft Word (docx)',
                \   'depend'    : ['pandoc'],
                \   'pandoc_to' : 'docx',
                \   'after_ext' : '.docx',
                \   'postproc'  : g:dn_false,
                \   'final_ext' : '.docx',
                \   'steps'     : ['figures',   'equations',  'tables',
                \                  'footnotes', 'standalone', 'smart',
                \                  'citeproc',  'style_docx', 'template'],
                \   },
                \ 'epub' : {
                \   'format'    : 'Electronic publication (ePub)',
                \   'depend'    : ['pandoc'],
                \   'pandoc_to' : 'epub3',
                \   'after_ext' : '.epub',
                \   'postproc'  : g:dn_false,
                \   'final_ext' : '.epub',
                \   'steps'     : ['figures',    'equations',  'tables',
                \                  'footnotes',  'standalone', 'smart',
                \                  'style_epub', 'cover_epub', 'citeproc',
                \                  'template'],
                \   },
                \ 'html' : {
                \   'format'    : 'HyperText Markup Language (html)',
                \   'depend'    : ['pandoc'],
                \   'pandoc_to' : 'html5',
                \   'after_ext' : '.html',
                \   'postproc'  : g:dn_false,
                \   'final_ext' : '.html',
                \   'steps'     : ['figures',       'equations',  'tables',
                \                  'footnotes',     'standalone', 'smart',
                \                  'selfcontained', 'citeproc',   'style_html',
                \                  'template'],
                \   },
                \ 'latex' : {
                \   'format'    : 'LaTeX (tex)',
                \   'depend'    : ['pandoc', 'latex'],
                \   'pandoc_to' : 'latex',
                \   'after_ext' : '.tex',
                \   'postproc'  : g:dn_false,
                \   'final_ext' : '.tex',
                \   'steps'     : ['figures',    'equations',  'tables',
                \                  'footnotes',  'standalone', 'citeproc',
                \                  'smart',      'pdfengine',  'fontsize',
                \                  'latexlinks', 'papersize',  'template'],
                \   },
                \ 'mobi' : {
                \   'format'    : 'Mobipocket e-book (mobi) via ePub',
                \   'depend'    : ['pandoc'],
                \   'pandoc_to' : 'epub3',
                \   'after_ext' : '.epub',
                \   'postproc'  : g:dn_true,
                \   'final_ext' : '.mobi',
                \   'steps'     : {'source': 'epub'},
                \   },
                \ 'odt' : {
                \   'format'    : 'OpenDocument Text (odt)',
                \   'depend'    : ['pandoc'],
                \   'pandoc_to' : 'odt',
                \   'after_ext' : '.odt',
                \   'postproc'  : g:dn_false,
                \   'final_ext' : '.odt',
                \   'steps'     : ['figures',   'equations',  'tables',
                \                  'footnotes', 'standalone', 'smart',
                \                  'citeproc',  'style_odt',  'template'],
                \   },
                \ 'pdf_context' : {
                \   'format'    : 'Portable Document Format (pdf) via ConTeXt',
                \   'depend'    : ['pandoc', 'context'],
                \   'pandoc_to' : 'context',
                \   'after_ext' : '.pdf',
                \   'postproc'  : g:dn_false,
                \   'final_ext' : '.pdf',
                \   'steps'     : {'source': 'context'},
                \   },
                \ 'pdf_html' : {
                \   'format'    : 'Portable Document Format (pdf) via HTML',
                \   'depend'    : ['pandoc', 'wkhtmltopdf'],
                \   'pandoc_to' : 'html5',
                \   'after_ext' : '.pdf',
                \   'postproc'  : g:dn_false,
                \   'final_ext' : '.pdf',
                \   'steps'     : {'source': 'html'},
                \   },
                \ 'pdf_latex' : {
                \   'format'    : 'Portable Document Format (pdf) via LaTeX',
                \   'depend'    : ['pandoc', 'latex'],
                \   'pandoc_to' : 'latex',
                \   'after_ext' : '.pdf',
                \   'postproc'  : g:dn_false,
                \   'final_ext' : '.pdf',
                \   'steps'     : {'source': 'latex'},
                \   },
                \ }
    return
endfunction

" s:_utils_missing()    {{{1
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

" s:_valid_dict(value, var)    {{{1
" does:   check that value is a dict
" params: value - value to test [required, any]
"         var   - name of variable used in error messages [required, string]
" prints: error message if not a valid Dict
" return: whether value is a Dict
function! s:_valid_dict(value, var) abort
    " params
    if type(a:var) != type('') || empty(a:var)
        let l:msg = 'expected string var name, got '
                    \ . dn#util#varType(a:var) . " with value '"
                    \ . dn#util#stringify(a:var) . "'"
        call dn#util#error(l:msg)
        return
    endif
    " check whether Dict
    if type(a:value) != type({})
        let l:type = dn#util#varType(a:value)
        let l:msg = '- ' . a:var . ': expected Dict, got ' . l:type
        call dn#util#wrap(l:msg, 2)
        return
    endif
    return g:dn_true
endfunction

" s:_valid_list(value, var)    {{{1
" does:   check that value is a list
" params: value - value to test [required, any]
"         var   - name of variable used in error messages [required, string]
" prints: error message if not a valid List
" return: whether value is a List
function! s:_valid_list(value, var) abort
    " params
    if type(a:var) != type('') || empty(a:var)
        let l:msg = 'expected string var name, got '
                    \ . dn#util#varType(a:var) . " with value '"
                    \ . dn#util#stringify(a:var) . "'"
        call dn#util#error(l:msg)
        return
    endif
    " check whether List
    if type(a:value) != type([])
        let l:type = dn#util#varType(a:value)
        let l:msg = '- ' . a:var . ': expected List, got ' . l:type
        call dn#util#wrap(l:msg, 2)
        return
    endif
    return g:dn_true
endfunction

" s:_valid_keys(valid_keys, keys, var)    {{{1
" does:   check list of keys to ensure it matches valid keys
" params: valid_keys - valid keys [required, List]
"         keys       - candidate keys [required, List]
"         var        - name of variable [required, string]
" prints: error message if invalidity detected
" return: whether all keys are valid
" note:   all keys must be present, no duplicates allowed
function! s:_valid_keys(valid_keys, keys, var) abort
    " check params    {{{3
    if type(a:var) != type('')
        let l:msg = "invalid 'var' param: expected string, got "
                    \ . dn#util#varType(a:var)
        call dn#util#error(l:msg)
        return
    endif
    if empty(a:var)
        call dn#util#error("empty 'var' string param")
        return
    endif
    if type(a:keys) != type([])
        let l:msg = "invalid 'keys' param: expected List, got "
                    \ . dn#util#varType(a:keys)
        call dn#util#error(l:msg)
        return
    endif
    if empty(a:keys)
        call dn#util#error("empty 'keys' List param")
        return
    endif
    if type(a:valid_keys) != type([])
        let l:msg = "invalid 'valid_keys' param: expected List, got "
                    \ . dn#util#varType(a:keys)
        call dn#util#error(l:msg)
        return
    endif
    if empty(a:valid_keys)
        call dn#util#error("empty 'valid_keys' List param")
        return
    endif
    " all keys must be non-empty strings    {{{3
    if len(filter(copy(a:valid_keys), 'type(v:val) != type("")'))
        let l:msg = '- ' . a:var . ": non-string 'valid' key(s)"
        call dn#util#wrap(l:msg, 2)
        return
    endif
    if len(filter(copy(a:keys), 'type(v:val) != type("")'))
        let l:msg = '- ' . a:var . ': non-string key(s)'
        call dn#util#wrap(l:msg, 2)
        return
    endif
    if len(filter(copy(a:valid_keys), 'empty(v:val)'))
        let l:msg = '- ' . a:var . ": empty 'valid' key(s)"
        call dn#util#wrap(l:msg, 2)
        return
    endif
    if len(filter(copy(a:keys), 'empty(v:val)'))
        let l:msg = '- ' . a:var . ': empty key(s)'
        call dn#util#wrap(l:msg, 2)
        return
    endif
    " check that all keys are valid    {{{3
    for l:key in a:keys
        if !count(a:valid_keys, l:key)
            let l:msg = '- ' . a:var . ": invalid key '" . l:key . "'"
            call dn#util#wrap(l:msg, 2)
            return
        endif
    endfor
    " check that all valid keys are present    {{{3
    for l:key in a:valid_keys
        let l:count = count(a:keys, l:key)
        if l:count != 1
            let l:msg = '- ' . a:var . ": missing key '" . l:key . "'"
            call dn#util#wrap(l:msg, 2)
            return
        endif
    endfor    " }}}3
    return g:dn_true
endfunction

" s:_valid_non_empty_string(value, var)    {{{1
" does:   check that value is a non-empty string
" params: value - value to test [required, any]
"         var   - name of variable [required, string]
" prints: error message if not a non-empty string
" return: whether value is a non-empty string
function! s:_valid_non_empty_string(value, var) abort
    " params
    if type(a:var) != type('') || empty(a:var)
        let l:msg = 'expected var to be non-empty string, got '
                    \ . dn#util#varType(a:var) . " with value '"
                    \ . string(a:var) . "'"
        call dn#util#error(l:msg)
        return
    endif
    " check for string type
    if type(a:value) != type('')
        let l:type = dn#util#varType(a:value)
        let l:msg  = '- ' . a:var . ': expected string, got ' . l:type
        call dn#util#wrap(l:msg, 2)
        return
    endif
    " check that not empty
    if empty(a:value)
        let l:msg = '- ' . a:var . ': is empty'
        call dn#util#wrap(l:msg, 2)
        return
    endif
    return g:dn_true
endfunction    " }}}1

call s:main()

" vim: set foldmethod=marker :
