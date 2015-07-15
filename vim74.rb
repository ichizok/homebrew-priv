class Vim74 < Formula
  homepage "http://www.vim.org/"
  # Get stable versions from hg repo instead of downloading an increasing
  # number of separate patches.
  patchlevel = 764
  url "https://vim.googlecode.com/hg/", :tag => format("v7-4-%03d", patchlevel)
  version "7.4.#{patchlevel}"

  # We only have special support for finding depends_on :python, but not yet for
  # :ruby, :perl etc., so we use the standard environment that leaves the
  # PATH as the user has set it right now.
  env :std

  option "without-nls", "Build vim without National Language Support (translated messages, keymaps)"
  option "with-client-server", "Enable client/server mode"

  LANGUAGES_OPTIONAL = %w[lua mzscheme perl python3 tcl]
  LANGUAGES_DEFAULT  = %w[ruby python]

  LANGUAGES_OPTIONAL.each do |language|
    option "with-#{language}", "Build vim with #{language} support"
  end
  LANGUAGES_DEFAULT.each do |language|
    option "without-#{language}", "Build vim without #{language} support"
  end

  depends_on :python => :recommended
  depends_on :python3 => :optional
  depends_on "lua" => :optional
  depends_on "luajit" => :optional
  depends_on "gtk+" if build.with? "client-server"

  conflicts_with "ex-vi",
    :because => "vim and ex-vi both install bin/ex and bin/view"

  def install
    ENV["LUA_PREFIX"] = HOMEBREW_PREFIX if build.with?("lua") || build.with?("luajit")
    ENV.append_to_cflags "-mtune=native"

    # vim doesn't require any Python package, unset PYTHONPATH.
    ENV.delete("PYTHONPATH")

    opts = []
    opts += LANGUAGES_OPTIONAL.map do |language|
      "--enable-#{language}interp=dynamic" if build.with? language
    end
    opts += LANGUAGES_DEFAULT.map do |language|
      "--enable-#{language}interp=dynamic" if build.with? language
    end

    if build.with? "luajit"
      opts << "--enable-luainterp=dynamic" if build.without? "lua"
      opts << "--with-luajit"
    end

    opts << "--disable-nls" if build.without? "nls"

    if build.with? "client-server"
      opts << "--enable-gui=gtk2"
    else
      opts << "--enable-gui=no"
      opts << "--without-x"
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
                          "--enable-cscope",
                          "--with-features=huge",
                          "--with-compiledby=Homebrew",
                          "--enable-fail-if-missing",
                          *opts

    # Require Python's dynamic library, and needs to be built as a framework.
    if build.with?("python") && build.with?("python3")
      py_prefix = `python -c "import sys; print(sys.prefix)"`.chomp
      py3_prefix = `python3 -c "import sys; print(sys.prefix)"`.chomp
      # Help vim find Python's dynamic library as absolute path.
      inreplace "src/auto/config.mk" do |s|
        s.gsub! /-DDYNAMIC_PYTHON_DLL=\\".*\\"/, %(-DDYNAMIC_PYTHON_DLL=\'\"#{py_prefix}/Python\"\')
        s.gsub! /-DDYNAMIC_PYTHON3_DLL=\\".*\\"/, %(-DDYNAMIC_PYTHON3_DLL=\'\"#{py3_prefix}/Python\"\')
      end
    end

    system "make"
    # If stripping the binaries is not enabled, vim will segfault with
    # statically-linked interpreters like ruby
    # http://code.google.com/p/vim/issues/detail?id=114&thanks=114&ts=1361483471
    system "make", "install", "prefix=#{prefix}", "STRIP=true"
  end

  test do
    #
  end
end
