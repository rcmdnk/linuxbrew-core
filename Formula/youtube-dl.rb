class YoutubeDl < Formula
  desc "Download YouTube videos from the command-line"
  homepage "https://ytdl-org.github.io/youtube-dl/"
  url "https://github.com/ytdl-org/youtube-dl/releases/download/2020.01.01/youtube-dl-2020.01.01.tar.gz"
  sha256 "0ab06abce0eecf77b6ceed4c06613325ede4e72e1a6ff528be320277250a1b5d"

  head do
    url "https://github.com/ytdl-org/youtube-dl.git"
    depends_on "pandoc" => :build
  end

  bottle :unneeded

  def install
    system "make", "PREFIX=#{prefix}" if build.head?
    bin.install "youtube-dl"
    man1.install "youtube-dl.1"
    bash_completion.install "youtube-dl.bash-completion"
    zsh_completion.install "youtube-dl.zsh" => "_youtube-dl"
    fish_completion.install "youtube-dl.fish"
  end

  test do
    system "#{bin}/youtube-dl", "--simulate", "https://www.youtube.com/watch?v=he2a4xK8ctk"
    system "#{bin}/youtube-dl", "--simulate", "--yes-playlist", "https://www.youtube.com/watch?v=7FlzFH9xOF8&list=PLRuS3NbVmMIq4XypJdggVfUVJNRZjbfCR"
  end
end
