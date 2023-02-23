{ lib, buildLinux, fetchFromGitHub, fetchurl, ... } @ args:

let
  patchRepo = fetchFromGitHub {
    owner = "t2linux";
    repo = "linux-t2-patches";
    rev = "cab84310e3f7bae984cb3a7e82d099922d6b4f57";
    sha256 = "sha256-8BO8WhBzmx+o7EtgzPx2vKFolgV09RxCij1Om/P7/1M=";
  };

  version = "6.2";
  majorVersion = with lib; (elemAt (take 1 (splitVersion version)) 0);
in
buildLinux (args // {
  inherit version;

  pname = "linux-t2";
  # Snippet from nixpkgs
  modDirVersion = with lib; "${concatStringsSep "." (take 3 (splitVersion "${version}.0"))}";

  src = fetchurl {
    url = "mirror://kernel/linux/kernel/v${majorVersion}.x/linux-${version}.tar.xz";
    sha256 = "sha256-dIYvqKtA7a6FuzOFwLcf4QMoi85RhSbWMZeACzy97LE=";
  };

  structuredExtraConfig = with lib.kernel; {
    APPLE_BCE = module;
    BT_HCIUART_BCM = yes;
    BT_HCIBCM4377 = module;
    HID_APPLE_TOUCHBAR = module;
    HID_APPLE_MAGIC_BACKLIGHT = module;
  };

  kernelPatches = lib.attrsets.mapAttrsToList (file: type: { name = file; patch = "${patchRepo}/${file}"; })
    (lib.attrsets.filterAttrs (file: type: type == "regular" && lib.strings.hasSuffix ".patch" file)
      (builtins.readDir patchRepo));
} // (args.argsOverride or {}))
