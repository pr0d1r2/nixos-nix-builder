{ pkgs, ... }:

{
  systemd.services.nix-store-overlay = {
    description = "Move nix store overlay to fastest storage";
    wantedBy = [ "multi-user.target" ];
    after = [
      "storage-link.service"
      "qemu-9p-store.service"
    ];
    requires = [ "storage-link.service" ];
    wants = [ "qemu-9p-store.service" ];
    before = [ "nix-daemon.service" ];
    path = [
      pkgs.coreutils
      pkgs.util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = builtins.readFile ../../fragments/nix-store-overlay.sh;
    preStop = builtins.readFile ../../fragments/nix-store-overlay-stop.sh;
  };
}
