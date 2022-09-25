{ pkgs, lib, config, ... }:

let
  cfg = config.hardware.apple.t2;

  audioFiles = pkgs.fetchFromGitHub {
    owner = "kekrby";
    repo = "t2-better-audio";
    rev = "adbd7640b4055dc79a334ea4d31572e9599b4365";
    sha256 = "sha256-eoh64WAqhKRJ4m/8WRoX1kn1YJQ9+VicuCkOGk50YuQ=";
  };

  overrideAudioFiles = package: pluginsPath:
    package.overrideAttrs (new: old: {
      preConfigurePhases = old.preConfigurePhases or [] ++ [ "postPatchPhase" ];

      postPatchPhase = ''
        cp -r ${audioFiles}/files/{profile-sets,paths} ${pluginsPath}/alsa/mixer/
      '';
    });
in
{
  nixpkgs.overlays = map (pkg: self: super: { ${pkg} = super.callPackage ./pkgs/${super.lib.strings.toLower pkg}.nix {}; })
    [ "t2-linux" "apple-bce" "apple-ibridge" ]; # Some packages depend on others so they have to be imported with order

  # For keyboard and touchbar
  boot.kernelPackages = with pkgs; linuxPackagesFor t2-linux;
  boot.extraModulePackages = with pkgs; [ apple-bce apple-ibridge ];
  boot.initrd.kernelModules = [ "apple-bce" ];

  # For audio
  boot.kernelParams = [ "pcie_ports=compat" "intel_iommu=on" "iommu=pt" ];
  services.udev.extraRules = builtins.readFile (pkgs.substitute {
    src = "${audioFiles}/files/91-audio-custom.rules";
    replacements = [ "--replace" "/usr/bin/sed" "${pkgs.gnused}/bin/sed" ];
  });

  hardware.pulseaudio.package = overrideAudioFiles pkgs.pulseaudio "src/modules/";

  services.pipewire = rec {
    package = overrideAudioFiles pkgs.pipewire "spa/plugins/";

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
