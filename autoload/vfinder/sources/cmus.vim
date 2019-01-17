" Creation         : 2019-01-17
" Last modification: 2019-01-17


" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 	            main object
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vfinder#sources#cmus#get(...) abort " {{{1
    call s:cmus_define_maps()
    return {
                \   'name'         : 'cmus',
                \   'to_execute'   : function('s:cmus_source'),
                \   'candidate_fun': function('s:cmus_candidate_fun'),
                \   'format_fun'   : function('s:cmus_format_fun'),
                \   'syntax_fun'   : function('s:cmus_syntax_fun'),
                \   'maps'         : s:cmus_maps()
                \ }
endfun
" 1}}}

fun! s:cmus_source() abort " {{{1
    let res = []
    if !vfinder#cache#exists('cmus') || b:vf.bopts.manual_update
        for l in split(join(systemlist('cmus-remote -C "save -l -e -"')), 'file ')
            call add(res, json_encode({
                        \   'file'  : fnamemodify(matchstr(l, '.*\ze duration \d\+'), ':p'),
                        \   'artist': matchstr(l, 'tag artist \zs.\{-}\ze tag '),
                        \   'album' : matchstr(l, 'tag album \zs.\{-}\ze tag '),
                        \   'title' : matchstr(l, 'tag title \zs.\{-}\ze tag '),
                        \   'date'  : matchstr(l, 'tag date \zs.\{-}\ze tag '),
                        \   'track' : matchstr(l, 'tag tracknumber \zs.\{-}\ze tag ')
                        \ }))
        endfor
        call vfinder#cache#write('cmus', res, 0)
    else
        let res = vfinder#cache#read('cmus')
    endif

    let b:vf.flags.modes = s:cmus_modes_str()
    return res
endfun
" 1}}}

fun! s:cmus_format_fun(songs_list) abort " {{{1
    let res = []
    for s in a:songs_list
        let s_dict = json_decode(s)
        call add(res, printf('%-30S %-60S %02d %-45S "%s"',
                \   s_dict.artist,
                \   s_dict.title,
                \   s_dict.track,
                \   s_dict.album . '(' . s_dict.date . ')',
                \   fnamemodify(s_dict.file, ':~')
                \ ))
    endfor
    return res
endfun
" 1}}}

fun! s:cmus_candidate_fun() abort " {{{1
    return fnamemodify(matchstr(getline('.'), '"\zs.*\ze"$'), ':p')
endfun
" 1}}}

fun! s:cmus_syntax_fun() abort " {{{1
    " to overwrite the vfinderIndex highlighting
    syntax match vfinderCmus =\%>1l^.*$=
    highlight! link vfinderCmus Normal
endfun
" 1}}}

fun! s:cmus_maps() abort " {{{1
    let maps = {}
    let keys = vfinder#maps#get('cmus')
    let actions = {
                \   'play': {'action': function('s:play'), 'options': {'function': 1}},
                \   'queue': {'action': function('s:queue'), 'options': {'function': 1, 'quit': 0}},
                \   'pre_queue': {'action': function('s:pre_queue'), 'options': {'function': 1, 'quit': 0}},
                \   'show_current': {'action': function('s:show_current'), 'options': {'function': 1, 'quit': 0}},
                \ }
    let maps.i = {
                \   keys.i.play        : actions.play,
                \   keys.i.queue       : actions.queue,
                \   keys.i.pre_queue   : actions.pre_queue,
                \   keys.i.show_current: actions.show_current
                \ }
    let maps.n = {
                \   keys.n.play        : actions.play,
                \   keys.n.queue       : actions.queue,
                \   keys.n.pre_queue   : actions.pre_queue,
                \   keys.n.show_current: actions.show_current
                \ }
    return maps
endfun
" 1}}}

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 	        	actions
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:play(file) abort " {{{1
    call s:cmus_remote('player-play', a:file)
    call s:show_current()
endfun
" 1}}}

fun! s:queue(file) abort " {{{1
    call s:cmus_remote('add -q', a:file)
    call s:cmus_echo('add to queue list', a:file)
endfun
" 1}}}

fun! s:pre_queue(file) abort " {{{1
    call s:cmus_remote('add -Q', a:file)
    call s:cmus_echo('prepend to queue list', a:file)
endfun
" 1}}}

fun! s:show_current(...) abort " {{{1
    let cmd = 'cmus-remote -C  "format_print \"%s\""'
    let [artist, track, title, album, date] =
                \ split(system(printf(cmd, '%a::%n::%t::%l::%y'))[:-2], '::')

    let album_infos_str = printf("[%s%s%s]",
                \   track ? track . '. ' : '',
                \   !empty(album) ? album : '',
                \   !empty(date) ? ' (' . date . ')' : '',
                \ )

    call s:cmus_echo('playing', {
                \   'artist'     : artist,
                \   'title'      : title,
                \   'album_infos': album_infos_str
                \ })
endfun
" 1}}}

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 	        	helpers
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:cmus_is_valid() abort " {{{1
    if executable('cmus')
        unsilent call vfinder#helpers#echo('"cmus" was not found', 'Error', 'cmus')
        return v:false
    endif
    return v:true
endfun
" 1}}}

fun! s:cmus_remote(cmd, file) abort " {{{1
    call system('cmus-remote -C ' . shellescape(a:cmd . ' ' . a:file))
    redrawstatus
endfun
" 1}}}

fun! s:cmus_modes_str() abort " {{{1
    " modes: [C]ontinue, [F]ollow, [R]epeat, [S]huffle

    let modes = ''
    for m in ['continue', 'follow', 'repeat', 'shuffle']
        let modes .= matchstr(systemlist('cmus-remote -C "set ' . m . '?"')[0], '=\zs\w\+') is# 'true'
                    \ ? toupper(m[0])
                    \ : ' '
    endfor
    return modes
endfun
" 1}}}

fun! s:cmus_echo(state, song) abort " {{{1
    echohl vfinderIndex
    unsilent echon a:state . '> '

    if type(a:song) is# v:t_dict
        echohl vfinderName
        unsilent echon a:song.artist
        echohl None
        unsilent echon ' ' . a:song.title
        echohl vfinderSymbols
        unsilent echon ' ' . a:song.album_infos
    else
        echohl vfinderName
        unsilent echon fnamemodify(a:song, ':t:r')
    endif

    echohl None
endfun
" 1}}}

" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" 	        	maps
" """"""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:cmus_define_maps() abort " {{{1
    call vfinder#maps#define_gvar_maps('cmus', {
                \   'i': {
                \       'play'        : '<CR>',
                \       'queue'       : '<C-s>',
                \       'pre_queue'   : '<C-v>',
                \       'show_current': '<C-o>'
                \   },
                \   'n': {
                \       'play'        : '<CR>',
                \       'queue'       : 's',
                \       'pre_queue'   : 'v',
                \       'show_current': 'o'
                \   }
                \ })
endfun
" 1}}}


" vim:ft=vim:fdm=marker:fmr={{{,}}}:
