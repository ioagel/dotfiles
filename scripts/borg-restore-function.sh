#!/usr/bin/env bash

# Function to restore specific home directories from Borg backup
restore_from_borg() {
    info "Checking for Borg backup restore..."

    # Check if USER_NAME is defined
    if [ -z "$USER_NAME" ]; then
        error "USER_NAME variable is not defined. Cannot continue with Borg restore."
        return 1
    fi

    # Verify the user exists in the chroot environment
    if ! arch-chroot /mnt id "$USER_NAME" &>/dev/null; then
        error "User $USER_NAME does not exist in the chroot environment. Cannot continue with Borg restore."
        return 1
    fi

    # Ask if user wants to restore from backup
    if ! gum confirm "Do you want to restore specific home directories from a Borg backup?"; then
        info "Skipping Borg backup restore."
        return 0
    fi

    # Ask for Borg repository URL
    BORG_REPO=$(gum input --placeholder "Enter Borg repository URL (e.g. username@host:/path/to/repo)" --prompt "Borg Repository: ")
    if [ -z "$BORG_REPO" ]; then
        warning "No Borg repository specified. Skipping restore."
        return 0
    fi

    # Set up SSH configuration if using SSH
    BORG_REMOTE_PATH=""
    SSH_PASSWORD=""
    if [[ "$BORG_REPO" == *"@"* ]]; then
        # Configure SSH options
        SSH_HOST=$(echo "$BORG_REPO" | cut -d '@' -f 2 | cut -d ':' -f 1)
        SSH_USER=$(echo "$BORG_REPO" | cut -d '@' -f 1)
        info "Detected SSH host: $SSH_HOST with user: $SSH_USER"
        
        # Configure SSH to ignore host keys
        export BORG_RSH='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
        
        # Get SSH password
        SSH_PASSWORD=$(gum input --placeholder "Enter SSH password for $SSH_USER@$SSH_HOST" --prompt "SSH Password: " --password)
        if [ -n "$SSH_PASSWORD" ]; then
            # Install sshpass if password is provided
            info "Installing sshpass in the chroot environment..."
            arch-chroot /mnt pacman -Sy --noconfirm --needed sshpass
            export SSHPASS="$SSH_PASSWORD"
        fi
        
        # Get remote borg path
        REMOTE_PATH=$(gum input --placeholder "Enter path to Borg on remote server (e.g. /usr/local/bin/borg)" --prompt "Remote Borg Path: " --value "/usr/local/bin/borg")
        BORG_REMOTE_PATH="--remote-path $REMOTE_PATH"
    fi

    # Ask for Borg passphrase
    BORG_PASSPHRASE=$(gum input --placeholder "Enter Borg passphrase" --prompt "Borg Passphrase: " --password)
    if [ -z "$BORG_PASSPHRASE" ]; then
        warning "No Borg passphrase provided. Skipping restore."
        return 0
    fi
    export BORG_PASSPHRASE

    # Install borg in the chroot environment
    info "Installing Borg in the chroot environment..."
    arch-chroot /mnt pacman -Sy --noconfirm --needed borg || {
        error "Failed to install borg. Skipping restore."
        return 1
    }

    # Define directories to restore
    RESTORE_OPTIONS=(
        "gnupg"
        "ssh"
        "docker"
        "mozilla"
        "evolution"
        "brave"
        "google-chrome"
        "1Password"
        "gnome-keyring"
        "mise"
        "Code"
        "Cursor"
        "Windsurf"
    )

    # Get user selection
    SELECTED_DIRS=$(gum choose --no-limit --header "Select directories to restore:" "${RESTORE_OPTIONS[@]}")
    if [ -z "$SELECTED_DIRS" ]; then
        warning "No directories selected for restore. Skipping."
        return 0
    fi

    # Build common environment variables for all borg commands
    ENV_VARS="BORG_PASSPHRASE='$BORG_PASSPHRASE' BORG_RSH='$BORG_RSH'"
    if [ -n "$SSH_PASSWORD" ]; then
        ENV_VARS="$ENV_VARS SSHPASS='$SSH_PASSWORD'"
        BORG_CMD="sshpass -e borg"
    else
        BORG_CMD="borg"
    fi

    # Get latest archive
    info "Getting latest archive from repository..."
    LATEST_ARCHIVE=$(arch-chroot /mnt sh -c "$ENV_VARS $BORG_CMD list $BORG_REMOTE_PATH --last 1 --short '$BORG_REPO'" | head -1)
    if [ -z "$LATEST_ARCHIVE" ]; then
        error "No archives found in the repository. Exiting."
        return 1
    fi
    info "Using latest archive: $LATEST_ARCHIVE"

    # Function to extract a directory - simplified
    extract_directory() {
        local dir="$1"
        local path="$2"
        info "Extracting $dir..."
        
        # Create directory if needed
        arch-chroot /mnt mkdir -p "/home/$USER_NAME/$(dirname "$path")" 2>/dev/null
        
        # Extract with proper permissions
        arch-chroot /mnt sh -c "$ENV_VARS su - $USER_NAME -c \"cd / && $ENV_VARS $BORG_CMD extract $BORG_REMOTE_PATH --sparse '$BORG_REPO::$LATEST_ARCHIVE' 'home/$USER_NAME/$path'\""
    }

    # Mapping of directory types to their paths
    declare -A DIR_PATHS
    DIR_PATHS["gnupg"]=".gnupg"
    DIR_PATHS["ssh"]=".ssh"
    DIR_PATHS["docker"]=".docker"
    DIR_PATHS["mozilla"]=".mozilla"
    DIR_PATHS["brave"]=".config/BraveSoftware"
    DIR_PATHS["google-chrome"]=".config/google-chrome"
    DIR_PATHS["1Password"]=".config/1Password"
    DIR_PATHS["gnome-keyring"]=".local/share/keyrings"
    DIR_PATHS["mise"]=".local/share/mise"
    DIR_PATHS["Windsurf"]=".config/Windsurf .windsurf"
    DIR_PATHS["Cursor"]=".config/Cursor .cursor"
    DIR_PATHS["Code"]=".config/Code .vscode"
    DIR_PATHS["evolution"]=".config/evolution .local/share/evolution"

    # Process selected directories
    for dir in $SELECTED_DIRS; do
        if [[ -n "${DIR_PATHS[$dir]}" ]]; then
            # Process space-separated paths for each directory type
            for path in ${DIR_PATHS[$dir]}; do
                extract_directory "$dir - $path" "$path"
            done
        fi
    done
    
    success "Borg restore process completed."
    
    # Clean up
    unset BORG_PASSPHRASE SSHPASS BORG_RSH
}

restore_from_borg
