{ pkgs, ... }:

{
  systemd.services.qemu-hostname = {
    description = "Override hostname via kernel cmdline (QEMU only)";
    after = [
      "systemd-hostnamed.service"
      "network.target"
    ];
    before = [ "avahi-daemon.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [
      pkgs.kmod
      pkgs.inetutils
      pkgs.coreutils
    ];

    script = builtins.readFile ../fragments/qemu-hostname.sh;
  };
}
