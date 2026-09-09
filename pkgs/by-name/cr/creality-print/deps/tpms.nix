{
  lib,
  stdenvNoCC,
  src,
  version,
  updateScript,
}:
stdenvNoCC.mkDerivation {
  pname = "creality-print-tpms";
  inherit src version;

  __structuredAttrs = true;
  strictDeps = true;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  # Preserve the vendor archive, including its symbol table
  dontStrip = true;

  installPhase =
    let
      platform = if stdenvNoCC.hostPlatform.isDarwin then "mac/arm64" else "linux/x86_64";
    in
    ''
      runHook preInstall
      install -Dm644 "$src/deps/CR_TPMS/cr_tpms/include/cr_tpms_library.h" \
        "$out/include/cr_tpms_library.h"
      install -Dm644 "$src/deps/CR_TPMS/cr_tpms/lib/${platform}/libcr_tpms_library.a" \
        "$out/lib/libcr_tpms_library.a"
      install -Dm644 "$src/LICENSE.txt" "$out/share/licenses/creality-print/LICENSE.txt"
      runHook postInstall
    '';

  passthru = { inherit updateScript; };

  meta = {
    description = "Prebuilt TPMS infill library distributed with Creality Print";
    homepage = "https://github.com/CrealityOfficial/CrealityPrint";
    license = lib.licenses.agpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    maintainers = [ lib.maintainers._4evy ];
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
}
