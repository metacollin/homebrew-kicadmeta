class Wxkicad31 < Formula
  url "https://github.com/wxWidgets/wxWidgets/releases/download/v3.1.0/wxWidgets-3.1.0.tar.bz2"
  sha256 "e082460fb6bf14b7dd6e8ac142598d1d3d0b08a7b5ba402fdbf8711da7e66da8"
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

  patch :p1 do
     url "https://gist.githubusercontent.com/metacollin/710d4cb34a549532cbd33c5ab668eecc/raw/e8ca8cb496d778cb356c83b659dc5736e302b964/wx31.patch"
     sha256 "bbe4a15ebbb4b5b58d3a01ae36902672fe6fe579302b2635e6cb395116f65e3b"
  end

  fails_with :gcc
  fails_with :llvm

   def install
    mkdir "wx-build" do
      ENV['MAC_OS_X_VERSION_MIN_REQUIRED'] = "#{MacOS.version}"
      ENV.append "ARCHFLAGS", "-Wunused-command-line-argument-hard-error-in-future"
      ENV.append "LDFLAGS", "-headerpad_max_install_names" # Need for building bottles.

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
        "CC=#{ENV.cc}",
        "CXX=#{ENV.cxx}"
      ]

      system "../configure", *args
      system "make", "-j6"
      system "make", "install"
    end
    (prefix/"wx-build").install Dir["wx-build/*"]
  end
end