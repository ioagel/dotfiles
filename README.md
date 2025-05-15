# Dotfiles

Managed using [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

This repository uses Stow packages organized by target directory:

- `home`: Files to be linked directly into `$HOME` (e.g., `.zshrc`, `.gitconfig`).
- `xdg_config`: Files to be linked into `$XDG_CONFIG_HOME` (usually `~/.config`). Contains subdirectories for
  applications (e.g., `alacritty`, `zellij`).
- `xdg_local`: Files to be linked into `$XDG_DATA_HOME`, `$XDG_STATE_HOME`, or other locations under `~/.local` (e.g.,
  `share`, `bin`).
- `etc`: System-wide configuration files to be linked into `/etc`. Requires root privileges.

## Requirements

- [GNU Stow](https://www.gnu.org/software/stow/)
- `sudo` access (for managing files in `/etc`)
- `zsh` as an advanced login shell
- `neovim-remote` for having live-update of neovim color theme (in arch do: `yay -S neovim-remote`)
- `python-i3ipc` for window_title.py i3blocks script (if using i3blocks, default is polybar)
- `xsettingsd` for gtk live theme changes
- `1Password` and `1Password cli` for sensitive data (needed by `install_sec.sh`)

## Installation

This repository includes an automated installation script.

1. **Clone the repository:**

   ```bash
   git clone https://github.com/ioagel/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Review the script (Optional but Recommended):**
   Take a look at [`install.sh`](./install.sh)  to understand what it does, especially the `sudo` commands for the `etc` package.

3. **Run the installer:**

   ```bash
   ./install.sh

   # Optional (Setup of sensitive data, requires 1Password)
   ./install_sec.sh
   ```

4. After the script finishes **log out and log back in** (even better you should `reboot`).

The `install.sh` script will:

- Check for dependencies (`stow`, `sudo`).
- Use `stow` to create symlinks for the `home`, `xdg_config`, and `xdg_local` packages to the appropriate user
  directories (`$HOME`, `~/.config`, `~/.local`).
- Prompt for your password to use `sudo stow` for the `etc` package, linking files into `/etc`.
- If systemd units are defined in `install.sh` (and present in `etc/systemd/system/`), it will automatically run
  `sudo systemctl daemon-reload` and `sudo systemctl enable <service>` for them.
- Then it will proceed to the final build steps

The `install_sec.sh` script (optional) will:

- Check for the `1Password CLI (`op`)`.
- Attempt to fetch sensitive configuration files (like `~/.item_expirations.txt` and the cron job fetcher config) from your 1Password vault and place them in the correct locations.

## Ubuntu (24.04)

- Need to compile `i3blocks` from git: <https://github.com/vivien/i3blocks>, because it has older version
  - To support variable passing to custom scripts

## NOTES

- Adds `.stow-local-ignore` in `home` package to prevent `.gitignore` from being ignored by stow.

- `yazi` light theme is not applied inside `zellij`, even if the last one and the terminal `wezterm` use a light theme.

  This in `theme.toml` fails and still shows the dark theme:

  ```toml
  [flavor]
  light = "catppuccin-latte"
  dark = "gruvbox-dark"
  ```

  Only this is **working**:

  ```toml
  [flavor]
  light = "catppuccin-latte"
  dark = "catppuccin-latte"
  ```
