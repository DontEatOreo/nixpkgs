{
  stdenv,
  lib,
  fetchFromGitHub,
  meson,
  ninja,
  glib,
  pkg-config,
  udev,
  udevCheckHook,
  libevdev,
  libgudev,
  python3,
  valgrind,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libwacom";
  version = "2.15.0";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitHub {
    owner = "linuxwacom";
    repo = "libwacom";
    rev = "libwacom-${finalAttrs.version}";
    hash = "sha256-fc7ymkyIJ5BvrPxJg7Vw1h1mBy+icr+5kVDecODxRLQ=";
  };

  postPatch = ''
    patchShebangs test/check-files-in-git.sh
  '';

  nativeBuildInputs = [
    pkg-config
    meson
    ninja
    python3
    udevCheckHook
  ];

  buildInputs = [
    glib
    udev
    libevdev
    libgudev
    (python3.withPackages (
      pp: with pp; [
        pp.libevdev
        pp.pyudev
      ]
    ))
  ];

  mesonFlags = [
    (lib.mesonEnable "tests" finalAttrs.finalPackage.doCheck)
    (lib.mesonOption "sysconfdir" "/etc")
  ];

  # Tests are in the `tests` pass-through derivation because one of them is flaky, frequently causing build failures.
  # See https://github.com/NixOS/nixpkgs/issues/328140
  doCheck = false;
  doInstallCheck = true;

  nativeCheckInputs = [
    valgrind
    (python3.withPackages (ps: [
      ps.libevdev
      ps.pytest
      ps.pyudev
    ]))
  ];

  passthru = {
    tests = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };
  };

  meta = {
    platforms = lib.platforms.linux;
    homepage = "https://linuxwacom.github.io/";
    changelog = "https://github.com/linuxwacom/libwacom/blob/${finalAttrs.src.rev}/NEWS";
    description = "Libraries, configuration, and diagnostic tools for Wacom tablets running under Linux";
    teams = [ lib.teams.freedesktop ];
    license = lib.licenses.hpnd;
  };
})
