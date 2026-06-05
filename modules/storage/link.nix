{ pkgs, ... }:

{
  systemd.services.storage-link = {
    description = "Point /mnt/storage at the fastest mounted storage tier";

    after = [
      "storage-nvme-mount.service"
      "storage-sata-mount.service"
    ];
    wants = [
      "storage-nvme-mount.service"
      "storage-sata-mount.service"
    ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = with pkgs; [
      util-linux
      coreutils
    ];

    script = builtins.readFile ../../fragments/storage-link.sh;
  };
}
