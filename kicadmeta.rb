class Kicadmeta < Formula
  desc "Electronic Design Automation Suite"
  homepage "http://www.kicad-pcb.org"
  head "lp:kicad", :using => :bzr 

  option "without-menu-icons", "Build without icons menus."
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

    # inreplace "3d-viewer/3d_cache/sg/CMakeLists.txt", "KICAD_LIB", "KICAD_BIN"
    # inreplace "plugins/3d/idf/CMakeLists.txt", "KICAD_USER_PLUGIN", "KICAD_BIN"
    # inreplace "plugins/3d/vrml/CMakeLists.txt", "KICAD_USER_PLUGIN", "KICAD_BIN"

    resource("wxk").stage do
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

  def caveats
    s = <<-EOS.undent

      KiCad component libraries must be installed manually in:
        /Library/Application Support/kicad

      This can be done with the following command:
        sudo git clone https://github.com/KiCad/kicad-library.git \
          /Library/Application\ Support/kicad
      EOS

    s
  end

  test do
    assert File.exist? "#{prefix}/KiCad.app/Contents/MacOS/kicad"
  end
end

__END__
diff --git a/include/gal/opengl/opengl_gal.h b/include/gal/opengl/opengl_gal.h
index 83598ba..27debf1 100644
--- a/include/gal/opengl/opengl_gal.h
+++ b/include/gal/opengl/opengl_gal.h
@@ -254,8 +254,8 @@ private:
     /// Super class definition
     typedef GAL super;

-    static const int    CIRCLE_POINTS   = 64;   ///< The number of points for circle approximation
-    static const int    CURVE_POINTS    = 32;   ///< The number of points for curve approximation
+    static const int    CIRCLE_POINTS   = 256;   ///< The number of points for circle approximation
+    static const int    CURVE_POINTS    = 128;   ///< The number of points for curve approximation

     wxClientDC*             clientDC;               ///< Drawing context
     static wxGLContext*     glContext;              ///< OpenGL context of wxWidgets
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
index 804cf83..9f7194d 100644
--- a/template/kicad.pro
+++ b/template/kicad.pro
@@ -1,4 +1,4 @@
-update=22/05/2015 07:44:53
+update=Thursday, 27 August 2015 'amt' 10:17:31
 version=1
 last_client=kicad
 [general]
@@ -13,13 +13,13 @@ PadDrill=0.600000000000
 PadDrillOvalY=0.600000000000
 PadSizeH=1.500000000000
 PadSizeV=1.500000000000
-PcbTextSizeV=1.500000000000
-PcbTextSizeH=1.500000000000
-PcbTextThickness=0.300000000000
-ModuleTextSizeV=1.000000000000
-ModuleTextSizeH=1.000000000000
-ModuleTextSizeThickness=0.150000000000
-SolderMaskClearance=0.000000000000
+PcbTextSizeV=0.800000000000
+PcbTextSizeH=0.800000000000
+PcbTextThickness=0.1250000000000
+ModuleTextSizeV=0.800000000000
+ModuleTextSizeH=0.800000000000
+ModuleTextSizeThickness=0.125000000000
+SolderMaskClearance=0.1012000000000
 SolderMaskMinWidth=0.000000000000
 DrawSegmentWidth=0.200000000000
 BoardOutlineThickness=0.100000000000
@@ -60,3 +60,69 @@ LibName26=opto
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
+LibName41=power_w
+LibName42=collieparts
+LibName43=power_2
+LibName44=nxp_armmcu
+LibName45=onsemi
+LibName46=powerint
+LibName47=pspice
+LibName48=references
+LibName49=relays
+LibName50=rfcom
+LibName51=sensors
+LibName52=silabs
+LibName53=stm8
+LibName54=stm32
+LibName55=supertex
+LibName56=switches
+LibName57=transf
+LibName58=ttl_ieee
+LibName59=video
+LibName60=74xgxx
+LibName61=ac-dc
+LibName62=actel
+LibName63=brooktre
+LibName64=cmos_ieee
+LibName65=dc-dc
+LibName66=elec-unifil
+LibName67=ftdi
+LibName68=gennum
+LibName69=graphic
+LibName70=hc11
+LibName71=ir
+LibName72=logo
+LibName73=microchip_pic10mcu
+LibName74=microchip_pic12mcu
+LibName75=microchip_pic16mcu
+LibName76=microchip_pic18mcu
+LibName77=microchip_pic32mcu
+LibName78=motor_drivers
+LibName79=msp430
+LibName80=nordicsemi
+LibName81=analog_devices
+LibName82=diode
+LibName83=ESD_Protection
+LibName84=Lattice
+LibName85=maxim
+LibName86=microchip_dspic33dsc
+LibName87=Oscillators
+LibName88=Power_Management
+LibName89=Xicor
+LibName90=Zilog
+LibName91=Altera
+LibName92=16C754
+LibName93=dips-s
+LibName94=s5038
+LibName95=usb-b
diff --git a/template/kicad.kicad_pcb b/template/kicad.kicad_pcb
index e69de29..8ef89d4 100644
--- a/template/kicad.kicad_pcb
+++ b/template/kicad.kicad_pcb
@@ -0,0 +1,123 @@
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
+    (user_trace_width 0.2032)
+    (user_trace_width 0.254)
+    (user_trace_width 0.3048)
+    (user_trace_width 0.381)
+    (user_trace_width 0.4572)
+    (user_trace_width 0.508)
+    (user_trace_width 0.635)
+    (user_trace_width 0.7112)
+    (user_trace_width 0.8128)
+    (user_trace_width 0.9144)
+    (user_trace_width 1.27)
+    (trace_clearance 0.1524)
+    (zone_clearance 0.1524)
+    (zone_45_only yes)
+    (trace_min 0.1524)
+    (segment_width 0.127)
+    (edge_width 0.127)
+    (via_size 0.6858)
+    (via_drill 0.3302)
+    (via_min_size 0.6858)
+    (via_min_drill 0.3302)
+    (user_via 0.8636 0.508)
+    (user_via 0.9906 0.635)
+    (user_via 1.0922 0.7366)
+    (user_via 1.2446 0.889)
+    (user_via 1.3716 1.016)
+    (uvia_size 0.6858)
+    (uvia_drill 0.3302)
+    (uvias_allowed no)
+    (uvia_min_size 0.6858)
+    (uvia_min_drill 0.3302)
+    (pcb_text_width 0.127)
+    (pcb_text_size 0.8 0.8)
+    (mod_edge_width 0.127)
+    (mod_text_size 0.8 0.8)
+    (mod_text_width 0.127)
+    (pad_size 1.524 1.524)
+    (pad_drill 0.762)
+    (pad_to_mask_clearance 0.05)
+    (pad_to_paste_clearance -0.04)
+    (aux_axis_origin 0 0)
+    (visible_elements FFFFFF7F)
+    (pcbplotparams
+      (layerselection 0x010f0_ffffffff)
+      (usegerberextensions false)
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
+  (net_class Default "This is the standard class."
+    (clearance 0.1524)
+    (trace_width 0.1524)
+    (via_dia 0.6858)
+    (via_drill 0.3302)
+    (uvia_dia 0.6858)
+    (uvia_drill 0.3302)
+  )
+
+)

