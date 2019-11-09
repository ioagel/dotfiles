nnoremap <Leader>bp orequire "pry"; binding.pry<esc>

" Don't make Vim traverse $PATH to find Ruby
let g:ruby_path = "~/.asdf/shims"

" NOTE: Use old ruby regex engine, which seems to perform better for large files.
" The possible values are: 0 automatic selection 1 old engine 2 NFA engine
" Default is: 0
" So by specifying set re=1 we are forcing Vim to fall back to the older regex engine.
" At least for editing Ruby files, this makes a profound difference in performance.
" In particular, scrolling is very snappy. I can set my macOS key repeat settings all the way up, and Vim keeps up just fine!
" https://github.com/joshukraine/dotfiles/blob/master/vim-performance.md
setlocal regexpengine=1

