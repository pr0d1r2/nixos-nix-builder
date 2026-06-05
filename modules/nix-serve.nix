{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.nix-serve ];

  environment.etc."nix/signing-key.sec" = {
    source = ../secrets/signing-key.sec;
    mode = "0600";
  };

  systemd.services.nix-serve = {
    description = "Nix binary cache (port 5000)";
    wantedBy = [ "multi-user.target" ];
    after = [
      "nix-daemon.service"
      "nix-store-overlay.service"
    ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.nix-serve}/bin/nix-serve -p 5000 --sign-key-path /etc/nix/signing-key.sec";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];
}
