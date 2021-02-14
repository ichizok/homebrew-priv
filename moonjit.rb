class Moonjit < Formula
  desc "Just-In-Time Compiler (JIT) for the Lua programming language"
  homepage "https://github.com/moonjit/moonjit"
  license "MIT"

  stable do
    url "https://github.com/moonjit/moonjit/archive/2.2.0.tar.gz"
    sha256 "83deb2c880488dfe7dd8ebf09e3b1e7613ef4b8420de53de6f712f01aabca2b6"
  end

  head do
    url "https://github.com/moonjit/moonjit"

    # Fix for Apple Silicon Mac (arm64)
    patch :DATA
  end

  conflicts_with "luajit", because: "both install an `luajit` binaries"

  def install
    # Per https://luajit.org/install.html: If MACOSX_DEPLOYMENT_TARGET
    # is not set then it's forced to 10.4, which breaks compile on Mojave.
    ENV["MACOSX_DEPLOYMENT_TARGET"] = MacOS.version

    args = %W[PREFIX=#{prefix}]

    system "make", "amalg", *args
    system "make", "install", *args

    # LuaJIT doesn't automatically symlink unversioned libraries:
    # https://github.com/Homebrew/homebrew/issues/45854.
    lib.install_symlink lib/"libluajit-5.1.dylib" => "libluajit.dylib"
    lib.install_symlink lib/"libluajit-5.1.a" => "libluajit.a"

    # Fix path in pkg-config so modules are installed
    # to permanent location rather than inside the Cellar.
    inreplace lib/"pkgconfig/luajit.pc" do |s|
      s.gsub! "INSTALL_LMOD=${prefix}/share/lua/${abiver}",
              "INSTALL_LMOD=#{HOMEBREW_PREFIX}/share/lua/${abiver}"
      s.gsub! "INSTALL_CMOD=${prefix}/${multilib}/lua/${abiver}",
              "INSTALL_CMOD=#{HOMEBREW_PREFIX}/${multilib}/lua/${abiver}"
      unless build.head?
        s.gsub! "Libs:",
                "Libs: -pagezero_size 10000 -image_base 100000000"
      end
    end

    # Having an empty Lua dir in lib/share can mess with other Homebrew Luas.
    %W[#{lib}/lua #{share}/lua].each { |d| rm_rf d }
  end

  test do
    system "#{bin}/luajit", "-e", <<~EOS
      local ffi = require("ffi")
      ffi.cdef("int printf(const char *fmt, ...);")
      ffi.C.printf("Hello %s!\\n", "#{ENV["USER"]}")
    EOS
  end
end

__END__
--- a/src/lj_asm_arm64.h
+++ b/src/lj_asm_arm64.h
@@ -868,7 +868,7 @@ static void asm_href(ASMState *as, IRIns *ir, IROp merge)
       emit_lso(as, A64I_LDRx, scr, dest, offsetof(Node, key.u64));
     }
   } else {
-    lua_assert(irt_ispri(kt) && !irt_isnil(kt));
+    lj_assertA(irt_ispri(kt) && !irt_isnil(kt), "bad HREF key type");
     emit_nm(as, A64I_CMPw, scr, type);
     emit_lso(as, A64I_LDRx, scr, dest, offsetof(Node, key));
   }
@@ -1296,7 +1296,6 @@ static void asm_cnew(ASMState *as, IRIns *ir)
     else
       r = ra_alloc1(as, ir->op2, allow);

-    lua_assert(sz == 4 || sz == 8);
     lj_assertA(sz == 4 || sz == 8, "bad CNEWI size %d", sz);
     emit_lso(as, sz == 8 ? A64I_STRx : A64I_STRw, r, RID_RET, ofs);
   } else if (ir->op2 != REF_NIL) {  /* Create VLA/VLS/aligned cdata. */
