{
  lib,
  writeShellApplication,
  python3,
  gh,
  git,
  nix,
  nix-prefetch-git,
}:
let
  updater = writeShellApplication {
    name = "update-creality-print";
    runtimeInputs = [
      python3
      gh
      git
      nix
      nix-prefetch-git
    ];
    text = ''
      exec python3 ${./update.py} "$@"
    '';
  };
in
{
  command = [ (lib.getExe updater) ];
  attrPath = "creality-print";
}
