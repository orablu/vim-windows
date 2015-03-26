" Plugins
    execute pathogen#infect()

" Top level settings
    set nocompatible
    source $VIMRUNTIME/vimrc_example.vim
    source $VIMRUNTIME/mswin.vim
    behave mswin
    cd \%SRCROOT\%\src\

" Choose a colorscheme
    colorscheme solarized
    set background=light

" Custom keybindings
    "let mapleader = ','
    imap jk          <esc>
    imap kj          <esc>
    imap <silent> <Tab> <c-r>=Tab_Or_Complete()<cr>
    imap <c-a>       <esc>ggVG
    map  <c-a>       <esc>ggVG
    map  <c-e>       :silent !explorer .<cr>
    map  <c-t>       :tabnew<cr>
    map  <c-x>       :tabclose<cr>
    map  <c-z>       :tabnew E:\Public Share\Programs\Vim\_vimrc<cr>
    map  <leader>=   :set background=light<cr>
    map  <leader>-   :set background=dark<cr>
    map  <leader>[   :setlocal wrap!<cr>:setlocal wrap?<cr>
    map  <leader>]   :noh<cr>
    map  <leader>i   :set foldmethod=indent<cr>
    map  <leader>m   :setlocal relativenumber!<cr>
    map  <leader>M   :setlocal number!<cr>
    map  <leader>v   "+p
    map  <leader>y   "+y
    map  j           gj
    map  k           gk
    map  <c-j>       <c-w>j
    map  <c-k>       <c-w>k
    map  <c-l>       <c-w>l
    map  <c-h>       <c-w>h
    map  zq          ZQ
    map  <leader>gor :e $SRCROOT\src\debugger\Razor<cr>
    map  <leader>gop :e E:\Public Share<cr>

" Tabs should be 4 spaces
    set tabstop=4
    set shiftwidth=4
    set expandtab
    set autoindent

" Search options
    set incsearch
    set ignorecase
    set smartcase
    set hlsearch

" Wrap settings
    set backspace=indent,eol,start
    set formatoptions=lrocj
    set lbr

" File organization
    set autochdir
    set foldmethod=syntax

" Keep your files free of .*~ backups
    set nobackup
    set nowritebackup

" Visual aesthetics
    set autoindent
    set nowrap
    set number relativenumber
    set showcmd
    set ruler
    set equalalways

" Plugin settings
    set encoding=utf-8
    set guifont=Fantasque\ Sans\ Mono:h12
    set laststatus=2
    set noshowmode

" GUI configuration
if has("gui")
	" GVim window style.
    set guitablabel=%t
	set guioptions=gtcLR
	set titlestring=%t%(\ %M%)%(\ (%{expand(\"%:p:h\")})%)%(\ %a%)\ -\ %{v:servername}
    if &diff
        set lines=50
        set columns=200
    else
        set lines=20
        set columns=80
    endif

    " GUI mouse management.
	set mouse=a
	set selectmode=
endif

" Diff configuration
if &diff
    colorscheme github
    set diffopt=filler,context:3
    if has("autocmd")
        autocmd VimEnter * simalt ~x | 
    endif
endif

" Autocommands
if has("autocmd")
	filetype plugin indent on

	" Stop dinging, dangit!
	set noerrorbells visualbell t_vb=
	autocmd GUIEnter * set visualbell t_vb=
    autocmd GUIEnter * call ColorScheme()

    " Jump to line cursor was on on last close if available.
	autocmd BufReadPost *
		\ if line("'\"") > 0 && line("'\"") <= line("$") |
		\  exe "normal g`\"" |
		\ endif
endif

" Functions

function! Tab_Or_Complete()
  if col('.')>1 && strpart( getline('.'), col('.')-2, 3 ) =~ '^\w'
    return "\<C-N>"
  else
    return "\<Tab>"
  endif
endfunction

function! ColorScheme()
    let l:time = str2nr(strftime('%H'))
    if (l:time > 13)
        set background=dark
    else
        set background=light
    endif
endfunction
