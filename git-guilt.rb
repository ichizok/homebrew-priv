class GitGuilt < Formula
  desc "Quilt on top of git"
  homepage "http://repo.or.cz/guilt.git"

  stable do
    url "http://repo.or.cz/guilt.git", :tag => "v0.36"
  end

  head do
    url "http://repo.or.cz/guilt.git", :branch => "master"
  end

  depends_on "git"
  depends_on "gnu-sed"
  depends_on "coreutils"
  #depends_on "asciidoc"
  #depends_on "xmlto"

  def install
    system "make", "PREFIX=#{prefix}", "install"
    #system "make", "-C", "Documentation", "PREFIX=#{prefix}", "install"
  end

  test do
    #system "make", "-C", "regression"
  end
end

