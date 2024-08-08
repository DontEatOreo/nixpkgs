{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "create-dmg";
  version = "1.2.2";

  src = fetchFromGitHub {
    owner = "create-dmg";
    repo = "create-dmg";
    rev = "v${finalAttrs.version}";
    hash = "sha256-oWrQT9nuFcJRwwXd5q4IqhG7M77aaazBG0+JSHAzPvw=";
  };

  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail "prefix = /usr/local" "prefix = ''${out}" \
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = " A shell script to build fancy DMGs";
    homepage = "https://github.com/create-dmg/create-dmg";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ donteatoreo ];
    platforms = lib.platforms.darwin;
  };
})
