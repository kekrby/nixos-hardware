{ pkgs, lib, config, ... }:

let
  cfg = config.hardware.apple.t2;

  audioFiles = (pkgs.fetchFromGitHub {
    owner = "kekrby";
    repo = "t2-better-audio";
    rev = "e4e9fba49c6352adeba315c5fc22e2a41b6059b4";
    sha256 = "sha256-yN2zTms/Vgr9QTtf9ulveOD7dQgHHRbbDs8gbA0AD6M=";
  });
in
{
  nixpkgs = {
    overlays = [
      (self: super: {
        t2-alsa-lib = pkgs.alsa-lib.override {
          alsa-ucm-conf = pkgs.alsa-ucm-conf.overrideAttrs (new: old: {
            postInstall = old.postInstall or "" + ''
              cp -r ${audioFiles}/files/ucm2/* "$out/share/alsa/ucm2/"
            '';
          });
        };
      })
    ] ++ map (pkg: self: super: { ${pkg} = super.callPackage ./pkgs/${super.lib.strings.toLower pkg}.nix {}; })
      [ "extractDiskImage" "t2-firmware" "t2-linux" "apple-bce" "apple-ibridge" ]; # Some packages depend on others so they have to be imported with order

    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "t2-firmware"
    ];
  };

  # For keyboard and touchbar
  boot.kernelPackages = with pkgs; linuxPackagesFor t2-linux;
  boot.extraModulePackages = with pkgs; [ apple-bce apple-ibridge ];
  boot.initrd.kernelModules = [ "apple-bce" ];

  # For audio
  boot.kernelParams = [ "pcie_ports=compat" "intel_iommu=on" "iommu=pt" ];

  hardware.pulseaudio.package = pkgs.pulseaudio.override {
    alsa-lib = pkgs.t2-alsa-lib;
  };

  services.pipewire = rec {
    package = pkgs.pipewire.override {
      alsa-lib = pkgs.t2-alsa-lib;
    };

    wireplumber.package = pkgs.wireplumber.override {
      pipewire = package;
    };
  };

  # Suspend does not work well, it should not be enabled
  services.logind = {
    lidSwitch = "lock";
    lidSwitchDocked = "lock";
    lidSwitchExternalPower = "lock";
  };
}
