### Unaliases
# I use 'sp' for spotify command line script
unalias sp 2>/dev/null # oh-my-zsh rails plugin
unalias g 2>/dev/null  # oh-my-zsh git plugin

## File System
alias ll="ls -al"
alias ltr="ls -lAFhtr"
alias ln="ln -v"
alias df="df -h"
alias mkdir="mkdir -p"
alias cd="z" # using zoxide utility
alias cat='bat --paging=never -p'
# In ubuntu at least, 'fd' is already aliased, and I overwrite it here
# Using the 'fdfind' utility as it is called in Ubuntu
# https://github.com/sharkdp/fd
command -v fdfind >/dev/null && alias fd="fdfind"

## Editor
alias vim='$EDITOR'
alias e='$EDITOR'
alias n='$EDITOR'

# Terminal
# Needed for starship prompt to show properly
# If initialized before the prompt, then use:
# alias fast='fastfetch'
alias fast='fastfetch --pipe false'
alias zel='zellij'

# Pretty print the path
alias ppath='echo $PATH | tr -s ":" "\n"'

# Docker related
alias lzd='lazydocker'

alias lzg='lazygit'

alias ssh="TERM=xterm-256color ssh"

# ssh related
alias sshk="ssh-keygen -R "

# sops encrypt - decrypt related
alias sei="sops -e -i"
alias sdi="sops -d -i"

# kubernetes
alias kns="kubens"
alias kctx="kubectx"

# i3 config
alias i3e='$EDITOR ~/.config/i3/config'

# zsh config
alias soz='source ~/.zshrc'

# Snapshots (using snap-manager custom script which wraps snapper)
alias sm="snap-manager"
alias snapshots="snap-manager list --config all"
alias snap="snap-manager create" # default config: root
alias snap-home="snap-manager create --config home"

# For laptop only
alias batt-optimal='sudo systemctl restart set-batt-thresholds-optimal.service'
alias batt-default='sudo systemctl restart set-batt-thresholds-default.service'

# Arch related
alias mypkgs="{ expac --timefmt='%Y-%m-%d %T' '%l\tRepo\t%n' -Q \$(pacman -Qenq); expac --timefmt='%Y-%m-%d %T' '%l\tAUR \t%n' -Q \$(pacman -Qemq); } | sort -rn"

##### World of Warcraft
# You should use `clean-wow-cache` only as a **troubleshooting step**, not as a regular maintenance routine. Clearing the cache is technically a "performance reset"—the next time you launch the game, your GPU has to re-calculate every shader from scratch, which causes temporary stuttering and longer loading screens.

# Here are the specific scenarios when you should run it:

### 1. After a Major Driver Update (The "Clean Slate")
# In 2026, Mesa is usually smart enough to invalidate old shaders when you update, but "Rolling Release" distros like Arch can sometimes leave "ghost" files.
# * **When to run:** If you just updated `mesa`, `vulkan-radeon`, or your `linux-cachyos` kernel and the game feels "jittery" or takes forever to load textures.

### 2. Visual Glitches (The "Fix-It" Button)
# If you start seeing things in Azeroth that aren't supposed to be there:
# * **Symptoms:** Neon-colored textures, flickering shadows, invisible walls, or "black box" spell effects.
# * **Why it happens:** Sometimes a shader gets corrupted on your disk. Deleting the cache forces the driver to write a fresh, clean version.

### 3. After Changing GPU Hardware
# When your **Sapphire Pulse RX 9070 XT** arrives:
# * **The Rule:** **Definitely run it.** Your current cache is filled with shaders compiled for the old RX 580 architecture (Polaris). While the driver *should* ignore them, it's best to clear the 10GB folder so your new RDNA 4 card can start building its own optimized cache immediately.

### 4. Severe Stuttering (The "Optimization" Reset)
# If you recently changed your launch arguments (like adding `RADV_PERFTEST=ngc,gpl`), it’s a good idea to clear the cache once. This ensures that *every* shader is compiled using your new, faster settings.

# ---

### ⚠️ When NOT to use it:
# * **Before a Raid:** Never clear your cache right before a raid or a dungeon. You will experience "shader compilation lag" for the first 10-15 minutes of gameplay while your GPU rebuilds the bank.
# * **To "Save Space":** Even though we set the limit to 10GB, Mesa is very efficient. It won't actually hit 10GB unless you've visited every single zone in the game multiple times.

# **Summary Recommendation:**
# Think of `clean-wow-cache` as a "Repair Tool." If the game looks weird or feels sluggish after a system update, fire it off. Otherwise, let that 10GB cache grow—it’s the reason your game feels so smooth on Arch!

# **Would you like me to show you how to add a "Cache Size" indicator to your `htop` or a terminal alias so you can see how much of that 10GB is actually being used?**
alias clean-wow-cache='rm -rf ~/.cache/mesa_shader_cache && echo "WoW Shader Cache Cleared. Next launch will compile fresh shaders."'
alias shader-wow-status='du -sh ~/.cache/mesa_shader_cache'
