class Tmux < Formula
  desc "Terminal multiplexer"
  homepage "https://tmux.github.io/"

  stable do
    url "https://github.com/tmux/tmux/releases/download/2.2/tmux-2.2.tar.gz"
    sha256 "bc28541b64f99929fe8e3ae7a02291263f3c97730781201824c0f05d7c8e19e4"

    patch do
      # required for the following unicode patch
      url "https://github.com/tmux/tmux/commit/d303e5.patch"
      sha256 "a3ae96b209254de9dc1f10207cc0da250f7d5ec771f2b5f5593c687e21028f67"
    end

    patch do
      # workaround for bug in system unicode library reporting negative width
      # for some valid characters
      url "https://github.com/tmux/tmux/commit/23fdbc.patch"
      sha256 "7ec4e7f325f836de5948c3f3b03bec6031d60a17927a5f50fdb2e13842e90c3e"
    end

    # Replace box-drawing characters from Unicode to VT100 ACS
    patch :DATA
  end

  head do
    url "https://github.com/tmux/tmux.git"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "pkg-config" => :build
  depends_on "libevent"

  resource "completion" do
    url "https://raw.githubusercontent.com/przepompownia/tmux-bash-completion/v0.0.1/completions/tmux"
    sha256 "a0905c595fec7f0258fba5466315d42d67eca3bd2d3b12f4af8936d7f168b6c6"
  end

  def install
    system "sh", "autogen.sh" if build.head?

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--sysconfdir=#{etc}"

    system "make", "install"

    pkgshare.install "example_tmux.conf"
    bash_completion.install resource("completion")
  end

  def caveats; <<-EOS.undent
    Example configuration has been installed to:
      #{opt_pkgshare}
    EOS
  end

  test do
    system "#{bin}/tmux", "-V"
  end
end

__END__
diff --git a/tty-acs.c b/tty-acs.c
--- a/tty-acs.c
+++ b/tty-acs.c
@@ -41,21 +41,21 @@ const struct tty_acs_entry tty_acs_table[] = {
 	{ 'g', "\302\261" },		/* plus/minus */
 	{ 'h', "\342\226\222" },	/* board of squares */
 	{ 'i', "\342\230\203" },	/* lantern symbol */
-	{ 'j', "\342\224\230" },	/* lower right corner */
-	{ 'k', "\342\224\220" },	/* upper right corner */
-	{ 'l', "\342\224\214" },	/* upper left corner */
-	{ 'm', "\342\224\224" },	/* lower left corner */
-	{ 'n', "\342\224\274" },	/* large plus or crossover */
+	{ 'j', "\033(0j\033(B" },	/* lower right corner */
+	{ 'k', "\033(0k\033(B" },	/* upper right corner */
+	{ 'l', "\033(0l\033(B" },	/* upper left corner */
+	{ 'm', "\033(0m\033(B" },	/* lower left corner */
+	{ 'n', "\033(0n\033(B" },	/* large plus or crossover */
 	{ 'o', "\342\216\272" },	/* scan line 1 */
 	{ 'p', "\342\216\273" },	/* scan line 3 */
-	{ 'q', "\342\224\200" },	/* horizontal line */
+	{ 'q', "\033(0q\033(B" },	/* horizontal line */
 	{ 'r', "\342\216\274" },	/* scan line 7 */
 	{ 's', "\342\216\275" },	/* scan line 9 */
-	{ 't', "\342\224\234" },	/* tee pointing right */
-	{ 'u', "\342\224\244" },	/* tee pointing left */
-	{ 'v', "\342\224\264" },	/* tee pointing up */
-	{ 'w', "\342\224\254" },	/* tee pointing down */
-	{ 'x', "\342\224\202" },	/* vertical line */
+	{ 't', "\033(0t\033(B" },	/* tee pointing right */
+	{ 'u', "\033(0u\033(B" },	/* tee pointing left */
+	{ 'v', "\033(0v\033(B" },	/* tee pointing up */
+	{ 'w', "\033(0w\033(B" },	/* tee pointing down */
+	{ 'x', "\033(0x\033(B" },	/* vertical line */
 	{ 'y', "\342\211\244" },	/* less-than-or-equal-to */
 	{ 'z', "\342\211\245" },	/* greater-than-or-equal-to */
 	{ '{', "\317\200" },   		/* greek pi */
