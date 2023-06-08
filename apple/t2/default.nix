{ pkgs, lib, config, ... }:

let
  cfg = config.hardware.apple.t2;

  audioFiles = pkgs.fetchFromGitHub {
    owner = "kekrby";
    repo = "t2-better-audio";
    rev = "e46839a28963e2f7d364020518b9dac98236bcae";
    sha256 = "sha256-x7K0qa++P1e1vuCGxnsFxL1d9+nwMtZUJ6Kd9e27TFs=";
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
  # For keyboard and touchbar
  boot.kernelPackages = with pkgs; recurseIntoAttrs (linuxPackagesFor (callPackage ./pkgs/linux-t2.nix {}));
  boot.initrd.kernelModules = [ "apple_bce" ];
  boot.kernelModules = [ "apple_touchbar" ];

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
}
