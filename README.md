# Homebrew Khulnasoft

A Homebrew tap for the Khulnasoft dev-tools package.

## Features

- Automated formula updates
- Multi-OS support (macOS and Linux)
- Caching for faster builds
- Security scanning

## Prerequisites

- [Homebrew](https://brew.sh/) installed
- GitHub repository with write access

## Setup

1. **Fork this repository**
2. **Configure secrets** in your repository settings:
   - `GITHUB_TOKEN` (automatically provided)

## Workflows

### Update Workflow

Automatically checks for updates to the dev-tools package and updates the formula.

**Trigger:**
- Scheduled (every 6 hours)
- Manual trigger via GitHub Actions UI

**Features:**
- Concurrent run prevention
- Matrix testing (macOS and Linux)
- Caching for faster builds
- GitHub commit status updates

### Publish Workflow

Handles PR merging and bottle pulling from Homebrew.

**Trigger:**
- PRs with the `pr-pull` label

## Manual Updates

To manually trigger an update:

```bash
# Basic update check
./brew-update.sh

# Force update (ignore cache)
./brew-update.sh --force

# Enable verbose output
./brew-update.sh --verbose

# Show help
./brew-update.sh --help
```

## Security

The workflow includes:
- Dependabot for dependency updates
- CodeQL for code scanning
- Caching with proper scoping
- GitHub's built-in secret protection

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

[Specify your license here]