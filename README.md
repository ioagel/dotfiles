Dotfiles
========

Forked by [Thoughtbot](https://github.com/thoughtbot/dotfiles) and heavily
customized using the dotfiles from [Gabe Berke-Williams](https://github.com/gabebw/dotfiles)
and [Chris Toomey](https://github.com/christoomey/dotfiles).

Requirements
------------

Set zsh as your login shell:

    chsh -s $(which zsh)

Install
-------

Clone onto your laptop:

    git clone https://github.com/ioagel/dotfiles.git ~/dotfiles

Install [rcm](https://github.com/thoughtbot/rcm):

    brew tap thoughtbot/formulae
    brew install rcm

Install the dotfiles:

    env RCRC=$HOME/dotfiles/rcrc rcup

After the initial installation, you can run `rcup` without the one-time variable
`RCRC` being set (`rcup` will symlink the repo's `rcrc` to `~/.rcrc` for future
runs of `rcup`). [See example](https://github.com/thoughtbot/dotfiles/blob/master/rcrc).

Install the dotfiles and lots of usefull mac apps and utilities:

    sh mac 2>&1 | tee ~/laptop.log

Check [thoughtbot/laptop repo](https://github.com/thoughtbot/laptop) for more
options!

Update
------

From time to time you should pull down any updates to these dotfiles, and run

    rcup

to link any new files and install new vim plugins. **Note** You _must_ run
`rcup` after pulling to ensure that all files in plugins are properly installed,
but you can safely run `rcup` multiple times so update early and update often!

Make your own customizations
----------------------------

Check [thoughtbot/dotfiles repo](https://github.com/thoughtbot/dotfiles).
