class Netpgp < Formula
  homepage "http://www.netpgp.com/"
  url "http://www.netpgp.com/src/netpgp-20140220.tar.gz"
  sha256 "76b854c97785bca26339b26282e373a56974c8b8aed3ab9ddcd23ae50969fb8f"
  version "3.99.17"

  depends_on "libressl"

  def install
    ENV.append "CPPFLAGS", "-I#{Formula["libressl"].opt_include}"
    ENV.append "LDFLAGS", "-L#{Formula["libressl"].opt_lib}"

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    system "#{bin}/netpgp", "--version"
  end
end
