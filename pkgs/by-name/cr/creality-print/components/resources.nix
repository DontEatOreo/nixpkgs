{
  lib,
  stdenvNoCC,
  gettext,
  src,
  version,
  updateScript,
}:
stdenvNoCC.mkDerivation {
  pname = "creality-print-resources";
  inherit src version;

  nativeBuildInputs = [ gettext ];
  __structuredAttrs = true;
  strictDeps = true;
  dontConfigure = true;

  buildPhase = ''
    runHook preBuild
    for po in localization/i18n/*/CrealityPrint_*.po; do
      language="''${po##*/CrealityPrint_}"
      language="''${language%.po}"
      mkdir -p "resources/i18n/$language"
      msgfmt --check-format "$po" -o "resources/i18n/$language/CrealityPrint.mo"
    done
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share"
    mv resources "$out/share/CrealityPrint"
    install -Dm644 src/platform/unix/CrealityPrint.desktop \
      "$out/share/applications/CrealityPrint.desktop"
    for size in 32 128 192; do
      install -Dm644 "$out/share/CrealityPrint/images/CrealityPrint_''${size}px.png" \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/CrealityPrint.png"
    done
    install -Dm644 LICENSE.txt "$out/share/licenses/creality-print/LICENSE.txt"
    runHook postInstall
  '';

  passthru = { inherit updateScript; };

  meta = {
    description = "Resources and translations for Creality Print";
    homepage = "https://github.com/CrealityOfficial/CrealityPrint";
    license = lib.licenses.agpl3Only;
    maintainers = [ lib.maintainers._4evy ];
    platforms = lib.platforms.all;
  };
}
