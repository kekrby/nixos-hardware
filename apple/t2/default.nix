{ pkgs, lib, config, ... }:

let
  cfg = config.hardware.apple.t2;
  overrideAlsa = package: pluginsPath:
    (package.override {
      alsa-lib = pkgs.t2-alsa-lib;
    }).overrideAttrs (new: old: {
      preConfigurePhases = old.preConfigurePhases or [] ++ [ "postPatchPhase" ];

      postPatchPhase = ''
        cp ${./files/audio/profile-sets}/* ${pluginsPath}/alsa/mixer/profile-sets
      '';
    });
in
{
  nixpkgs = {
    overlays = [
      (self: super: {
        t2-alsa-lib = pkgs.alsa-lib.overrideAttrs (new: old: {
          postInstall = old.postInstall or "" + ''
            cp ${./files/audio/alsa-card-configs}/* "$out/share/alsa/cards/"
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

  services.connman.wifi.backend = "iwd";
  networking.networkmanager.wifi.backend = "iwd";

  # For audio
  # Audio configuration files are from https://gist.github.com/MCMrARM/c357291e4e5c18894bea10665dcebffb, https://gist.github.com/kevineinarsson/8e5e92664f97508277fefef1b8015fba and https://gist.github.com/bigbadmonster17/8b670ae29e0b7be2b73887f3f37a057b
  boot.kernelParams = [ "pcie_ports=compat" "intel_iommu=on" "iommu=pt" ];
  services.udev.extraRules = ''
    SUBSYSTEM!="sound", GOTO="pulseaudio_end"
    ACTION!="change", GOTO="pulseaudio_end"
    KERNEL!="card*", GOTO="pulseaudio_end"

    SUBSYSTEMS=="pci", ATTRS{vendor}=="0x106b", ATTRS{device}=="0x1803", PROGRAM="${pkgs.gnused}/bin/sed -n 's/.*AppleT2x\([248]\).*/\1/p' /proc/asound/cards", ENV{PULSE_PROFILE_SET}="apple-t2x%c.conf", ENV{ACP_PROFILE_SET}="apple-t2x%c.conf"

    LABEL="pulseaudio_end"
  '';

  hardware.pulseaudio.package = overrideAlsa pkgs.pluseaudio "src/modules/";

  services.pipewire = rec {
    package = overrideAlsa pkgs.pipewire "spa/plugins/";

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
