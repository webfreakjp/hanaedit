class Hanaedit < Formula
  desc "macOS native AppKit text editor"
  homepage "https://github.com/webfreakjp/hanaedit"
  url "https://github.com/webfreakjp/hanaedit/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_SHA256"
  license "MIT"

  depends_on :macos
  depends_on macos: :ventura

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/HanaEdit" => "hanaedit"
  end

  test do
    assert_match "HanaEdit 0.1.0", shell_output("#{bin}/hanaedit --version")
  end
end
