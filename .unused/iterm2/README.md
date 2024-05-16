# Install

    $ tic -x xterm-256color-italic.terminfo
    $ tic -x tmux-256color.terminfo

Further instructions at [How to actually get italics and true colour to work in iTerm + tmux + vim](https://medium.com/@dubistkomisch/how-to-actually-get-italics-and-true-colour-to-work-in-iterm-tmux-vim-9ebe55ebc2be)

## iTerm2 preferences

    killall cfprefsd     # This will get rid of cached settings
    # Specify the preferences directory
    defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "~/.dotfiles/iterm2"
    # Tell iTerm2 to use the custom preferences in the directory
    defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
