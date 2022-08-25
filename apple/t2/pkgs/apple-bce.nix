{ stdenv, t2-linux, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "apple-bce";

  src = fetchFromGitHub {
    owner = "T2Linux";
    repo = "apple-bce-drv";
    rev = "f93c6566f98b3c95677de8010f7445fa19f75091";
    sha256 = "sha256-5jvfDSa7tHp6z+E+RKIalNiLpsku1RNnKoJV2Ps8288=";
  };

  makeFlags = [
    "KERNELRELEASE=${t2-linux.modDirVersion}"
    "KDIR=${t2-linux.dev}/lib/modules/${t2-linux.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = t2-linux.moduleBuildDependencies;
}
