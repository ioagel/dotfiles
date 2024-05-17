Install
-------

Clone onto your laptop:

    git clone https://github.com/ioagel/dotfiles.git ~/.dotfiles

Install the dotfiles:
```bash
cd ~/.dotfiles/.scripts
# Variables with default values that can be overridden
# WITH_ASDF_JAVA="${WITH_ASDF_JAVA:-yes}"
# WITH_ASDF_NODE="${WITH_ASDF_NODE:-yes}"
# WITH_ASDF_GO="${WITH_ASDF_GO:-yes}"
# WITH_ASDF_PYTHON="${WITH_ASDF_PYTHON:-yes}"
# WITH_GUI="${WITH_GUI:-no}" # for Linux
# WITH_ALACRITTY_COLORSCHEME="${WITH_ALACRITTY_COLORSCHEME:-no}"
./install
```

Update
------

From time to time you should pull down any updates to these dotfiles, and run

    cd ~/.dotfiles && stow */
