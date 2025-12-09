require "language/node"

class DevTools < Formula
  desc "KhulnaSoft Developer Tools - A collection of development utilities"
  homepage "https://khulnasoft.com"
  url "https://registry.npmjs.org/@khulnasoft.com/dev-tools/-/khulnasoft-dev-tools-1.10.0.tgz"
  sha256 "c8d3eae160a892e32837db3dcae515e843e5383fef52b8141940c8bcf8b6d59f"
  license "Proprietary"

  depends_on "node@24"

  def install
    # Install the npm package with all dependencies
    system "npm", "install", *Language::Node.local_npm_install_args, "--prefix", libexec, "@khulnasoft.com/dev-tools@#{version}"

    # Create wrapper scripts for the different command names
    (bin/"khulnasoft.com").write <<~EOS
      #!/bin/bash
      # Check for updates using brew-update.sh
      if command -v brew >/dev/null 2>&1; then
        # Find the brew-update.sh script in the tap directory
        TAP_DIR="$(brew --prefix)/Library/Taps/khulnasoft/homebrew-khulnasoft"
        if [[ -f "$TAP_DIR/brew-update.sh" ]]; then
          "$TAP_DIR/brew-update.sh"
        fi
      fi
      exec "#{libexec}/node_modules/@khulnasoft.com/dev-tools/cli/main.cjs" "$@"
    EOS

    (bin/"khulnasoft").write <<~EOS
      #!/bin/bash
      # Check for updates using brew-update.sh
      if command -v brew >/dev/null 2>&1; then
        # Find the brew-update.sh script in the tap directory
        TAP_DIR="$(brew --prefix)/Library/Taps/khulnasoft/homebrew-khulnasoft"
        if [[ -f "$TAP_DIR/brew-update.sh" ]]; then
          "$TAP_DIR/brew-update.sh"
        fi
      fi
      exec "#{libexec}/node_modules/@khulnasoft.com/dev-tools/cli/main.cjs" "$@"
    EOS

    chmod 0755, bin/"khulnasoft.com"
    chmod 0755, bin/"khulnasoft"
  end

  test do
    # Test that the CLI runs and shows help
    assert_match "Khulnasoft.com Dev Tools", shell_output("#{bin}/khulnasoft-dev-tools --help", 1)
  end
end