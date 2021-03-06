class Folly < Formula
  desc "Collection of reusable C++ library artifacts developed at Facebook"
  homepage "https://github.com/facebook/folly"
  url "https://github.com/facebook/folly/archive/v2020.01.06.00.tar.gz"
  sha256 "d1870b6c578dd671b7d8c545cb7da1cbf2b80b4ce0ffa4fca3bca2b3b83f4ba3"
  head "https://github.com/facebook/folly.git"

  bottle do
    cellar :any
    sha256 "281d35a3634d5a84cc7fcc924c4ac98faf086e1fa47fff1e5898574400a7c146" => :catalina
    sha256 "14f2e203ee7d7027492a376c37f2fdbfe8ed5e7f7e731aaabf1d3e6c6f652a6d" => :mojave
    sha256 "d5bb3c7ad3ebb00abc3e11e33cf64c83b4e7b6722e151d2e74353baf5b107d86" => :high_sierra
    sha256 "4780d7b24a702a21ad555ba1450861d14fccf0dd7088ac99e2c0492d85098bb1" => :x86_64_linux
  end

  depends_on "cmake" => :build
  depends_on "pkg-config" => :build
  depends_on "boost"
  depends_on "double-conversion"
  depends_on "fmt"
  depends_on "gflags"
  depends_on "glog"
  depends_on "libevent"
  depends_on "lz4"

  # https://github.com/facebook/folly/issues/966
  depends_on :macos => :high_sierra if OS.mac?

  depends_on "openssl@1.1"
  depends_on "snappy"
  depends_on "xz"
  depends_on "zstd"
  depends_on "jemalloc" unless OS.mac?

  uses_from_macos "python"

  def install
    mkdir "_build" do
      args = std_cmake_args
      args << "-DFOLLY_USE_JEMALLOC=#{OS.mac? ? "OFF" : "ON"}"

      system "cmake", "..", *args, "-DBUILD_SHARED_LIBS=ON", ("-DCMAKE_POSITION_INDEPENDENT_CODE=ON" unless OS.mac?)
      system "make"
      system "make", "install"

      system "make", "clean"
      system "cmake", "..", *args, "-DBUILD_SHARED_LIBS=OFF"
      system "make"
      lib.install "libfolly.a", "folly/libfollybenchmark.a"
    end
  end

  test do
    (testpath/"test.cc").write <<~EOS
      #include <folly/FBVector.h>
      int main() {
        folly::fbvector<int> numbers({0, 1, 2, 3});
        numbers.reserve(10);
        for (int i = 4; i < 10; i++) {
          numbers.push_back(i * 2);
        }
        assert(numbers[6] == 12);
        return 0;
      }
    EOS
    system ENV.cxx, "-std=c++14", "test.cc", "-I#{include}", "-L#{lib}",
                    "-lfolly", "-o", "test"
    system "./test"
  end
end
