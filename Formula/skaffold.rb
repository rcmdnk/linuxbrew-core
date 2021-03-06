class Skaffold < Formula
  desc "Easy and Repeatable Kubernetes Development"
  homepage "https://github.com/GoogleContainerTools/skaffold"
  url "https://github.com/GoogleContainerTools/skaffold.git",
      :tag      => "v1.1.0",
      :revision => "2f14d99fc5f81e3a52dd76d43cad8d014f150327"
  head "https://github.com/GoogleContainerTools/skaffold.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "58959ee3dfc8798704724d1fbc78431cb9c7f65993eeb79d9777e35667ad7ed4" => :catalina
    sha256 "f6e43b7276ab84965e172fbc65d4216dc75f5b40490a95e873fe174467fc5be0" => :mojave
    sha256 "fe31564bc2becd7d821c6b5520b3361c3355b85bf2ae8b0fec476f5ad38ec647" => :high_sierra
    sha256 "cf31ed673b4d06a2fff58c84890eb8a76f70883ac278fb13c6d1d1ab8066e408" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    dir = buildpath/"src/github.com/GoogleContainerTools/skaffold"
    dir.install buildpath.children - [buildpath/".brew_home"]
    cd dir do
      system "make"
      bin.install "out/skaffold"

      output = Utils.popen_read("#{bin}/skaffold completion bash")
      (bash_completion/"skaffold").write output

      output = Utils.popen_read("#{bin}/skaffold completion zsh")
      (zsh_completion/"_skaffold").write output

      prefix.install_metafiles
    end
  end

  test do
    output = shell_output("#{bin}/skaffold version --output {{.GitTreeState}}")
    assert_match "clean", output
  end
end
