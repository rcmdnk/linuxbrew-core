class Istioctl < Formula
  desc "Istio configuration command-line utility"
  homepage "https://github.com/istio/istio"
  url "https://github.com/istio/istio.git",
      :tag      => "1.4.3",
      :revision => "17f6bfc3d7121ad527c2d617ffc27c758d6a7241"

  bottle do
    cellar :any_skip_relocation
    sha256 "661348a8ce82de4df9817207357d1d600b97c6feaa76db63e6f38e7a297abdd4" => :catalina
    sha256 "661348a8ce82de4df9817207357d1d600b97c6feaa76db63e6f38e7a297abdd4" => :mojave
    sha256 "661348a8ce82de4df9817207357d1d600b97c6feaa76db63e6f38e7a297abdd4" => :high_sierra
    sha256 "1089b1a71faa3d9d8f527ad84586d62c51f6228913987348c9993a9cd5fdf5ca" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    ENV["TAG"] = version.to_s
    ENV["ISTIO_VERSION"] = version.to_s
    ENV["HUB"] = "docker.io/istio"

    srcpath = buildpath/"src/istio.io/istio"
    if OS.mac?
      outpath = buildpath/"out/darwin_amd64/release"
    else
      outpath = buildpath/"out/linux_amd64/release"
    end
    srcpath.install buildpath.children

    cd srcpath do
      system "make", "istioctl"
      prefix.install_metafiles
      bin.install outpath/"istioctl"
    end
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/istioctl version --remote=false")
  end
end
