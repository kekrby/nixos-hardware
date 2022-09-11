{ stdenv, t2-linux, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "apple-bce";

  src = fetchFromGitHub {
    owner = "kekrby";
    repo = "apple-bce";
    rev = "170e7ad37166319f1a13b37e52f83a43608826b5";
    sha256 = "sha256-7f/j5YpP5xBPXPXIvjk1wSBvGbwXMvjJ5fPgW/Frgio=";
  };

  makeFlags = [
    "KERNELRELEASE=${t2-linux.modDirVersion}"
    "KDIR=${t2-linux.dev}/lib/modules/${t2-linux.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = t2-linux.moduleBuildDependencies;
}
