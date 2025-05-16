# Load common path configuration for both shell (e.g. .zshrc) and X (e.g. .zprofile)

export GOPATH="$HOME/.golang"
PATH="$GOPATH/bin:$PATH"

if [ -d "$HOME/.local/share/JetBrains/Toolbox/scripts" ]; then
    # Make Jetbrains happy
    PATH="$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH"
fi

# home dir bin dirs
PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# What does .git/safe/../../bin mean?
# - .git/safe is a directory inside your repo’s .git folder.
# - ../../bin means: from .git/safe, go up two directories (to the repo root), then into bin.
# So, if your repo root is /home/user/project, then .git/safe/../../bin resolves to /home/user/project/bin.
# What’s the effect?
# - This adds the bin directory from your current git repository to your PATH,
# but only if you are inside a repo where .git/safe exists.
# - This is a safety measure: it only activates custom scripts from bin,
# in repositories you explicitly trust (where you created .git/safe).
# Summary:
# This code safely adds the bin directory of trusted git repositories to your PATH,
# so you can run project-specific scripts, but only in repos you mark as “safe” by creating .git/safe.
PATH=".git/safe/../../bin:$PATH"

# Zsh-specific PATH uniqueness
if [ -n "$ZSH_VERSION" ]; then
    # This de-duplicates the current PATH string into the 'path' array
    # and updates the PATH string variable itself to the de-duplicated version.
    # shellcheck disable=SC2034
    typeset -U path
    export PATH # Ensure this (now de-duplicated) PATH is marked for export.
else
    export PATH # For other POSIX shells
fi
