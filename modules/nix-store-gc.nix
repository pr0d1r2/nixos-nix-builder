{ pkgs, ... }:

{
  systemd.services.nix-store-gc = {
    description = "Garbage-collect nix store when disk usage exceeds 80%";
    after = [ "nix-store-overlay.service" ];

    serviceConfig = {
      Type = "oneshot";
    };

    path = [
      pkgs.coreutils
      pkgs.nix
    ];

    script = builtins.readFile ../fragments/nix-store-gc.sh;
  };

  systemd.timers.nix-store-gc = {
    description = "Periodic nix store garbage collection";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "*-*-* 03:00:00 UTC";
      Persistent = true;
    };
  };
}
