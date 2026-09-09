{
  callPackage,
  stdenv,
  withSystemd ? stdenv.hostPlatform.isLinux,
  componentOverrides ? (_final: _prev: { }),
  # Use the same component selections with a local, Git-tracked upstream checkout
  localSource ? null,
}:
let
  scope =
    (callPackage ./scope.nix { inherit withSystemd localSource; }).overrideScope
      componentOverrides;
in
scope.creality-print
