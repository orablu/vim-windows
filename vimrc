set nocompatible
let g:vimrc = expand(has('win32') ? '$HOME/vimfiles/vimrc' : '~/.vim/vimrc')

" Load vimrc pre-file {{{
if filereadable(g:vimrc.'.leader')
    let g:vimrc_leader = g:vimrc.'.leader'
elseif filereadable(g:vimrc.'.before')
    let g:vimrc_leader = g:vimrc.'.before'
endif
if exists('g:vimrc_leader') | exe 'source '.g:vimrc_leader | endif
" }}}

" Functions {{{

" Tabs {{{
function! TermTabLabel() " {{{
    let label = ''
    for i in range(tabpagenr('$'))
        " Select the highlighting
        if i + 1 == tabpagenr()
            let label .= '%#TabLineSel#'
        else
            let label .= '%#TabLine#'
        endif

        " Set the tab page number (for mouse clicks)
        let label .= '%'.(i+1).'T'

        " The label is made by MyTabLabel()
        let label .= ' %{MyTabLabel('.(i+1).')} '

        " Add divider
        let label .= '%#TabLine#|'
    endfor

    " After the last tab fill with TabLineFill and reset tab page nr
    let label .= '%#TabLineFill#%T'

    " Right-align the label to close the current tab page
    if tabpagenr('$') > 1
        let label .= '%=%#TabLine#%999XX'
    endif

    return l:label
endfunction " }}}

function! GuiTabLabel() " {{{
    return MyTabLabel(v:lnum)
endfunction " }}}

function! MyTabLabel(lnum) " {{{
    " Buffer name
    let bufnrlist = tabpagebuflist(a:lnum)
    let bufnr = tabpagewinnr(a:lnum) - 1
    let name = bufname(bufnrlist[bufnr])
    let modified = getbufvar(bufnrlist[bufnr], '&modified')
    let readonly = getbufvar(bufnrlist[bufnr], '&readonly')
    let readonly = readonly || !getbufvar(bufnrlist[bufnr], '&modifiable')


    if (name != '' && name !~ 'NERD_tree')
        " Get the name of the first real buffer
        let name = fnamemodify(name, ':t')
    else
        let bufnr = len(bufnrlist)
        while ((name == '' || name =~ 'NERD_tree') && bufnr >= 0)
            let bufnr -= 1
            let name = bufname(bufnrlist[bufnr])
            let modified = getbufvar(bufnrlist[bufnr], '&modified')
        endwhile
        if (name == '')
            if (&buftype == 'quickfix')
                " Don't show other marks
                let modified = 0
                let readonly = 0
                let name = '[Quickfix]'
            else
                let name = '[No Name]'
            endif
        else
            " Get the name of the first real buffer
            let name = fnamemodify(name, ':t')
        endif
    endif
    if (getbufvar(bufnrlist[bufnr], '&buftype') == 'help')
        " Don't show other marks
        let modified = 0
        let readonly = 0
        let name = 'H['.fnamemodify(name, ':r').']'
    endif
    let label = a:lnum.' '.name

    " The number of windows in the tab page
    let uncounted = 0
    for bufnr in bufnrlist
        let tmpname = bufname(bufnr)
        if tmpname == '' || tmpname =~ 'NERD_tree' || getbufvar(bufnr, '&buftype') == 'help'
            " We don't care about auxiliary buffer count, so if it's not in
            " focus, don't count it
            if bufnr != bufnrlist[tabpagewinnr(a:lnum) - 1]
                let uncounted += 1
            endif
        endif
    endfor
    let wincount = tabpagewinnr(a:lnum, '$') - uncounted
    if (wincount > 1)
        let label .= ' (..'.wincount

        " Add '[+]' inside the others section if one of the other buffers in
        " the tab page is modified
        for bufnr in bufnrlist
            if (modified == 0 && getbufvar(bufnr, '&modified'))
                let label .= ' [+]'
                break
            endif
        endfor

        let label .= ')'
    endif

    " Add '[+]' at the end if this buffer is modified, and '[-]' if it is readonly
    if (modified == 1 || readonly == 1)
        let label .= ' ['
        if modified == 1
            let label .= '+'
            if readonly == 1
                let label .= '/'
            endif
        endif
        if readonly == 1
            let label .= '-'
        endif
        let label .= ']'
    endif

    return label
endfunction " }}}

function! GuiTabToolTip() " {{{
    let tooltip = ''
    let bufnrlist = tabpagebuflist(v:lnum)
    for bufnr in bufnrlist
        let name=bufname(bufnr)
        if (name =~ 'NERD_tree')
            continue
        endif

        " Separate buffer entries
        if tooltip!=''
            let tooltip .= "\n"
        endif

        " Add name of buffer
        if name == ''
            " Give a name to no name documents
            if getbufvar(bufnr,'&buftype')=='quickfix'
                let name = '[Quickfix List]'
            else
                let name = '[No Name]'
            endif
        elseif getbufvar(bufnr,'&buftype')=='help'
            let name = 'help: '.fnamemodify(name, ':p:t:r')
        else
            let name = fnamemodify(name, ':p:t')
        endif
        let tooltip .= name

        " add modified/modifiable flags
        if getbufvar(bufnr, '&modified')
            let tooltip .= ' [+]'
        endif
        if getbufvar(bufnr, '&modifiable') == 0 || getbufvar(bufnr, '&readonly') == 1
            let tooltip .= ' [-]'
        endif
    endfor
    return tooltip
endfunction " }}}
" }}}

function! IsGui() " {{{
    return has('gui_running') || (has('nvim') && get(g:, 'GuiLoaded', 0) == 1)
endfunction " }}}

function! GrowToContents(maxlines, maxcolumns) " {{{
    let totallines = line('$') + 3
    let linenumbers = 0
    if (&number == 1 || &relativenumber == 1)
        let linenumbers = len(line('$')) + 1
    endif
    let totalcolumns = GetMaxColumn() + linenumbers + 1
    if (totallines > &lines)
        if (totallines < a:maxlines)
            let &lines = totallines
        else
            let &lines = a:maxlines
        endif
    endif
    if (totalcolumns > &columns)
        if (totalcolumns < a:maxcolumns)
            let &columns = totalcolumns
        else
            let &columns = a:maxcolumns
        endif
    endif
endfunction " }}}

function! OpenHelp(topic) " {{{
    try
        if &columns > 80 + g:help_threshold
            let position = 'vert'
            if exists('g:open_help_on_right') && g:open_help_on_right != 0
                let position = l:position.' rightbelow'
            endif
            exe l:position.' help '.a:topic
        else
            exe 'tab help '.a:topic
        endif
    catch
        echohl ErrorMsg | echo 'Help:'.split(v:exception, ':')[-1] | echohl None
    endtry
endfunction " }}}

function! IsEmptyFile() " {{{
    if @% != ''
        " No filename for current buffer
        return 0
    elseif filereadable(@%) != 0
        " File doesn't exist yet
        return 0
    elseif line('$') != 1 || col('$') != 1
        " File is empty
        return 0
    endif
    return 1
endfunction " }}}

function! GetMaxColumn() " {{{
    let maxlength = 0
    let linenr = 1
    let curline = line('.')
    let curcol = col('.')
    while (linenr <= line('$'))
        exe ':'.linenr
        let linelength = col('$')
        if (linelength > maxlength)
            let maxlength = linelength
        endif
        let linenr = linenr + 1
    endwhile
    exe ':norm '.curline.'G'.curcol.'|'
    return maxlength
endfunction " }}}

function! ResizeWindow(class) " {{{
    if a:class == 's' " Small
        set lines=20 columns=60
    elseif a:class == 'm' " Medium
        set lines=40 columns=120
    elseif a:class == 'l' " Large
        set lines=60 columns=180
    elseif a:class == 'n' " Narrow
        set lines=40 columns=60
    elseif a:class == 'd' " Diff
        set lines=50 columns=200
    elseif a:class == 'r' " Resized
        set lines=4 columns=12
        call GrowToContents(60, 180)
    else
        echoerr 'Unknown size class: '.a:class
    endif
    silent call wimproved#set_monitor_center()
endfunction " }}}

function! SetRenderOptions(mode) "{{{
    if !has('directx')
        return
    endif

    if (a:mode == 1) || (a:mode != 0 && &renderoptions == '')
        set renderoptions=type:directx
        let system = 'DirectX'
    else
        set renderoptions=
        let system = 'default'
    endif

    if a:mode > 1
        redraw
        echo '[render system set to: '.l:system.']'
    endif
endfunction "}}}

function! ToggleAlpha() "{{{
    if exists('s:alpha')
        execute 'WSetAlpha 256'
        unlet s:alpha
    else
        execute 'WSetAlpha '.g:alpha_level
        let s:alpha = 1
    endif
endfunction "}}}

function! ToggleIdeMode() " {{{
    if (g:idemode == 0)
        set guioptions+=emr
        let g:idemode = 1
    else
        set guioptions-=emr
        let g:idemode = 0
    endif
endfunction " }}}

function! TryCreateDir(path) " {{{
    if !filereadable(a:path) && filewritable(a:path) != 2
        call mkdir(a:path)
    endif
endfunction " }}}

function! GenerateCAbbrev(orig, new) "{{{
    let l = len(a:orig)
    while l > 0
        let s = strpart(a:orig, 0, l)
        execute "cabbrev ".s." <c-r>=(getcmdtype()==':' && getcmdpos()==1 ? '".a:new."' : '".s."')<CR>"
        let l = l - 1
    endwhile
endfunction" }}}
" }}}

" Preferences and Settings {{{

" General settings {{{
syntax on
filetype plugin indent on
set mouse=a
set encoding=utf-8
set spelllang=en_us
set formatoptions=
set titlestring=%t%(\ %M%)%(\ (%{expand(\"%:p:h\")})%)%(\ %a%)\ -\ %{v:servername}
" }}}

" Neovim settings {{{
if has('nvim')
    set inccommand=split
endif
" }}}

" Visual aesthetics {{{
set noerrorbells belloff=all visualbell t_vb=
set termguicolors
set number norelativenumber
set laststatus=2 showcmd ruler noshowmode
set cursorline
set tabline=%!TermTabLabel()
set scrolloff=3 sidescrolloff=8 sidescroll=1
set wildmenu
set lazyredraw
set conceallevel=2
let g:idemode = 0
let g:alpha_level = 200
let g:height_proportion = 75
let g:width_proportion = 66
let g:help_threshold = 80
" }}}

" Search {{{
set updatetime=500
set incsearch hlsearch
set ignorecase smartcase
set completeopt=longest,menuone,preview
" }}}

" Whitespace and comments {{{
set tabstop=4 softtabstop=4 shiftwidth=4
set expandtab smarttab
set autoindent smartindent
set formatoptions+=jr
set list listchars=tab:»\ ,space:·,trail:◌
" }}}

" Word wrap {{{
set backspace=indent,eol,start
set nowrap
set linebreak
set formatoptions+=cn
" }}}

" File organization {{{
set autoread
set shortmess+=A
set hidden
set switchbuf=usetab
set noautochdir
set foldmethod=syntax foldenable foldlevelstart=10
set modeline modelines=1
" }}}

" }}}

" Keybindings and Commands {{{
     map <silent> <f11>      :WToggleFullscreen<cr>
 noremap <silent> <a-p>      :CtrlP<cr>
    imap <silent> <c-space>  <tab>
 noremap <silent> <c-a>      <esc>ggVG
inoremap <silent> <c-a>      <esc>ggVG
 noremap <silent> <c-b>      :CtrlPBuffer<cr>
    "map          <c-e>      {TAKEN: Open file explorer}
 noremap <silent> <c-h>      <c-w>h
 noremap <silent> <c-j>      <c-w>j
 noremap <silent> <c-k>      <c-w>k
 noremap <silent> <c-l>      <c-w>l
    "map          <c-p>      {TAKEN: Fuzzy file search}
 noremap          <c-q>      Q
 noremap <silent> <c-t>      :tabnew<cr>
    "map  <leader><leader>   {TAKEN: Easymotion}
 noremap <silent> <leader>b  :call ToggleIdeMode()<cr>
    "map          <leader>c  {TAKEN: NERDCommenter}
 noremap <silent> <leader>cd :execute 'cd '.expand('%:p:h')<cr>
 noremap          <leader>co :colorscheme <c-d>
 noremap <silent> <leader>d  <c-x>
 noremap <silent> <leader>f  <c-a>
    "map          <leader>h  {TAKEN: GitGutter previews}
 noremap <silent> <leader>i  :set foldmethod=indent<cr>
 noremap <silent> <leader>l  :setlocal list!<cr>:setlocal list?<cr>
    "map          <leader>m  {TAKEN: Toggle GUI menu}
    "map          <leader>n  {TAKEN: HoverHl search forward}
    "map          <leader>N  {TAKEN: HoverHl search backward}
 noremap <silent> <leader>o  :call SetRenderOptions(2)<cr>
 noremap <silent> <leader>rc :WCenter<cr>
 noremap <silent> <leader>rd :call ResizeWindow('d')<cr>
 noremap <silent> <leader>rl :call ResizeWindow('l')<cr>
 noremap <silent> <leader>rm :call ResizeWindow('m')<cr>
 noremap <silent> <leader>rn :call ResizeWindow('n')<cr>
 noremap <silent> <leader>rr :call ResizeWindow('r')<cr>
 noremap <silent> <leader>rs :call ResizeWindow('s')<cr>
    "map          <leader>t  {TAKEN: TaskList}
 noremap <silent> <leader>va :execute 'tabnew<bar>args '.g:vimrc_custom<cr>
 noremap <silent> <leader>vb :execute 'tabnew<bar>args '.g:vimrc_leader<cr>
 noremap <silent> <leader>vr :execute 'tabnew<bar>args '.g:vimrc<cr>
 noremap <silent> <leader>vv :execute 'tabnew<bar>args '.g:vimrc.'*<bar>all<bar>wincmd J<bar>wincmd t'<cr>
 noremap <silent> <leader>vz :execute 'source '.g:vimrc<cr>
 noremap <silent> <leader>w  :execute 'resize '.line('$')<cr>
 noremap <silent> <leader>-  :e .<cr>
 noremap <silent> <leader>'  :if &go=~#'r'<bar>set go-=r<bar>else<bar>set go+=r<bar>endif<cr>
 noremap <silent> <leader>[  :setlocal wrap!<cr>:setlocal wrap?<cr>
 noremap <silent> <leader>/  :nohlsearch<cr>
 noremap <silent> <leader>=  :call ToggleAlpha()<cr>
 noremap <silent> go         <c-]>
 noremap <silent> gV         `[v`]
     map          g/         <Plug>(incsearch-stay)
 noremap <silent> j          gj
 noremap <silent> gj         j
inoremap          jk         <esc>
 noremap <silent> k          gk
 noremap <silent> gk         k
 noremap <silent> K          :Help <c-r><c-w><cr>
inoremap          kj         <esc>
 noremap          Q          :q
 noremap          TQ         :tabclose<cr>
 noremap          Y          y$
 noremap          zj         jzz
 noremap          zJ         Hzz
 noremap          zk         kzz
 noremap          zK         Lzz
   "imap          <tab>      {TAKEN: Supertab}
 noremap          <tab>      %
 noremap          <space>    za
 noremap          ;          :
 noremap          :          ;
 noremap          '          "
 noremap          "          '
 noremap          -          _
 noremap          _          -
 noremap <silent> [[         ^
 noremap <silent> ]]         $
     map          /          <Plug>(incsearch-forward)
     map          ?          <Plug>(incsearch-backward)
    "map          (          {TAKEN: Prev code line}
    "map          )          {TAKEN: Next code line}
    "map          {          {TAKEN: Prev code block}
    "map          }          {TAKEN: Next code block}

if (exists('g:mapleader'))
    exe 'noremap \ '.g:mapleader
endif

command! -nargs=0 Light set background=light
command! -nargs=0 Dark set background=dark
command! -nargs=1 -complete=help Help call OpenHelp(<f-args>)
call GenerateCAbbrev('help', 'Help')

" }}}

" Platform-Specific Settings {{{
if has('win32')
    let g:slash = '\'
    if filewritable($TMP) == 2
        let g:temp = expand($TMP).'\Vim'
    elseif filewritable($TEMP) == 2
        let g:temp = expand($TEMP).'\Vim'
    elseif filewritable('C:\TMP') == 2
        let g:temp = 'C:\TMP\Vim'
    else
        let g:temp = 'C:\TEMP\Vim'
    endif
    call TryCreateDir(g:temp)

    source $VIMRUNTIME/mswin.vim
    set selectmode=
    noremap <c-a> <c-c>ggVG
    noremap <c-v> "+gP
    call SetRenderOptions(1)

    noremap <silent> <c-e> :execute "silent !explorer ".shellescape(expand('%:p:h'))<cr>
else
    let g:slash = '/'
    if filewritable($TMPDIR) == 2
        let g:temp = expand($TMPDIR).'/vim'
    elseif filewritable('/tmp') == 2
        let g:temp = '/tmp/vim'
    else
        let g:temp = expand('$HOME').'/.vim/temp'
    endif
    call TryCreateDir(g:temp)

    map  <silent> <c-e> :silent !open .<cr>
endif
" }}}

" Backup and Undo {{{
set backup writebackup
let s:backupdir = expand(g:temp.g:slash.'backups')
let &directory = s:backupdir.g:slash.g:slash
if has('autocmd')
    augroup Backups
        autocmd BufRead * let &l:backupdir = s:backupdir.g:slash.expand("%:p:h:t") |
                    \ call TryCreateDir(&l:backupdir)
    augroup END
endif
call TryCreateDir(s:backupdir)
if has('persistent_undo')
    call TryCreateDir(g:temp.g:slash.'undo')
    set undofile
    let &undodir = expand(g:temp.g:slash.'undo')
endif
" }}}

" Plugin Settings {{{

" Update packpath {{{
let s:packpath = fnamemodify(g:vimrc, ':p:h')
if match(&packpath, substitute(s:packpath, '[\\/]', '[\\\\/]', 'g')) == -1
    let &packpath .= ','.s:packpath
endif
" }}}

" Legacy plugins {{{
if !has('nvim')
    packadd! matchit
endif
" }}}

" Airline configuration {{{
let g:airline_left_sep=''
let g:airline_right_sep=''
let g:airline_inactive_collapse=1 " Show only file name for inactive buffers
let g:airline#extensions#branch#format = 2 " Truncate branch name from long/section/name/branch to l/s/n/branch

" When showing whitespace, use more compact messages
let g:airline#extensions#whitespace#trailing_format = 't[%s]'
let g:airline#extensions#whitespace#mixed_indent_format = 'm[%s]'
let g:airline#extensions#whitespace#long_format = 'l[%s]'
let g:airline#extensions#whitespace#mixed_indent_file_format = 'mf[%s]'
" }}}

" Ctrlp configuration {{{
let g:ctrlp_cmd = 'CtrlPMRU'
let g:ctrlp_match_window = 'top,order:ttb,max:5'
let g:ctrlp_clear_cache_on_exit = 0
" Disable ctrlp checking for source control, it
" makes it unusable on large repositories
let g:ctrlp_working_path_mode = 'a'
" }}}

" HoverHl configuration {{{
let g:hoverhl#enabled_filetypes = [ 'cs', 'cpp', 'c', 'ps1', 'typescript', 'javascript', 'json', 'sh', 'dosbatch', 'vim' ]
" }}}

" Omnisharp configuration {{{
if has('python')
    packadd omnisharp
    let g:OmniSharp_selector_ui = 'ctrlp'
    let g:omnicomplete_fetch_documentation = 1
    let g:syntastic_cs_checkers = ['syntax', 'semantic', 'issues']
endif

augroup Omnisharp
    autocmd!

    "Set autocomplete function to OmniSharp (if not using YouCompleteMe completion plugin)
    autocmd FileType cs setlocal omnifunc=OmniSharp#Complete |
                      \ let b:SuperTabDefaultCompletionType = '<c-x><c-o>'

    "show type information automatically when the cursor stops moving
    autocmd CursorHold *.cs call OmniSharp#TypeLookupWithoutDocumentation()

    "The following commands are contextual, based on the current cursor position.

    autocmd FileType cs noremap <buffer> gd :OmniSharpGotoDefinition<cr>
    autocmd FileType cs noremap <buffer> gc :OmniSharpFindUsages<cr>

    " cursor can be anywhere on the line containing an issue
    autocmd FileType cs noremap <buffer> <c-.>  :OmniSharpFixIssue<cr>
    autocmd FileType cs noremap <buffer> <leader>fx :OmniSharpFixUsings<cr>
    autocmd FileType cs noremap <buffer> <leader>gd :OmniSharpDocumentation<cr>

    "navigate up by method/property/field
    autocmd FileType cs noremap <buffer> { :OmniSharpNavigateUp<cr>
    autocmd FileType cs noremap <buffer> } :OmniSharpNavigateDown<cr>
augroup END
" }}}

" Pencil configuration {{{
let g:pencil_gutter_color = 1
" }}}

" GitGutter configuration {{{
let g:gitgutter_sign_added = '>>'
let g:gitgutter_sign_modified = '<>'
let g:gitgutter_sign_removed = '__'
let g:gitgutter_sign_removed_first_line = '¯¯'
let g:gitgutter_sign_modified_removed = '≤≥'

" }}}

" }}}

" Filetype Settings {{{
let g:markdown_fenced_languages = ['cs', 'cpp', 'c', 'typescript', 'javascript', 'sh', 'dosbatch', 'vim']

if has('autocmd')
    augroup Filetypes
        autocmd!
        autocmd FileType cs setlocal foldmethod=indent
            autocmd BufRead *.md setlocal wrap nonumber norelativenumber
        autocmd FileType json noremap <buffer> <silent> { 0?[\[{]\s*$<cr>0^:noh<cr>|
                    \ noremap <buffer> <silent> } $/[\[{]\s*$<cr>0^:noh<cr>
        autocmd BufNew,BufReadPre *.xaml,*.targets setf xml
        autocmd BufNew,BufReadPre *.xml,*.html let b:match_words = '<.\{-}[^/]>:</[^>]*>'
        autocmd FileType xml,html setlocal matchpairs+=<:> nospell
        autocmd FileType gitcommit call setpos('.', [0, 1, 1, 0]) |
                    \ setlocal textwidth=72 formatoptions+=t colorcolumn=50,+0 |
                    \ setlocal scrolloff=0 sidescrolloff=0 sidescroll=1 |
                    \ set columns=80 lines=20 |
                    \ call GrowToContents(50, 80)
    augroup END

    augroup HelpFiles
        autocmd!
        autocmd BufWinEnter * if (&buftype == 'help') |
                        \     setlocal winwidth=80 sidescrolloff=0 |
                        \     vertical resize 80 |
                        \     noremap <buffer> q <c-w>c |
                        \ endif
        autocmd BufWinEnter * if (&buftype == 'quickfix' || &previewwindow) | noremap <buffer> q <c-w>c | endif
    augroup END
endif
" }}}

" GUI Settings {{{
if IsGui()
    " GVim window style.
    set guitablabel=%{GuiTabLabel()}
    set guitabtooltip=%{GuiTabToolTip()}
    set guioptions=gt
    set guicursor+=n-v-c:blinkon0
    colorscheme github

    " Custom keybindings
    map  <silent> <leader>m :if &go=~#'m'<bar>set go-=m<bar>else<bar>set go+=m<bar>endif<cr>

    if has('autocmd')
        augroup GuiStartup
            autocmd!
            autocmd GUIEnter * set visualbell t_vb= | call ResizeWindow('s')
        augroup END

        let g:auto_resized = 0
        augroup GuiResize
            autocmd!
            autocmd BufReadPost * if IsGui() && g:auto_resized == 0 |
                        \     if &filetype == 'markdown' |
                        \         call ResizeWindow('n') |
                        \     else |
                        \         call ResizeWindow('r') |
                        \     endif |
                        \     let g:auto_resized = 1 |
                        \ endif
            autocmd VimResized let g:auto_resized = 1
        augroup END
    endif
endif
" }}}

" Auto Commands {{{
if has('autocmd')
    augroup RememberCursor
        autocmd!
        " Jump to line cursor was on when last closed, if available
        autocmd BufReadPost * if line("'\'") > 0 && line("'\'") <= line('$') |
                       \    exe "normal g`\"" |
                       \ endif
    augroup END

    augroup Spelling
        autocmd!
        autocmd ColorScheme * hi clear SpellRare | hi clear SpellLocal
        autocmd FileType markdown,txt setlocal spell
        autocmd BufReadPost * if &l:modifiable == 0 | setlocal nospell | endif
    augroup END

    augroup AutoChDir
        autocmd!
        autocmd BufEnter * silent! lcd %:p:h
        autocmd BufEnter * if IsEmptyFile() | set ft=markdown | end
    augroup END

    highlight link MixedWhitespace Underlined
    highlight link BadBraces Error
    augroup MixedWhitespace
        autocmd!
        autocmd InsertEnter * highlight! link BadBraces NONE
        autocmd InsertLeave * highlight! link BadBraces Error
        autocmd BufEnter * match MixedWhitespace /\s*\(\( \t\)\|\(\t \)\)\s*/
        autocmd BufEnter *.c,*.cpp,*.cs,*.js,*.ps1,*.ts 2match BadBraces /[^}]\s*\n\s*\n\s*\zs{\ze\|\s*\n\s*\n\s*\zs}\ze\|\zs}\ze\s*\n\s*\(else\>\|catch\>\|finally\>\|while\>\|}\|\s\|\n\)\@!\|\zs{\ze\s*\n\s*\n/
    augroup END

    augroup WinHeight
        autocmd!
        autocmd VimResized * if (&buftype != 'help') |
                      \     let &l:winheight = (&lines * g:height_proportion) / 100 |
                      \     let &l:winwidth = (&columns * g:width_proportion) / 100 |
                      \ endif
    augroup END
endif
" }}}

" Diff Settings {{{
" NOTE: Group must be last, as it clears some augroups!

let g:diff_font = 'consolas'
let g:diff_colorscheme = 'github'
let g:diff_width = g:width_proportion

if &diff
    set diffopt=filler,context:3
    let g:airline_left_sep=''
    let g:airline_right_sep=''
    if has('autocmd')
        augroup DiffLayout
            autocmd VimEnter * call SetDiffLayout()
            autocmd GUIEnter * simalt ~x
        augroup END
        augroup RememberCursor | autocmd! | augroup END " Clear cursor jump command
        augroup GuiResize      | autocmd! | augroup END " Clear autoresize command
    elseif IsGui()
        call ResizeWindow('d')
    endif
endif

function! SetDiffLayout()
    " Allow for a different diff ui, as many configurations that
    " look nice in edit mode don't look nice in diff mode.
    let &guifont = g:diff_font
    execute 'colorscheme '.g:diff_colorscheme
    execute 'vertical resize '.((&columns * g:diff_width) / 100)

    call setpos('.', [0, 1, 1, 0]) " Start at the top of the diff
    set guioptions-=m              " Maximize screen space during diff
    set guioptions+=lr             " Show both scroll bars
    noremap <buffer> q :qa<cr>
endfu
" }}}

" Load vimrc post-file {{{
if filereadable(g:vimrc.'.custom')
    let g:vimrc_custom = g:vimrc.'.custom'
elseif filereadable(g:vimrc.'.after')
    let g:vimrc_custom = g:vimrc.'.after'
endif
if exists('g:vimrc_custom') | exe 'source '.g:vimrc_custom | endif
" }}}

" Load help docs {{{

" Credit goes to Tim Pope (https://tpo.pe/) for these functions.

function! s:Helptags() abort "| Invoke :helptags on all non-$VIM doc directories in runtimepath. {{{
    for glob in s:Split(&rtp)
        for dir in map(split(glob(glob), "\n"), 'v:val.g:slash."/doc/".g:slash')
            if (dir)[0 : strlen($VIMRUNTIME)] !=# $VIMRUNTIME.g:slash &&
                        \ filewritable(dir) == 2 &&
                        \ !empty(split(glob(dir.'*.txt'))) &&
                        \ (!filereadable(dir.'tags') || filewritable(dir.'tags'))
                silent! execute 'helptags' fnameescape(dir)
            endif
        endfor
    endfor
endfunction " }}}

function! s:Split(path) abort "| Split a path into a list. {{{
    if type(a:path) == type([]) | return a:path | endif
    if empty(a:path) | return [] | endif
    let split = split(a:path,'\\\@<!\%(\\\\\)*\zs,')
    return map(split,'substitute(v:val,''\\\([\\,]\)'',''\1'',"g")')
endfunction " }}}

call s:Helptags()

" }}}

" vim: foldmethod=marker foldlevel=0
