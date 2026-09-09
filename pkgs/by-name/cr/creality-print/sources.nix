{
  lib,
  fetchFromGitHub,
  localSource ? null,
  release,
}:
let
  # Explicit component versions change only when their source hash changes
  inherit (release) rev;
  localTrackedFiles = lib.fileset.gitTracked localSource;
  pins = (builtins.fromJSON (builtins.readFile ./sources.json)).components;
  headerExtensions = [
    "h"
    "hpp"
    "ipp"
    "tpp"
    "in"
    "inl"
    "inc"
  ];
  # Must match creality_vendor_directories in components/CrealityComponents.cmake
  vendorDirectories = [
    "admesh"
    "boost"
    "clipper"
    "clipper2"
    "miniz"
    "minilzo"
    "glu-libtess"
    "qhull"
    "Shiny"
    "semver"
    "libigl"
    "qoi"
  ];
  # Must match creality_gui_vendor_directories in the same CMake helper
  guiVendorDirectories = [
    "glad"
    "imgui"
    "imguizmo"
    "hidapi"
  ];
  components = {
    code = {
      root = true;
      exclude = [
        "resources"
        "localization"
        "deps"
      ];
    };
    engine = {
      root = true;
      exclude = [
        "resources"
        "localization"
        "deps"
      ];
      excludeExts = map (directory: {
        path = "src/${directory}";
        extensions = [
          "cpp"
          "c"
          "mm"
        ];
      }) ([ "slic3r" ] ++ guiVendorDirectories);
    };
    volume = {
      files = [
        "LICENSE.txt"
        "version.inc"
        "src/libslic3r/OpenVDBUtils.cpp"
      ];
      headersUnder = [ "src" ];
    };
    geometry = {
      files = [
        "LICENSE.txt"
        "version.inc"
        "src/libslic3r/CMakeLists.txt"
        "src/libslic3r/CutSurface.cpp"
        "src/libslic3r/IntersectionPoints.cpp"
        "src/libslic3r/TryCatchSignal.cpp"
        "src/libslic3r/Triangulation.cpp"
        "src/libslic3r/MeshBoolean.cpp"
      ];
      dirs = [ "src/libigl" ];
      headersUnder = [ "src" ];
    };
    vendor = {
      files = [ "LICENSE.txt" ];
      dirs = [
        "cmake"
        "src/build-utils"
      ]
      ++ map (directory: "src/${directory}") vendorDirectories;
      headersUnder = [ "src" ];
    };
    guiVendor = {
      files = [ "LICENSE.txt" ];
      dirs = [
        "cmake"
        "src/build-utils"
      ]
      ++ map (directory: "src/${directory}") guiVendorDirectories;
    };
    mcut = {
      files = [ "LICENSE.txt" ];
      dirs = [ "src/mcut" ];
    };
    video = {
      files = [
        "LICENSE.txt"
        "cmake/modules/FindFFmpeg.cmake"
      ];
      dirs = [ "src/video" ];
    };
    resources = {
      files = [
        "LICENSE.txt"
        "src/platform/unix/CrealityPrint.desktop"
      ];
      dirs = [
        "resources"
        "localization"
      ];
    };
    tpms = {
      files = [ "LICENSE.txt" ];
      dirs = [ "deps/CR_TPMS/cr_tpms" ];
    };
  };
  toSparseCheckout =
    sel:
    lib.lists.flatten [
      (lib.lists.optional (sel.root or false) "/*")
      (map (directory: "!/${directory}/") (sel.exclude or [ ]))
      (map (file: "/${file}") (sel.files or [ ]))
      (map (directory: "/${directory}/") (sel.dirs or [ ]))
      (lib.lists.concatMap (
        directory: map (extension: "/${directory}/**/*.${extension}") headerExtensions
      ) (sel.headersUnder or [ ]))
      (lib.lists.concatMap (rule: map (extension: "!/${rule.path}/**/*.${extension}") rule.extensions) (
        sel.excludeExts or [ ]
      ))
    ];
  toFileset =
    sel:
    let
      path = entry: localSource + "/${entry}";
    in
    if sel.root or false then
      lib.fileset.difference localSource (
        lib.fileset.unions (
          map (entry: lib.fileset.maybeMissing (path entry)) ([ ".git" ] ++ (sel.exclude or [ ]))
          ++ map (
            rule: lib.fileset.fileFilter (file: lib.lists.any file.hasExt rule.extensions) (path rule.path)
          ) (sel.excludeExts or [ ])
        )
      )
    else
      lib.fileset.unions (
        map path ((sel.files or [ ]) ++ (sel.dirs or [ ]))
        ++ map (
          directory:
          lib.fileset.fileFilter (file: lib.lists.any file.hasExt headerExtensions) (path directory)
        ) (sel.headersUnder or [ ])
      );
in
lib.attrsets.mapAttrs (name: sel: {
  version = pins.${name}.version or release.version;
  src =
    if localSource != null then
      lib.fileset.toSource {
        root = localSource;
        fileset = lib.fileset.intersection localTrackedFiles (toFileset sel);
      }
    else
      fetchFromGitHub {
        owner = "CrealityOfficial";
        repo = "CrealityPrint";
        inherit rev;
        sparseCheckout = toSparseCheckout sel;
        nonConeMode = true;
        name = "creality-print-${name}-source";
        inherit (pins.${name}) hash;
      };
}) components
