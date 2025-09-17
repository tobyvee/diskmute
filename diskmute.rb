class Diskmute < Formula
  desc "Remove system files and metadata from mounted volumes on macOS"
  homepage "https://github.com/tobyvee/diskmute"
  url "https://github.com/tobyvee/diskmute/archive/v1.0.0.tar.gz"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  license "MIT"

  def install
    bin.install "diskmute.sh" => "diskmute"
  end

  test do
    system "#{bin}/diskmute", "--version"
    system "#{bin}/diskmute", "--help"
    
    # Test that it fails appropriately without root
    assert_match "This script must be run as root", shell_output("#{bin}/diskmute /tmp 2>&1", 1)
  end
end