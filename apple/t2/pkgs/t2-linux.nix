{ lib, buildLinux, fetchFromGitHub, fetchurl, ... }:

let
  patchRepo = fetchFromGitHub {
    owner = "kekrby";
    repo = "linux-t2-patches";
    rev = "2cab5e4525b9dd7377b067cf645bae6f460fe30b";
    sha256 = "sha256-EavU+90IY8SKquT8DhXnjASXFvy/PgxvwZpsDw85d5U=";
  };

  version = "6.0.3";
  majorVersion = with lib; (elemAt (take 1 (splitVersion version)) 0);
  # Snippet from nixpkgs
  modDirVersion = with lib; concatStringsSep "." (take 3 (splitVersion "${version}.0"));

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v${majorVersion}.x/linux-${version}.tar.xz";
    sha256 = "sha256-sNUiJBgFeU2K86Z9MxugY6Fklsb7bTZdSPfteO4cPc8=";
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
