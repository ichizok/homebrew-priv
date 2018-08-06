class Vim < Formula
  desc "Vi 'workalike' with many additional features"
  homepage "https://www.vim.org"
  patchlevel = 240
  url "https://github.com/vim/vim.git", :tag => format("v8.1.%04d", patchlevel)
  head "https://github.com/vim/vim.git"

  option "with-override-system-vi", "Override system vi"
  option "with-gettext", "Build vim with National Language Support (translated messages, keymaps)"
  option "with-client-server", "Enable client/server mode"
  option "with-clpum", "Build vim with CLPUM option (http://h-east.github.io/vim)"

  LANGUAGES_OPTIONAL = %w[perl python@2 ruby tcl].freeze
  LANGUAGES_DEFAULT  = %w[lua python].freeze

  LANGUAGES_OPTIONAL.each do |language|
    option "with-#{language}", "Build vim with #{language} support"
  end
  LANGUAGES_DEFAULT.each do |language|
    option "without-#{language}", "Build vim without #{language} support"
  end

  depends_on "lua" => :recommended
  depends_on "luajit" => :optional
  depends_on "perl" => :optional
  depends_on "python" => :recommended
  depends_on "python@2" => :optional
  depends_on "ruby" => :optional
  depends_on "gettext" => :optional
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
    ENV.prepend_path "PATH", Formula["python"].opt_libexec/"bin"

    # https://github.com/Homebrew/homebrew-core/pull/1046
    ENV.delete("SDKROOT")

    # vim doesn't require any Python package, unset PYTHONPATH.
    ENV.delete("PYTHONPATH")

    ENV.append_to_cflags "-mtune=native"

    if build.with?("python") && which("python").to_s == "/usr/bin/python" && !MacOS::CLT.installed?
      # break -syslibpath jail
      ln_s "/System/Library/Frameworks", buildpath
      ENV.append "LDFLAGS", "-F#{buildpath}/Frameworks"
    end

    opts = []

    (LANGUAGES_OPTIONAL + LANGUAGES_DEFAULT).each do |language|
      feature = { "python" => "python3", "python@2" => "python" }
      if build.with? language
        opts << "--enable-#{feature.fetch(language, language)}interp=dynamic"
      end
    end

    if opts.include?("--enable-pythoninterp") && opts.include?("--enable-python3interp")
      # only compile with either python or python3 support, but not both
      # (if vim74 is compiled with +python3/dyn, the Python[3] library lookup segfaults
      # in other words, a command like ":py3 import sys" leads to a SEGV)
      opts -= %w[--enable-python3interp]
    end

    opts << "--disable-nls" if build.without? "gettext"
    opts << "--enable-gui=no"

    if build.with? "client-server"
      opts << "--with-x"
    else
      opts << "--without-x"
    end

    if build.with?("lua") || build.with?("luajit")
      ENV["LUA_PREFIX"] = HOMEBREW_PREFIX
      if build.with? "luajit"
        opts << "--enable-luainterp=dynamic" if build.without? "lua"
        opts << "--with-luajit"
      end
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
      if build.with? "python@2"
        s.gsub! /-DDYNAMIC_PYTHON_DLL=\\".*?\\"/,
          %Q(-DDYNAMIC_PYTHON_DLL=\'\"#{python_framework_path(2)}/Python\"\')
      end
      if build.with? "python"
        s.gsub! /-DDYNAMIC_PYTHON3_DLL=\\".*?\\"/,
          %Q(-DDYNAMIC_PYTHON3_DLL=\'\"#{python_framework_path(3)}/Python\"\')
      end
    end

    system "make"
    # Parallel install could miss some symlinks
    # https://github.com/vim/vim/issues/1031
    ENV.deparallelize
    # If stripping the binaries is enabled, vim will segfault with
    # statically-linked interpreters like ruby
    # https://github.com/vim/vim/issues/114
    system "make", "install", "prefix=#{prefix}", "STRIP=#{which "true"}"
    bin.install_symlink "vim" => "vi" if build.with? "override-system-vi"
  end

  def python_framework_path(ver = nil)
    `python#{ver}-config --exec-prefix`.chomp.gsub(%r{#{HOMEBREW_CELLAR}/(?:.+?)/(?:.+?)/}, "#{HOMEBREW_PREFIX}/")
  end

  test do
    # if build.with? "python@2"
    #   (testpath/"commands.vim").write <<~EOS
    #     :python import vim; vim.current.buffer[0] = 'hello world'
    #     :wq
    #   EOS
    #   system bin/"vim", "-T", "dumb", "-s", "commands.vim", "test.txt"
    #   assert_equal "hello world", File.read("test.txt").chomp
    # elsif build.with? "python"
    #   (testpath/"commands.vim").write <<~EOS
    #     :python3 import vim; vim.current.buffer[0] = 'hello python3'
    #     :wq
    #   EOS
    #   system bin/"vim", "-T", "dumb", "-s", "commands.vim", "test.txt"
    #   assert_equal "hello python3", File.read("test.txt").chomp
    # end
    # if build.with? "gettext"
    #   assert_match "+gettext", shell_output("#{bin}/vim --version")
    # end
  end
end
