{ lib, pkgs, ... }:

let
  configDir = ../../config/user;
  fstype =
    if builtins.pathExists (configDir + "/fstype") then
      lib.strings.trim (builtins.readFile (configDir + "/fstype"))
    else
      "ext4";
in
{
  systemd.tmpfiles.rules = [
    "d /mnt/storage-nvme 0755 root root - -"
  ];

  systemd.services.storage-nvme-mount = {
    description = "Mount the largest ${fstype} partition on an NVMe disk";

    after = [
      "local-fs.target"
      "systemd-udev-settle.service"
    ];
    wants = [ "systemd-udev-settle.service" ];
    wantedBy = [ "multi-user.target" ];

    unitConfig = {
      ConditionPathIsMountPoint = "!/mnt/storage-nvme";
    };

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = with pkgs; [
      util-linux
      coreutils
      gawk
    ];

    script =
      "STORAGE_FSTYPE=${fstype}\n"
      + builtins.readFile ../../fragments/storage-nvme-mount.sh
      + builtins.readFile ../../fragments/storage-mount-target.sh;
  };
}
