require "language/node"

class AwsCdk < Formula
  desc "AWS Cloud Development Kit - framework for defining AWS infra as code"
  homepage "https://github.com/aws/aws-cdk"
  url "https://registry.npmjs.org/aws-cdk/-/aws-cdk-1.20.0.tgz"
  sha256 "30b74d4ff6f9f90c618da577fc56c6ff6ee1f6efca849f51653bb74c453c9c75"

  bottle do
    cellar :any_skip_relocation
    sha256 "c2ddbda5e79af6b6fd2d10b253381631518b6d9b9e3b01249f7809fb8886090d" => :catalina
    sha256 "70350256c55942a9b4584d6d4d556789b712b35ba3fe1d3f17fdb12a3db77c65" => :mojave
    sha256 "c890f8997c90dd4b4b1b547506840e08bba76f7706f72ffed8d14077decb6485" => :high_sierra
    sha256 "e900898ea5d14866978f97a0a60b78c5e14c3e8c86cfefebfa258b1dd5f0c6ce" => :x86_64_linux
  end

  depends_on "node"

  def install
    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    mkdir "testapp"
    cd testpath/"testapp"
    shell_output("#{bin}/cdk init app --language=javascript")
    list = shell_output("#{bin}/cdk list")
    cdkversion = shell_output("#{bin}/cdk --version")
    assert_match "TestappStack", list
    assert_match version.to_s, cdkversion
  end
end
