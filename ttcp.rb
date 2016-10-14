class Ttcp < Formula
  homepage "http://www.pcausa.com/Utilities/pcattcp.htm"
  url "http://www.pcausa.com/Utilities/pcattcp/UnixTTCP.zip"
  sha256 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
  version "1.12"

  def install
    inreplace "makefile", "gcc", "#{ENV.cc} #{ENV.cflags}"

    system "make", "ttcp"
    bin.install "ttcp"
  end

  test do
    #
  end
end
