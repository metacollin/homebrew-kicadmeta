class Kicadmeta < Formula
  desc "Electronic Design Automation Suite"
  homepage "http://www.kicad-pcb.org"
  head "lp:kicad", :using => :bzr 

  option "without-menu-icons", "Build without icons menus."
  option "with-default-paths", "Do not alter KiCad's file paths."
  option "with-new-icons", "Pull in the new icon package."
  option "with-defaults-patch", "My own patch to make sensible design rules be filled in for new pcbnew files."
  option "with-new-3d", "Pull in new 3D viewer branch."

  depends_on "bazaar" => :build
  depends_on "boost"
  depends_on "cairo"
  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "fontconfig"
  depends_on "freetype"
  depends_on "gettext"
  depends_on "glew"
  depends_on "glib"
  depends_on "icu4c"
  depends_on "libffi"
  depends_on "libpng"
  depends_on "makedepend" => :build
  depends_on "openssl"
  depends_on "pcre"
  depends_on "pixman"
  depends_on "pkg-config" => :build
  depends_on "python" => :optional
  depends_on "swig" => :build if build.with? "python"
  depends_on "xz"
  depends_on "glm"
  depends_on "wxkicad"

  fails_with :gcc
  fails_with :llvm

  patch :DATA

  # KiCad requires wx to have several bugs fixed to function, but the patches have yet to be included with a wx release
  # so KiCad, as part of its build system, builds its own wx binaries with these fixes included.  It uses a bash script
  # for this, so I have simply concatenated all the patches into one patch to make it fit better into homebrew.  These
  # Patches are the ones that come from the stable release archive of KiCad under the patches directory.
  # resource "wxpatch" do
  #   url "https://gist.githubusercontent.com/metacollin/2d5760743df73c939d53/raw/b25008a92c8f518df582ad88d266dcf2d75f9d12/wxp.patch"
  #   sha256 "0a19c475ded29186683a9e7f7d9316e4cbea4db7b342f599cee0e116fa019f3e"
  # end

  resource "wxk" do
    url "https://downloads.sourceforge.net/project/wxpython/wxPython/3.0.2.0/wxPython-src-3.0.2.0.tar.bz2"
    sha256 "d54129e5fbea4fb8091c87b2980760b72c22a386cb3b9dd2eebc928ef5e8df61"
  end

  resource "kicad-library" do
    url "https://github.com/KiCad/kicad-library.git"
  end

  def install
    ENV["MAC_OS_X_VERSION_MIN_REQUIRED"] = "#{MacOS.version}"
    ENV.append "ARCHFLAGS", "-Wunused-command-line-argument-hard-error-in-future"
    ENV.append "LDFLAGS", "-headerpad_max_install_names"
    if MacOS.version < :mavericks
      ENV.libstdcxx
    else
      ENV.libcxx
    end

    if build.without? "default-paths"
      inreplace "common/common.cpp", "/Library/Application Support/kicad", "#{etc}/kicad"
      inreplace "common/common.cpp", "wxStandardPaths::Get().GetUserConfigDir()", "wxT( \"#{etc}/kicad\" )"
      inreplace "common/pgm_base.cpp", "DEFAULT_INSTALL_PATH", "\"#{etc}/kicad\""
    end

      #inreplace "3d-viewer/3d_cache/sg/CMakeLists.txt", "KICAD_LIB", "KICAD_BIN"
     # inreplace "plugins/3d/idf/CMakeLists.txt", "KICAD_USER_PLUGIN", "KICAD_BIN"
     #  inreplace "plugins/3d/vrml/CMakeLists.txt", "KICAD_USER_PLUGIN", "KICAD_BIN"

     resource("wxk").stage do
    #   (Pathname.pwd).install resource("wxpatch")
    #   safe_system "/usr/bin/patch", "-g", "0", "-f", "-d", Pathname.pwd, "-p1", "-i", "wxp.patch"

    #   mkdir "wx-build" do
    #     args = [
    #       "--prefix=#{buildpath/"wxk"}",
    #       "--with-opengl",
    #       "--enable-aui",
    #       "--enable-utf8",
    #       "--enable-html",
    #       "--enable-stl",
    #       "--with-libjpeg=builtin",
    #       "--with-libpng=builtin",
    #       "--with-regex=builtin",
    #       "--with-libtiff=builtin",
    #       "--with-zlib=builtin",
    #       "--with-expat=builtin",
    #       "--without-liblzma",
    #       "--with-macosx-version-min=#{MacOS.version}",
    #       "--enable-universal_binary=i386,x86_64",
    #       "CC=#{ENV.cc}",
    #       "CXX=#{ENV.cxx}",
    #     ]

    #     system "../configure", *args
    #     system "make", "-j#{ENV.make_jobs}"
    #     system "make", "install"
    #   end

      if build.with? "python"
        cd "wxPython" do
          args = [
            "WXPORT=osx_cocoa",
            "WX_CONFIG=#{Formula["wxkicad"].bin}/wx-config",
            "UNICODE=1",
            "BUILD_BASE=#{Formula["wxkicad"]}/wx-build",
          ]

          system "python", "setup.py", "build_ext", *args
          system "python", "setup.py", "install", "--prefix=#{buildpath}/py", *args
        end
      end
    end

    mkdir "build" do
      if build.with? "python"
        ENV.prepend_create_path "PYTHONPATH", "#{buildpath}/py/lib/python2.7/site-packages"
      end

      args = %W[
        -DCMAKE_INSTALL_PREFIX=#{prefix}
        -DCMAKE_OSX_DEPLOYMENT_TARGET=#{MacOS.version}
        -DwxWidgets_CONFIG_EXECUTABLE=#{Formula["wxkicad"].bin}/wx-config
        -DKICAD_REPO_NAME=brewed_product
        -DKICAD_SKIP_BOOST=ON
        -DBoost_USE_STATIC_LIBS=ON
      ]

      if build.with? "debug"
        args << "-DCMAKE_BUILD_TYPE=Debug"
        args << "-DwxWidgets_USE_DEBUG=ON"
      else
        args << "-DCMAKE_BUILD_TYPE=Release"
      end

      if build.with? "python"
        args << "-DPYTHON_SITE_PACKAGE_PATH=#{buildpath}/py/lib/python2.7/site-packages"
        args << "-DKICAD_SCRIPTING=ON"
        args << "-DKICAD_SCRIPTING_MODULES=ON"
        args << "-DKICAD_SCRIPTING_WXPYTHON=ON"
        python_executable = `which python`.strip
        args << "-DPYTHON_EXECUTABLE=#{python_executable}"
      else
        args << "-DKICAD_SCRIPTING=OFF"
        args << "-DKICAD_SCRIPTING_MODULES=OFF"
        args << "-DKICAD_SCRIPTING_WXPYTHON=OFF"
      end
      args << "-DCMAKE_C_COMPILER=#{ENV.cc}"
      args << "-DCMAKE_CXX_COMPILER=#{ENV.cxx}"

      if build.with? "menu-icons"
        args << "-DUSE_IMAGES_IN_MENUS=ON"
      end

      system "cmake", "../", *(std_cmake_args + args)
      system "make", "-j#{ENV.make_jobs}"
      system "make", "install"
    end
  end

  def kicaddir
    etc/"kicad"
  end

  def post_install
    if build.without? "default-paths"
      kicaddir.mkpath
      resource("kicad-library").stage do
        cp_r Dir["*"], kicaddir
      end
    end
  end

  def caveats
    s = ""
    if build.without? "default-paths"
      s += <<-EOS.undent

      KiCad component libraries and preferences are located in:
        #{kicaddir}

      Component libraries have been setup for you, but
      footprints and 3D models must be downloaded from
      within Pcbnew.  It will automatically guide you
      through this process upon first lauch.
      EOS
    else
      s += <<-EOS.undent

      KiCad component libraries must be installed manually in:
        /Library/Application Support/kicad

      This can be done with the following command:
        sudo git clone https://github.com/KiCad/kicad-library.git \
          /Library/Application\ Support/kicad
      EOS
    end

    s
  end

  test do
    assert File.exist? "#{prefix}/KiCad.app/Contents/MacOS/kicad"
  end
end

__END__
diff --git a/common/project.cpp b/common/project.cpp
index ebf8f13..9a706a0 100644
--- a/common/project.cpp
+++ b/common/project.cpp
@@ -227,6 +227,7 @@ static bool copy_pro_file_template( const SEARCH_STACK& aSearchS, const wxString
     }
 
     wxString templateFile = wxT( "kicad." ) + ProjectFileExtension;
+    wxString pcbFile = wxT( "kicad." ) + KiCadPcbFileExtension;
 
     wxString kicad_pro_template = aSearchS.FindValidPath( templateFile );
 
@@ -253,6 +254,9 @@ static bool copy_pro_file_template( const SEARCH_STACK& aSearchS, const wxString
 
     DBG( printf( "%s: using template file '%s' as project file.\n", __func__, TO_UTF8( kicad_pro_template ) );)
 
+
+    wxString kicad_pcb_template = aSearchS.FindValidPath( pcbFile );
+
     // Verify aDestination can be created. if this is not the case, wxCopyFile
     // will generate a crappy log error message, and we *do not want* this kind
     // of stupid message
@@ -260,7 +264,20 @@ static bool copy_pro_file_template( const SEARCH_STACK& aSearchS, const wxString
     bool success = true;
 
     if( fn.IsOk() && fn.IsDirWritable() )
+    {
         success = wxCopyFile( kicad_pro_template, aDestination );
+        if ( !kicad_pcb_template )
+        {
+        }
+        else
+        {
+
+            wxString aDest = aDestination;
+            aDest.Replace(ProjectFileExtension, KiCadPcbFileExtension);
+            wxCopyFile( kicad_pcb_template, aDest);
+        }
+        
+    }
     else
     {
         wxLogMessage( _( "Cannot create prj file '%s' (Directory not writable)" ),
diff --git a/template/CMakeLists.txt b/template/CMakeLists.txt
index a804e9e..c3e128d 100644
--- a/template/CMakeLists.txt
+++ b/template/CMakeLists.txt
@@ -1,5 +1,6 @@
 install( FILES
     kicad.pro
+    kicad.kicad_pcb
     gost_landscape.kicad_wks
     gost_portrait.kicad_wks
     pagelayout_default.kicad_wks
diff --git a/template/kicad.pro b/template/kicad.pro
index 804cf83..5cef6e8 100644
--- a/template/kicad.pro
+++ b/template/kicad.pro
@@ -60,3 +60,15 @@ LibName26=opto
 LibName27=atmel
 LibName28=contrib
 LibName29=valves
+LibName30=w_analog
+LibName31=w_connectors
+LibName32=w_device
+LibName33=w_logic
+LibName34=w_memory
+LibName35=w_microcontrollers
+LibName36=w_opto
+LibName37=w_relay
+LibName38=w_rtx
+LibName39=w_transistor
+LibName40=w_vacuum
+LibName41=collieparts
diff --git a/template/kicad.kicad_pcb b/template/kicad.kicad_pcb
index e69de29..8ef89d4 100644
--- a/template/kicad.kicad_pcb
+++ b/template/kicad.kicad_pcb
@@ -0,0 +1,118 @@
+(kicad_pcb (version 4) (host pcbnew "(2014-09-28 BZR 5153)-product")
+
+  (general
+    (links 0)
+    (no_connects 0)
+    (area 0 0 0 0)
+    (thickness 1.6)
+    (drawings 0)
+    (tracks 0)
+    (zones 0)
+    (modules 0)
+    (nets 1)
+  )
+
+  (page A4)
+  (layers
+    (0 F.Cu signal)
+    (31 B.Cu signal)
+    (32 B.Adhes user)
+    (33 F.Adhes user)
+    (34 B.Paste user)
+    (35 F.Paste user)
+    (36 B.SilkS user)
+    (37 F.SilkS user)
+    (38 B.Mask user)
+    (39 F.Mask user)
+    (40 Dwgs.User user)
+    (41 Cmts.User user)
+    (42 Eco1.User user)
+    (43 Eco2.User user)
+    (44 Edge.Cuts user)
+    (45 Margin user)
+    (46 B.CrtYd user)
+    (47 F.CrtYd user)
+    (48 B.Fab user)
+    (49 F.Fab user)
+  )
+
+  (setup
+    (last_trace_width 0.254)
+    (user_trace_width 0.1524)
+    (user_trace_width 0.2)
+    (user_trace_width 0.25)
+    (user_trace_width 0.3)
+    (user_trace_width 0.4)
+    (user_trace_width 0.5)
+    (user_trace_width 0.6)
+    (user_trace_width 0.8)
+    (user_trace_width 1)
+    (user_trace_width 1.2)
+    (user_trace_width 1.5)
+    (user_trace_width 2)
+    (trace_clearance 0.1524)
+    (zone_clearance 0.1524)
+    (zone_45_only yes)
+    (trace_min 0.1524)
+    (segment_width 0.127)
+    (edge_width 0.127)
+    (via_size 0.6096)
+    (via_drill 0.3302)
+    (via_min_size 0.6096)
+    (via_min_drill 0.3302)
+    (uvia_size 0.6096)
+    (uvia_drill 0.3302)
+    (uvias_allowed no)
+    (uvia_min_size 0.6096)
+    (uvia_min_drill 0.3302)
+    (pcb_text_width 0.127)
+    (pcb_text_size 0.6 0.6)
+    (mod_edge_width 0.127)
+    (mod_text_size 0.6 0.6)
+    (mod_text_width 0.127)
+    (pad_size 1.524 1.524)
+    (pad_drill 0.762)
+    (pad_to_mask_clearance 0.05)
+    (pad_to_paste_clearance -0.04)
+    (aux_axis_origin 0 0)
+    (visible_elements FFFFFF7F)
+    (pcbplotparams
+      (layerselection 0x3ffff_80000001)
+      (usegerberextensions true)
+      (usegerberattributes true)
+      (excludeedgelayer true)
+      (linewidth 0.127000)
+      (plotframeref false)
+      (viasonmask false)
+      (mode 1)
+      (useauxorigin false)
+      (hpglpennumber 1)
+      (hpglpenspeed 20)
+      (hpglpendiameter 15)
+      (hpglpenoverlay 2)
+      (psnegative false)
+      (psa4output false)
+      (plotreference true)
+      (plotvalue true)
+      (plotinvisibletext false)
+      (padsonsilk false)
+      (subtractmaskfromsilk false)
+      (outputformat 1)
+      (mirror false)
+      (drillshape 0)
+      (scaleselection 1)
+      (outputdirectory CAM/))
+  )
+
+  (net 0 "")
+
+  (net_class Default "This is the standaard class."
+    (clearance 0.1524)
+    (trace_width 0.1524)
+    (via_dia 0.6096)
+    (via_drill 0.3302)
+    (uvia_dia 0.6096)
+    (uvia_drill 0.3302)
+  )
+
+)

