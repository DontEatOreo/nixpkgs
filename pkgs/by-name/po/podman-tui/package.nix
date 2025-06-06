{
  lib,
  stdenv,
  fetchFromGitHub,
  buildGoModule,
  testers,
  podman-tui,
}:

buildGoModule rec {
  pname = "podman-tui";
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "containers";
    repo = "podman-tui";
    rev = "v${version}";
    hash = "sha256-t9VhDl4pBW5H5RhpskU8Us9NxpPJmyishKROvbAc2V0=";
  };

  vendorHash = null;

  env.CGO_ENABLED = 0;

  tags = [
    "containers_image_openpgp"
    "remote"
  ] ++ lib.optional stdenv.hostPlatform.isDarwin "darwin";

  ldflags = [
    "-s"
    "-w"
  ];

  checkFlags =
    let
      skippedTests = [
        # Disable flaky tests
        "TestDialogs"
        "TestVoldialogs"
      ];
    in
    [ "-skip=^${builtins.concatStringsSep "$|^" skippedTests}$" ];

  passthru.tests.version = testers.testVersion {
    package = podman-tui;
    command = "HOME=$(mktemp -d) podman-tui version";
    version = "v${version}";
  };

  meta = {
    homepage = "https://github.com/containers/podman-tui";
    description = "Podman Terminal UI";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ aaronjheng ];
    mainProgram = "podman-tui";
  };
}
