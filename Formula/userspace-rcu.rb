class UserspaceRcu < Formula
  desc "Library for userspace RCU (read-copy-update)"
  homepage "https://liburcu.org"
  url "https://lttng.org/files/urcu/userspace-rcu-0.11.1.tar.bz2"
  sha256 "92b9971bf3f1c443edd6c09e7bf5ff3b43531e778841f16377a812c8feeb3350"

  bottle do
    cellar :any_skip_relocation
    sha256 "9775f683e726589140c2c5e7ceb3c0c050ea40315275eb093f25f866501e5626" => :catalina
    sha256 "2b70670f8a4a37cfd7a60a3a5c46908556ec7fb78f9992dbe73f022154c601fe" => :mojave
    sha256 "c1923cecf3ed76e60ac2980a703817789dbc82315aec3fd84d49b528ce28da80" => :high_sierra
    sha256 "70f936b43372e4596cdfa543f1b3a42aa01a4d8ca93fe2a38e0b8e6994aa65de" => :sierra
    sha256 "955e4f461ac538085eb3783994a65fd8e01fd412afd0b74cfba22c7afe906283" => :x86_64_linux
  end

  def install
    # Enforce --build to work around broken upstream detection
    # https://bugs.lttng.org/issues/578#note-1
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --build=x86_64
    ]

    system "./configure", *args
    system "make"
    system "make", "install"
  end

  test do
    cp_r "#{doc}/examples", testpath
    system "make", "-C", "examples"
  end
end
