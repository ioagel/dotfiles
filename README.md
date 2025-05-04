# Dotfiles

Managed using [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

This repository uses Stow packages organized by target directory:

*   `home`: Files to be linked directly into `$HOME` (e.g., `.zshrc`, `.gitconfig`).
*   `xdg_config`: Files to be linked into `$XDG_CONFIG_HOME` (usually `~/.config`). Contains subdirectories for applications (e.g., `alacritty`, `zellij`).
*   `xdg_local`: Files to be linked into `$XDG_DATA_HOME`, `$XDG_STATE_HOME`, or other locations under `~/.local` (e.g., `share`, `bin`).
*   `etc`: System-wide configuration files to be linked into `/etc`. Requires root privileges.

## Requirements

*   [GNU Stow](https://www.gnu.org/software/stow/)
*   `sudo` access (for managing files in `/etc`)
*   Set zsh as your login shell:
    ```bash
    chsh -s $(which zsh)
    ```

## Installation

This repository includes an automated installation script.

1.  **Clone the repository:**
    ```bash
    git clone <your-repo-url> ~/.dotfiles
    cd ~/.dotfiles
    ```

2.  **Review the script (Optional but Recommended):**
    Take a look at `install.sh` to understand what it does, especially the `sudo` commands for the `etc` package.

3.  **Run the installer:**
    ```bash
    ./install.sh
    ```

The script will:
*   Check for dependencies (`stow`, `sudo`).
*   Use `stow` to create symlinks for the `home`, `xdg_config`, and `xdg_local` packages to the appropriate user directories (`$HOME`, `~/.config`, `~/.local`).
*   Prompt for your password to use `sudo stow` for the `etc` package, linking files into `/etc`.
*   If systemd units are defined in `install.sh` (and present in `etc/systemd/system/`), it will automatically run `sudo systemctl daemon-reload` and `sudo systemctl enable <service>` for them.

## Manual Stowing (Alternative)

If you prefer not to use the script, you can stow packages manually from the `~/.dotfiles` directory:

```bash
# User files
stow -R home
stow -R -t ~/.config xdg_config
stow -R -t ~/.local xdg_local

# System files (Requires sudo)
sudo stow -R -t /etc etc

# Manually reload/enable systemd services if needed
sudo systemctl daemon-reload
sudo systemctl enable <service_name>
# sudo systemctl start <service_name>

## Post Stowing
# Install or update alacritty themes
git clone --depth 1 https://github.com/alacritty/alacritty-themes.git ~/.config/alacritty/themes
# or
cd ~/.config/alacritty/themes && git pull

# Build i3 config
build-i3-config -t gruvbox

# Build zellij config
build-zellij-config -t gruvbox-dark
```

## Ubuntu (24.04)

- Need to compile `i3blocks` from git: <https://github.com/vivien/i3blocks>, because it has older version
  - To support variable passing to custom scripts

## NOTES

- Adds `.stow-local-ignore` in `home` package to prevent `.gitignore` from being ignored by stow.