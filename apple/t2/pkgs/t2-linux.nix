{ lib, buildLinux, fetchFromGitHub, fetchurl, ... }:

let
  patchRepo = fetchFromGitHub {
    owner = "Redecorating";
    repo = "linux-t2-arch";
    rev = "ede033e1549091cda1471114f9d77f1053c40132";
    sha256 = "sha256-0pz282kjwa757mcx35aha2lgvn8py9wx051zw0dh2qnls8qmay0w";
  };

  version = "5.19.12";
  # Snippet from nixpkgs
  modDirVersion = with lib; concatStringsSep "." (take 3 (splitVersion "${version}.0"));

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v5.x/linux-${version}.tar.xz";
    sha256 = "sha256-xDalSMcxLOb8WjRyy+rYle749ShB++fHH9jki9/isLo=";
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
