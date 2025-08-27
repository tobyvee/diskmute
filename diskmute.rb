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
  end
end