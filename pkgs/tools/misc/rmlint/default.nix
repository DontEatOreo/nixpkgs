{
  lib,
  stdenv,
  cairo,
  elfutils,
  fetchFromGitHub,
  fetchpatch,
  glib,
  gobject-introspection,
  gtksourceview3,
  json-glib,
  makeWrapper,
  pango,
  pkg-config,
  polkit,
  python3,
  scons,
  sphinx,
  util-linux,
  wrapGAppsHook3,
  withGui ? false,
}:

assert withGui -> !stdenv.hostPlatform.isDarwin;

stdenv.mkDerivation rec {
  pname = "rmlint";
  version = "2.10.2";

  src = fetchFromGitHub {
    owner = "sahib";
    repo = "rmlint";
    rev = "v${version}";
    sha256 = "sha256-pOo1YfeqHUU6xyBRFbcj2lX1MHJ+a5Hi31BMC1nYZGo=";
  };

  patches = [
    # pass through NIX_* environment variables to scons.
    ./scons-nix-env.patch
    # fixes https://github.com/sahib/rmlint/issues/664
    (fetchpatch {
      url = "https://github.com/sahib/rmlint/commit/f0ca57ec907f7199e3670038d60b4702d1e1d8e2.patch";
      hash = "sha256-715X+R2BcQIaUV76hoO+EXPfNheOfw4OIHsqSoruIUI=";
    })
  ];

  nativeBuildInputs = [
    pkg-config
    sphinx
    scons
  ]
  ++ lib.optionals withGui [
    makeWrapper
    wrapGAppsHook3
    gobject-introspection
  ];

  buildInputs = [
    glib
    json-glib
    util-linux
  ]
  ++ lib.optionals withGui [
    cairo
    gtksourceview3
    pango
    polkit
    python3
    python3.pkgs.pygobject3
  ]
  ++ lib.optionals (lib.meta.availableOn stdenv.hostPlatform elfutils) [
    elfutils
  ];

  prePatch = ''
    # remove sources of nondeterminism
    substituteInPlace lib/cmdline.c \
      --replace "__DATE__" "\"Jan  1 1970\"" \
      --replace "__TIME__" "\"00:00:00\""
    substituteInPlace docs/SConscript \
      --replace "gzip -c " "gzip -cn "
  '';

  # Otherwise tries to access /usr.
  prefixKey = "--prefix=";

  sconsFlags = lib.optionals (!withGui) [ "--without-gui" ];

  # in GUI mode, this shells out to itself, and tries to import python modules
  postInstall = lib.optionalString withGui ''
    gappsWrapperArgs+=(--prefix PATH : "$out/bin")
    gappsWrapperArgs+=(--prefix PYTHONPATH : "$(toPythonPath $out):$(toPythonPath ${python3.pkgs.pygobject3}):$(toPythonPath ${python3.pkgs.pycairo})")
  '';

  meta = with lib; {
    description = "Extremely fast tool to remove duplicates and other lint from your filesystem";
    homepage = "https://rmlint.readthedocs.org";
    platforms = platforms.unix;
    license = licenses.gpl3;
    maintainers = with maintainers; [
      aaschmid
      koral
    ];
    mainProgram = "rmlint";
  };
}
