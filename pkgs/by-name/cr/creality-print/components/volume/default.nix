{
  lib,
  clangStdenv,
  cmake,
  ninja,
  pkg-config,
  boost,
  cereal,
  eigen,
  openvdb,
  onetbb,
  c-blosc,
  zlib,
  src,
  version,
  updateScript,
  buildNumber,
}:
clangStdenv.mkDerivation (finalAttrs: {
  pname = "creality-print-volume";
  inherit src version;
  component = "volume";

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];
  buildInputs = [
    boost
    cereal
    eigen
    openvdb
    onetbb
    c-blosc
    zlib
  ];
  __structuredAttrs = true;
  strictDeps = true;
  dontStrip = true;
  env.NIX_CFLAGS_COMPILE = lib.strings.optionalString clangStdenv.hostPlatform.isLinux "-g";

  postPatch = ''
    cp ${./CMakeLists.txt} CMakeLists.txt
  '';
  cmakeFlags = [
    (lib.strings.cmakeFeature "CREALITYPRINT_VERSION" "${finalAttrs.version}.${buildNumber}")
    (lib.strings.cmakeFeature "PROJECT_VERSION_EXTRA" "Release")
    (lib.strings.cmakeFeature "OpenVDB_CMAKE_PATH" "${openvdb.dev}/lib/cmake/OpenVDB")
    (lib.strings.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
  ];
  postInstall = ''
    install -Dm644 ../LICENSE.txt "$out/share/licenses/creality-print/LICENSE.txt"
  '';

  passthru = { inherit updateScript; };

  meta = {
    description = "OpenVDB mesh and volume conversion library for Creality Print";
    homepage = "https://github.com/CrealityOfficial/CrealityPrint";
    license = lib.licenses.agpl3Only;
    maintainers = [ lib.maintainers._4evy ];
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
})
