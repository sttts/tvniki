class Tvniki < Formula
  desc "Educational programming environment with robot simulation"
  homepage "https://github.com/sttts/tvniki"
  url "https://github.com/sttts/tvniki/archive/refs/tags/v2.0.0.tar.gz"
  sha256 "c21c6027981fbf08a07830dac86c8f84aaa558bddf39b39ffe2df7a555f58c4d"
  license "MIT"
  head "https://github.com/sttts/tvniki.git", branch: "main"

  depends_on "fpc" => :build

  def install
    # Remove system Free Vision to avoid conflicts with bundled fv_utf8
    fv_system = "#{Formula["fpc"].lib}/fpc/#{Formula["fpc"].version}/units/#{Hardware::CPU.arch}-darwin/fv"
    rm_rf fv_system if Dir.exist?(fv_system)

    # Determine version from git tags
    version = Utils.safe_popen_read("git", "describe", "--tags", "--match", "v[0-9]*", "--dirty").strip
    version = version.sub(/^v/, "") # Remove leading 'v'

    system "make"
    bin.install "tvniki"
    bin.install "nikic"

    # Install data files
    pkgshare.install "hilfe.hlp"
    pkgshare.install Dir["*.rob"]

    # Record version for reference
    (pkgshare/"VERSION").write version
  end

  def caveats
    <<~EOS
      Example world files and help are installed in:
        #{pkgshare}

      Run from a directory containing .rob world files, or copy examples:
        cp #{pkgshare}/*.rob .
        cp #{pkgshare}/hilfe.hlp .
    EOS
  end

  test do
    assert_predicate bin/"tvniki", :executable?
  end
end
