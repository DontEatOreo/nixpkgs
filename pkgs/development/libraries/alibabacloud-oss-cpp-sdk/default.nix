{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  curl,
  openssl,
}:

let
  generic =
    { version, hash }:
    stdenv.mkDerivation (finalAttrs: {
      pname = "alibabacloud-oss-cpp-sdk";
      inherit version;

      src = fetchFromGitHub {
        owner = "aliyun";
        repo = "aliyun-oss-cpp-sdk";
        tag = finalAttrs.version;
        inherit hash;
      };

      __structuredAttrs = true;
      strictDeps = true;

      nativeBuildInputs = [ cmake ];

      buildInputs = [
        curl
        openssl
      ];

      # Upstream enables -Werror, including warnings from newer compilers
      env.NIX_CFLAGS_COMPILE = "-Wno-error";

      cmakeFlags = [
        (lib.cmakeBool "BUILD_SHARED_LIBS" true)
        (lib.cmakeBool "BUILD_SAMPLE" false)
        (lib.cmakeBool "BUILD_TESTS" false)
        (lib.cmakeFeature "CMAKE_POLICY_VERSION_MINIMUM" "3.5")
      ];

      meta = {
        description = "Alibaba Cloud OSS SDK for C++";
        homepage = "https://github.com/aliyun/aliyun-oss-cpp-sdk";
        changelog = "https://github.com/aliyun/aliyun-oss-cpp-sdk/releases/tag/${finalAttrs.version}";
        license = lib.licenses.asl20;
        maintainers = [ lib.maintainers._4evy ];
        platforms = lib.platforms.unix;
      };
    });
in
{
  # Match the dependency version pinned by Creality Print
  alibabacloud-oss-cpp-sdk_1_9 = generic {
    version = "1.9.2";
    hash = "sha256-XOtOtU4H4oIgNEUBbC06VGpLEuzmPaeRRpCRIUuBL6g=";
  };

  alibabacloud-oss-cpp-sdk_1_10 = generic {
    version = "1.10.1";
    hash = "sha256-dT2NsP21fx7u4DLrVk/GzpamYEzepsq78sOYEVb6JO4=";
  };
}
