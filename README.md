# Dotfiles

Managed using [GNU Stow](https://www.gnu.org/software/stow/) for user dotfiles and [Ansible](https://www.ansible.com/) for system configuration.

## Structure

This repository uses a hybrid approach for configuration management:

- **User Configuration (managed by Stow):**
  - `home`: Files to be linked directly into `$HOME` (e.g., `.zshrc`, `.gitconfig`).
  - `xdg_config`: Files to be linked into `$XDG_CONFIG_HOME` (usually `~/.config`). Contains subdirectories for applications (e.g., `alacritty`, `zellij`).
  - `xdg_local`: Files to be linked into `$XDG_DATA_HOME`, `$XDG_STATE_HOME`, or other locations under `~/.local` (e.g., `share`, `bin`).

- **System Configuration (managed by Ansible):**
  - `ansible/`: Contains playbooks and variable files for system configuration
  - `system/`: Contains system-level files (like SDDM themes) that are copied by Ansible

## Requirements

- `ansible` for system packages setup and configuration
- [GNU Stow](https://www.gnu.org/software/stow/) for user dotfiles
- `1Password` and `1Password cli` for sensitive data (needed by `setup-secrets.sh`)

## Installation

This repository includes an automated installation process.

1. **Clone the repository:**

   ```sh
   git clone https://github.com/ioagel/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles

   # Setup Ansible
   ansible-galaxy collection install -r ansible/requirements.yml
   ```

2. **Review the scripts (Optional but Recommended):**
   Take a look at [`setup-dotfiles.sh`](./setup-dotfiles.sh) and [`ansible/system-play.yml`](./ansible/system-play.yml).

3. **Run the installation process:**

   ```bash
   ./post-install.sh  # On first boot of the new system
   ./setup-dotfiles.sh
   ./setup-secrets.sh  # Optional: Configure sensitive files from 1Password
   ```

4. After the scripts finish **reboot**.

### What Each Script Does

The **Ansible playbook** (`ansible/system-play.yml`) will:

- Install system and AUR packages from the package list
- Set up the SDDM theme and configuration
- Configure system-level settings that require root privileges
- Enable necessary system services

The **`setup-dotfiles.sh`** script will:

- Install user dotfiles using [GNU Stow](https://www.gnu.org/software/stow/)
- Set up terminal shell (zsh with oh-my-zsh and plugins)
- Configure and apply themes (initial theme can be specified with `-t` option)
- Create necessary directories and symlinks

The **`setup-secrets.sh`** script (optional) will:

- Check for the 1Password CLI (`op`)
- Fetch sensitive configuration files from your 1Password vault

## Ubuntu (24.04)

- Need to compile `i3blocks` from git: <https://github.com/vivien/i3blocks>, because it has older version
  - To support variable passing to custom scripts

## NOTES

- Adds `.stow-local-ignore` in `home` package to prevent `.gitignore` from being ignored by stow.

- Testing `dotfiles` with rsync copying to a test `Arch` install:
  
  ```sh
  cd ~/.dotfiles

  # Prevent copying of symlinks and ignored files
  find . -type l > .rsync-exclude.txt
  sed -i 's|^\./||' .rsync-exclude.txt

  # Then add all the files generated from templates

  rsync -a --delete --exclude-from=.rsync-exclude.txt ~/.dotfiles dest/
  ```

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
