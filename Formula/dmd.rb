class Dmd < Formula
  desc "D programming language compiler for macOS"
  homepage "https://dlang.org/"

  stable do
    url "https://github.com/dlang/dmd/archive/v2.090.0.tar.gz"
    sha256 "ab591e45163b2653a3253d0fe3a58f3e40c9c43a1b466114d10c7e67ee569fdc"

    resource "druntime" do
      url "https://github.com/dlang/druntime/archive/v2.090.0.tar.gz"
      sha256 "675303e9a773ebd6e91c3ae60108f140780c8ffd5abf4c3df52876b3bebcaa64"
    end

    resource "phobos" do
      url "https://github.com/dlang/phobos/archive/v2.090.0.tar.gz"
      sha256 "c7f709843b0ee50da53e138df0b61eae2e59550df0bf0adf0a8d0482f715cb4f"
    end

    resource "tools" do
      url "https://github.com/dlang/tools/archive/v2.090.0.tar.gz"
      sha256 "84338fd55c82051ab103cbd165f277d2f855c6b5ce12305ab63968d9316ffb7c"
    end
  end

  bottle do
    sha256 "12a52d3553afe09f3a12a2e40c4f27bb2910eacdf6003d9866527550187c9857" => :mojave
    sha256 "6f9f0daa60dd0e44bd5d6cc47dbf4ea96487f5e51338177447691d151db7775c" => :high_sierra
    sha256 "80e8eaaa3931f7cbb56b467e16c09e447b3da7be29cbb2a133120937e8fdc998" => :x86_64_linux
  end

  head do
    url "https://github.com/dlang/dmd.git"

    resource "druntime" do
      url "https://github.com/dlang/druntime.git"
    end

    resource "phobos" do
      url "https://github.com/dlang/phobos.git"
    end

    resource "tools" do
      url "https://github.com/dlang/tools.git"
    end
  end

  unless OS.mac?
    depends_on "unzip" => :build
    depends_on "xz" => :build
  end

  def install
    # DMD defaults to v2.088.0 to bootstrap as of DMD 2.090.0
    # On MacOS Catalina, a version < 2.087.1 would not work due to TLS related symbols missing

    make_args = %W[
      INSTALL_DIR=#{prefix}
      MODEL=64
      BUILD=release
      -f posix.mak
    ]

    dmd_make_args = %W[
      SYSCONFDIR=#{etc}
      TARGET_CPU=X86
      AUTO_BOOTSTRAP=1
      ENABLE_RELEASE=1
    ]

    system "make", *dmd_make_args, *make_args

    make_args.unshift "DMD_DIR=#{buildpath}", "DRUNTIME_PATH=#{buildpath}/druntime", "PHOBOS_PATH=#{buildpath}/phobos"

    (buildpath/"druntime").install resource("druntime")
    system "make", "-C", "druntime", *make_args

    (buildpath/"phobos").install resource("phobos")
    system "make", "-C", "phobos", "VERSION=#{buildpath}/VERSION", *make_args

    resource("tools").stage do
      inreplace "posix.mak", "install: $(TOOLS) $(CURL_TOOLS)", "install: $(TOOLS) $(ROOT)/dustmite"
      system "make", "install", *make_args
    end

    os = OS.mac? ? "osx" : "linux"
    bin.install "generated/#{os}/release/64/dmd"
    pkgshare.install "samples"
    man.install Dir["docs/man/*"]

    (include/"dlang/dmd").install Dir["druntime/import/*"]
    cp_r ["phobos/std", "phobos/etc"], include/"dlang/dmd"
    if OS.mac?
      lib.install Dir["druntime/**/libdruntime.*", "phobos/**/libphobos2.a"]
    else
      lib.install Dir["druntime/**/libdruntime.*", "phobos/**/libphobos2.*"]
    end

    (buildpath/"dmd.conf").write <<~EOS
      [Environment]
      DFLAGS=-I#{opt_include}/dlang/dmd -L-L#{opt_lib}
    EOS
    etc.install "dmd.conf"
  end

  # Previous versions of this formula may have left in place an incorrect
  # dmd.conf.  If it differs from the newly generated one, move it out of place
  # and warn the user.
  def install_new_dmd_conf
    conf = etc/"dmd.conf"

    # If the new file differs from conf, etc.install drops it here:
    new_conf = etc/"dmd.conf.default"
    # Else, we're already using the latest version:
    return unless new_conf.exist?

    backup = etc/"dmd.conf.old"
    opoo "An old dmd.conf was found and will be moved to #{backup}."
    mv conf, backup
    mv new_conf, conf
  end

  def post_install
    install_new_dmd_conf
  end

  test do
    system bin/"dmd", pkgshare/"samples/hello.d"
    system "./hello"
  end
end
