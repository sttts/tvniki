class Tvniki < Formula
  desc "Educational programming environment with robot simulation"
  homepage "https://github.com/sttts/tvniki"
  license "MIT"
  head "https://github.com/sttts/tvniki.git", branch: "main"
  url "https://github.com/sttts/tvniki.git", tag: "v2.0.0"

  depends_on "fpc" => :build

  def install
    # Initialize submodules (fv_utf8)
    system "git", "submodule", "update", "--init", "--recursive"

    # Remove system Free Vision to avoid conflicts with bundled fv_utf8
    fv_system = "#{Formula["fpc"].lib}/fpc/#{Formula["fpc"].version}/units/#{Hardware::CPU.arch}-darwin/fv"
    rm_rf fv_system if Dir.exist?(fv_system)

    # Determine version: use git describe for HEAD, formula version for stable
    if build.head?
      ver = Utils.safe_popen_read("git", "describe", "--tags", "--match", "v[0-9]*", "--dirty").strip
      ver = ver.sub(/^v/, "")
    else
      ver = version.to_s
    end

    system "make"
    bin.install "tvniki"
    bin.install "nikic"

    # Install data files
    pkgshare.install "hilfe.hlp"
    pkgshare.install Dir["*.rob"]

    # Record version for reference
    (pkgshare/"VERSION").write ver
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
