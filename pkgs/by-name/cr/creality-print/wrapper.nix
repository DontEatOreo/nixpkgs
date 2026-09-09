{
  lib,
  stdenvNoCC,
  makeWrapper,
  overrideScope,
  wrapGAppsHook3,
  glew,
  glib-networking,
  gst_all_1,
  gtk3,
  hicolor-icon-theme,
  unwrapped,
  resources,
  sources,
  updateScript,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "creality-print";
  inherit (unwrapped) version meta;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  __structuredAttrs = true;
  strictDeps = true;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.lists.optionals stdenvNoCC.hostPlatform.isLinux [ wrapGAppsHook3 ];
  buildInputs = lib.lists.optionals stdenvNoCC.hostPlatform.isLinux [
    glib-networking
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-good
    gtk3
    hicolor-icon-theme
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -rs ${unwrapped}/. "$out/"
    find "$out" -type d -exec chmod u+w {} +
    ln -s ${finalAttrs.passthru.resources}/share/CrealityPrint "$out/share/CrealityPrint"
    runHook postInstall
  '';

  postInstall =
    lib.strings.optionalString stdenvNoCC.hostPlatform.isLinux ''
      cp -rs ${finalAttrs.passthru.resources}/share/applications "$out/share/"
      cp -rs ${finalAttrs.passthru.resources}/share/icons "$out/share/"
    ''
    + lib.strings.optionalString stdenvNoCC.hostPlatform.isDarwin ''
      bundle="$out/Applications/CrealityPrint.app/Contents"
      ln -s ${finalAttrs.passthru.resources}/share/CrealityPrint "$bundle/Resources"
      rm "$bundle/MacOS/CrealityPrint" "$out/bin/CrealityPrint"
      makeWrapper ${unwrapped}/Applications/CrealityPrint.app/Contents/MacOS/CrealityPrint \
        "$bundle/MacOS/CrealityPrint" \
        --set CREALITY_PRINT_RESOURCES ${finalAttrs.passthru.resources}/share/CrealityPrint
      ln -s "$bundle/MacOS/CrealityPrint" "$out/bin/CrealityPrint"
    '';

  preFixup = lib.strings.optionalString stdenvNoCC.hostPlatform.isLinux ''
    gappsWrapperArgs+=(
      --set CREALITY_PRINT_RESOURCES "${finalAttrs.passthru.resources}/share/CrealityPrint"
      --prefix LD_LIBRARY_PATH : "${
        lib.strings.makeLibraryPath [
          unwrapped
          glew
        ]
      }"
      --set WEBKIT_DISABLE_COMPOSITING_MODE 1
    )
  '';

  passthru = {
    overrideScope = f: (overrideScope f).creality-print;
    inherit
      unwrapped
      updateScript
      resources
      sources
      ;
    inherit (unwrapped)
      src
      vendor
      guiVendor
      geometry
      volume
      engine
      gui
      tpms
      wxwidgets
      imatistl
      mcut
      video
      ;
  }
  // lib.attrsets.optionalAttrs stdenvNoCC.hostPlatform.isLinux { inherit (unwrapped) debug; };
})
