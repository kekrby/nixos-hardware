{ stdenv, t2-linux, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "apple-bce";

  src = fetchFromGitHub {
    owner = "kekrby";
    repo = "apple-bce";
    rev = "dc3188291922ca78e4b4422187f42cc722bfba69";
    sha256 = "sha256-goAP/9tn7S8eEtjHceOvrPvQ5nKI2Vzx9lgAdfUeISY=";
  };

  makeFlags = [
    "KERNELRELEASE=${t2-linux.modDirVersion}"
    "KDIR=${t2-linux.dev}/lib/modules/${t2-linux.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = t2-linux.moduleBuildDependencies;
}
