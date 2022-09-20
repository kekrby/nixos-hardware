{ lib, buildLinux, fetchFromGitHub, fetchurl, ... }:

let
  patchRepo = fetchFromGitHub {
    owner = "Redecorating";
    repo = "linux-t2-arch";
    rev = "65a5575de77284c0a36c95510ebaaa8e8a867bc5";
    sha256 = "sha256-c5cTWLyGsuudyvz3PIDgJ7sd8veB/x6z/XpsK7M82lY=";
  };

  version = "5.19.10";
  # Snippet from nixpkgs
  modDirVersion = with lib; concatStringsSep "." (take 3 (splitVersion "${version}.0"));

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v5.x/linux-${version}.tar.xz";
    sha256 = "sha256-Z9q5Muhfm5BiztZmyOqIgjCh2t/WJLBa6ta268bTvdU=";
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
