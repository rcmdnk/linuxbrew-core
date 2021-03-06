class Iozone < Formula
  desc "File system benchmark tool"
  homepage "http://www.iozone.org/"
  url "http://www.iozone.org/src/current/iozone3_488.tar"
  sha256 "960265163d93f15f7ad352f726d4837c5dd794fff357c743fdb56cbcf4abca04"

  bottle do
    cellar :any_skip_relocation
    sha256 "427c5f658ea923ff3ad2fc78285d833019ec97f17acd4c7d390014fa80fc2968" => :catalina
    sha256 "d912590bbafdfbcfdf6d353fd21adece2362e4107db91178efbf8a647e068c6f" => :mojave
    sha256 "8eb647b295cabacbd9cc698e74354f0c82a8205c35d5ba48bbbfbecb590b50bc" => :high_sierra
    sha256 "52bf9281b8f153a3950ff586178e0511c88dbc92ea68aac1e79d31f9c0b235f4" => :x86_64_linux
  end

  def install
    cd "src/current" do
      system "make", OS.mac? ? "macosx" : "linux", "CC=#{ENV.cc}"
      bin.install "iozone"
      pkgshare.install %w[Generate_Graphs client_list gengnuplot.sh gnu3d.dem
                          gnuplot.dem gnuplotps.dem iozone_visualizer.pl
                          report.pl]
    end
    man1.install "docs/iozone.1"
  end

  test do
    assert_match "File size set to 16384 kB",
      shell_output("#{bin}/iozone -I -s 16M")
  end
end
