" Syntax-highlight languages inside fenced markdown blocks
let g:vim_markdown_fenced_languages = [
      \ 'css',
      \ 'diff',
      \ 'html',
      \ 'javascript',
      \ 'ruby',
      \ 'scss',
      \ 'bash=sh',
      \ 'sql',
      \ 'vim',
      \ 'java',
      \ 'go',
      \ 'python'
      \ ]

let g:vim_markdown_conceal_code_blocks = 0

" Enable spellchecking
setlocal spell

" Automatically wrap at 80 characters
setlocal textwidth=80
