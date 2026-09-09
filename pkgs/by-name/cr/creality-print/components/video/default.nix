{
  lib,
  clangStdenv,
  cmake,
  ninja,
  ffmpeg,
  src,
  version,
  updateScript,
}:
clangStdenv.mkDerivation (finalAttrs: {
  pname = "creality-print-video";
  inherit src version;

  sourceRoot = "${finalAttrs.src.name}/src/video";

  postUnpack = ''
    cp --preserve=timestamps "$src/cmake/modules/FindFFmpeg.cmake" "$sourceRoot/"
  '';

  postPatch = ''
    cp ${./CMakeLists.txt} CMakeLists.txt
  '';
  nativeBuildInputs = [
    cmake
    ninja
  ];
  buildInputs = [ ffmpeg ];
  __structuredAttrs = true;
  strictDeps = true;
  dontStrip = true;
  env.NIX_CFLAGS_COMPILE = toString (
    [ "-fsigned-char" ] ++ lib.lists.optional clangStdenv.hostPlatform.isLinux "-g"
  );

  passthru = { inherit updateScript; };

  meta = {
    description = "FFmpeg RTSP camera decoder for Creality Print";
    homepage = "https://github.com/CrealityOfficial/CrealityPrint";
    license = lib.licenses.agpl3Only;
    maintainers = [ lib.maintainers._4evy ];
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
})
