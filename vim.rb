class Vim < Formula
  desc "Vi \"workalike\" with many additional features"
  homepage "http://www.vim.org/"
  # Get stable versions from hg repo instead of downloading an increasing
  # number of separate patches.
  patchlevel = 495
  url "https://github.com/vim/vim.git", :tag => format("v8.0.%04d", patchlevel)
  version "8.0.#{patchlevel}"

  # We only have special support for finding depends_on :python, but not yet for
  # :ruby, :perl etc., so we use the standard environment that leaves the
  # PATH as the user has set it right now.
  env :std

  option "without-nls", "Build vim without National Language Support (translated messages, keymaps)"
  option "with-client-server", "Enable client/server mode"
  option "with-clpum", "Build vim with CLPUM option (http://h-east.github.io/vim)"

  LANGUAGES_OPTIONAL = %w[mzscheme perl python python3 ruby tcl].freeze
  LANGUAGES_DEFAULT  = %w[lua].freeze

  LANGUAGES_OPTIONAL.each do |language|
    option "with-#{language}", "Build vim with #{language} support"
  end
  LANGUAGES_DEFAULT.each do |language|
    option "without-#{language}", "Build vim without #{language} support"
  end

  depends_on "perl" => :optional
  depends_on "python" => :optional
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
      # omit sha256
    end
  end

  def install
    # https://github.com/Homebrew/homebrew-core/pull/1046
    ENV.delete("SDKROOT")
    ENV["LUA_PREFIX"] = HOMEBREW_PREFIX if build.with?("lua") || build.with?("luajit")
    ENV.append_to_cflags "-mtune=native"

    # vim doesn't require any Python package, unset PYTHONPATH.
    ENV.delete("PYTHONPATH")

    if build.with?("python") && which("python").to_s == "/usr/bin/python" && !MacOS::CLT.installed?
      # break -syslibpath jail
      ln_s "/System/Library/Frameworks", buildpath
      ENV.append "LDFLAGS", "-F#{buildpath}/Frameworks"
    end

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
      opts << "--with-luajit"
      opts << "--enable-luainterp=dynamic" if build.without? "lua"
    end

    # We specify HOMEBREW_PREFIX as the prefix to make vim look in the
    # the right place (HOMEBREW_PREFIX/share/vim/{vimrc,vimfiles}) for
    # system vimscript files. We specify the normal installation prefix
    # when calling "make install".
    # Homebrew will use the first suitable Perl & Ruby in your PATH if you
    # build from source. Please don't attempt to hardcode either.
    system "./configure", "--prefix=#{HOMEBREW_PREFIX}",
                          "--mandir=#{man}",
                          "--enable-multibyte",
                          "--with-tlib=ncurses",
                          "--enable-cscope",
                          "--with-compiledby=Homebrew",
                          "--with-features=huge",
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
    # https://github.com/vim/vim/issues/114
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
