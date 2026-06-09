{
  lib,
  pkgs,
  ...
}:

{
  boot.supportedFilesystems.zfs = lib.mkForce false;
  hardware = {
    cpu.amd.updateMicrocode = true;
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    tmp.useTmpfs = true;
  };
}
