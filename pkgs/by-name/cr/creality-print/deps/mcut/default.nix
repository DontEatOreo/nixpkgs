{
  lib,
  clangStdenv,
  cmake,
  ninja,
  src,
  version,
  updateScript,
}:
clangStdenv.mkDerivation (finalAttrs: {
  pname = "creality-print-mcut";
  inherit src version;

  # Use the exact copy bundled with Creality Print and MCUT's own build
  sourceRoot = "${finalAttrs.src.name}/src/mcut";

  nativeBuildInputs = [
    cmake
    ninja
  ];
  __structuredAttrs = true;
  strictDeps = true;
  dontStrip = true;
  env.NIX_CFLAGS_COMPILE = toString (
    [ "-fsigned-char" ] ++ lib.lists.optional clangStdenv.hostPlatform.isLinux "-g"
  );

  postPatch = ''
    cat ${./install.cmake} >> CMakeLists.txt
  '';

  cmakeFlags = [
    (lib.strings.cmakeBool "MCUT_BUILD_TESTS" false)
    (lib.strings.cmakeBool "MCUT_BUILD_TUTORIALS" false)
    (lib.strings.cmakeBool "MCUT_BUILD_DOCUMENTATION" false)
    (lib.strings.cmakeBool "MCUT_BUILD_AS_SHARED_LIB" false)
    (lib.strings.cmakeBool "MCUT_BUILD_WITH_COMPUTE_HELPER_THREADPOOL" true)
    (lib.strings.cmakeBool "CMAKE_POSITION_INDEPENDENT_CODE" true)
    (lib.strings.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
  ];

  passthru = { inherit updateScript; };

  meta = {
    description = "MCUT mesh cutting library used by Creality Print";
    homepage = "https://github.com/CrealityOfficial/CrealityPrint";
    license = lib.licenses.gpl3Plus;
    maintainers = [ lib.maintainers._4evy ];
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
})
