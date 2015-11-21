class Tmux < Formula
  desc "Terminal multiplexer"
  homepage "https://tmux.github.io/"

  stable do
    url "https://github.com/tmux/tmux/releases/download/2.1/tmux-2.1.tar.gz"
    sha256 "31564e7bf4bcef2defb3cb34b9e596bd43a3937cad9e5438701a81a5a9af6176"

    patch do
      # This fixes the Tmux 2.1 update that broke the ability to use select-pane [-LDUR]
      # to switch panes when in a maximized pane https://github.com/tmux/tmux/issues/150#issuecomment-149466158
      url "https://github.com/tmux/tmux/commit/a05c27a7e1c4d43709817d6746a510f16c960b4b.diff"
      sha256 "2a60a63f0477f2e3056d9f76207d4ed905de8a9ce0645de6c29cf3f445bace12"
    end

    patch do
      # This fixes a problems with displaying Ambiguous-width, Japanese Dakuten and Handakuten signs
      # part of https://gist.github.com/waltarix/1399751
      url "https://gist.githubusercontent.com/waltarix/1399751/raw/695586fad1664f500df9a22622a6ff52c262c3eb/tmux-ambiguous-width-cjk.patch"
      sha256 "943a1d99dc76c3bdde82b24ecca732f0410c3e58dba39396cc7f87c9635bc37c"
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

  def install
    system "sh", "autogen.sh" if build.head?

    system "./configure", "--disable-dependency-tracking",
                          "--prefix=#{prefix}",
                          "--sysconfdir=#{etc}"

    system "make", "install"

    bash_completion.install "examples/bash_completion_tmux.sh" => "tmux"
    pkgshare.install "examples"
  end

  def caveats; <<-EOS.undent
    Example configurations have been installed to:
      #{opt_pkgshare}/examples
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
