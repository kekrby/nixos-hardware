{ lib, stdenvNoCC, vmTools, apfs-fuse, kmod }:

let
  runInLinuxVM = drv: lib.overrideDerivation (vmTools.runInLinuxVM drv) (old: { requiredSystemFeatures = []; }); # Workaround for when the first build is done in a container
in
extract: dmg: runInLinuxVM (stdenvNoCC.mkDerivation {
  name = "${dmg}-${extract}-extract";
  nativeBuildInputs = [ apfs-fuse kmod ];

  buildCommand = ''
    modprobe fuse

    mkdir mnt
    apfs-fuse ${dmg} mnt

    path="mnt/root/${extract}"
    if [ -d "$path" ]; then
        mkdir -p "$out"
        cp -r "$path"/* "$out"
    else
        cp "$path" "$out"
    fi
  '';
})
