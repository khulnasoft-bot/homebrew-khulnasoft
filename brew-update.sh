#!/usr/bin/env bash
set -euo pipefail

# brew-update.sh - A script to check and update dev-tools Homebrew formula
#
# This script checks for updates to the dev-tools package and updates the Homebrew formula
# if a newer version is available. It includes caching to avoid unnecessary checks.
#
# Usage:
#   ./brew-update.sh [options]
#
# Options:
#   -v, --verbose  Enable verbose output
#   -f, --force    Force update check, ignoring cache
#   -h, --help     Show this help message
#
# Exit codes:
#   0 - Success
#   1 - Error in script execution
#   2 - Missing required dependencies
#   3 - Version check failed

# Configuration
readonly SCRIPT_NAME="${0##*/}"
readonly TMP_DIR="${TMPDIR:-/tmp}"
readonly TMP_FILE="$(mktemp "${TMP_DIR}/dev-tools-update.XXXXXX")"
readonly FORMULA_FILE="Formula/dev-tools.rb"
readonly MAX_CACHE_AGE=86400  # 1 day in seconds

# Cleanup function
trap 'rm -f "$TMP_FILE" 2>/dev/null' EXIT

# Initialize variables
VERBOSE=false
FORCE=false

# Log function for verbose output
log() {
    if [[ "$VERBOSE" == true ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
    fi
}

# Error function
error() {
    echo "${SCRIPT_NAME}: error: $*" >&2
    exit 1
}

# Show help
show_help() {
    grep '^# ' -A 1000 <<'EOF' | tail -n +3 | sed 's/^# \(.*\)$/\1/'
brew-update.sh - A script to check and update dev-tools Homebrew formula

This script checks for updates to the dev-tools package and updates the Homebrew formula
if a newer version is available. It includes caching to avoid unnecessary checks.

Usage:
  ./brew-update.sh [options]

Options:
  -v, --verbose  Enable verbose output
  -f, --force    Force update check, ignoring cache
  -h, --help     Show this help message

Exit codes:
  0 - Success
  1 - Error in script execution
  2 - Missing required dependencies
  3 - Version check failed
EOF
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    
    if ! command -v brew &> /dev/null; then
        missing_deps+=("Homebrew (brew)")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_deps+=("jq")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Missing required dependencies: ${missing_deps[*]}. Please install them and try again."
        exit 2
    fi
}

# Compare version numbers
# Returns:
#   0 if versions are equal
#   1 if first version is greater
#   2 if second version is greater
compare_versions() {
    if [[ "$1" == "$2" ]]; then
        return 0
    fi
    
    local IFS=.
    local i ver1=($1) ver2=($2)
    
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    
    return 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Main execution
main() {
    log "Starting dev-tools update check"
    check_dependencies
    
    # Check if we should skip based on cache
    if [[ "$FORCE" != true && -f "$TMP_FILE" ]]; then
        local current_time file_mtime time_diff
        current_time=$(date +%s)
        file_mtime=$(stat -f "%m" "$TMP_FILE" 2>/dev/null || stat -c "%Y" "$TMP_FILE")
        time_diff=$((current_time - file_mtime))
        
        if [[ $time_diff -lt $MAX_CACHE_AGE ]]; then
            log "Skipping check (cache valid for $((MAX_CACHE_AGE - time_diff)) more seconds)"
            log "Last checked: $(date -r "$file_mtime")"
            return 0
        fi
    fi

    # Check if formula file exists
    if [[ ! -f "$FORMULA_FILE" ]]; then
        error "Formula file not found at $FORMULA_FILE"
    fi

    # Get current version from formula
    local current_version
    current_version=$(grep 'url.*dev-tools-' "$FORMULA_FILE" | sed -E 's/.*dev-tools-([0-9.]+)\.tgz.*/\1/')
    if [[ -z "$current_version" ]]; then
        error "Could not extract current version from $FORMULA_FILE"
    fi

    log "Current version in formula: $current_version"

    # Get latest version from brew
    local output latest_version
    log "Checking for updates using 'brew livecheck dev-tools'"
    
    if ! output=$(brew livecheck dev-tools 2>&1); then
        error "Failed to check for updates: $output"
    fi

    latest_version=$(echo "$output" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
    if [[ -z "$latest_version" ]]; then
        error "Could not extract latest version from brew output"
    fi

    log "Latest available version: $latest_version"

    # Compare versions
    compare_versions "$latest_version" "$current_version"
    local version_compare=$?

    if [[ $version_compare -eq 0 ]]; then
        log "dev-tools is already up to date (version $current_version)"
    elif [[ $version_compare -eq 1 ]]; then
        log "Upgrading dev-tools from $current_version to $latest_version"
        
        if ! brew upgrade dev-tools; then
            error "Failed to upgrade dev-tools"
        fi
        
        log "Successfully upgraded dev-tools to version $latest_version"
    else
        log "Current version ($current_version) is newer than latest available ($latest_version). This is unexpected."
        return 3
    fi

    # Update cache file
    if ! date > "$TMP_FILE"; then
        log "Warning: Could not update cache file $TMP_FILE"
    fi

    return 0
}

# Run the main function
main "$@"

exit $?