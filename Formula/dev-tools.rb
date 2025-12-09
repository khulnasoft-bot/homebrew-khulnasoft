class DevTools < Formula
  desc "KhulnaSoft Developer Tools - A collection of development utilities"
  homepage "https://khulnasoft.com"
  url "https://registry.npmjs.org/@khulnasoft.com/dev-tools/-/khulnasoft-dev-tools-1.10.0.tgz"
  sha256 "c8d3eae160a892e32837db3dcae515e843e5383fef52b8141940c8bcf8b6d59f"
  license "Proprietary"

  depends_on "node"

  def install
    # Install the package globally
    system "npm", "install", "-g", "--prefix", libexec, "--ignore-scripts", "--no-package-lock", "--no-audit", "--no-fund", "--no-update-notifier", "--no-audit"

    # Create a wrapper script
    (bin/"dev-tools").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/bin/dev-tools" "$@"
    EOS

    # Make the wrapper script executable
    chmod "+x", bin/"dev-tools"
  end

  test do
    # Simple test to verify the binary works
    assert_match "1.10.0", shell_output("#{bin}/dev-tools --version").strip
  end

  def post_install
    # Clean up any leftover files
    system "npm", "cache", "clean", "--force"
  end

  def caveats
    <<~EOS
      KhulnaSoft Dev Tools has been installed. You can now use the 'dev-tools' command.
      
      To get started, run:
        dev-tools --help
      
      For more information, visit:
        https://khulnasoft.com/docs/dev-tools
    EOS
  end
end
