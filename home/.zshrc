ZSH_DIR="$HOME/.zsh"

# Credits to: Thoughtbot dotfiles https://github.com/thoughtbot/dotfiles for initial implementation
# extra files in $ZSH_DIR/configs/pre , $ZSH_DIR/configs , and $ZSH_DIR/configs/post
# these are loaded first, second, and third, respectively.
_load_settings() {
    local _dir="$1"
    local config

    if [ ! -d "$_dir" ]; then
        return 1 # Exit if base directory doesn't exist
    fi

    setopt nullglob extendedglob

    # Process 'pre' directory
    if [ -d "$_dir/pre" ]; then
        # Glob for all regular files recursively, sorted by name
        for config in "$_dir"/pre/**/*(N-.); do
            # Skip .zwc files inside the loop
            if [[ "$config" == *.zwc ]]; then
                continue
            fi
            # Source the config file
            . "$config"
        done
    fi

    # Process main directory (excluding pre/post subdirectories)
    # Glob for all regular files recursively, sorted by name
    for config in "$_dir"/**/*(N-.); do
        # Skip files within pre/post directories and .zwc files
        if [[ "$config" == "$_dir"/pre/* || "$config" == "$_dir"/post/* || "$config" == *.zwc ]]; then
            continue
        fi
        # Source the config file
        . "$config"
    done

    # Process 'post' directory
    if [ -d "$_dir/post" ]; then
        # Glob for all regular files recursively, sorted by name
        for config in "$_dir"/post/**/*(N-.); do
            # Skip .zwc files inside the loop
            if [[ "$config" == *.zwc ]]; then
                continue
            fi
            # Source the config file
            . "$config"
        done
    fi
}
_load_settings "$ZSH_DIR/configs"

# Include custom zshrc
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# Include custom secret aliases
[[ -f ~/.aliases ]] && source ~/.aliases
