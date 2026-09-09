{
  lib,
  clangStdenv,
  cmake,
  ninja,
  boost,
  cereal,
  cgal_5,
  eigen,
  gmp,
  mpfr,
  onetbb,
  openssl,
  mcut,
  src,
  version,
  updateScript,
  buildNumber,
}:
clangStdenv.mkDerivation (finalAttrs: {
  pname = "creality-print-geometry";
  inherit src version;
  component = "geometry";

  nativeBuildInputs = [
    cmake
    ninja
  ];
  buildInputs = [
    boost
    cereal
    cgal_5
    eigen
    gmp
    mpfr
    onetbb
    openssl
    mcut
  ];
  __structuredAttrs = true;
  strictDeps = true;
  # Preserve the archive's debug information for the executable's debug output
  dontStrip = true;
  env.NIX_CFLAGS_COMPILE = lib.strings.optionalString clangStdenv.hostPlatform.isLinux "-g";

  patches = [
    ../../patches/0011-extract-geometry.patch
  ];
  postPatch = ''
    cp ${./CMakeLists.txt} CMakeLists.txt
    mkdir -p cmake
    cp ${../CrealityComponents.cmake} cmake/CrealityComponents.cmake
    cp ${./library.cmake} src/libslic3r/CMakeLists.txt
    rm -r src/mcut/include
    ln -s ${mcut}/include src/mcut/include
  '';

  cmakeFlags = [
    (lib.strings.cmakeFeature "CREALITY_COMPONENT" "geometry")
    (lib.strings.cmakeFeature "CREALITYPRINT_VERSION" "${finalAttrs.version}.${buildNumber}")
    (lib.strings.cmakeFeature "PROJECT_VERSION_EXTRA" "Release")
    (lib.strings.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
  ];
  installTargets = [ "creality-install" ];

  passthru = { inherit updateScript; };

  meta = {
    description = "CGAL geometry library for Creality Print";
    homepage = "https://github.com/CrealityOfficial/CrealityPrint";
    license = lib.licenses.agpl3Only;
    maintainers = [ lib.maintainers._4evy ];
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
})
