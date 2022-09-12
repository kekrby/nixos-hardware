{ pkgs, lib, config, ... }:

let
  cfg = config.hardware.apple.t2;

  audioFiles = (pkgs.fetchFromGitHub {
    owner = "kekrby";
    repo = "t2-zero-conf-audio";
    rev = "1e10945e326c923d19093a513d66281207438979";
    sha256 = "sha256-op2e1H78pZxJBxQa355znPp0OnneubKjmOcoVJlUgaU=";
  });

  overrideAlsa = package: pluginsPath:
    (package.override {
      alsa-lib = pkgs.t2-alsa-lib;
    }).overrideAttrs (new: old: {
      preConfigurePhases = old.preConfigurePhases or [] ++ [ "postPatchPhase" ];

      postPatchPhase = ''
        cp ${audioFiles}/files/profile-sets/* ${pluginsPath}/alsa/mixer/profile-sets
      '';
    });
in
{
  nixpkgs = {
    overlays = [
      (self: super: {
        t2-alsa-lib = pkgs.alsa-lib.overrideAttrs (new: old: {
          postInstall = old.postInstall or "" + ''
            cp ${audioFiles}/files/alsa-card-configs/* "$out/share/alsa/cards/"
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
  services.udev.extraRules = builtins.readFile (pkgs.substitute {
    src = "${audioFiles}/files/91-pulseaudio-custom.rules";
    replacements = [ "--replace" "/usr/bin/sed" "${pkgs.gnused}/bin/sed" ];
  });

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
