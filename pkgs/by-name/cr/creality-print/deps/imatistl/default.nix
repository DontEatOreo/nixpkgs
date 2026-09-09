{
  lib,
  clangStdenv,
  fetchurl,
  fetchpatch,
  writeShellApplication,
  curl,
  gnused,
  coreutils,
  common-updater-scripts,
  cmake,
  ninja,
  unzip,
  dos2unix,
  cgal_5,
  boost183,
  gmp,
  mpfr,
}:
clangStdenv.mkDerivation (finalAttrs: {
  pname = "imatistl";
  version = "4.2-4";

  src = fetchurl {
    url = "mirror://sourceforge/imatistl/ImatiSTL-${finalAttrs.version}.zip";
    hash = "sha256-szfASju9CoihDuwOLmcp+8Dgnua1BnnKAwSaIfFQZxA=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    unzip
    dos2unix
  ];
  buildInputs = [
    cgal_5
    boost183
    gmp
    mpfr
  ];
  __structuredAttrs = true;
  strictDeps = true;

  prePatch = ''
    dos2unix include/Kernel/coordinates.h include/TMesh/edgeHeap.h \
      src/Algorithms/spherize.cpp src/ImatiSTL/computeOuterHull.cpp src/TMesh/edgeHeap.cpp
  '';

  patches = [
    (fetchpatch {
      name = "0001-add-cmake-and-fix-modern-cxx.patch";
      url = "https://raw.githubusercontent.com/CrealityOfficial/CrealityPrint/24b9395c131a9849724c5bf098cba140a207e877/deps/ImatiSTL/0001-add-CMakeLists.patch";
      # Reuse Creality's build definition and C++ fixes, without deleting
      # unrelated Windows projects and samples
      includes = [
        "CMakeLists.txt"
        "include/Kernel/coordinates.h"
        "include/TMesh/edgeHeap.h"
        "src/Algorithms/spherize.cpp"
        "src/ImatiSTL/computeOuterHull.cpp"
        "src/TMesh/edgeHeap.cpp"
      ];
      hash = "sha256-mboq4ZhSG++JnjlKZbVIN5GrViE+mdgimZk0jQNYhHo=";
    })
  ];

  postPatch = ''
    # Let the CMake hook choose optimization flags and dependency paths.
    substituteInPlace CMakeLists.txt \
      --replace-fail 'SET(CMAKE_CXX_FLAGS_DEBUG "''${CMAKE_CXX_FLAGS_DEBUG} -O0")' "" \
      --replace-fail 'SET(CMAKE_CXX_FLAGS_RELEASE "''${CMAKE_CXX_FLAGS_RELEASE} -Os")' "" \
      --replace-fail 'SET(CMAKE_LIBRARY_PATH /opt/local/lib ''${CMAKE_LIBRARY_PATH})' "" \
      --replace-fail 'INCLUDE(''${CGAL_USE_FILE})' ""
    cat ${./install.cmake} >> CMakeLists.txt
    # The stored vertex indices are ints; keep fprintf's %d arguments as ints
    # after the pointer-width conversion introduced by the upstream patch
    substituteInPlace src/ImatiSTL/computeOuterHull.cpp \
      --replace-fail '(intptr_t)t->' '(int)(intptr_t)t->'
    # These messages are already formatted, and Darwin's
    # compiler rejects passing them as printf format strings
    substituteInPlace src/Kernel/tmesh.cpp \
      --replace-fail 'fprintf(stderr,fms);' 'fprintf(stderr,"%s",fms);' \
      --replace-fail 'printf(fms);' 'printf("%s",fms);' \
      --replace-fail 'fprintf(fp, msg);' 'fprintf(fp, "%s", msg);'
  '';

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" false)
    (lib.cmakeBool "CMAKE_POSITION_INDEPENDENT_CODE" true)
    (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
  ];

  passthru.updateScript = lib.getExe (writeShellApplication {
    name = "update-creality-print-imatistl";
    runtimeInputs = [
      curl
      gnused
      coreutils
      common-updater-scripts
    ];
    text = ''
      version=$(curl --fail --silent --show-error --location \
        'https://sourceforge.net/projects/imatistl/rss?path=/' \
        | sed -nE 's@.*ImatiSTL-([0-9]+(\.[0-9]+)*(-[0-9]+)?)\.zip.*@\1@p' \
        | sort -Vu | tail -n 1)
      if [[ -z "$version" ]]; then
        echo "No ImatiSTL release found in the SourceForge feed" >&2
        exit 1
      fi
      update-source-version creality-print.imatistl "$version" \
        --file=pkgs/by-name/cr/creality-print/deps/imatistl/default.nix
    '';
  });

  meta = {
    description = "Triangle mesh processing and repair library";
    homepage = "https://sourceforge.net/projects/imatistl/";
    license = lib.licenses.gpl3Plus;
    maintainers = [ lib.maintainers._4evy ];
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
  };
})
