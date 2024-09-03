Dotfiles
========

Forked by [Thoughtbot](https://github.com/thoughtbot/dotfiles) and heavily
customized using the dotfiles from [Gabe Berke-Williams](https://github.com/gabebw/dotfiles)
and [Chris Toomey](https://github.com/christoomey/dotfiles).

Requirements
------------

Set zsh as your login shell:

    chsh -s $(which zsh)

#### Ubuntu (24.04)

- Need to compile `i3blocks` from git: https://github.com/vivien/i3blocks, because it has older version
  - To support variable passing to custom scripts


Install
-------

Clone onto your laptop:

    git clone https://github.com/ioagel/dotfiles.git ~/.dotfiles

Install [rcm](https://github.com/thoughtbot/rcm):

    # Mac OS (Not supported anymore)
    brew tap thoughtbot/formulae
    brew install rcm

    # Ubuntu
    sudo apt install rcm

Install the dotfiles:

    env RCRC=$HOME/.dotfiles/rcrc rcup -t desktop

After the initial installation, you can run `rcup` without the one-time variable
`RCRC` being set (`rcup` will symlink the repo's `rcrc` to `~/.rcrc` for future
runs of `rcup`). [See example](https://github.com/thoughtbot/dotfiles/blob/master/rcrc).

Install the dotfiles and lots of useful mac/ubuntu apps and utilities:

    bash install desktop 2>&1 | tee ~/laptop.log


Update
------

From time to time you should pull down any updates to these dotfiles, and run

    rcup -t desktop

to link any new files and install new Vim plugins. **Note** You _must_ run
`rcup` after pulling to ensure that all files in plugins are properly installed,
but you can safely run `rcup` multiple times so update early and update often!

Secure Data
-----------

You can have a private repo named: **dotfiles-secret** where you can store
confidential data, and use encryption like [git-crypt](https://github.com/AGWA/git-crypt).
I put my encrypted files in a directory named **tag-secrets**.
