class R < Formula
  desc "Software environment for statistical computing"
  homepage "https://www.r-project.org/"
  url "https://cran.r-project.org/src/base/R-3/R-3.6.2.tar.gz"
  sha256 "bd65a45cddfb88f37370fbcee4ac8dd3f1aebeebe47c2f968fd9770ba2bbc954"

  bottle do
    sha256 "d1d1c643d70a82eae3d702af54502b1446584d560c0e9f59d4814e5598245069" => :catalina
    sha256 "fcd1dc2749a1b8af36f2fb71ced861ae29edaba1b5924ec3944e25b1227ad142" => :mojave
    sha256 "b062cbf25e5ed5ea0f27e8b9b7a967ed087876d7b220261e5b152c230aab949a" => :high_sierra
    sha256 "da0cd9fadf7f325e3c24b7995941610a8f0c6c5544b16752de3c38d4da9564c8" => :x86_64_linux
  end

  depends_on "pkg-config" => :build
  depends_on "gcc" # for gfortran
  depends_on "gettext"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "openblas"
  depends_on "pcre"
  depends_on "readline"
  depends_on "xz"

  unless OS.mac?
    depends_on "cairo"
    depends_on "curl"
    depends_on "pango"
    depends_on "linuxbrew/xorg/xorg"
  end

  # needed to preserve executable permissions on files without shebangs
  skip_clean "lib/R/bin"

  resource "gss" do
    url "https://cloud.r-project.org/src/contrib/gss_2.1-10.tar.gz", :using => :nounzip
    mirror "https://mirror.las.iastate.edu/CRAN/src/contrib/gss_2.1-10.tar.gz"
    sha256 "26c47ecae6a9b7854a1b531c09f869cf8b813462bd8093e3618e1091ace61ee2"
  end

  def install
    # Fix dyld: lazy symbol binding failed: Symbol not found: _clock_gettime
    if MacOS.version == "10.11" && MacOS::Xcode.installed? &&
       MacOS::Xcode.version >= "8.0"
      ENV["ac_cv_have_decl_clock_gettime"] = "no"
    end

    args = [
      "--prefix=#{prefix}",
      "--enable-memory-profiling",
      "--with-lapack",
      "--enable-R-shlib",
      "--disable-java",
      "--with-blas=-L#{Formula["openblas"].opt_lib} -lopenblas",
    ]

    # don't remember Homebrew's sed shim
    args << "SED=/usr/bin/sed" if File.exist?("/usr/bin/sed")

    unless OS.mac?
      args << "--libdir=#{lib}" # avoid using lib64 on CentOS
      args << "--with-cairo"

      # If LDFLAGS contains any -L options, configure sets LD_LIBRARY_PATH to
      # search those directories. Remove -LHOMEBREW_PREFIX/lib from LDFLAGS.
      ENV.remove "LDFLAGS", "-L#{HOMEBREW_PREFIX}/lib"
    end

    # Help CRAN packages find gettext and readline
    ["gettext", "readline"].each do |f|
      ENV.append "CPPFLAGS", "-I#{Formula[f].opt_include}"
      ENV.append "LDFLAGS", "-L#{Formula[f].opt_lib}"
    end

    system "./configure", *args
    system "make"
    ENV.deparallelize do
      system "make", "install"
    end

    cd "src/nmath/standalone" do
      system "make"
      ENV.deparallelize do
        system "make", "install"
      end
    end

    r_home = lib/"R"

    # make Homebrew packages discoverable for R CMD INSTALL
    inreplace r_home/"etc/Makeconf" do |s|
      s.gsub!(/^CPPFLAGS =.*/, "\\0 -I#{HOMEBREW_PREFIX}/include")
      s.gsub!(/^LDFLAGS =.*/, "\\0 -L#{HOMEBREW_PREFIX}/lib")
      s.gsub!(/.LDFLAGS =.*/, "\\0 $(LDFLAGS)")
    end

    include.install_symlink Dir[r_home/"include/*"]
    lib.install_symlink Dir[r_home/"lib/*"]

    # avoid triggering mandatory rebuilds of r when gcc is upgraded
    inreplace lib/"R/etc/Makeconf",
      Formula["gcc"].prefix.realpath,
      Formula["gcc"].opt_prefix,
      OS.mac?
  end

  def post_install
    short_version =
      `#{bin}/Rscript -e 'cat(as.character(getRversion()[1,1:2]))'`.strip
    site_library = HOMEBREW_PREFIX/"lib/R/#{short_version}/site-library"
    site_library.mkpath
    ln_s site_library, lib/"R/site-library"
  end

  test do
    dylib_ext = OS.mac? ? ".dylib" : ".so"
    assert_equal "[1] 2", shell_output("#{bin}/Rscript -e 'print(1+1)'").chomp
    assert_equal dylib_ext, shell_output("#{bin}/R CMD config DYLIB_EXT").chomp

    testpath.install resource("gss")
    system bin/"R", "CMD", "INSTALL", "--library=.", Dir["gss*"].first
    assert_predicate testpath/"gss/libs/gss.so", :exist?,
                     "Failed to install gss package"
  end
end
