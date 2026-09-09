{
  lib,
  clangStdenv,
  cmake,
  ninja,
  boost,
  eigen,
  onetbb,
  src,
  version,
  updateScript,
  component ? "vendor",
}:
clangStdenv.mkDerivation {
  pname = "creality-print-${if component == "gui_vendor" then "gui-vendor" else "vendor"}";
  inherit src version component;

  nativeBuildInputs = [
    cmake
    ninja
  ];
  buildInputs = [
    boost
  ]
  ++ lib.optionals (component == "vendor") [
    eigen
    onetbb
  ];
  __structuredAttrs = true;
  strictDeps = true;
  dontStrip = true;
  env.NIX_CFLAGS_COMPILE = lib.strings.optionalString clangStdenv.hostPlatform.isLinux "-g";

  postPatch = ''
    cp ${./CMakeLists.txt} CMakeLists.txt
    cp ${../CrealityComponents.cmake} cmake/CrealityComponents.cmake
  '';

  cmakeFlags = [
    (lib.strings.cmakeFeature "CREALITY_COMPONENT" component)
    (lib.strings.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
  ];
  installTargets = [ "creality-install" ];

  passthru = { inherit updateScript; };

  meta = {
    description = "Bundled ${
      if component == "gui_vendor" then "GUI" else "engine"
    } support libraries for Creality Print";
    homepage = "https://github.com/CrealityOfficial/CrealityPrint";
    license = lib.licenses.agpl3Only;
    maintainers = [ lib.maintainers._4evy ];
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
}
