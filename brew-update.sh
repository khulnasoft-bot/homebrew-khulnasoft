#!/usr/bin/env bash

# Enhanced dev-tools version checker with better error handling and features

# Configuration
TMP_FILE="${TMPDIR}/dev-tools-livecheck"
FORMULA_FILE="Formula/dev-tools.rb"
MAX_CACHE_AGE=86400  # 1 day in seconds

# Initialize variables
VERBOSE=false
FORCE=false

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
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Log function for verbose output
log() {
    if [[ "$VERBOSE" == true ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $*"
    fi
}

# Check if we should skip based on cache
if [[ "$FORCE" != true && -f "$TMP_FILE" ]]; then
    current_time=$(date +%s)
    file_mtime=$(stat -f "%m" "$TMP_FILE")
    time_diff=$((current_time - file_mtime))
    
    if [[ $time_diff -lt $MAX_CACHE_AGE ]]; then
        log "Skipping check (cache valid for $((MAX_CACHE_AGE - time_diff)) more seconds)"
        log "Last checked: $(date -r "$file_mtime")"
        exit 0
    fi
fi

# Check if formula file exists
if [[ ! -f "$FORMULA_FILE" ]]; then
    log "Error: Formula file not found at $FORMULA_FILE"
    exit 1
fi

# Get current version from formula
CURRENT_VERSION=$(grep 'url.*dev-tools-' "$FORMULA_FILE" | sed -E 's/.*dev-tools-([0-9.]+)\.tgz.*/\1/')
if [[ -z "$CURRENT_VERSION" ]]; then
    log "Error: Could not extract current version from $FORMULA_FILE"
    exit 1
fi

# Get latest version from brew
OUTPUT=$(brew livecheck dev-tools 2>&1)
if [[ $? -ne 0 ]]; then
    log "Error running brew livecheck:"
    echo "$OUTPUT" >&2
    exit 1
fi

LATEST_VERSION=$(echo "$OUTPUT" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
if [[ -z "$LATEST_VERSION" ]]; then
    log "Error: Could not extract latest version from brew output"
    exit 1
fi

log "Current version: $CURRENT_VERSION"
log "Latest version: $LATEST_VERSION"

# Upgrade if versions differ
if [[ "$LATEST_VERSION" != "$CURRENT_VERSION" ]]; then
    log "Upgrading dev-tools from $CURRENT_VERSION to $LATEST_VERSION"
    if ! brew upgrade dev-tools >/dev/null 2>&1; then
        log "Error upgrading dev-tools"
        exit 1
    fi
else
    log "dev-tools is already up to date"
fi

# Update cache file
if ! touch "$TMP_FILE"; then
    log "Warning: Could not update cache file $TMP_FILE"
fi

exit 0