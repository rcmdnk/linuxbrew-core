class Git < Formula
  desc "Distributed revision control system"
  homepage "https://git-scm.com"
  url "https://www.kernel.org/pub/software/scm/git/git-2.24.1.tar.xz"
  sha256 "723f24dce8fdd621a308b6187553fce7d5244205c065fe0a3aebd0b7c3f88562"
  head "https://github.com/git/git.git", :shallow => false

  bottle do
    sha256 "2779f9cea861ef4d906093ac7b7255b3eeb7b6f76cbbc8407035bd3d3b80305d" => :catalina
    sha256 "423599ea4d93020e4ee33965bf53c0e629c1d5a16e59efc657b4c914d9f52bd0" => :mojave
    sha256 "ce56a6b4012a93bfee18cc5017788033c423bef5f732f3117dfa59b688b08b5c" => :high_sierra
    sha256 "4adc1fe4616371dc9c3daac692dbab0e84027cb1a0d4d352926a7a9427a7c825" => :x86_64_linux
  end

  depends_on "gettext"
  depends_on "pcre2"

  if !OS.mac? || MacOS.version < :yosemite
    depends_on "openssl@1.1"
    depends_on "curl"
    depends_on "expat"
    depends_on "zlib"
  end

  resource "html" do
    url "https://www.kernel.org/pub/software/scm/git/git-htmldocs-2.24.1.tar.xz"
    sha256 "8b4da79e7931c5156f3f994c6d8162c7ccb525ebd3f71e26ae8f8430db038403"
  end

  resource "man" do
    url "https://www.kernel.org/pub/software/scm/git/git-manpages-2.24.1.tar.xz"
    sha256 "27304ab2674d5ad623a0a72c22116cb47df4a611499a53aef5c7ec39a32cfefb"
  end

  resource "Net::SMTP::SSL" do
    url "https://cpan.metacpan.org/authors/id/R/RJ/RJBS/Net-SMTP-SSL-1.04.tar.gz"
    sha256 "7b29c45add19d3d5084b751f7ba89a8e40479a446ce21cfd9cc741e558332a00"
  end

  def install
    # If these things are installed, tell Git build system not to use them
    ENV["NO_FINK"] = "1"
    ENV["NO_DARWIN_PORTS"] = "1"
    ENV["NO_R_TO_GCC_LINKER"] = "1" # pass arguments to LD correctly
    ENV["PYTHON_PATH"] = which("python")
    ENV["PERL_PATH"] = which("perl")
    ENV["USE_LIBPCRE2"] = "1"
    ENV["INSTALL_SYMLINKS"] = "1"
    ENV["LIBPCREDIR"] = Formula["pcre2"].opt_prefix
    ENV["V"] = "1" # build verbosely

    perl_version = Utils.popen_read("perl --version")[/v(\d+\.\d+)(?:\.\d+)?/, 1]

    if OS.mac?
      ENV["PERLLIB_EXTRA"] = %W[
        #{MacOS.active_developer_dir}
        /Library/Developer/CommandLineTools
        /Applications/Xcode.app/Contents/Developer
      ].uniq.map do |p|
        "#{p}/Library/Perl/#{perl_version}/darwin-thread-multi-2level"
      end.join(":")
    end

    unless quiet_system ENV["PERL_PATH"], "-e", "use ExtUtils::MakeMaker"
      ENV["NO_PERL_MAKEMAKER"] = "1"
    end

    # Ensure we are using the correct system headers (for curl) to workaround
    # mismatched Xcode/CLT versions:
    # https://github.com/Homebrew/homebrew-core/issues/46466
    if MacOS.version == :mojave && MacOS::CLT.installed? && MacOS::CLT.provides_sdk?
      ENV["HOMEBREW_SDKROOT"] = MacOS::CLT.sdk_path(MacOS.version)
    end

    args = %W[
      prefix=#{prefix}
      sysconfdir=#{etc}
      CC=#{ENV.cc}
      CFLAGS=#{ENV.cflags}
      LDFLAGS=#{ENV.ldflags}
    ]
    args << "NO_TCLTK=1" if build.without? "tcl-tk"

    if !OS.mac? && MacOS.version < :yosemite
      openssl_prefix = Formula["openssl@1.1"].opt_prefix
      args += %W[NO_APPLE_COMMON_CRYPTO=1 OPENSSLDIR=#{openssl_prefix}]
    else
      args += %w[NO_OPENSSL=1 APPLE_COMMON_CRYPTO=1]
    end

    system "make", "install", *args

    git_core = libexec/"git-core"

    # Install the macOS keychain credential helper
    if OS.mac?
      cd "contrib/credential/osxkeychain" do
        system "make", "CC=#{ENV.cc}",
                       "CFLAGS=#{ENV.cflags}",
                       "LDFLAGS=#{ENV.ldflags}"
        git_core.install "git-credential-osxkeychain"
        system "make", "clean"
      end
    end

    # Generate diff-highlight perl script executable
    cd "contrib/diff-highlight" do
      system "make"
    end

    # Install the netrc credential helper
    cd "contrib/credential/netrc" do
      system "make", "test"
      git_core.install "git-credential-netrc"
    end

    # Install git-subtree
    cd "contrib/subtree" do
      system "make", "CC=#{ENV.cc}",
                     "CFLAGS=#{ENV.cflags}",
                     "LDFLAGS=#{ENV.ldflags}"
      git_core.install "git-subtree"
    end

    # install the completion script first because it is inside "contrib"
    bash_completion.install "contrib/completion/git-completion.bash"
    bash_completion.install "contrib/completion/git-prompt.sh"
    zsh_completion.install "contrib/completion/git-completion.zsh" => "_git"
    cp "#{bash_completion}/git-completion.bash", zsh_completion

    elisp.install Dir["contrib/emacs/*.el"]
    (share/"git-core").install "contrib"

    # We could build the manpages ourselves, but the build process depends
    # on many other packages, and is somewhat crazy, this way is easier.
    man.install resource("man")
    (share/"doc/git-doc").install resource("html")

    # Make html docs world-readable
    chmod 0644, Dir["#{share}/doc/git-doc/**/*.{html,txt}"]
    chmod 0755, Dir["#{share}/doc/git-doc/{RelNotes,howto,technical}"]

    # To avoid this feature hooking into the system OpenSSL, remove it
    if !OS.mac? && MacOS.version >= :yosemite
      rm "#{libexec}/git-core/git-imap-send"
    end

    # git-send-email needs Net::SMTP::SSL
    resource("Net::SMTP::SSL").stage do
      (share/"perl5").install "lib/Net"
    end

    # This is only created when building against system Perl, but it isn't
    # purged by Homebrew's post-install cleaner because that doesn't check
    # "Library" directories. It is however pointless to keep around as it
    # only contains the perllocal.pod installation file.
    rm_rf prefix/"Library/Perl"

    pod = Dir[lib/"*/*/perllocal.pod"][0]
    unless pod.nil?
      # Remove perllocal.pod, which conflicts with the perl formula.
      # I don't know why this issue doesn't affect Mac.
      rm_r Pathname.new(pod).dirname.dirname
    end

    # Set the macOS keychain credential helper by default
    # (as Apple's CLT's git also does this).
    (buildpath/"gitconfig").write <<~EOS
      [credential]
      \thelper = osxkeychain
    EOS
    etc.install "gitconfig" if OS.mac?
  end

  test do
    system bin/"git", "init"
    %w[haunted house].each { |f| touch testpath/f }

    # Test environment has no git configuration, which prevents commiting
    system bin/"git", "config", "user.email", "you@example.com"
    system bin/"git", "config", "user.name", "Your Name"

    system bin/"git", "add", "haunted", "house"
    system bin/"git", "commit", "-a", "-m", "Initial Commit"
    assert_equal "haunted\nhouse", shell_output("#{bin}/git ls-files").strip

    if OS.mac?
      # Check Net::SMTP::SSL was installed correctly.
      %w[foo bar].each { |f| touch testpath/f }
      system bin/"git", "add", "foo", "bar"
      system bin/"git", "commit", "-a", "-m", "Second Commit"
      assert_match "Authentication Required", shell_output(
        "#{bin}/git send-email --to=dev@null.com --smtp-server=smtp.gmail.com " \
        "--smtp-encryption=tls --confirm=never HEAD^ 2>&1", 255
      )
    end
  end
end
