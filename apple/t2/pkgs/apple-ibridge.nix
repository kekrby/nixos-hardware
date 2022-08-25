{ stdenv, t2-linux, fetchFromGitHub }:

stdenv.mkDerivation {
  name = "apple-ibridge";

  src = fetchFromGitHub {
    owner = "T2Linux";
    repo = "apple-ib-drv";
    rev = "d8411ad1d87db8491e53887e36c3d37f445203eb";
    sha256 = "sha256-mPx9Y4488pcxnJ5iyeNRuWvnyluHXmOOBnRNw+GAC2k=";
  };

  makeFlags = [
    "KERNELRELEASE=${t2-linux.modDirVersion}"
    "KDIR=${t2-linux.dev}/lib/modules/${t2-linux.modDirVersion}/build"
    "INSTALL_MOD_PATH=$(out)"
  ];

  hardeningDisable = [ "pic" "format" ];
  nativeBuildInputs = t2-linux.moduleBuildDependencies;
}
