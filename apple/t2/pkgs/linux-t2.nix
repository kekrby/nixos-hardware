{ lib, buildLinux, fetchFromGitHub, ... } @ args:

buildLinux (args // rec {
  pname = "linux-t2";
  version = "6.0.11";
  # Snippet from nixpkgs
  modDirVersion = with lib; "${concatStringsSep "." (take 3 (splitVersion "${version}.0"))}-t2";

  src = fetchFromGitHub {
    owner = "kekrby";
    repo = "linux-t2";
    rev = "v${version}-t2";
    sha256 = "sha256-rCn8Fh9dM5WAehQupYNsQVzVic6TAL7rcwl/MGg6VBk=";
  };

  kernelPatches = [];

  structuredExtraConfig = with lib.kernel; {
    APPLE_BCE = module;
    BT_HCIUART_BCM = yes;
    BT_HCIBCM4377 = module;
    HID_APPLE_TOUCHBAR = module;
    HID_APPLE_MAGIC_BACKLIGHT = module;
  };
} // (args.argsOverride or {}))
