class Topgrade < Formula
  desc "Upgrade all the things"
  homepage "https://github.com/r-darwish/topgrade"
  url "https://github.com/r-darwish/topgrade/archive/v3.7.1.tar.gz"
  sha256 "2f75d3315ac925d0735836ddee251446f78366060e801202cecd8ad76fe1ea08"

  bottle do
    cellar :any_skip_relocation
    sha256 "07fd2930e14600aebe6b76e14e3d31d7c1184cd46c7c3b602058f21abed70350" => :catalina
    sha256 "8ca38e391770a338bc58554afff8e08e42baab8d7a393a079543f5d11a1f983c" => :mojave
    sha256 "0ff77ad06ae5a3231fa61f1856eff477156d62643417978102dbd0b143c360a8" => :high_sierra
    sha256 "68525cb322620cfcc55b67d76f108b0bed88d94053c3e15d29292ceec04b1e19" => :x86_64_linux
  end

  depends_on "rust" => :build

  def install
    system "cargo", "install", "--locked", "--root", prefix, "--path", "."
  end

  test do
    # Configuraton path details: https://github.com/r-darwish/topgrade/blob/master/README.md#configuration-path
    # Sample config file: https://github.com/r-darwish/topgrade/blob/master/config.example.toml
    (testpath/"Library/Preferences/topgrade.toml").write <<~EOS
      # Additional git repositories to pull
      #git_repos = [
      #    "~/src/*/",
      #    "~/.config/something"
      #]
    EOS

    assert_match version.to_s, shell_output("#{bin}/topgrade --version")

    mkdir "#{ENV["HOME"]}/.config" if OS.linux?
    output = shell_output("#{bin}/topgrade -n")
    assert_match "Dry running: #{HOMEBREW_PREFIX}/bin/brew upgrade", output
    assert_not_match /\sSelf update\s/, output
  end
end
