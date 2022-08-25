{ pkgs, lib, config, ... }:

let
  cfg = config.hardware.apple.t2;
in
{
  options.hardware.apple.t2.audioModel = lib.mkOption {
    description = ''
      The model of your Mac which is used to find which audio files must be installed.
      This is only needs to be set if your Mac is in the list of possible values as the default configuration works for almost all of T2 Macs.
    '';
    type = lib.types.enum [ "default" "MacBookPro16,1" "MacBookPro16,4" "MacBookAir9,1" ];
    default = "default";
  };

  config = {
    nixpkgs = {
      overlays = [
        (self: super: {
          t2-alsa-lib = pkgs.alsa-lib.overrideAttrs (new: old: {
            postInstall = old.postInstall or "" + ''
              cp ${./files/audio/${cfg.audioModel}/AppleT2.conf} "$out/share/alsa/cards/AppleT2.conf"
            '';
          });
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

    # For wifi
    hardware.firmware = [ pkgs.t2-firmware ];

    # For audio
    # Audio configuration files are from https://gist.github.com/MCMrARM/c357291e4e5c18894bea10665dcebffb, https://gist.github.com/kevineinarsson/8e5e92664f97508277fefef1b8015fba and https://gist.github.com/bigbadmonster17/8b670ae29e0b7be2b73887f3f37a057b
    boot.kernelParams = [ "pcie_ports=compat" "intel_iommu=on" "iommu=pt" ];
    services.udev.extraRules = builtins.readFile ./files/audio/91-pulseaudio-custom.rules;

    hardware.pulseaudio.package = with pkgs; pulseaudio.override {
      alsa-lib = t2-alsa-lib;
    };

    services.pipewire = rec {
      package = with pkgs; pipewire.override {
        alsa-lib = t2-alsa-lib;
      };

      wireplumber.package = pkgs.wireplumber.override {
        pipewire = package;
      };
    };

    environment.systemPackages = with pkgs; [
      (writeTextDir "share/alsa-card-profile/mixer/profile-sets/apple-t2.conf" (builtins.readFile ./files/audio/${cfg.audioModel}/apple-t2.conf))
    ];

    # Suspend does not work well, it should not be enabled
    services.logind = {
      lidSwitch = "lock";
      lidSwitchDocked = "lock";
      lidSwitchExternalPower = "lock";
    };
  };
}
