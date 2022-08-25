{ lib, stdenvNoCC, fetchPartial, extractDiskImage, fetchFromGitHub, python3 }:

let
  firmware = extractDiskImage "/usr/share/firmware" (fetchPartial {
    url = "https://updates.cdn-apple.com/2022SpringFCS/fullrestores/071-08757/74A4F2A1-C747-43F9-A22A-C0AD5FB4ECB6/UniversalMac_12.3_21E230_Restore.ipsw";
    file =  "022-11646-316.dmg";
    sha256 = "sha256-ILmD605YmvnK/gqM2kbdoKGxwmmwkkQ8Cbrb2GnDClA=";
  });

  # `wifi.sh` can already do the necessary renaming and also fixes some issues in NVRAM files so it is used instead of reimplemeting its features
  # It is not used for bluetooth as there are only two files to copy for T2 macs
  asahi-installer = fetchFromGitHub {
    owner = "AsahiLinux";
    repo = "asahi-installer";
    rev = "10ec7b2ad41660bdc6144bb5c6157f236e074fd1";
    sha256 = "sha256-38ZA0hrYH/HtXewpyDQURxIaiPspY80eyivnwbk5wLI=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "t2-firmware";
  version = "12.3";

  nativeBuildInputs = [ python3 ];

  # Adapted from https://lore.kernel.org/linux-acpi/20211226153624.162281-1-marcan@marcan.st/
  buildCommand = ''
    pwd=$(pwd)

    cd ${asahi-installer}
    python3 -m src.firmware.wifi ${firmware}/wifi "$pwd/wifi.tar"

    dir="$out/lib/firmware"
    mkdir -p "$dir"
    cd "$dir"

    tar xf "$pwd/wifi.tar"

    cp "${firmware}"/bluetooth/BCM4377B3*Formosa*PROD*.ptb brcm/brcmbt4377b3-apple,formosa.ptb
    cp "${firmware}"/bluetooth/BCM4377B3*Formosa*PROD*.bin brcm/brcmbt4377b3-apple,formosa.bin
  '';

  meta.license = {
    fullName = "Unfree unredistributable firmware";
    free = false;
    redistributable = false;
  };
}
