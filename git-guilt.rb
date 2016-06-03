class GitGuilt < Formula
  desc "Quilt on top of git"
  homepage "http://repo.or.cz/guilt.git"

  stable do
    url "http://repo.or.cz/guilt.git", :tag => "v0.36"
    patch :DATA
  end

  head do
    url "http://repo.or.cz/guilt.git", :branch => "master"
    patch :DATA
  end

  resource "man" do
    url "https://github.com/ichizok/guilt-manpages/releases/download/v0.36/guilt-manpages-v0.36.tar.gz"
    sha256 "e73e7b66cbe1899476f1312dcee4eeeaae7ce8e1ce11bd0b9186ff6e7c8da876"
  end

  depends_on "git"
  depends_on "gnu-sed"
  depends_on "coreutils"

  def install
    system "make", "PREFIX=#{prefix}", "install"
    man.install resource("man")
  end

  test do
    #system "make", "-C", "regression"
  end
end

__END__
diff --git a/guilt-help b/guilt-help
--- a/guilt-help
+++ b/guilt-help
@@ -34,7 +34,7 @@ case $# in
 		;;
 esac
 
-MANDIR=`dirname $0`/../man
+MANDIR=`dirname $0`/../share/man
 MANDIR=`(cd "$MANDIR"; pwd)`
 exec man -M "$MANDIR" "$page"
 
