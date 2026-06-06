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
      OnBootSec = "5min";
      OnUnitActiveSec = "1h";
      RandomizedDelaySec = "5min";
    };
  };
}
