# Vi Mode
bindkey -M viins 'jj' vi-cmd-mode # Map 'jj' in insert mode to Escape (Normal Mode)
bindkey -M viins '^U' kill-whole-line # Need this when using vi-mode

bindkey -s "^K" "^[Isudo ^[A"
