class Wxkicad < Formula
  url "https://downloads.sourceforge.net/project/wxpython/wxPython/3.0.2.0/wxPython-src-3.0.2.0.tar.bz2"
  sha256 "d54129e5fbea4fb8091c87b2980760b72c22a386cb3b9dd2eebc928ef5e8df61"
  homepage "https://kicad-pcb.org"

  depends_on "cairo"
  depends_on "swig" => :build
  depends_on "pkg-config" => :build
  depends_on "pcre"
  depends_on "glew"

  keg_only "Custom patched version of wxWidgets, only for use by KiCad."


 # bottle do
 #   root_url "https://electropi.mp"
 #   revision 3
 #   sha256 "c9e92d9a896e3558a684345e4ce20d123b265487965c3cfd29673ea64381cee7" => :yosemite
 #   sha256 "3553e767d5aa30bbd43004316a755e736f694775de8b12b58b0ecc5157a97654" => :lion
 # end

  patch :p0 do
    url "https://gist.githubusercontent.com/metacollin/b6bbb5d54734bea3dcaca1ff22668016/raw/1bdf06a34efba3a67351b034bad27f97f7f712e0/wx_patch_unified.patch"
    sha256 "d94339ea67b3c0ecef61bcf9abf786627269465df1afa710fed828975602445f"
  end

  if MacOS.version > :elcapitan
    patch :p1 do
      url "https://gist.githubusercontent.com/metacollin/232d39cdc5cfd3664a23b18efd50ec4f/raw/465b9368a8a4ad983992ec3842f56e2010d18f1b/wxwidgets-3.0.2_macosx_sierra.patch"
      sha256 "cf46d8b1ec6e90e8fef458a610ae1ecdc6607e2f4bbd6fb527e83e40c5b5fb24"
    end
  end


  fails_with :gcc
  fails_with :llvm

   def install

  #  inreplace "src/stc/scintilla/src/Editor.cxx", "if (abs(pt1.x - pt2.x) > 3)", "if (std::abs(pt1.x - pt2.x) > 3)"
  #  inreplace "src/stc/scintilla/src/Editor.cxx", "if (abs(pt1.y - pt2.y) > 3)", "if (std::abs(pt1.y - pt2.y) > 3)"
  #  inreplace "src/stc/scintilla/src/Editor.cxx", "#include <stdlib.h>", "#include <stdlib.h>\n#include <cmath>"
  if MacOS.version < :yosemite
    inreplace "src/osx/webview_webkit.mm", "#include <WebKit/WebKitLegacy.h>", "#include <WebKit/WebKit.h>"
  end
    mkdir "wx-build" do
      ENV['MAC_OS_X_VERSION_MIN_REQUIRED'] = "#{MacOS.version}"
      ENV.append "ARCHFLAGS", "-Wunused-command-line-argument-hard-error-in-future"
      ENV.append "LDFLAGS", "-headerpad_max_install_names" # Need for building bottles.
      ENV["CC"] = "clang"
      ENV["CXX"] = "clang++"

      if MacOS.version < :mavericks
        ENV.libstdcxx
      else
        ENV.libcxx
      end



      args = [
        "--prefix=#{prefix}",
        "--with-opengl",
        "--enable-aui",
        "--enable-utf8",
        "--enable-html",
        "--enable-stl",
        "--with-libjpeg=builtin",
        "--with-libpng=builtin",
        "--with-regex=builtin",
        "--with-libtiff=builtin",
        "--with-zlib=builtin",
        "--with-expat=builtin",
        "--without-liblzma",
        "--with-macosx-version-min=#{MacOS.version}",
        "--enable-universal_binary=i386,x86_64",
        "CC=clang",
        "CXX=clang++"
      ]

      if MacOS.version > :elcapitan
        args << "--disable-mediactrl"
      end

      system "../configure", *args
      system "make", "-j#{ENV.make_jobs}"
      system "make", "install"
    end
    (prefix/"wx-build").install Dir["wx-build/*"]
  end
end
