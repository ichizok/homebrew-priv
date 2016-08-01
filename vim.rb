class Vim < Formula
  desc "Vi \"workalike\" with many additional features"
  homepage "http://www.vim.org/"
  # Get stable versions from hg repo instead of downloading an increasing
  # number of separate patches.
  patchlevel = 2136
  url "https://github.com/vim/vim.git", :tag => format("v7.4.%03d", patchlevel)
  version "7.4.#{patchlevel}"

  # We only have special support for finding depends_on :python, but not yet for
  # :ruby, :perl etc., so we use the standard environment that leaves the
  # PATH as the user has set it right now.
  env :std

  option "without-nls", "Build vim without National Language Support (translated messages, keymaps)"
  option "with-client-server", "Enable client/server mode"
  option "with-clpum", "Build vim with CLPUM option (http://h-east.github.io/vim)"

  LANGUAGES_OPTIONAL = %w[mzscheme perl python3 ruby tcl]
  LANGUAGES_DEFAULT  = %w[lua python]

  LANGUAGES_OPTIONAL.each do |language|
    option "with-#{language}", "Build vim with #{language} support"
  end
  LANGUAGES_DEFAULT.each do |language|
    option "without-#{language}", "Build vim without #{language} support"
  end

  depends_on "python" => :recommended
  depends_on "python3" => :optional
  depends_on "ruby" => :optional
  depends_on "lua" => :recommended
  depends_on "luajit" => :optional
  depends_on :x11 if build.with? "client-server"

  conflicts_with "ex-vi",
    :because => "vim and ex-vi both install bin/ex and bin/view"

  if build.with? "clpum"
    patch do
      url "https://github.com/vim/vim/compare/master...h-east:clpum.diff"
      sha256 "1727a92b9c6a45f2d16df1d46b37fee6b5c4c4241b276a7430df2713c8d1ee0f"
    end
  end

  def install
    ENV["LUA_PREFIX"] = HOMEBREW_PREFIX if build.with?("lua") || build.with?("luajit")
    ENV.append_to_cflags "-mtune=native"

    # vim doesn't require any Python package, unset PYTHONPATH.
    ENV.delete("PYTHONPATH")

    opts = []

    (LANGUAGES_OPTIONAL + LANGUAGES_DEFAULT).each do |language|
      opts << "--enable-#{language}interp=dynamic" if build.with? language
    end

    opts << "--disable-nls" if build.without? "nls"
    opts << "--enable-gui=no"

    if build.with? "client-server"
      opts << "--with-x"
    else
      opts << "--without-x"
    end

    if build.with? "luajit"
      opts << "--enable-luainterp=dynamic" if build.without? "lua"
      opts << "--with-luajit"
    end

    # XXX: Please do not submit a pull request that hardcodes the path
    # to ruby: vim can be compiled against 1.8.x or 1.9.3-p385 and up.
    # If you have problems with vim because of ruby, ensure a compatible
    # version is first in your PATH when building vim.

    # We specify HOMEBREW_PREFIX as the prefix to make vim look in the
    # the right place (HOMEBREW_PREFIX/share/vim/{vimrc,vimfiles}) for
    # system vimscript files. We specify the normal installation prefix
    # when calling "make install".
    system "./configure", "--prefix=#{HOMEBREW_PREFIX}",
                          "--mandir=#{man}",
                          "--enable-multibyte",
                          "--with-tlib=ncurses",
                          "--with-features=huge",
                          "--with-compiledby=Homebrew",
                          "--enable-fail-if-missing",
                          *opts

    # Replace `Cellar' paths by `Homebrew/opt' paths in config.mk
    inreplace "src/auto/config.mk" do |s|
      s.gsub! %r{#{HOMEBREW_CELLAR}/(.+?)/(?:.+?)/}, "#{HOMEBREW_PREFIX}/opt/\\1/"

      # Require Python's dynamic library, and needs to be built as a framework.
      # Help vim find Python's dynamic library as absolute path.
      if build.with? "python"
        s.gsub! /-DDYNAMIC_PYTHON_DLL=\\".*?\\"/,
          %(-DDYNAMIC_PYTHON_DLL=\'\"#{python_framework_path(2)}/Python\"\')
      end
      if build.with? "python3"
        s.gsub! /-DDYNAMIC_PYTHON3_DLL=\\".*?\\"/,
          %(-DDYNAMIC_PYTHON3_DLL=\'\"#{python_framework_path(3)}/Python\"\')
      end
    end

    system "make"
    # If stripping the binaries is enabled, vim will segfault with
    # statically-linked interpreters like ruby
    # http://code.google.com/p/vim/issues/detail?id=114&thanks=114&ts=1361483471
    system "make", "install", "prefix=#{prefix}", "STRIP=true"
  end

  def python_framework_path(v = nil)
    `python#{v}-config --exec-prefix`.chomp.gsub(%r{#{HOMEBREW_CELLAR}/(?:.+?)/(?:.+?)/}, "#{HOMEBREW_PREFIX}/")
  end

  test do
    # Simple test to check if Vim was linked to Python version in $PATH
    # if build.with? "python"
    #   vim_path = bin/"vim"
    #
    #   # Get linked framework using otool
    #   otool_output = `otool -L #{vim_path} | grep -m 1 Python`.gsub(/\(.*\)/, "").strip.chomp
    #
    #   # Expand the link and get the python exec path
    #   vim_framework_path = Pathname.new(otool_output).realpath.dirname.to_s.chomp
    #   system_framework_path = `python-config --exec-prefix`.chomp
    #
    #   assert_equal system_framework_path, vim_framework_path
    # end
  end
end
