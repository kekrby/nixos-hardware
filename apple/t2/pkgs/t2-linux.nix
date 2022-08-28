{ lib, buildLinux, fetchFromGitHub, fetchurl, ... }:

let
  patchRepo = fetchFromGitHub {
    owner = "Redecorating";
    repo = "mbp-16.1-linux-wifi";
    rev = "28559e3ebf40176121b35d2b5dfb7878ce76fdf8";
    sha256 = "sha256-bflUMRmnXVEWwxJOCWzzLTtBYXMmHiLN75P1Ii/AoYc=";
  };

  version = "5.19.4";
  # Snippet from nixpkgs
  modDirVersion = with lib; concatStringsSep "." (take 3 (splitVersion "${version}.0"));

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v5.x/linux-${version}.tar.xz";
    sha256 = "sha256-qSFLlwha+Y38qqjC6O/0hYwdU9zNbFiTHPewRV/5v4c=";
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
  # 10xx => apple-bce and apple-ibridge related patches which are not needed as they are built seperately
  kernelPatches = lib.attrsets.mapAttrsToList (file: type: { name = file; patch = "${patchRepo}/${file}"; })
    (lib.attrsets.filterAttrs (file: type: type == "regular" && lib.strings.hasSuffix ".patch" file && !lib.strings.hasPrefix "00" file && !lib.strings.hasPrefix "10" file)
      (builtins.readDir patchRepo));
}
