{ pkgs, ... }:

{
  systemd.services.qemu-nix-cache = {
    description = "Configure host nix-serve as substituter (QEMU only)";
    after = [ "nix-daemon.service" ];
    wants = [ "nix-daemon.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = [
      pkgs.kmod
      pkgs.coreutils
      pkgs.systemd
    ];

    script = builtins.readFile ../fragments/nix-cache-qemu.sh;
  };
}
