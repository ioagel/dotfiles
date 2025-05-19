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
- `1Password` and `1Password cli` for sensitive data (needed by `install_sec.sh`)

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
   Take a look at [`install.sh`](./install.sh) and [`ansible/system-play.yml`](./ansible/system-play.yml).

3. **Run the installation process:**

   ```sh
   # Step 1: Install and setup system packages and configurations
   ansible-playbook ansible/system-play.yml -K

   # Step 2: Setup user-level dotfiles
   ./install.sh

   # Optional: Setup sensitive data (requires 1Password)
   ./install_sec.sh
   ```

4. After the scripts finish **reboot**.

### What Each Script Does

The **Ansible playbook** (`ansible/system-play.yml`) will:

- Install system and AUR packages from the package list
- Set up the SDDM theme and configuration
- Configure system-level settings that require root privileges
- Enable necessary system services

The **`install.sh`** script will:

- Check for dependencies (`stow`)
- Use `stow` to create symlinks for the user packages to their appropriate directories
- Install and configure ZSH plugins
- Set up Alacritty themes and configure theme-related settings
- Build and configure various applications (i3, zellij, VS Code, etc.)

The **`install_sec.sh`** script (optional) will:

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
  find . -type l > rsync-exclude.txt
  sed -i 's|^\./||' rsync-exclude.txt

  # Then add all the files generated from templates

  rsync -a --delete --exclude-from=rsync-exclude.txt ~/.dotfiles dest/
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
