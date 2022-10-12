{ lib, buildLinux, fetchFromGitHub, fetchurl, ... }:

let
  patchRepo = fetchFromGitHub {
    owner = "kekrby";
    repo = "linux-t2-patches";
    rev = "3e7a6c1c82c8d201708292e075e36fe6b9a934da";
    sha256 = "sha256-va3Ch0uJuBCy3wQo7UCnkm19z+tba8/gdOUKOofY/wk=";
  };

  version = "6.0.1";
  majorVersion = with lib; (elemAt (take 1 (splitVersion version)) 0);
  # Snippet from nixpkgs
  modDirVersion = with lib; concatStringsSep "." (take 3 (splitVersion "${version}.0"));

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v${majorVersion}.x/linux-${version}.tar.xz";
    sha256 = "sha256-jt50Wmk1HqDyf+DEh4DU76N/8IYTXhKTWM4JaUlX6Pk=";
  };
in
buildLinux {
  inherit src version modDirVersion;

  pname = "t2-linux";

  structuredExtraConfig = with lib.kernel; {
    BT_HCIBCM4377 = module;
    BT_HCIUART_BCM = yes;
  };

  # 00xx => arch additions which are not really necesarry
  # 10xx, 201x => apple-bce and apple-ibridge related patches which are not needed as they are built seperately
  kernelPatches = lib.attrsets.mapAttrsToList (file: type: { name = file; patch = "${patchRepo}/${file}"; })
    (lib.attrsets.filterAttrs (file: type: type == "regular" && lib.strings.hasSuffix ".patch" file && !lib.any (x: lib.strings.hasPrefix x file) [ "00" "10" "201" ])
      (builtins.readDir patchRepo));
}
