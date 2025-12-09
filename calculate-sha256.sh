#!/usr/bin/env bash

# Enhanced script to calculate SHA256 hash for KhulnaSoft Dev Tools npm package
# Generates the checksum needed for Homebrew formula with better error handling and features

set -euo pipefail  # Enable strict mode

# Configuration
VERSION="1.10.0"
PACKAGE_NAME="@khulnasoft.com/dev-tools"
TARBALL="khulnasoft-dev-tools-${VERSION}.tgz"
REGISTRY_URL="https://registry.npmjs.org"
PACKAGE_URL="${REGISTRY_URL}/${PACKAGE_NAME}/-/${TARBALL}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to display error messages
error() {
    echo -e "${RED}Error: $*${NC}" >&2
    exit 1
}

# Function to display success messages
success() {
    echo -e "${GREEN}$*${NC}"
}

# Main execution
echo "Calculating SHA256 hash for ${PACKAGE_NAME} v${VERSION}..."

# Download the package
if ! curl -sSL -o "${TARBALL}" "${PACKAGE_URL}"; then
    error "Failed to download package from ${PACKAGE_URL}"
fi

# Verify the downloaded file exists
if [[ ! -f "${TARBALL}" ]]; then
    error "Downloaded file ${TARBALL} not found"
fi

# Calculate SHA256 hash
if ! SHA256_HASH=$(shasum -a 256 "${TARBALL}" | awk '{print $1}'); then
    error "Failed to calculate SHA256 hash"
fi

# Output the result
success "Successfully calculated SHA256 hash:"
echo "sha256 \"${SHA256_HASH}\""

# Clean up
if ! rm -f "${TARBALL}"; then
    error "Failed to remove temporary file ${TARBALL}"
fi

success "Done."
exit 0