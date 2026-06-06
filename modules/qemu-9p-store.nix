{ pkgs, ... }:

{
  systemd.services.qemu-9p-store = {
    description = "Mount host nix store via 9p (QEMU only)";
    wantedBy = [ "multi-user.target" ];
    before = [ "nix-store-overlay.service" ];
    after = [ "systemd-modules-load.service" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      SuccessExitStatus = "0 1 2 32";
    };

    path = [
      pkgs.kmod
      pkgs.util-linux
      pkgs.coreutils
    ];

    script = builtins.readFile ../fragments/qemu-9p-store-mount.sh;
    preStop = builtins.readFile ../fragments/qemu-9p-store-unmount.sh;
  };
}
