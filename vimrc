" vim:foldmethod=marker
" The folding settings above make the {{{ and }}} sections fold up.

set encoding=utf-8

" Leader
let mapleader = " "

" let g:python_host_prog = '~/.asdf/shims/python2'
let g:python3_host_prog = '/usr/local/bin/python3'

" if $TERM =~ '^\(tmux\|iterm\|alacritty\|xterm\|vte\|gnome\)\(-.*\)\?$'
"   " Enforce italics
"   " let &t_ZH="\e[3m"
"   " let &t_ZR="\e[23m"
"   let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
"   let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
"   set termguicolors
" else
"   set notermguicolors
" endif

" True colors and italics
if exists('+termguicolors')
  let &t_8f="\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b="\<Esc>[48;2;%lu;%lu;%lum"
  set termguicolors
endif

" Placeholder for when we will need it
" set OS type
if has('unix')
  if has('mac')
    let s:os_type='mac'
  else
    let s:os_type='linux'
  endif
endif

" ============================================================================
" AUTOCOMMANDS {{{
" ===========================================================================
" on opening the file, clear search-highlighting
autocmd BufReadCmd set nohlsearch

" quit search with just 'q'
au filetype help call HelpFileMode()

" Without this, the next line copies a bunch of netrw settings like `let
" g:netrw_dirhistmax` to the system clipboard.
" I never use netrw, so disable its history.
let g:netrw_dirhistmax = 0

" Highlight the current line, only for the buffer with focus
augroup CursorLine
  autocmd!
  autocmd VimEnter,WinEnter,BufWinEnter * setlocal cursorline
  autocmd WinLeave * setlocal nocursorline
augroup END

augroup vimrc
  autocmd!
  " Include ! as a word character, so dw will delete all of e.g. gsub!,
  " and not leave the "!"
  au FileType ruby,eruby,yaml set iskeyword+=!,?
  au BufNewFile,BufRead,BufWrite *.md,*.markdown,*.html syntax match Comment /\%^---\_.\{-}---$/
  " automatically rebalance windows on vim resize
  " autocmd VimResized * wincmd =
  autocmd VimResized * GoldenRatioResize

  " Re-source vimrc whenever it changes
  autocmd BufWritePost vimrc,$MYVIMRC nested if expand("%") !~ 'fugitive' | source % | endif
augroup END

augroup vimrcEx
  autocmd!

  " it is replaced by vim-lastplace plugin
  " When editing a file, always jump to the last known cursor position.
  " Don't do it for commit messages, when the position is invalid, or when
  " inside an event handler (happens when dropping a file on gvim).
  " autocmd BufReadPost *
  "   \ if &ft != 'gitcommit' && line("'\"") > 0 && line("'\"") <= line("$") |
  "   \   exe "normal g`\"" |
  "   \ endif

  " Set syntax highlighting for specific file types
  autocmd BufRead,BufNewFile *.md set filetype=markdown
  autocmd BufRead,BufNewFile .{jscs,jshint,eslint}rc set filetype=json
  autocmd BufRead,BufNewFile aliases.local,zshrc.local,*/zsh/configs/* set filetype=sh
  autocmd BufRead,BufNewFile gitconfig.local set filetype=gitconfig
  autocmd BufRead,BufNewFile .gitignore*,gitignore* set filetype=gitignore
  autocmd BufRead,BufNewFile vimrc.local set filetype=vim
  au BufRead,BufNewFile *.es6 setf javascript
  au BufRead,BufNewFile *.ru,Gemfile,Guardfile,.simplecov,*.step,*.json.jbuilder,Vagrantfile,Brewfile* setf ruby
  " The `sql` filetype doesn't have good highlighting but `plsql` does!
  au BufRead,BufNewFile *.sql set ft=plsql
  au BufNewFile,BufRead .tmux.conf*,tmux.conf* setf tmux
  " Wrap the quickfix window
  autocmd FileType qf setlocal wrap linebreak
  " Don't automatically continue comments after newline
  autocmd BufNewFile,BufRead * setlocal formatoptions-=cro
augroup END
" }}}

" ============================================================================
" COMPLETION {{{
" ===========================================================================
" The wild* settings are for _command_ (like `:color<TAB>`) completion, not for
" completion of words in files.
set wildmenu " enable a menu near the Vim command line
set wildignorecase " ignore case when completing file names and directories
set wildmode=list:longest,list:full

" completeopt values (default: "menu,preview")
" menu:    use popup menu to show possible completion
" menuone: Use the popup menu also when there is only one match.
"          Useful when there is additional information about the match,
"          e.g., what file it comes from.
" longest: only tab-completes up to the common elements, if any: " allows
"          you to hit tab, type to reduce options, hit tab to complete.
" preview: Show extra information about the currently selected completion in
"          the preview window. Only works in combination with "menu" or
"          "menuone".
set completeopt=menu,menuone,longest,preview
" }}}

" ============================================================================
" MAPPINGS {{{
" ===========================================================================
" Change the current working directory to the directory that the current file you are editing is in.
nnoremap <Leader>cd :cd %:p:h <CR>

map <Leader>fr :call RenameFile()<cr>

" Switch between the last two files
nnoremap <Leader><Leader> <C-^>

" Toggle quickfix
nnoremap yoq :<C-R>=QuickFixIsOpen() ? "cclose" : "copen"<CR><CR>

" Edit another file in the same directory as the current file
" uses expression to extract path from current file's path
map <Leader>fe :e <C-R>=escape(expand("%:p:h"),' ') . '/'<CR>
map <Leader>fs :split <C-R>=escape(expand("%:p:h"), ' ') . '/'<CR>
map <Leader>fv :vnew <C-R>=escape(expand("%:p:h"), ' ') . '/'<CR>

" Mnemonic: vgf = "vsplit gf"
nnoremap vgf :vsplit<CR>gf
" Mnemonic: hgf = "split gf"
nnoremap hgf :split<CR>gf
" Mnemonic: tgf = "tab gf"
nnoremap tgf <C-w>gf

" Movement
" move vertically by _visual_ line
nnoremap j gj
nnoremap k gk

imap jj <esc>

nnoremap ; :

" Q for Ex mode is useless. This will run the macro in q register
nnoremap Q @q

" Swap 0 and ^. I tend to want to jump to the first non-whitespace character
" so make that the easier one to do.
nnoremap 0 ^
nnoremap ^ 0

" Use C-Space to Esc out of any mode
nnoremap <C-Space> <Esc>:noh<CR>
vnoremap <C-Space> <Esc>gV
onoremap <C-Space> <Esc>
cnoremap <C-Space> <C-c>
inoremap <C-Space> <Esc>
" Terminal sees <C-@> as <C-space>
nnoremap <C-@> <Esc>:noh<CR>
vnoremap <C-@> <Esc>gV
onoremap <C-@> <Esc>
cnoremap <C-@> <C-c>
inoremap <C-@> <Esc>

" re-select the last pasted text
nnoremap gV V`]

" edit vimrc/zshrc and load vimrc bindings
function! MaybeTabedit(file)
  let new_empty_file = line('$') == 1 && getline(1) == '' && bufname('%') == ''
  if bufname('%') ==# a:file
    " Already editing vimrc, do nothing
  elseif new_empty_file
    " If this is an empty file, just replace it with the file to edit
    execute 'edit ' . a:file
  else
    execute 'tabedit ' . a:file
  endif
endfunction
nnoremap <leader>tev :call MaybeTabedit($MYVIMRC)<CR>
nnoremap <leader>sov :source $MYVIMRC<CR>
" Quick sourcing of the current file, allowing for quick vimrc testing
nnoremap <leader>soc :source %<cr>
nnoremap <leader>tez :call MaybeTabedit('$HOME/.zshrc')<CR>

" open dotfiles dir from anywhere
nnoremap <leader>df :FZF ~/dotfiles<cr>
" fast install of new plugins
nmap <leader>bi :source ~/.vimrc<cr>:PlugInstall<cr>

" easier than ,SHIFT>;
" nnoremap <leader>; :

" excellent gist for remote clipboard functionality for mac and linux
" https://gist.github.com/burke/5960455
nnoremap <leader>6 :call PopulatePasteBufferFromOSX()<cr>
nnoremap <leader>7 :call PropagatePasteBufferToOSX()<cr>

" Tab completion
" will insert tab at beginning of line,
" will use completion if not at beginning
inoremap <Tab> <C-r>=InsertTabWrapper()<CR>
inoremap <S-Tab> <C-p>

" Quicker window movement
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" Get off my lawn
nnoremap <Left> :echoe "Use h"<CR>
nnoremap <Right> :echoe "Use l"<CR>
nnoremap <Up> :echoe "Use k"<CR>
nnoremap <Down> :echoe "Use j"<CR>

" Searching
" -----------------------
" Use The Silver Searcher https://github.com/ggreer/the_silver_searcher
if executable('ag')
  " Use Ag over Grep
  set grepprg=ag\ --nogroup\ --nocolor

  " Use ag in fzf for listing files. Lightning fast and respects .gitignore
  let $FZF_DEFAULT_COMMAND = 'ag --literal --files-with-matches --nocolor --hidden -g ""'

  if !exists(":Ag")
    command -nargs=+ -complete=file -bar Ag silent! grep! <args>|cwindow|redraw!
    nnoremap \ :Ag<SPACE>
  endif
endif

" Typo
nnoremap :Nohl :nohlsearch
nnoremap <leader>sub :%s///g<left><left>
vnoremap <leader>sub :s///g<left><left>

nnoremap <leader>rh :h local-additions<cr>

" Toggle numbers, relativenumbers on/off
noremap <silent> <Leader>cn :call CycleNumbering()<CR>

" Copy - Paste
" Copy selected text to system clipboard (requires gvim/nvim/vim-x11 installed):
vnoremap <C-c> "+y
" Big Yank to clipboard
nnoremap Y "*yiw
" Paste
map <C-v> "*p
" Copy whole buffer into clipboard
map <C-c>a mmggVG"*y`m
" Set paste, copy and exit paste
map <Leader>pa :set paste<CR><esc>"*]p:set nopaste<cr>
" }}}

" ============================================================================
" General OPTIONS {{{
" ===========================================================================
" Maximum value is 10,000
set history=10000
set noswapfile    " http://robots.thoughtbot.com/post/18739402579/global-gitignore#comment-458413287
set ruler         " show cursor position all the time
set showcmd       " display incomplete commands
set incsearch     " do incremental searching
set smarttab      " insert tabs on the start of a line according to shiftwidth, not tabstop
set modelines=2   " inspect top/bottom 2 lines for modeline
set scrolloff=1   " When scrolling, keep cursor in the middle
set colorcolumn=+1 " Set to the textwidth
" Softtabs, 2 spaces
set tabstop=2
set shiftwidth=2
set shiftround
set expandtab
set shiftround    " When at 3 spaces and I hit >>, go to 4, not 5.
set hidden
set clipboard=unnamed
set conceallevel=2

" Use one space, not two, after punctuation.
set nojoinspaces

" Don't ask me if I want to load changed files. The answer is always 'Yes'
set autoread

" https://github.com/thoughtbot/dotfiles/pull/170
" Automatically :write before commands such as :next or :!
" Saves keystrokes by eliminating writes before running tests, etc
" See :help 'autowrite' for more information
" I am not sure about that setting. I have it here to be
" notified that it exists
" set autowrite

" When the type of shell script is /bin/sh, assume a POSIX-compatible
" shell for syntax highlighting purposes.
" More on why: https://github.com/thoughtbot/dotfiles/pull/471
let g:is_posix = 1

" Persistent undo
set undofile " Create FILE.un~ files for persistent undo
set undodir=~/.vim/undodir

set formatoptions-=t " Don't auto-break long lines, except comments

" Let mappings and key codes timeout in 100ms
set ttimeout
set ttimeoutlen=100

" Create backups
set backup
set writebackup
set backupdir=~/.vim/backups
" setting backupskip to this to allow for 'crontab -e' using vim.
" thanks to: http://tim.theenchanter.com/2008/07/crontab-temp-file-must-be-ed
if has('unix')
  set backupskip=/tmp/*,/private/tmp/*"
endif

" Display extra whitespace
set list listchars=tab:»·,trail:·,nbsp:·

" Numbers
" With relativenumber and number set, shows relative number but has current
" number on current line.
set relativenumber
set number
set numberwidth=5

set backspace=indent,eol,start " allow backspacing over everything in insert mode
set autoindent
set copyindent " copy previous indentation on autoindenting
set showmatch " show matching parenthesis

" make searches case-sensitive only if they contain upper-case characters
set ignorecase smartcase

" Open new split panes to right and bottom, which feels more natural
set splitbelow
set splitright

" File encoding and format
set fileencodings=utf-8,iso-8859-1
set fileformats=unix,mac,dos
set textwidth=80

" Meta characters
" Prepended to wrapped lines
set showbreak='@'

" Set spellfile to location that is guaranteed to exist, can be symlinked to
" Dropbox or kept in Git and managed outside of thoughtbot/dotfiles using rcm.
set spellfile=$HOME/.vim/vim-spell-en.utf-8.add

" Autocomplete with dictionary words when spell check is on
set complete+=kspell

" Always use vertical diffs
set diffopt+=vertical
" }}}

" ============================================================================
" FUNCTIONS and COMMANDS {{{
" ===========================================================================
function! s:SourceConfigFilesIn(directory)
  let directory_splat = '~/.vim/' . a:directory . '/*'
  for config_file in split(glob(directory_splat), '\n')
    if filereadable(config_file)
      execute 'source' config_file
    endif
  endfor
endfunction

" add quickfix to argslist
command! -nargs=0 -bar Qargs execute 'args' QuickfixFilenames()
function! QuickfixFilenames()
  " Building a hash ensures we get each buffer only once
  let buffer_numbers = {}
  for quickfix_item in getqflist()
    let buffer_numbers[quickfix_item['bufnr']] = bufname(quickfix_item['bufnr'])
  endfor
  return join(map(values(buffer_numbers), 'fnameescape(v:val)'))
endfunction

" Cycle through relativenumber + number, number (only), and no numbering.
function! CycleNumbering() abort
  if exists('+relativenumber')
    execute {
          \ '00': 'set relativenumber   | set number',
          \ '01': 'set norelativenumber | set number',
          \ '10': 'set norelativenumber | set nonumber',
          \ '11': 'set norelativenumber | set number' }[&number . &relativenumber]
  else
    " No relative numbering, just toggle numbers on and off.
    set number!<CR>
  endif
endfunction

" RENAME CURRENT FILE (thanks Gary Bernhardt)
function! RenameFile()
  let old_name = expand('%')
  let new_name = input('New file name: ', expand('%'), 'file')
  if new_name != '' && new_name != old_name
    exec ':saveas ' . new_name
    exec ':silent !rm ' . old_name
    redraw!
  endif
endfunction

function! QuickFixIsOpen()
  let l:result = filter(getwininfo(), 'v:val.quickfix && !v:val.loclist')
  return !empty(l:result)
endfunction

function! PropagatePasteBufferToOSX()
  let @n=getreg("*")
  call system('pbcopy-remote', @n)
  echo "done"
endfunction

function! PopulatePasteBufferFromOSX()
  let @+ = system('pbpaste-remote')
  echo "done"
endfunction

function! InsertTabWrapper()
    let col = col('.') - 1
    if !col || getline('.')[col - 1] !~ '\k'
        return "\<Tab>"
    else
        return "\<C-n>"
    endif
endfunction

" Help File Speedups
"-------------------
function! HelpFileMode()
  wincmd _ " Maximze the help on open
  nnoremap <buffer> <tab> :call search('\|.\{-}\|', 'w')<cr>:noh<cr>2l
  nnoremap <buffer> <S-tab> F\|:call search('\|.\{-}\|', 'wb')<cr>:noh<cr>2l
  nnoremap <buffer> <cr> <c-]>
  nnoremap <buffer> <bs> <c-T>
  nnoremap <buffer> q :q<CR>
  setlocal nonumber
endfunction

" Requires 'jq' (brew install jq)
function! s:PrettyJSON()
  %!jq .
  set filetype=json
endfunction
command! PrettyJSON :call <sid>PrettyJSON()

" close all other buffers
command! Bd %bd|e#
" }}}

" ============================================================================
" Folding configurations {{{
" ===========================================================================
"Enable indent folding
set foldenable
set foldmethod=indent
set foldlevel=999

" So I never use s, and I want a single key map to toggle folds, thus
" lower s = toggle <=> upper S = toggle recursive
nnoremap <leader>ff za
nnoremap <leader>FF zA

"Maps for folding, unfolding all
nnoremap <LEADER>fu zM<CR>
nnoremap <LEADER>uf zR<CR>
" }}}

" ============================================================================
" PLUGIN OPTIONS {{{
" ===========================================================================
" vim-tmuxline
" --------------
let g:tmuxline_preset = {
      \'a'    : '#S',
      \'b'    : '#(whoami)',
      \'win'  : ['#I', '#W'],
      \'cwin' : '#I #W #F',
      \'x'    : ['#{?pane_synchronized,--SYNCED--,}'],
      \'y'    : ['#(~/.bin/spotify-compact-status)', '%R', '#(date "+%a - %b %d %Y")'],
      \'z'    : '#h'}

" vim-easymotion
" ----------------
let g:EasyMotion_do_mapping = 0 " Disable default mappings
" <Leader>f{char} to move to {char}
map  s <Plug>(easymotion-bd-f)
nmap s <Plug>(easymotion-overwin-f)
" s{char}{char} to move to {char}{char}
" nmap ss <Plug>(easymotion-overwin-f2)
" Move to line
map <c-e>l <Plug>(easymotion-bd-jk)
nmap <c-e>l <Plug>(easymotion-overwin-line)
" Move to word
map  <c-e>w <Plug>(easymotion-bd-w)
nmap <c-e>w <Plug>(easymotion-overwin-w)

" gundo
" -----
nnoremap <Leader>gu :GundoToggle<CR>
" Without this, Gundo won't run because Python 2 isn't installed.
let g:gundo_prefer_python3 = 1

" peekaboo
" --------
let g:peekaboo_window	= 'vert bo 50new'

" FZF
" -----------------
" This prefixes all FZF-provided commands with 'Fzf' so I can easily find cool
" FZF commands and not have to remember 'Colors' and 'History/' etc.
let g:fzf_command_prefix = 'Fzf'
" Map Ctrl + p to open fuzzy find (FZF)
nnoremap <c-p> :FZF<cr>
nnoremap <c-f>b :FzfBuffers<CR>

" Tabularize
" ------------
nmap <Leader>a= :Tabularize /=<CR>
vmap <Leader>a= :Tabularize /=<CR>
nmap <Leader>a: :Tabularize /:\zs<CR>
vmap <Leader>a: :Tabularize /:\zs<CR>
nmap <Leader>a/ :Tabularize /\|<CR>
vmap <Leader>a/ :Tabularize /\|<CR>

" emmet-vim
" -----------
let g:user_emmet_leader_key = '<c-e>'

" vim-json
" ---------
let g:vim_json_syntax_conceal = 0

" vim-prettier
" ------------
" Don't open quickfix on errors, eslint will warn of that
let g:prettier#quickfix_enabled = 0
let g:prettier#config#config_precedence = 'prefer-file'
nmap <Leader>pr <Plug>(PrettierAsync)

" vim-gitgutter
"---------------
let g:gitgutter_max_signs=9999

" vim-airline
" ------------
" let g:airline_theme = 'one'
" let g:airline_theme = 'gruvbox'
" let g:airline_theme = 'solarized'
" let g:airline_theme='papercolor'
let g:airline_powerline_fonts = 1
if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif
let g:airline#extensions#tabline#enabled = 1
" let g:airline#extensions#ale#enabled = 1
let g:airline#extensions#coc#enabled = 1
let g:airline#extensions#tabline#show_buffers = 1
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#tmuxline#enabled = 1

" Color schemes
" ---------------
" Gruvbox
let g:gruvbox_italic=1
let g:gruvbox_contrast_light='hard'
let g:gruvbox_contrast_dark='hard'

" vim-one
let g:one_allow_italics = 1

" PaperColor
let g:PaperColor_Theme_Options = {
  \   'theme': {
  \     'default.light': {
  \        'allow_italic': 1
  \       }
  \     }
  \   }

" IndentLine
" let g:indentLine_setColors = 0
let g:indentLine_char_list = ['|', '¦', '┆', '┊']
let g:indentLine_setConceal = 0

" NERDTree
" ---------
augroup ps_nerdtree
    au!

    au Filetype nerdtree setlocal nolist
    au Filetype nerdtree nnoremap <buffer> H :vertical resize -10<cr>
    au Filetype nerdtree nnoremap <buffer> L :vertical resize +10<cr>
    " au Filetype nerdtree nnoremap <buffer> K :q<cr>
augroup END
nmap ,. :NERDTreeToggle<CR>
nmap ,m :NERDTreeFind<CR>

" gist.vim
" -----------------
let g:gist_open_browser_after_post = 1
" Copy the URL after gisting
let g:gist_clip_command = 'pbcopy'
" Post privately by default
let g:gist_post_private = 1

" fugitive
" --------
" Get a direct link to the current line (with specific commit included!) and
" copy it to the system clipboard
command! GitLink silent! .Gbrowse!
command! GitLinkFile silent! 0Gbrowse!
" Open the commit hash under the cursor, in GitHub
autocmd FileType fugitiveblame nnoremap <buffer> <silent> gb :Gbrowse <C-r><C-w><CR>
" Prevent Fugitive from raising an error about .git/tags by telling it to
" explicitly check .git/tags
set tags^=.git/tags
nnoremap <leader>gs :Gstatus<CR>

" vim-run-interactive
" -------------------
" Run commands that require an interactive shell
nnoremap <Leader>ri :RunInInteractiveShell<Space>

" vim-tmux-runner
" -----------------
" Open runner pane to the right, not to the bottom
let g:VtrOrientation = 'h'
" Take up this percentage of the screen
let g:VtrPercentage = 30
" Attach to a specific pane
nnoremap <leader>va :VtrAttachToPane<CR>
" Zoom into tmux test runner pane. To get back to vim, use <C-a><C-p>
nnoremap <leader>zr :VtrFocusRunner<CR>
" ReRun last command
nnoremap <Leader>rr :write\|VtrSendCommand! !-1 <CR>
nnoremap <Leader>vs :VtrSendCommand!<Space>
nnoremap <Leader>vd :VtrSendCtrlD<CR>
nnoremap <Leader>vq :VtrKillRunner<CR>
" tagbar
nmap <F8> :TagbarToggle<CR>

" vim-terraform
let g:terraform_align=1
let g:terraform_fmt_on_save=1

" }}}

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if (&t_Co > 2 || has("gui_running")) && !exists("syntax_on")
  syntax on
endif

if filereadable(expand("~/.vimrc.bundles"))
  source ~/.vimrc.bundles
endif

" Load matchit.vim, but only if the user hasn't installed a newer version.
if !exists('g:loaded_matchit') && findfile('plugin/matchit.vim', &rtp) ==# ''
  runtime! macros/matchit.vim
endif

filetype plugin indent on

" colors
if filereadable(expand("~/.vimrc_background"))
  " let base16colorspace=256          " Remove this line if not necessary
  source ~/.vimrc_background
else
  " For one and solarized8 themes remove the file ~/.vimrc_background
  " set background=light
  set background=dark
  " colorscheme one
  colorscheme gruvbox
  " colorscheme papercolor
  " colorscheme solarized8_high
endif

" make vim transparent
hi Normal ctermbg=none guibg=none

" Treat <li> and <p> tags like the block tags they are
let g:html_indent_tags = 'li\|p'

call s:SourceConfigFilesIn('rcfiles')

" Local config
if filereadable($HOME . "/.vimrc.local")
  source ~/.vimrc.local
endif
