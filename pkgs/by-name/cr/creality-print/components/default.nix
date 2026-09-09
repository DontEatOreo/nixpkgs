{
  clangStdenv,
  stdenv,
  lib,
  alibabacloud-oss-cpp-sdk_1_9,
  binutils,
  cmake,
  ninja,
  pkg-config,
  boost,
  cereal,
  cgal_5,
  curl,
  dbus,
  eigen,
  expat,
  ffmpeg,
  glew,
  glfw,
  glib,
  gmp,
  gst_all_1,
  gtk3,
  libsecret,
  libpng,
  mpfr,
  nlopt,
  opencascade-occt_7_6,
  openssl,
  openvdb,
  opencv,
  systemd,
  onetbb,
  webkitgtk_4_1,
  libx11,
  libnoise,
  assimp,
  paho-mqtt-c,
  paho-mqtt-cpp,
  freetype,
  libdeflate,
  lerc,
  libjpeg,
  x264,
  zstd,
  component,
  src,
  version,
  buildNumber,
  updateScript,
  wxwidgets,
  imatistl,
  tpms,
  mcut,
  geometry ? null,
  volume,
  video ? null,
  vendor ? null,
  guiVendor ? null,
  engine ? null,
  gui ? null,
  withSystemd ? stdenv.hostPlatform.isLinux,
}:
let
  isApplication = component == "application";
  buildsGui = component == "gui" || isApplication;
in
# Like OrcaSlicer, this codebase needs substantially less memory with Clang
clangStdenv.mkDerivation (finalAttrs: {
  pname = "creality-print-${if isApplication then "unwrapped" else component}";
  inherit component;
  inherit src version;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ]
  # GNU ar/ranlib produce archives that Apple's linker cannot consume
  ++ lib.lists.optional stdenv.hostPlatform.isLinux binutils
  ++ lib.lists.optional buildsGui wxwidgets;

  buildInputs = [
    tpms
    mcut
    boost
    cereal
    cgal_5
    curl
    eigen
    expat
    freetype
    glew
    glfw
    gmp
    libdeflate
    lerc
    libjpeg
    libpng
    mpfr
    nlopt
    opencascade-occt_7_6
    openssl
    openvdb
    opencv.cxxdev
    onetbb
    assimp
    libnoise
  ]
  ++ lib.lists.optionals buildsGui [
    imatistl
    alibabacloud-oss-cpp-sdk_1_9
    ffmpeg
    glib
    paho-mqtt-c
    paho-mqtt-cpp
    wxwidgets
    x264
  ]
  ++ lib.lists.optional (video != null) video
  # Upstream's top-level Linux configuration also discovers D-Bus for the engine
  ++ lib.lists.optional stdenv.hostPlatform.isLinux dbus
  # GTK/WebKit/GStreamer provide the GUI backend on Linux only
  # On Darwin, wxWidgets uses the native Cocoa + WebKit stack
  ++ lib.lists.optionals (buildsGui && stdenv.hostPlatform.isLinux) [
    gst_all_1.gstreamer
    gtk3
    libsecret
    webkitgtk_4_1
    libx11
  ]
  # Upstream links zstd explicitly only on Apple
  ++ lib.lists.optionals stdenv.hostPlatform.isDarwin [ zstd ]
  ++ lib.lists.optionals (buildsGui && withSystemd) [ systemd ];

  patches = [
    # The bundled OpenVDB finder requires the removed IlmBase::Half target
    ../patches/0001-remove-ilmbase.patch
    # Use the separate OpenCV modules provided by nixpkgs
    ../patches/0002-use-system-opencv.patch
    # metartc6 is not packaged; retain FFmpeg RTSP camera support
    ../patches/0003-make-webrtc-optional.patch
  ]
  ++ lib.lists.optionals (buildsGui && stdenv.hostPlatform.isDarwin) [
    # Top-level configuration honors ENABLE_BREAKPAD on Darwin
    ../patches/0007-guard-macos-breakpad.patch
  ]
  ++ [
    # Share resources and compiled translations with a separate derivation
    ../patches/0009-use-external-resources.patch
    # Import cached internal libraries and preserve their CMake link interfaces
    ../patches/0010-use-prebuilt-components.patch
    ../patches/0011-extract-geometry.patch
    ../patches/0014-use-prebuilt-volume.patch
  ]
  ++ lib.optionals (component == "gui") [
    ../patches/0013-guard-webrtc-consumers.patch
    ../patches/0004-guard-gtk-cell-layout.patch
    ../patches/0005-guard-plater-destruction.patch
    ../patches/0006-fix-media-state-type.patch
  ]
  ++ lib.optionals (component == "gui" && stdenv.hostPlatform.isDarwin) [
    ../patches/0008-fix-macos-outline-accessor.patch
  ]
  ++ lib.optionals isApplication [
    # The entry point also includes this patched GUI header
    ../patches/0006-fix-media-state-type.patch
    ../patches/0012-runtime-resources.patch
  ];

  __structuredAttrs = true;
  strictDeps = true;

  separateDebugInfo = isApplication && stdenv.hostPlatform.isLinux;
  # Preserve archive debug information for the executable's final debug output
  dontStrip = !isApplication;

  env = {
    NLOPT = nlopt;

    NIX_CFLAGS_COMPILE = toString (
      [
        "-Wno-ignored-attributes"
        "-I${opencv.out}/include/opencv4"
        "-Wno-error=incompatible-pointer-types"
        "-Wno-uninitialized"
        "-Wno-unused-result"
        "-Wno-deprecated-declarations"
        # Downgrade Clang errors triggered by these upstream patterns:
        #  - overloaded-virtual: wxWidgets 3.1 bumped some bases to
        #    wxBitmapBundle; Creality still overrides with wxBitmap
        #  - format-security: nixpkgs hardening sets -Werror=format-security;
        #    Creality passes runtime _L("...") strings to ImGui::Text
        "-Wno-error=overloaded-virtual"
        "-Wno-error=format-security"
        "-DBOOST_ALLOW_DEPRECATED_HEADERS"
        "-DBOOST_MATH_DISABLE_STD_FPCLASSIFY"
        "-DBOOST_MATH_NO_LONG_DOUBLE_MATH_FUNCTIONS"
        "-DBOOST_MATH_DISABLE_FLOAT128"
        "-DBOOST_MATH_NO_QUAD_SUPPORT"
        "-DBOOST_MATH_MAX_FLOAT128_DIGITS=0"
        "-DBOOST_CSTDFLOAT_NO_LIBQUADMATH_SUPPORT"
        "-DBOOST_MATH_DISABLE_FLOAT128_BUILTIN_FPCLASSIFY"
        "-DBOOST_LOG_DYN_LINK"
        # Match ImatiSTL's pointer-sized index type on both supported platforms
        "-DIS64BITPLATFORM"
      ]
      ++ lib.lists.optional (!isApplication && stdenv.hostPlatform.isLinux) "-g"
    );

    NIX_LDFLAGS = toString (
      lib.lists.optionals (buildsGui && stdenv.hostPlatform.isLinux) [ "-lwebkit2gtk-4.1" ]
      ++ lib.lists.optionals (buildsGui && withSystemd) [ "-ludev" ]
      # MacDarkMode.mm references WKWebView via a category;
      # upstream's CMake doesn't link WebKit on darwin
      ++ lib.lists.optionals (buildsGui && stdenv.hostPlatform.isDarwin) [
        "-framework"
        "WebKit"
      ]
    );
  };

  postPatch = ''
    cp ${./CrealityComponents.cmake} cmake/CrealityComponents.cmake
    # Keep consumers on the headers installed with the separately built MCUT
    rm -r src/mcut/include
    ln -s ${mcut}/include src/mcut/include

    # Fix nlopt and libnoise lookup
    substituteInPlace cmake/modules/FindNLopt.cmake \
      --replace-fail "nlopt_cxx" "nlopt"
    # Use shared paho-mqtt-cpp instead of static; fix install dir
    substituteInPlace src/CMakeLists.txt \
      --replace-fail "PahoMqttCpp::paho-mqttpp3-static" "PahoMqttCpp::paho-mqttpp3" \
      --replace-fail 'set(CMAKE_INSTALL_BINDIR "./")' ""
  ''
  + lib.optionalString (vendor != null) ''
    # Upstream mixes <miniz.h> with "miniz/miniz.h"; both must resolve to
    # the same file for its #pragma once guard to work.
    rm -r src/miniz
    ln -s ${vendor}/include/miniz src/miniz
  ''
  + lib.strings.optionalString (video != null) ''
    ln -sf ${video}/include/video/RTSPDecoder.h src/video/RTSPDecoder.h
  ''
  + lib.strings.optionalString (buildsGui && stdenv.hostPlatform.isDarwin) ''
    # Nixpkgs' Autotools build supplies wx-config rather than a CMake config
    substituteInPlace src/CMakeLists.txt \
      --replace-fail 'find_package(wxWidgets 3.3 CONFIG REQUIRED' \
        'find_package(wxWidgets 3.3 REQUIRED'
  ''
  + lib.optionalString (component == "engine") ''
    substituteInPlace src/libslic3r/Feature/FuzzySkin/FuzzySkin.cpp \
      --replace-fail '"libnoise/noise.h"' '"noise/noise.h"'

    # Remove hardcoded OpenCASCADE path
    substituteInPlace src/libslic3r/CMakeLists.txt \
      --replace-fail 'set(OpenCASCADE_DIR "''${CMAKE_PREFIX_PATH}/lib/cmake/occt")' ""

  '';

  cmakeFlags = [
    (lib.strings.cmakeFeature "CREALITY_COMPONENT" component)
    (lib.strings.cmakeFeature "CREALITYPRINT_VERSION" "${finalAttrs.version}.${buildNumber}")
    (lib.strings.cmakeFeature "PROJECT_VERSION_EXTRA" "Release")
    (lib.strings.cmakeBool "SLIC3R_STATIC" false)
    (lib.strings.cmakeBool "SLIC3R_GUI" buildsGui)
    (lib.strings.cmakeBool "SLIC3R_FHS" stdenv.hostPlatform.isLinux)
    (lib.strings.cmakeFeature "SLIC3R_GTK" "3")
    (lib.strings.cmakeFeature "BBL_RELEASE_TO_PUBLIC" "1")
    (lib.strings.cmakeFeature "BBL_INTERNAL_TESTING" "0")
    (lib.strings.cmakeBool "SLIC3R_BUILD_TESTS" false)
    (lib.strings.cmakeBool "SLIC3R_PCH" true)
    (lib.strings.cmakeBool "ENABLE_BREAKPAD" false)
    (lib.strings.cmakeBool "ENABLE_WEBRTC_VIDEO" false)
    (lib.strings.cmakeBool "SLIC3R_ENABLE_IMATISTL" buildsGui)
    (lib.strings.cmakeBool "SLIC3R_INSTALL_RESOURCES" false)
    (lib.strings.cmakeBool "CMAKE_SKIP_INSTALL_ALL_DEPENDENCY" true)
    (lib.strings.cmakeFeature "CMAKE_CXX_FLAGS" "-DGL_SILENCE_DEPRECATION")
    (lib.strings.cmakeFeature "CMAKE_INSTALL_BINDIR" (
      if stdenv.hostPlatform.isDarwin then "Applications" else "bin"
    ))
    (lib.strings.cmakeFeature "LIBNOISE_INCLUDE_DIR" "${libnoise}/include")
    (lib.strings.cmakeFeature "LIBNOISE_LIBRARY_RELEASE" "${libnoise}/lib/libnoise-static.a")
    (lib.strings.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
    "-Wno-dev"
  ]
  # GNU ld flag; Apple ld64 doesn't understand --no-as-needed
  ++ lib.lists.optionals stdenv.hostPlatform.isLinux [
    (lib.strings.cmakeFeature "CMAKE_EXE_LINKER_FLAGS" "-Wl,--no-as-needed")
  ]
  ++ lib.lists.optionals stdenv.hostPlatform.isDarwin [
    (lib.strings.cmakeBool "CMAKE_MACOSX_BUNDLE" true)
  ]
  ++ lib.lists.optional (video != null) (
    lib.strings.cmakeFeature "CREALITY_VIDEO_DIR" (toString video)
  )
  ++ lib.lists.optional (vendor != null) (
    lib.strings.cmakeFeature "CREALITY_VENDOR_DIR" (toString vendor)
  )
  ++ lib.lists.optional (guiVendor != null) (
    lib.strings.cmakeFeature "CREALITY_GUI_VENDOR_DIR" (toString guiVendor)
  )
  ++ lib.lists.optional (geometry != null) (
    lib.strings.cmakeFeature "CREALITY_GEOMETRY_DIR" (toString geometry)
  )
  ++ [ (lib.strings.cmakeFeature "CREALITY_VOLUME_DIR" (toString volume)) ]
  ++ lib.lists.optional (engine != null) (
    lib.strings.cmakeFeature "CREALITY_ENGINE_DIR" (toString engine)
  )
  ++ lib.lists.optional (gui != null) (lib.strings.cmakeFeature "CREALITY_GUI_DIR" (toString gui));

  ninjaFlags = [
    (if isApplication then "CrealityPrint" else "creality_component")
  ];

  installTargets = [ (if isApplication then "install" else "creality-install") ];

  postInstall =
    lib.strings.optionalString isApplication ''
      install -Dm644 ../LICENSE.txt "$out/share/licenses/creality-print/LICENSE.txt"
    ''
    + lib.strings.optionalString (isApplication && stdenv.hostPlatform.isLinux) ''
      rm "$out/LICENSE.txt"
    ''
    + lib.strings.optionalString (isApplication && stdenv.hostPlatform.isDarwin) ''
      mkdir -p "$out/bin"
      ln -s "$out/Applications/CrealityPrint.app/Contents/MacOS/CrealityPrint" "$out/bin/CrealityPrint"
    '';

  passthru = {
    inherit updateScript;
    inherit
      wxwidgets
      imatistl
      tpms
      mcut
      video
      vendor
      guiVendor
      geometry
      volume
      engine
      gui
      ;
  };

  meta = {
    description =
      if isApplication then
        "3D printing slicer software by Creality for Creality and other 3D printers"
      else if component == "gui" then
        "GUI library for Creality Print"
      else
        "${lib.strings.toSentenceCase component} libraries for Creality Print";
    homepage = "https://github.com/CrealityOfficial/CrealityPrint";
    changelog = "https://github.com/CrealityOfficial/CrealityPrint/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.agpl3Only;
    # The TPMS infill implementation is shipped as a prebuilt static library
    sourceProvenance = [
      lib.sourceTypes.fromSource
    ]
    ++ lib.lists.optional isApplication lib.sourceTypes.binaryNativeCode;
    maintainers = [ lib.maintainers._4evy ];
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  }
  // lib.attrsets.optionalAttrs isApplication { mainProgram = "CrealityPrint"; };
})
