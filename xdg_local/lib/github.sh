#!/usr/bin/env bash
# Function to get the latest version indicator from a GitHub repository.
# It tries in order:
#   1. Latest release tag (/releases/latest)
#   2. Most recent tag (/tags)
#   3. Default branch name (/repos/{owner}/{repo})
#
# Usage:
#   latest_release_from_github <github_repo> [with_v_prefix]
#
# Arguments:
#   github_repo:    The repository in "owner/repo" format (e.g., "stedolan/jq").
#   with_v_prefix:  "yes" (default) to include the "v" prefix if present (only applies to tags/releases),
#                   "no" to remove it. This argument has no effect if the default branch is returned.
#
# Outputs:
#   The version indicator string, or an empty string and an error message
#   to stderr on failure to fetch any information.
#
# Depends on: curl, jq
#

# In your environment or a secure config file
# I use 1password to store my tokens
# or
# export GITHUB_TOKEN_IOAGEL="token_for_ioagel"
# export GITHUB_TOKEN_FLOULAB="token_for_floulab"
# export GITHUB_TOKEN_FLOULABS="token_for_floulabs"
get_token_for_repo() {
    local repo_full_name="$1" # e.g., "floulab/myrepo"
    local owner
    owner=$(echo "$repo_full_name" | cut -d'/' -f1)
    case "$owner" in
    "ioagel") op read op://Private/GitHub/ioagelReadToken ;;     # or echo "$GITHUB_TOKEN_IOAGEL"
    "floulab") echo "" ;;                                        # Not Implemented yet
    "floulabs") op read op://Private/GitHub/floulabsReadToken ;; # or echo "$GITHUB_TOKEN_FLOULABS"
    *) echo "" ;;                                                # No specific token, try unauthenticated or a default
    esac
}

latest_release_from_github() {
    local github_repo="$1"
    local with_v_prefix="${2:-yes}"
    local version=""
    local endpoint
    local curl_auth_header=() # Array to hold authorization header if token is present
    local current_token

    # Check for GITHUB_TOKEN environment variable, first
    if [[ -n $GITHUB_TOKEN ]]; then
        current_token=$GITHUB_TOKEN
    else # Otherwise, try to get a token from the repo owner
        current_token=$(get_token_for_repo "$github_repo")
    fi

    if [[ -n "$current_token" ]]; then
        curl_auth_header=("-H" "Authorization: Bearer $current_token")
    fi

    if ! command -v jq &>/dev/null; then
        echo "Error: jq is not installed. Please install jq." >&2
        return 1
    fi

    if ! command -v curl &>/dev/null; then
        echo "Error: curl is not installed. Please install curl." >&2
        return 1
    fi

    if [[ -z "$github_repo" ]]; then
        echo "Error: GitHub repository not specified." >&2
        echo "Usage: latest_release_from_github <owner/repo> [yes|no]" >&2
        return 1
    fi

    # 1. Try the /releases/latest endpoint
    endpoint="https://api.github.com/repos/$github_repo/releases/latest"
    version=$(curl -fsSL --connect-timeout 5 "${curl_auth_header[@]}" "$endpoint" 2>/dev/null | jq -r '.tag_name // empty')

    # 2. If /releases/latest failed or no .tag_name, try /tags endpoint
    if [[ -z "$version" ]]; then
        endpoint="https://api.github.com/repos/$github_repo/tags"
        version=$(curl -fsSL --connect-timeout 5 "${curl_auth_header[@]}" "$endpoint" 2>/dev/null | jq -r '.[0].name // empty')
    fi

    # 3. If still no version, try to get the default branch name
    if [[ -z "$version" ]]; then
        endpoint="https://api.github.com/repos/$github_repo"
        version=$(curl -fsSL --connect-timeout 5 "${curl_auth_header[@]}" "$endpoint" 2>/dev/null | jq -r '.default_branch // empty')
        if [[ -n "$version" ]]; then
            echo "$version"
            return 0
        fi
    fi

    if [[ -z "$version" ]]; then
        echo "Error: Failed to fetch release, tag, or default branch information from GitHub for $github_repo." >&2
        return 1
    fi

    if [[ "$with_v_prefix" == "yes" ]]; then
        echo "$version"
    else
        if [[ "$version" == v* ]]; then
            echo "${version:1}"
        else
            echo "$version"
        fi
    fi
}

# Example Usage (uncomment to test):
# echo "--- Testing stedolan/jq (should have release) ---"
# latest_release_from_github "stedolan/jq"
# latest_release_from_github "stedolan/jq" "no"

# echo "--- Testing basecamp/omakub (should have release) ---"
# latest_release_from_github "basecamp/omakub"

# echo "--- Testing nixxxon/virtmon (no releases/tags, should get default branch) ---"
# latest_release_from_github "nixxxon/virtmon"
# latest_release_from_github "nixxxon/virtmon" "no" # 'no' will have no effect on branch name

# echo "--- Testing a repo that might only have a default branch (e.g., a new empty repo or one without tags/releases) ---"
# Example: Create a new empty public repo on GitHub and test it here
# latest_release_from_github "YOUR_USERNAME/YOUR_NEW_EMPTY_REPO"

# echo "--- Testing nonexistent/repo (should fail) ---"
# latest_release_from_github "nonexistent/repo"
