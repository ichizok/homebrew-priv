class Vim < Formula
  desc "Vi \"workalike\" with many additional features"
  homepage "https://vim.sourceforge.io"
  patchlevel = 1376
  url "https://github.com/vim/vim.git", :tag => format("v8.0.%04d", patchlevel)

  option "with-gettext", "Build vim with National Language Support (translated messages, keymaps)"
  option "with-client-server", "Enable client/server mode"
  option "with-clpum", "Build vim with CLPUM option (http://h-east.github.io/vim)"
  option "with-python3", "Build vim with python3 instead of python[2] support"

  LANGUAGES_OPTIONAL = %w[perl python ruby tcl].freeze
  LANGUAGES_DEFAULT  = %w[lua python3].freeze

  if MacOS.version >= :mavericks
    option "with-custom-python", "Build with a custom Python 2 instead of the Homebrew version."
    option "with-custom-ruby", "Build with a custom Ruby instead of the Homebrew version."
    option "with-custom-perl", "Build with a custom Perl instead of the Homebrew version."
  end

  LANGUAGES_OPTIONAL.each do |language|
    option "with-#{language}", "Build vim with #{language} support"
  end
  LANGUAGES_DEFAULT.each do |language|
    option "without-#{language}", "Build vim without #{language} support"
  end

  depends_on :python => :optional
  depends_on :python3 => :recommended
  depends_on :ruby => "1.8" # Can be compiled against 1.8.x or >= 1.9.3-p385.
  depends_on :perl => "5.3"
  depends_on "lua" => :recommended
  depends_on "luajit" => :optional
  depends_on :x11 if build.with? "client-server"
  depends_on "gettext" => :optional

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

    if opts.include?("--enable-pythoninterp") && opts.include?("--enable-python3interp")
      # only compile with either python or python3 support, but not both
      # (if vim74 is compiled with +python3/dyn, the Python[3] library lookup segfaults
      # in other words, a command like ":py3 import sys" leads to a SEGV)
      opts -= %w[--enable-pythoninterp]
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
      if build.with? "python"
        s.gsub! /-DDYNAMIC_PYTHON_DLL=\\".*?\\"/,
          %Q(-DDYNAMIC_PYTHON_DLL=\'\"#{python_framework_path(2)}/Python\"\')
      end
      if build.with? "python3"
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
  end

  def python_framework_path(v = nil)
    `python#{v}-config --exec-prefix`.chomp.gsub(%r{#{HOMEBREW_CELLAR}/(?:.+?)/(?:.+?)/}, "#{HOMEBREW_PREFIX}/")
  end

  test do
    # if build.with? "python3"
    #   (testpath/"commands.vim").write <<-EOS.undent
    #     :python3 import vim; vim.current.buffer[0] = 'hello python3'
    #     :wq
    #   EOS
    #   system bin/"vim", "-T", "dumb", "-s", "commands.vim", "test.txt"
    #   assert_equal "hello python3", File.read("test.txt").chomp
    # elsif build.with? "python"
    #   (testpath/"commands.vim").write <<-EOS.undent
    #     :python import vim; vim.current.buffer[0] = 'hello world'
    #     :wq
    #   EOS
    #   system bin/"vim", "-T", "dumb", "-s", "commands.vim", "test.txt"
    #   assert_equal "hello world", File.read("test.txt").chomp
    # end
    # if build.with? "gettext"
    #   assert_match "+gettext", shell_output("#{bin}/vim --version")
    # end
  end
end
