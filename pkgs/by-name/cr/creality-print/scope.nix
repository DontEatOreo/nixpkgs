{
  lib,
  newScope,
  stdenv,
  openvdb,
  boost183,
  withSystemd ? stdenv.hostPlatform.isLinux,
  localSource ? null,
}:
lib.makeScope newScope (self: {
  updateScript = {
    inherit (self.callPackage ./update.nix { }) command attrPath;
  };
  inherit withSystemd;
  release = (builtins.fromJSON (builtins.readFile ./sources.json)).release;
  inherit (self.release) version buildNumber;
  sources = self.callPackage ./sources.nix { inherit localSource; };
  src = self.sources.code.src;

  # Keep the filesystem APIs used by Creality Print and a consistent Boost ABI
  boostBase = boost183;
  boost = self.boostBase.override {
    enableShared = true;
    enableStatic = false;
    extraFeatures = [
      "log"
      "thread"
      "filesystem"
    ];
  };
  openvdb = openvdb.override { boost = self.boostBase; };

  wxwidgets = self.callPackage ./deps/wxwidgets.nix { };
  imatistl = self.callPackage ./deps/imatistl { boost183 = self.boostBase; };
  tpms = self.callPackage ./deps/tpms.nix { inherit (self.sources.tpms) src version; };
  mcut = self.callPackage ./deps/mcut { inherit (self.sources.mcut) src version; };
  resources = self.callPackage ./components/resources.nix {
    inherit (self.sources.resources) src version;
  };
  video = self.callPackage ./components/video { inherit (self.sources.video) src version; };
  vendor = self.callPackage ./components/vendor { inherit (self.sources.vendor) src version; };
  guiVendor = self.callPackage ./components/vendor {
    component = "gui_vendor";
    inherit (self.sources.guiVendor) src version;
  };
  # CGAL mesh booleans and triangulation are expensive template compilations
  geometry = self.callPackage ./components/geometry { inherit (self.sources.geometry) src; };
  volume = self.callPackage ./components/volume { inherit (self.sources.volume) src; };
  engine = self.callPackage ./components {
    component = "engine";
    inherit (self.sources.engine) src;
    engine = null;
    gui = null;
    video = null;
    guiVendor = null;
    imatistl = null;
  };
  gui = self.callPackage ./components {
    component = "gui";
    gui = null;
  };
  unwrapped = self.callPackage ./components { component = "application"; };
  creality-print = self.callPackage ./wrapper.nix { };
})
